#!/bin/bash

in_dir=RSAnorm  # Define input directory

out_dir=permutations


if [ -d ${out_dir} ]
then
    echo output directory already exists. Doing noting
    exit
fi

mkdir $in_dir/$out_dir

# Transform Spearman rho to Fisher z

cd $in_dir

for i in `ls *.BRIK`
do
    3dcalc -a ${i} -expr 'atanh(a)' -prefix $out_dir/FisherZ_${i}
done

cd ..


res_dir=tests

mkdir $in_dir/$out_dir/$res_dir

cd $in_dir/$out_dir


# Semantic

3dttest++ -Clustsim -prefix ${res_dir}/semantic -mask ../MNI_mask+tlrc.HEAD -setA *_sem_*.BRIK 

# Word2Vec

3dttest++ -Clustsim -prefix ${res_dir}/w2vec -mask ../MNI_mask+tlrc.HEAD -setA *_w2vec_*.BRIK 


# Phonological

3dttest++ -Clustsim -prefix ${res_dir}/phonological -mask ../MNI_mask+tlrc.HEAD -setA *_phon_*.BRIK 
