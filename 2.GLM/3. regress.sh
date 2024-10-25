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
cd ${subj}.results/

# verify that the results directory does not yet exist
if [ -d regress ]
then
    echo output dir "regress" already exists. Doing nothing.
    exit
fi

mkdir regress

#Concatenate the preprocessed, scaled volumes for run 1-6 in a single file named scl
3dTcat -prefix regress/scl pb04.${subj}.r0*.BRIK

#Create a censor file with TRs with excesive motion to be excluded from analyses
1d_tool.py -infile dfile_rall.1D -set_nruns 6       \
-show_censor_count -censor_motion 0.5 ${subj}

#Plot the outlier volumes and report them
1dplot -one '1D: 4104@0.5' ${subj}_enorm.1D &
cat ${subj}_CENSORTR.txt

#Run regression analysis with 3dDeconvolve
3dDeconvolve -input regress/scl+tlrc                                                                                                                                                                \
-mask mask_group+tlrc.BRIK.gz                                                                                                                                                                       \
-censor ${subj}_censor.1D                                                                                                                                                                           \
-polort 5                                                                                                                                                                                           \
-concat '1D: 0 684 1368 2052 2736 3420'                                                                                                                                                             \
-num_stimts 15                                                                                                                                                                                      \
-stim_times 1 stimuli/abs_lfam_low.1D 'GAM' -stim_label 1 abs_lfam_low                                                                                                                              \
-stim_times 2 stimuli/abs_lfam_hi.1D 'GAM' -stim_label 2 abs_lfam_hi                                                                                                                                \
-stim_times 3 stimuli/abs_hfam_low.1D 'GAM' -stim_label 3 abs_hfam_low                                                                                                                              \
-stim_times 4 stimuli/abs_hfam_hi.1D 'GAM' -stim_label 4 abs_hfam_hi                                                                                                                                \
-stim_times 5 stimuli/con_lfam_low.1D 'GAM' -stim_label 5 con_lfam_low                                                                                                                              \
-stim_times 6 stimuli/con_lfam_hi.1D 'GAM' -stim_label 6 con_lfam_hi                                                                                                                                \
-stim_times 7 stimuli/con_hfam_low.1D 'GAM' -stim_label 7 con_hfam_low                                                                                                                              \
-stim_times 8 stimuli/con_hfam_hi.1D 'GAM' -stim_label 8 con_hfam_hi                                                                                                                                \
-stim_times 9 stimuli/nonword.1D 'GAM' -stim_label 9 nonword                                                                                                                                        \
-stim_file 10 dfile_rall.1D'[0]' -stim_base 10 -stim_label 10 roll                                                                                                                                  \
-stim_file 11 dfile_rall.1D'[1]' -stim_base 11 -stim_label 11 pitch                                                                                                                                 \
-stim_file 12 dfile_rall.1D'[2]' -stim_base 12 -stim_label 12 yaw                                                                                                                                   \
-stim_file 13 dfile_rall.1D'[3]' -stim_base 13 -stim_label 13 dS                                                                                                                                    \
-stim_file 14 dfile_rall.1D'[4]' -stim_base 14 -stim_label 14 dL                                                                                                                                    \
-stim_file 15 dfile_rall.1D'[5]' -stim_base 15 -stim_label 15 dP                                                                                                                                    \
-num_glt 20                                                                                                                                                                                         \
-gltsym 'SYM: +0.125*abs_lfam_low +0.125*abs_lfam_hi +0.125*abs_hfam_low +0.125*abs_hfam_hi +0.125*con_lfam_low +0.125*con_lfam_hi +0.125*con_hfam_low +0.125*con_hfam_hi' -glt_label 1 All-Null    \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*abs_lfam_hi +0.25*abs_hfam_low +0.25*abs_hfam_hi' -glt_label 2 abs-Null                                                                                      \
-gltsym 'SYM: +0.25*con_lfam_low +0.25*con_lfam_hi +0.25*con_hfam_low +0.25*con_hfam_hi' -glt_label 3 con-Null                                                                                      \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*abs_lfam_hi +0.25*con_lfam_low +0.25*con_lfam_hi' -glt_label 4 lfam-Null                                                                                     \
-gltsym 'SYM: +0.25*abs_hfam_low +0.25*abs_hfam_hi +0.25*con_hfam_low +0.25*con_hfam_hi' -glt_label 5 hfam-Null                                                                                     \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*abs_hfam_low +0.25*con_lfam_low +0.25*con_hfam_low' -glt_label 6 low-Null                                                                                    \
-gltsym 'SYM: +0.25*abs_lfam_hi +0.25*abs_hfam_hi +0.25*con_lfam_hi +0.25*con_hfam_hi' -glt_label 7 hi-Null                                                                                         \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*abs_lfam_hi +0.25*abs_hfam_low +0.25*abs_hfam_hi -0.25*con_lfam_low -0.25*con_lfam_hi -0.25*con_hfam_low -0.25*con_hfam_hi' -glt_label 8 abs-con             \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*con_lfam_low +0.25*abs_hfam_low +0.25*con_hfam_low -0.25*abs_lfam_hi -0.25*con_lfam_hi -0.25*abs_hfam_hi -0.25*con_hfam_hi' -glt_label 9 low-hi              \
-gltsym 'SYM: +0.25*abs_lfam_low +0.25*con_lfam_low +0.25*abs_lfam_hi +0.25*con_lfam_hi -0.25*abs_hfam_low -0.25*con_hfam_low -0.25*abs_hfam_hi -0.25*con_hfam_hi' -glt_label 10 lfa-hfa            \
-gltsym 'SYM: +0.5*abs_lfam_low +0.5*abs_lfam_hi -0.5*abs_hfam_low -0.5*abs_hfam_hi' -glt_label 11 absNonFam-absFam                                                                                 \
-gltsym 'SYM: +0.5*con_lfam_low +0.5*con_lfam_hi -0.5*con_hfam_low -0.5*con_hfam_hi' -glt_label 12 conNonFam-conFam                                                                                 \
-gltsym 'SYM: +0.5*abs_lfam_low +0.5*abs_hfam_low -0.5*abs_lfam_hi -0.5*abs_hfam_hi' -glt_label 13 absLow-abs_Hi                                                                                    \
-gltsym 'SYM: +0.5*con_lfam_low +0.5*con_hfam_low -0.5*con_lfam_hi -0.5*con_hfam_hi' -glt_label 14 conLow-conHi                                                                                     \
-gltsym 'SYM: +0.5*abs_lfam_low +0.5*con_lfam_low -0.5*abs_hfam_hi -0.5*con_hfam_hi' -glt_label 15 LFamLow-HFamHi                                                                                   \
-gltsym 'SYM: +1*abs_lfam_low -1*nonword' -glt_label 16 abslfamlow-nonword                                                                                                                          \
-gltsym 'SYM: +1*abs_hfam_hi -1*nonword' -glt_label 17 abshfamhi-nonword                                                                                                                            \
-gltsym 'SYM: +1*con_lfam_low -1*nonword' -glt_label 18 conlfamlow-nonword                                                                                                                          \
-gltsym 'SYM: +1*con_hfam_hi -1*nonword' -glt_label 19 conhfamhi-nonword                                                                                                                            \
-gltsym 'SYM: +1*abs_lfam_low -1*con_hfam_hi' -glt_label 20 abslfamlow-conhfamhi                                                                                                                    \
-tout -x1D regress/rall_X.xmat.1D                                                                                                                                                                   \
-x1D_uncensored regress/rall_X.noncensor.xmat.1D                                                                                                                                                    \
-fitts regress/rall_fitts -bucket regress/rall_func                                                                                                                                                 \
-errts regress/rall_errts                                                                                                                                                                           \
-jobs 12

#Copy the anatomical normalized image to regress folder for ease of use, and finish 
cp anat_w_skull_warped* regress/
cd ..
echo "execution of regress finished `date`"
