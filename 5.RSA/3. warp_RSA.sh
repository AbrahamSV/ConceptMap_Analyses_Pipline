#!/bin/bash

# the user may specify a single subject to run with
if [ -z ${1} ]
then
    subj=sub-00
else
    subj=$1
fi

echo "Converting RSA searchlights to MNI for ${subj}..."

# verify that the results directory does not yet exist
if [ ! -d group_results/RSAnorm ]
then
    mkdir group_results/RSAnorm
fi



# define iput variables for 3dNwarpApply
MNI_template=ROIs/MNI152_2009_template.nii.gz
subdir=${subj}.results_native
anat_mask=${subdir}/mask_anat.${subj}+orig.BRIK.gz
sub_anat=${subdir}/anat_final.${subj}+orig
resultsdir=group_results

phon=${subdir}/regress/RSAsearchlight_model_phon.nii
sem=${subdir}/regress/RSAsearchlight_model_sem.nii
w2vec=${subdir}/regress/RSAsearchlight_model_w2vec.nii

masked_phon=${subdir}/regress/RSA_masked_phon.nii
masked_sem=${subdir}/regress/RSA_masked_sem.nii
masked_w2vec=${subdir}/regress/RSA_masked_w2vec.nii

# If the masked images exist, delete them
if [ -f ${masked_phon} ]
then
    rm ${masked_phon} 
fi

if [ -f ${masked_sem} ]
then
    rm ${masked_sem} 
fi

if [ -f ${masked_w2vec} ]
then
    rm ${masked_w2vec} 
fi

# Mask the results with the anatomical to remove extra-brain voxels
3dcalc -a ${phon} -b ${anat_mask} -expr 'a*bool(b)' -prefix ${masked_phon}
3dcalc -a ${sem} -b ${anat_mask} -expr 'a*bool(b)' -prefix ${masked_sem}
3dcalc -a ${w2vec} -b ${anat_mask} -expr 'a*bool(b)' -prefix ${masked_w2vec}

# Run 3dNwarpApply on the map for each model
# no need to run 3dQwarp, we already have the qwarp image

# Copy MNI template to RSAnorm for visualization
cp ${MNI_template} group_results/RSAnorm

# ---- Phonological ----#

# Convert the results from the ponological model
3dNwarpApply                                                                \
    -prefix group_results/RSAnorm/RSA_warp_phon_${subj}                     \
    -nwarp ${subdir}/warp/qwp_${subj}_WARP+tlrc                             \
    -ainterp NN                                                             \
    -source ${masked_phon}                                                         \
    -master ${MNI_template}

# ---- Semantic ----#

# Convert the results from the semantic model
3dNwarpApply                                                                \
    -prefix group_results/RSAnorm/RSA_warp_sem_${subj}                      \
    -nwarp ${subdir}/warp/qwp_${subj}_WARP+tlrc                             \
    -ainterp NN                                                             \
    -source ${masked_sem}                                                          \
    -master ${MNI_template}

# ---- W2vec ----#

# Convert the results from the w2vec model
3dNwarpApply                                                                \
    -prefix group_results/RSAnorm/RSA_warp_w2vec_${subj}                    \
    -nwarp ${subdir}/warp/qwp_${subj}_WARP+tlrc                             \
    -ainterp NN                                                             \
    -source ${masked_w2vec}                                                        \
    -master ${MNI_template}