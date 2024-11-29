#!/bin/tcsh -f
# Author: Leandro F. Estrozi, Institut de Biologie Structurale, Grenoble, CNRS.
# This script runs Alphafold3 from chai-lab
# This script places its outputs in the current folder but it also uses /storage/Data/AF3chaijobs as a temporary space.

#REMINDER: the caller add two arguments (uid,jobname) before the fastafile

umask 113; # rw-rw-r--

set caller = "/storage/Alphafold/scripts/alphafold3_chai_caller.bin"
  if($#argv < 3) then
echo "Usage: $caller fastafile [restraints] [seed]"; 
echo "";
exit 0;
  endif

onintr failed;

set u = $1;
set g = 7182;

set jobname = $2;

set fasta = $3;
  if( ! -e $fasta || -z $fasta ) then
echo "ERROR: fastafile not found";
goto failed;
  endif

set outdir = ${fasta:t:r}"_AF3chai_IBS";
set outdir2 = /storage/Data/AF3chaijobs/$outdir;

# 1) To clone the IBS AF3 chai repository:
# #>git clone https://github.com/estrozi/chai-lab.git
# 2) To build the IBS AF3 chai Docker image (as a ADMIN you need to be in docker group):
# #>cd chai-lab/
# #>docker build --build-arg GNAME=`id -gn` --build-arg GID=`id -g` --build-arg UNAME=`id -un` -f Dockerfile.chailab -t chai-lab .

#set AF3chai_CMD = "srun --gres=gpu docker run --user "${u}":"${g}" --rm --gpus all --mount type=bind,source=/storage,target=/app/storage";
set AF3chai_CMD = "srun -J ${jobname} --gres=gpu docker run --user "0":"${g}" --rm --gpus all --mount type=bind,source=/storage,target=/app/storage --env CHAI_DOWNLOADS_DIR=$CHAI_DOWNLOADS_DIR --env PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True";

  if( -e $outdir) then
    if( ! -e $outdir2 ) then
echo "Moving already existing output folder $outdir to $outdir2"
echo "(it will be moved back in the end if everything goes fine)"
mv $outdir $outdir2;
if($status) goto failed;
    else
echo "Conflict: Both $outdir and $outdir2 exit. Aborting..." | tee -a $outdir.log;
goto failed;
    endif
rm -f $outdir2/finished.txt;
  else
mkdir -m 775 $outdir2;
chown ${u}:${g} $outdir2;
if($status) goto failed;
  endif

chmod 770 $outdir2;
if($status) goto failed;
chgrp 7182 $outdir2;
if($status) goto failed;

  if( -e $outdir2/pred.model_idx_4.cif && ! -z $outdir2/pred.model_idx_4.cif ) then
echo "Final file pred.model_idx_4.cif found. Aborting..." |& tee -a $outdir.log;
echo "This probably means that this prediction was already calculated before." |& tee -a $outdir.log;
goto legrandfinale;
  endif

echo 0 >! $outdir2/running.txt;
if($status) goto failed;
chown ${u}:${g} $outdir2/running.txt
if($status) goto failed;

set restra = "";
  if($#argv > 3) then
    if( $4 != "") then
      if(! -e "$4") then
echo "${caller}: ERROR restaints file not found" | tee -a $outdir.log;
goto failed;
      else
set restra = "$4";
      endif
    endif
  endif

set seed = "";
  if($#argv > 4) then
    if( $5 != "") then
      if(`echo $5 | awk '{if(math($1,/[^0-9]+/)){print 1} else {print 0}}'`) then
echo "${caller}: ERROR 5th argument is not a numeric seed" | tee -a $outdir.log;
goto failed;
      else
set seed = "$5";
      endif
    endif
  endif

cp -a $fasta /storage/Data/AF3chaijobs/${fasta:t};
if($status) goto failed;

  if($restra != "") then
cp -a $restra /storage/Data/AF3chaijobs/${restra:t};
if($status) goto failed;
eval ${AF3chai_CMD}" chai-lab /app/storage/Data/AF3chaijobs/${fasta:t} /app${outdir2} '/app/storage/Data/AF3chaijobs/${restra:t}' '${seed}'" |& tee -a $outdir.log;
if($status) goto failed;
  else
eval ${AF3chai_CMD}" chai-lab /app/storage/Data/AF3chaijobs/${fasta:t} /app${outdir2} '' '${seed}'" |& tee -a $outdir.log;
if($status) goto failed;
  endif

    
chown ${u}:${g} $outdir.log;
if($status) goto failed;

chown -R ${u}:${g} $outdir2;
if($status) goto failed;

rm -f $outdir2/running.txt;
if($status) goto failed;

legrandfinale:

  if(-e /storage/Data/AF3chaijobs/AF3chai.log ) then
grep $jobname /storage/Data/AF3chaijobs/AF3chai.log | awk -v FS="<td>" '{print $3}' | sed -e 's/<\/td>//' >& /dev/null;
    if($status) then
echo "${caller}: grep jobname failed." |& tee -a $outdir.log;
    else
set email = `grep $jobname /storage/Data/AF3chaijobs/AF3chai.log | awk -v FS="<td>" '{print $3}' | sed -e 's/<\/td>//'`
set hostname = `hostname`;
set email = "${email}@ibs.fr"
sudo -u \#50809 mail -s '[no-reply] AF3 chai results' -c leandro.estrozi@ibs.fr -- $email << EOF
AF3 chai results are ready.
You can downdload them at: http://${hostname}.ibs.fr:8080/AF3chaiIBS/browse/${jobname}?filepath=
EOF
if($status) echo "${caller}: send mail failed." |& tee -a $outdir.log;
    endif
  endif

echo 0 >! $outdir2/finished.txt;
if($status) goto failed;
chown ${u}:${g} $outdir2/finished.txt
if($status) goto failed;
echo "Moving $outdir2 to $outdir" |& tee -a $outdir.log;
mv $outdir2 $outdir;
if($status) goto failed;
chown -R ${u}:${g} $outdir;
if($status) goto failed;
rm -f /storage/Data/AF3chaijobs/${fasta:t};
if($status) goto failed;
rm -f /storage/Data/AF3chaijobs/${restra:t};

exit 0;

failed:
echo "last cmd before fail: $_" >! $outdir2/failed.txt;
chown ${u}:${g} $outdir2/failed.txt
chown ${u}:${g} $outdir.log
echo "Moving $outdir2 to $outdir" |& tee -a $outdir.log;
mv $outdir2 $outdir;
rm -f /storage/Data/AF3chaijobs/${fasta:t};
exit 1;

