
# Using EI hpc system, a primer
Documentation to get used to npb hpc system and submiting job with slurm/singularity/conda

## General infos

EI hpc system is a cluster, each server is called a node. When connecting to the hpc, you will have access to a submission node, it can be different each time you connect. At the time of writing this, there is only 2 different submission nodes, v0548 and v0558. Once connected to a submission node, you can access the other one with ssh, for instance `ssh raguidea@v0548.`

The system is thought out as a place where you submit jobs/tasks. It is discouraged to use the submission node to do anything else but submitting a job to the cluster. For instance gzip will be terminated after 1 min and you'll receive a mail about starting an interactive session. Indeed for any day to day tasks, you can start an interactive session which will be a job submitted to the cluster.

#### Interactive sessions
They can be launched by just typing `interactive`
You can use -h for all option, but mostly you can ask for cpu with `-c` and memory with `--mem` 
They are one-off, one you exit disconnect you can't rejoin.

#### Internet access
Hpc is mostly isolated from internet. By default you can't download database/software or access the internet. As this is not a viable setup there is a node you can connect to do so. That is the software node. To access is just type `software`

#### Database
Some databases are stored in a common folder /ei/public/databases. Adding, updating these needs a ticket.
 
#### Storage space
- scratch/vs backed
- project structuration
- group project folder
- check for available space

#### Transfert files
- (command line) aspera: https://ascptrans.cis.nbi.ac.uk
- (browser/laptop) open on demand: https://ood.hpc.nbi.ac.uk/pun/sys/dashboard/
- (cheating) use the Qib-vm mounted fs, whith access to all Projects. This can be accessed through ssh but using a vpn. Typical scp/rsync are able to work. 

## Initial setup
-  transfert your .bashrc to get you aliases/PS1 .... 
- nothing is installed, you have to do local install for everything you want to use outside of singularity, either build from source locally or only use singularity
- List of things missing:
	- git
	- byobu (better than screen, or tmux)
	- ....

## Singularity
### Principle
- singularity generate containers: multi os/platform compatible immutable images 
- you can also build and work with modifiable containers called "sandbox". It looks like a folder and can be modified to install any software/dependencies.
### Building a sandbox
- example definition file, see ubuntu.def/centos7.def in repos
```bash
sudo singularity build --sandbox <SANDBOX_PATH> <DEFINITION_FILE>
```
- this command works even if you don't have sudo rigth (don't ask me why)
### Running a command inside a sandbox or an image
##### Basic
```bash
singularity exec  -w <SANDBOX_PATH> <COMMAND>
```
- you can work open a shell inside the container by doing
```bash
singularity exec  -w <SANDBOX_PATH> bash
```
##### Mounting FileSystem
- **This is useful on software node, but by default there is automount on all other nodes (/hpc/home, /ei/projects, ... are already mounted)** 
- No access to anything outside of container, be that software or.... **files**
- To get access to files outside the container, you need to mount filesystem external to the container to a location inside the container
-  If we continue with command bash, it looks like:
```bash
singularity exec --bind <OUTSIDE_PATH>:<INSIDE_PATH> -w <SANDBOX_PATH> bash
```
- **WARNING** the folder `<INSIDE_PATH>` need to exist and be empty inside your container. You can create it before mounting filesystem or inside the definition file
- It is easier to keep path identical between inside the container and outside, this will help with symlinks
- A typical example would be

```bash
singularity exec -w <SANDBOX_PATH> bash -c "mkdir -p $HOME"
singularity exec --bind $HOME:$HOME -w <SANDBOX_PATH> bash
```

##### Aesthetics
- to make it so the terminal inside the container looks like a normal terminal, just pass the PS1 variable to env:
```bash
singularity exec --env PS1="$(echo $PS1 |sed 's/\\h/\\h (sglrt)/g') " --bind $HOME:$HOME -w <SANDBOX_PATH> bash
```
### Modify/install things in the sandbox
- the `exec` option doesn't let you use sudo right inside the bash terminal instead use:

```bash
sudo singularity shell -w <SANDBOX_PATH>
```
- this open an interactive shell inside the container with sudo rigth. 
- **WARNING** it is not possible to use this command to mount filesystems with the bind argument

### Ease of life commands
- you can make it painless use bash inside singularity, by adding these command into your .bashrc file
```bash
function bash2() {
singularity exec --env PS1="$(echo $PS1 |sed 's/\\h/\\h (sglrt)/g') " --bind $HOME:$HOME -w <SANDBOX_PATH> bash
}
```
```bash
function modify() {
sudo singularity shell -w <SANDBOX_PATH>
}
```

## Slurm
#### Concepts
- The principle of slurm is that you submit a job to a queue (partition), with requirement of resources (cpu/ram/gpu). It is queued, if there is space the job is started. It is not a fifo queue, rare user will get priority over people having intensive usage.
- If your task uses more resources than what you asked (ask for 100mo ram uses 101mo), it will be automatically terminated.

