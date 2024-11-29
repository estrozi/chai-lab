#!/bin/sh
umask 113;
if [ -z "${IBSJOBNAME}" ]; then
  export IBSJOBNAME=fromTTY
fi
export CHAI_DOWNLOADS_DIR=/app/storage/chai-lab/downloads
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
sudo --preserve-env=CHAI_DOWNLOADS_DIR,PYTORCH_CUDA_ALLOC_CONF /storage/Alphafold/scripts/.alphafold3_chai_callee.csh `id -u` "$IBSJOBNAME" "$@"
