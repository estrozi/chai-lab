import sys, os, random, subprocess
from pathlib import Path

import numpy as np
import torch

from chai_lab.chai1 import run_inference

if (len(sys.argv)-1 < 2):
    print("Usage: /storage/Alphafold/scripts/alphafold3_caller.bin fastafile outdir [seed]")
    exit(1)

infname = sys.argv[1]

if os.access(infname, os.R_OK):
    infilepath = Path(infname)
    outfname = sys.argv[2]
    if(len(sys.argv)-1 > 2):
        myseed = int(sys.argv[3])
    else:
        myseed = random.randint(0, 99999)
    output_dir = Path(outfname)
    output_pdb_paths = run_inference(
        fasta_file=infilepath,
        output_dir=output_dir,
        # 'default' setup
        num_trunk_recycles=3,
        num_diffn_timesteps=200,
        seed=myseed,
        device=torch.device("cuda:0"),
        use_esm_embeddings=True,
    )
    print("writing output to " + outfname)
    subprocess.call(['chmod', '755', outfname])
else:
    print("failed to read input fasta file "+infname)
