#!/bin/sh
umask 113;
sudo /storage/Alphafold/scripts/.alphafold3_callee.csh `id -u` "$@"
