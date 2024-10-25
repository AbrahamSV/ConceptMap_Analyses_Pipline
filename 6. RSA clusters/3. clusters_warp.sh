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

# create a folder for subject clusters

if [ ! -d ${subdir}/warp/clusters ]
then
	mkdir ${subdir}/warp/clusters
	mkdir ${subdir}/warp/clusters/nifti
else
	echo "clusters folder already exists. Doing nothing"
	exit
fi


# apply the inverted warp, which is output by 3dQwarp
# for each cluster

clusts=($(ls group_results/dipc_results/clusters/))

for i in ${clusts[@]}
do
	3dNwarpApply                                                       	 \
    		-prefix ${subdir}/warp/clusters/${i%.nii}                 	 \
    		-nwarp ${subdir}/warp/qwp_${subj}_WARPINV+tlrc                 	 \
    		-ainterp NN                                                    	 \
    		-source group_results/dipc_results/clusters/${i}                 \
		-master ${sub_anat}
	3dAFNItoNIFTI								\
		-prefix ${subdir}/warp/clusters/nifti/${i%.nii}			\
		${subdir}/warp/clusters/${i%.nii}+orig
done


