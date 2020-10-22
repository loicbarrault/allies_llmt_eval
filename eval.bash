#! /bin/bash

dir='/home/ac1lmb/git/allies_llmt_eval'

src=en # for now only en
trg=$1 # fr or de
output_dir=$2
detok="$dir/detokenizer.perl -q "
mbleu="$dir/multi-bleu.perl "
data_dir="/home/ac1lmb/git/allies_llmt_data/$src-$trg/$src-$trg/$trg"
ref_dir='reference'
file_order="/home/barrault/projects/allies/allies_llmt_eval/allies.nt14.$src-$trg.$trg.file_order"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target language (fr or de)> <output experiment directory name> "
  exit
fi

if ! [[ -d original ]] || ! [[ -d adapted ]]; then
  echo "Directories 'original' and 'adapted' don't exist.. exiting "
  exit
fi

# prepare reference
rm -fR $ref_dir
mkdir -p $ref_dir

# If a file was not using interactive or active learning, simply copy the original file
for f in `ls original`
do
  if ! [[ -e "./adapted/$f" ]]; then
    cp ./original/$f ./adapted/
  fi

  cp $data_dir/$f.txt $ref_dir/

done

# Prepare multi-bleu.perl reference file
cat $ref_dir/* > $ref_dir.all.txt

# detokenize
for dir in original adapted
do
  mkdir $dir.detok
  for f in `ls $dir`
  do
    echo $f
    sed -r 's/(@@ )|(@@ ?$)//g' < $dir/$f | $detok -l $trg > $dir.detok/$f
  done
done

# calculate BLEU scores separately for each document
for dir in original adapted
do
  echo "##### $dir"
  rm -f results.$dir
  for f in `ls $dir.detok`
  do
    echo $f
    $mbleu $ref_dir/$f.txt < $dir.detok/$f >> results.$dir
  done

  # Create merged file and score it
  cat $dir.detok/* > $dir.all.txt
  $mbleu $ref_dir.all.txt < $dir.all.txt > results.$dir.all.mbleu
done

# sacrebleu scoring
for dir in original adapted
do
  rm -f $dir.all.sacrebleu.txt
# prepare file in sacrebleu order
  for f in `cat $file_order`
  do
    cat $dir.detok/$f >> $dir.all.sacrebleu.txt
  done
# score it with sacrebleu
  sacrebleu -t wmt14 -l $src-$trg -i $dir.all.sacrebleu.txt > results.$dir.all.sacrebleu
done

mkdir $output_dir
mv original* adapted* results* $ref_dir.all.txt $output_dir

