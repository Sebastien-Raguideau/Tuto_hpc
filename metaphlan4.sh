#!/bin/bash
source /hpc-home/raguidea/.bashrc_non_interactive
conda activate
snakemake -s metaphIan2.snake --cores 100 --rerun-incomplete 

