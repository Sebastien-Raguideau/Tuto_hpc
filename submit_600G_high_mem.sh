#!/bin/bash -e

#SBATCH -p ei-long,ei-largemem #partition
#SBATCH -N 1 #all cores on the same server (node)
#SBATCH --mem=200000 #Ram for total task (in Mo)
#SBATCH -o "$pwd"/slurm.%N.%j.out #stdout
#SBATCH -e "$pwd"/slurm.%N.%j.err #stderr
#SBATC --gres=gpu:1 # require gpu resources


srun -p ei-largemem -N 1 -c 100 --mem=600000 -o $(pwd)/slurm.%N.%j.out -e $(pwd)/slurm.%N.%j.err  singularity exec  --env PS1="$(echo $PS1 |sed 's/\\h/\\h (sglrt)/g') " --bind $HOME:$HOME,/ei/projects/0/0dc38138-5425-46f1-aa4a-e4f57ae2abfc:/ei/projects/0/0dc38138-5425-46f1-aa4a-e4f57ae2abfc -w /hpc-home/raguidea/repos/submission/singularity/ubuntu $@
