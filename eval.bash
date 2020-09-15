#! /bin/bash

lang=fr
detok='/home/barrault/git/mosesdecoder/scripts/tokenizer/detokenizer.perl -q '
mbleu='/home/barrault/git/mosesdecoder/scripts/generic/multi-bleu.perl '
data_dir='/home/barrault/projects/allies/allies_llmt_data/en-fr/en-fr/fr'
ref_dir='reference'

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <experiment directory name> "
  exit
fi

if ! [[ -d original ]] || ! [[ -d adapted ]]; then
  echo "Directories 'original' and 'adapted' don't exist.. exiting "
  exit
fi

# prepare reference
mkdir -p $ref_dir

# If a file was not using interactive or active learning, simply copy the original file
for f in `ls original`
do
  if ! [[ -e "./adapted/$f" ]]; then
    cp ./original/$f ./adapted/
  fi

  cp $data_dir/$f.txt $ref_dir/

done


# detokenize
for dir in original adapted
do
  mkdir $dir.detok
  for f in `ls $dir`
  do
    echo $f
    sed -r 's/(@@ )|(@@ ?$)//g' < $dir/$f | $detok -l $lang > $dir.detok/$f
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
done

# Create merged original and adapted files
cat original.detok/* > original.all.txt
cat adapted.detok/* > adapted.all.txt

$mbleu $ref_dir/$f.txt < $dir.detok/$f >> results.$dir

mkdir $1
mv original* adapted* results* $1

