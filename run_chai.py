import sys, os, random, subprocess
from pathlib import Path

import numpy as np
import torch

from chai_lab.chai1 import run_inference

if (len(sys.argv)-1 < 2):
    print("Usage: /storage/Alphafold/scripts/alphafold3_caller.bin fastafile outdir [restraints] [seed]")
    exit(1)
infname = sys.argv[1]

if os.access(infname, os.R_OK):
    infilepath = Path(infname)
    outfname = sys.argv[2]
    restra = None
    if(len(sys.argv)-1 > 2):
        if(sys.argv[3] != ""):
            restra = sys.argv[3]
    if(len(sys.argv)-1 > 3):
        if(sys.argv[4] != ""):
            myseed = int(sys.argv[4])
        else:
            myseed = random.randint(0, 99999)
    else:
        myseed = random.randint(0, 99999)
    output_dir = Path(outfname)
    output_pdb_paths = run_inference(
        fasta_file=infilepath,
        output_dir=output_dir,
        constraint_path=restra,
        # 'default' setup
        num_trunk_recycles=3,
        num_diffn_timesteps=200,
        seed=myseed,
        device=torch.device("cuda:0"),
        use_esm_embeddings=True,
#        msa_directory=TODO/TOTEST read https://github.com/chaidiscovery/chai-lab/blob/main/examples/msas/README.md
    )
    print("the seed used was " + str(myseed))
    print("writing output to " + outfname)
    subprocess.call(['chmod', '755', outfname])
else:
    print("failed to read input fasta file "+infname)
