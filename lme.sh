#!/bin/bash

# verify that the group results directory does not yet exist
if [ -d group_results/lme ]
then
    echo output dir "group_results/lme" already exists. Doing nothing.
    exit
fi

# Create folder for the results
mkdir group_results/lme

# Run 3dLMEr 
    # Main effects and Interactions are obtained by default
    # We need to specify the pairwise contrasts we want
    # To explore simple effects:
        # - abs-con: Concreteness simple effect
        # - lfam-hfam: Familiarity simple effect
        # - low-hi: Frequency simple effect
    # To explore FamxFreq interactions within Concreteness:
        # - abs_famxfreq: within abstract words
        # - con_famxfreq: within concrete words
    # To explore simple effects of the FamXFreq interaction:
        # - Lfam_low-hi: Frequency effect within Low familiarity
        # - Hfam_low-hi: Frequency effect within High Familiarity
    # "Reverse" contrasts are just for plotting purposes
    
3dLMEr -prefix group_results/lme/lme_res -jobs 12                                                                                                                   \
 -model 'concr*fam*freq+(1|Subj)+(1|concr:Subj)+(1|fam:Subj)+(1|freq:Subj)+(1|concr:fam:Subj)+(1|concr:freq:Subj)+(1|fam:freq:Subj)'                                \
 -SS_type 3                                                                                                                                                         \
 -resid 'group_results/lme/lme_errts'                                                                                                                               \
 -gltCode abs_famxfreq 'concr : 1*abs fam : 1*lfam -1*hfam freq : 1*low -1*hi'                                                                                      \
 -gltCode con_famxfreq 'concr : 1*con fam : 1*lfam -1*hfam freq : 1*low -1*hi'                                                                                      \
 -gltCode Abs_lfam-hfam 'concr : 1*abs fam : 1*lfam -1*hfam '                                                                                                       \
 -gltCode Con_lfam-hfam 'concr : 1*con fam : 1*lfam -1*hfam'                                                                                                        \
 -gltCode Abs_low-hi 'concr : 1*abs freq : 1*low -1*hi'                                                                                                             \
 -gltCode Con_low-hi 'concr : 1*con freq : 1*low -1*hi'                                                                                                             \
 -gltCode Lfam_low-hi 'fam : 1*lfam freq : 1*low -1*hi'                                                                                                             \
 -gltCode Hfam_low-hi 'fam : 1*hfam freq : 1*low -1*hi'                                                                                                             \
 -gltCode abs-con 'concr : 1*abs -1*con'                                                                                                                            \
 -gltCode lfam-hfam 'fam : 1*lfam -1*hfam'                                                                                                                          \
 -gltCode low-hi 'freq : 1*low -1*hi'                                                                                                                               \
 -gltCode reverse_abs-con 'concr : 1*con -1*abs'                                                                                                                            \
 -gltCode reverse_lfam-hfam 'fam : 1*hfam -1*lfam'                                                                                                                          \
 -gltCode reverse_low-hi 'freq : 1*hi -1*low'                                                                                                                               \
 -dataTable @anova_table.txt
 
# Copy anatomical MNI template to lme folder
cp group_results/MNI152_2009_template.nii.gz group_results/lme

# Run 3dFWHMx to estimate autocorrelation function, in order to get cluster corrections

3dFWHMx -input group_results/lme/lme_errts+tlrc -acf > group_results/lme/autocorrFunc.txt

# Then run this with the output from 3dFWHMx

# 3dClustSim -acf [a b c] -athr 0.01 -pthr 0.001

# With an alpha of 0.01, applied over the voxel threshold of p < 0.001

echo "Execution of lme.sh finnished `date`"