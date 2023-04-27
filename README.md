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
- aspera: https://ascptrans.cis.nbi.ac.uk
- open on demand: https://ood.hpc.nbi.ac.uk/pun/sys/dashboard/
## Initial setup
-  copy you .bashrc to get you aliases/PS1 .... 
- nothing is installed, you have to do local install for everything you want to use outside of singularity
## Singularity
- example definition file, see 
- 
