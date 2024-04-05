#!/bin/bash

# the user may specify a single subject to run with
if [ -z ${1} ]
then
    subj=sub-00
else
    subj=$1
fi

echo "Running warp and ROI transform for ${subj}..."

# define iput variables for 3dQwarp and 3dNwarpApply
MNI_template=ROIs/MNI152_2009_template.nii.gz
aal18=ROIs/MNI_caez_ml_18_relabel.nii.gz
aal22=ROIs/MNI_caez_mpm_22+tlrc.BRIK.gz
glasser=ROIs/MNI_Glasser_HCP_v1.0.nii.gz
subdir=${subj}.results_native
sub_anat=${subdir}/anat_final.${subj}+orig

# if it doesn't exist, create a folder for the warp results
cd $subdir

if [ -d warp ]
then
    echo output dir "warp" already exists. Doing nothing.
    exit
fi

mkdir warp

cd ..

# run 3dQwarp and save results to subj.results_native/warp

3dQwarp                                 \
    -base ${MNI_template}               \
    -source ${sub_anat}                 \
    -iwarp                              \
    -resample                           \
    -allineate                          \
    -pblur                              \
    -prefix ${subdir}/warp/qwp_${subj} 


# create a folder for subject ROIs

mkdir ${subdir}/warp/natROIs

# apply the inverted warp, which is output by 3dQwarp
# for each atlas

# ---- Glasser ----#
3dNwarpApply                                                        \
    -prefix ${subdir}/warp/natROIs/glasser_${subj}                  \
    -nwarp ${subdir}/warp/qwp_${subj}_WARPINV+tlrc                  \
    -ainterp NN                                                     \
    -source ${glasser}                                              \
    -master ${sub_anat}

# Copy labels and color code

3drefit -copytables ${glasser} ${subdir}/warp/natROIs/glasser_${subj}+orig.HEAD
3drefit -cmap INT_CMAP ${subdir}/warp/natROIs/glasser_${subj}+orig.HEAD

# ---- AAL18 ----#
3dNwarpApply                                                        \
    -prefix ${subdir}/warp/natROIs/aal18_${subj}                    \
    -nwarp ${subdir}/warp/qwp_${subj}_WARPINV+tlrc                  \
    -ainterp NN                                                     \
    -source ${aal18}                                                \
    -master ${sub_anat}

# Copy labels and color code

3drefit -copytables ${aal18} ${subdir}/warp/natROIs/aal18_${subj}+orig.HEAD
3drefit -cmap INT_CMAP ${subdir}/warp/natROIs/aal18_${subj}+orig.HEAD

# ---- AAL22 ----#
3dNwarpApply                                                        \
    -prefix ${subdir}/warp/natROIs/aal22_${subj}                    \
    -nwarp ${subdir}/warp/qwp_${subj}_WARPINV+tlrc                  \
    -ainterp NN                                                     \
    -source ${aal22}                                                \
    -master ${sub_anat}

# Copy labels and color code

3drefit -copytables ${aal22} ${subdir}/warp/natROIs/aal22_${subj}+orig.HEAD
3drefit -cmap INT_CMAP ${subdir}/warp/natROIs/aal22_${subj}+orig.HEAD

# Copy the anatomical image to the final ROIs folder

cp ${sub_anat} ${subdir}/warp/natROIs


echo DONE DONE DONE DONE
echo "results saved to ${subdir}/warp" 
echo "execution of warp finished `date`"