- There are different queues, they are called **Partition**. They have different node (servers) with different specs. Usually partitions are intended for different use cases and may have limit in term of how long a task can run. For example, ei-short is for under 45min tasks while tasks in ei-largemem can run for 90 days and request large amount of memory (>500G). You can find all partitions [here](https://nbip-research-computing.atlassian.net/wiki/spaces/CIS/pages/5177513/Queue+Partition+Limits). 
- Note: a job can't be started on ei-largemem with less than 550G of memory requirement.

#### Nodes available
- not exhaustive/precise, but [here](https://nbip-research-computing.atlassian.net/wiki/spaces/CIS/pages/5177376/High+Performance+Computing+at+NBI).
- Most nodes are 32cpu with 128/256Gb.

#### submiting job
- Proposed workflow:
	- write a bash script with you task (**script_task**).
	- write  a wrapper bash script (**script_wrapper**) to submit you script_task from withing singularity.
#### script_task
Script is in github repos, here is an example,
```bash
#!/bin/bash
source /hpc-home/raguidea/.bashrc_non_interactive
conda activate
snakemake -s metaphIan2.snake --cores 100 --rerun-incomplete
```
The `.bashrc_non_interactive`  is just a file with aliases and conda install to be able to use conda

#### script_wrapper
Script is in github repos, here is an example,
```bash
#!/bin/bash -e

#SBATCH -p ei-long,ei-largemem #partition
#SBATCH -N 1 #all cores on the same server (node)
#SBATCH -c 100 #all cores on the same server (node)
#SBATCH --mem=600000 #Ram for total task (in Mo)
#SBATCH -o $(pwd)/slurm.%N.%j.out #stdout
#SBATCH -e $(pwd)/slurm.%N.%j.err #stderr
# if you need gpu resourcces #SBATCH --gres=gpu:1

srun singularity exec -w /hpc-home/raguidea/repos/submission/singularity/ubuntu $@
```
Here the commented SBATCH are potential option for using this script with sbatch, not extremely relevant here as we don't use SBATCH but srun. The flag are the same between them, so still informative

The `"$@"` at the end of the command line is the way to pass argument to **script_wrapper**

#### Example launching task:
```bash
sbatch <script_wrapper> <script_task>
sbatch submit_600G_high_mem.sh metaphlan4.sh
```
#### Monitoring tasks
- `seff <JOBID>` : only gives correct info when the task is done.
- `squeue -u $USER`: see all tasks in command line. 
- WIthin browser, **[recommended](https://ood.hpc.nbi.ac.uk/pun/sys/activejobs/)** : 

## FAQ
- I can't use chmod, is there a way to change permissions? 
	- nope. This is a weird filesystem, where everything is wrxwrx---. Permission are managed at another level using what Martin call ACL (access control list). You can't give access to your home directory. If you want/need access to a folder/project, open a ticket, contact Martin.  
	- You can't  even make a file non writable. Be careful!
- Singularity and mounting filesystem:
	- There is no need to care about this on most node
- is there a way to reconnect to interactive session:
	- nope, if you disconnected or left, your session got closed/killed and you lost everything you had there, screen/nohup, everything.
- is there a way to always connect to the same submission node and screen into it
	- not exactly, you don't control which node you are going to connect to. But you can ssh to the other one. Unclear how long a screen would last there. It is recommended to not do anything in there. And I once received maybe automated mail about how I am using gzip, I should not, and it is going to be killed in 5 min. 
- Easy way to see a partition specs (cpu/ram per node)
	- [here](https://nbip-research-computing.atlassian.net/wiki/spaces/CIS/pages/5177513/Queue+Partition+Limits). 
- how to mount hpc fs (filesystem) on my laptop?
	- you can't use this behind vpn, so you need to be physically onsite.
	- below are some line you need to write in your /etc/fstab file:
		-  In there the uid/gid should be the one from your laptop
		- the folder `/home/seb/Mount_Inside/hpc` is where you are mounting the hpc fs at. This folder should exist.
		- The is your nbi password and username stored in clear, but behind the `/root/.cifscredentials` file contain your nbi username and password in clear but protected by the  root password of your laptop. An example is below


```
//ei-hpc-data/hpc-home/ /home/seb/Mount_Inside/hpc cifs iocharset=utf8,uid=raguidea,gid=users,credentials=/root/.cifscredentials,file_mode=0775,dir_mode=0775 0 0
//ei-hpc-data.nbi.ac.uk/projects/ /ei/projects cifs iocharset=utf8,uid=raguidea,gid=users,credentials=/root/.cifscredentials,file_mode=0775,dir_mode=0775 0 0
//ei-hpc-data.nbi.ac.uk/project-scratch /ei/.project-scratch cifs iocharset=utf8,uid=raguidea,gid=users,credentials=/root/.cifscredentials,file_mode=0775,dir_mode=0775 0 0
```

    username=raguidea@nbi.ac.uk
    password=this_is_my_password_in_clear








