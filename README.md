# Using EI hpc system, a primer
Documentation to get used to npb hpc system and submiting job with slurm/singularity/conda

## General infos

EI hpc system is a cluster, each server is called a node. When connecting to the hpc, you will have access to a primary node, it can be different each time you connect. There is no way to connect to a specific one (to confirm).

The system is though out as a place where you submit jobs/tasks. It is discouraged to use the primary node to do anything else but submitting a job to the cluster. For instance gzip will be terminated after 1 min and you'll receive a mail about starting an interactive session. Indeed for any day to day tasks, you can start an interactive session which will be a job submitted to the cluster.

#### Interactive sessions
They can be launched by just typing `interactive`
You can use -h for all option, but mostly you can ask for cpu with `-c` and memory with `--mem` 
They are one-off, one you exit disconnect you can't rejoin **(to check with martin)**

#### Internet access
Hpc is mostly isolated from internet. By default you can't download database/software or access the internet. As this is not a viable setup there is a node you can connect to do so. That is the software node. To access is just type `software`

#### Database
(check with martin)
#### Storage space
- scratch/vs backed
- project structuration
- group project folder
- check for available space
#### Transfert files
- (command line) aspera: https://ascptrans.cis.nbi.ac.uk
- (browser/laptop) open on demand: https://ood.hpc.nbi.ac.uk/pun/sys/dashboard/
## Initial setup
-  transfert your .bashrc to get you aliases/PS1 .... 
- nothing is installed, you have to do local install for everything you want to use outside of singularity, either build from source locally or only use singularity
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
- The principle of slurm is that you submit a job to a partition, with requireement of resources (cpu/ram/gpu). It is queued, there is space the job is started. It is not a fifo queue, rare user will get priority over people having intensive usage.
- If your tasks uses more resources than what you asked (ask for 100mo ram uses 101mo), it will be automatically terminated.

- There are different queues, they are called **Partition**. They have different node (servers) with different specs. Usually partitions are intended for different use cases and may have limit in term of how long a task can run. For example, ei-short is for under 45min tasks while tasks in ei-largemem can run for 90 days and request large amount of memory (>500G). You can find all partitions [here](https://nbip-research-computing.atlassian.net/wiki/spaces/CIS/pages/5177513/Queue+Partition+Limits). 

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
#SBATCH --gres=gpu:1 # require gpu resources

srun -p ei- -N 1 -c 100 --mem=600000 -o $(pwd)/slurm.%N.%j.out -e $(pwd)/slurm.%N.%j.err  singularity exec  --env PS1="$(echo $PS1 |sed 's/\\h/\\h (sglrt)/g') " --bind $HOME:$HOME,/ei/projects/0/0dc38138-5425-46f1-aa4a-e4f57ae2abfc:/ei/projects/0/0dc38138-5425-46f1-aa4a-e4f57ae2abfc -w /hpc-home/raguidea/repos/submission/singularity/ubuntu $@
```
Here the commented SBATCH are potential option for using this script with sbatch, not extremely relevant here as we don't use SBATCH but srun. The flag are the same between them, so still informative

The `"$@"` at the end of the command line is the way to pass argument to **script_wrapper**

#### Example launching task:
```bash
nohup <script_wrapper> <script_task> &> log_file&
nohup submit_600G_high_mem.sh metaphlan4.sh &> log_file&
```
#### Monitoring tasks
- `seff <JOBID>`
- `squeue -u $USER`

## Q for martin
- how to mount hpc fs on my laptop, using this fail
	```
	sudo sshfs -o allow_other,default_permissions raguidea@hpc.nbi.ac.uk:/hpc-home/raguidea/repos /home/seb/Mount_Inside/hpc
	```
- There is a space with database managed at the hpc level, where is it and how do I access it?
- I can't use chmod, is there a way to change permissions? 
- system wide setting of singularity doesn't authorise automatic mounting, can we do something about that?
- is there a way to reconnect to interactive session
- is there a way to nohup snakemake for task scheduling
- is there a way to always connect to the same primary node and screen into it
- chris want access to my home dir, at least reading/execution
- easy way to see a partition specs (cpu/ram per node)
