#!/bin/bash

# the user may specify a single subject to run with
if [ -z ${1} ]
then
    subj=sub-00
else
    subj=$1
fi

echo "running regress for ${subj}..."

#Change to subject's dir and create folder for regression results
cd ${subj}.results_native/

# verify that the results directory does not yet exist
if [ -d regress ]
then
    echo output dir "regress" already exists. Doing nothing.
    exit
fi

mkdir regress

#Concatenate the preprocessed, scaled volumes for run 1-6 in a single file named scl
3dTcat -prefix regress/volreg pb02.${subj}.r0*.BRIK

#Create a censor file with TRs with excesive motion to be excluded from analyses
1d_tool.py -infile dfile_rall.1D -set_nruns 6       \
-show_censor_count -censor_motion 0.5 ${subj}

#Plot the outlier volumes and report them
1dplot -one '1D: 4104@0.5' ${subj}_enorm.1D &
cat ${subj}_CENSORTR.txt

#Run regression analysis with 3dDeconvolve
3dDeconvolve -input regress/volreg+orig                                                                                                                                                                \
-mask full_mask.${subj}*.BRIK.gz                                                                                                                                                                    \
-censor ${subj}_censor.1D                                                                                                                                                                           \
-polort 5                                                                                                                                                                                           \
-concat '1D: 0 684 1368 2052 2736 3420'                                                                                                                                                             \
-num_stimts 15                                                                                                                                                                                      \
-stim_times_IM 1 stimuli/abs_lfam_low.1D 'GAM' -stim_label 1 abs_lfam_low                                                                                                                           \
-stim_times_IM 2 stimuli/abs_lfam_hi.1D 'GAM' -stim_label 2 abs_lfam_hi                                                                                                                             \
-stim_times_IM 3 stimuli/abs_hfam_low.1D 'GAM' -stim_label 3 abs_hfam_low                                                                                                                           \
-stim_times_IM 4 stimuli/abs_hfam_hi.1D 'GAM' -stim_label 4 abs_hfam_hi                                                                                                                             \
-stim_times_IM 5 stimuli/con_lfam_low.1D 'GAM' -stim_label 5 con_lfam_low                                                                                                                           \
-stim_times_IM 6 stimuli/con_lfam_hi.1D 'GAM' -stim_label 6 con_lfam_hi                                                                                                                             \
-stim_times_IM 7 stimuli/con_hfam_low.1D 'GAM' -stim_label 7 con_hfam_low                                                                                                                           \
-stim_times_IM 8 stimuli/con_hfam_hi.1D 'GAM' -stim_label 8 con_hfam_hi                                                                                                                             \
-stim_times_IM 9 stimuli/nonword.1D 'GAM' -stim_label 9 nonword                                                                                                                                     \
-stim_file 10 dfile_rall.1D'[0]' -stim_base 10 -stim_label 10 roll                                                                                                                                  \
-stim_file 11 dfile_rall.1D'[1]' -stim_base 11 -stim_label 11 pitch                                                                                                                                 \
-stim_file 12 dfile_rall.1D'[2]' -stim_base 12 -stim_label 12 yaw                                                                                                                                   \
-stim_file 13 dfile_rall.1D'[3]' -stim_base 13 -stim_label 13 dS                                                                                                                                    \
-stim_file 14 dfile_rall.1D'[4]' -stim_base 14 -stim_label 14 dL                                                                                                                                    \
-stim_file 15 dfile_rall.1D'[5]' -stim_base 15 -stim_label 15 dP                                                                                                                                    \
-num_glt 3                                                                                                                                                                                         \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*abs_lfam_hi +0.25*abs_hfam_low +0.25*abs_hfam_hi -0.25*con_lfam_low -0.25*con_lfam_hi -0.25*con_hfam_low -0.25*con_hfam_hi' -glt_label 1 abs-con             \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*con_lfam_low +0.25*abs_hfam_low +0.25*con_hfam_low -0.25*abs_lfam_hi -0.25*con_lfam_hi -0.25*abs_hfam_hi -0.25*con_hfam_hi' -glt_label 2 low-hi              \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*con_lfam_low +0.25*abs_lfam_hi +0.25*con_lfam_hi -0.25*abs_hfam_low -0.25*con_hfam_low -0.25*abs_hfam_hi -0.25*con_hfam_hi' -glt_label 3 lfa-hfa             \
-tout -x1D regress/rall_X.xmat.1D                                                                                                                                                                   \
-x1D_uncensored regress/rall_X.noncensor.xmat.1D                                                                                                                                                    \
-fitts regress/rall_fitts -bucket regress/rall_func                                                                                                                                                 \
-errts regress/rall_errts                                                                                                                                                                           \
-jobs 15

#Copy the anatomical normalized image to regress folder for ease of use, and finish 
cp anat_final* regress/
cd ..
echo "execution of regress finished `date`"
