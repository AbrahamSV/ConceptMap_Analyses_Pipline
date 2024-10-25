#!/bin/bash

# the user may specify a single subject to run with
if [ -z ${1} ]
then
    subj=sub-00
else
    subj=$1
fi


echo "Getting individual ROIs for ${subj}..."

cd ${subj}.results_native/warp/natROIs

if [ -d indROIs ]
then
    echo indROIs folder already exists. Doing nothing
    cd ../../..
    exit
fi

mkdir indROIs

# Extract the Glasser sub-areas

#### IFG ####

# Orbitalis 

3dcalc -a glasser_${subj}+orig'<L_Area_47l_(47_lateral)>' -expr 'step(a)' -prefix indROIs/orb_47l
3dcalc -a glasser_${subj}+orig'<L_Area_anterior_47r>' -expr 'step(a)' -prefix indROIs/orb_47rAnt
3dcalc -a glasser_${subj}+orig'<L_Area_47s>' -expr 'step(a)' -prefix indROIs/orb_47s
3dcalc -a glasser_${subj}+orig'<L_Area_47m>' -expr 'step(a)' -prefix indROIs/orb_47m
3dcalc -a glasser_${subj}+orig'<L_Area_posterior_47r>' -expr 'step(a)' -prefix indROIs/orb_47rPos

# Triangularis

3dcalc -a glasser_${subj}+orig'<L_Area_45>' -expr 'step(a)' -prefix indROIs/tri_45
3dcalc -a glasser_${subj}+orig'<L_Area_IFSa>' -expr 'step(a)' -prefix indROIs/tri_IFSa
3dcalc -a glasser_${subj}+orig'<L_Area_IFSp>' -expr 'step(a)' -prefix indROIs/tri_IFSp

# Opercularis

3dcalc -a glasser_${subj}+orig'<L_Area_44>' -expr 'step(a)' -prefix indROIs/oper_44
3dcalc -a glasser_${subj}+orig'<L_Area_IFJa>' -expr 'step(a)' -prefix indROIs/oper_IFJa
3dcalc -a glasser_${subj}+orig'<L_Area_IFJp>' -expr 'step(a)' -prefix indROIs/oper_IFJp
3dcalc -a glasser_${subj}+orig'<L_Area_Frontal_Opercular>' -expr 'step(a)' -prefix indROIs/oper_FOp

#### ATL ####

3dcalc -a glasser_${subj}+orig'<L_Area_TG_dorsal>' -expr 'step(a)' -prefix indROIs/atl_TGd
3dcalc -a glasser_${subj}+orig'<L_Area_TE1_anterior>' -expr 'step(a)' -prefix indROIs/atl_TE1

#### pSTG ####

# We take this one as is to final folder
3dcalc -a glasser_${subj}+orig'<L_PeriSylvian_Language_Area>' -expr 'step(a)' -prefix indROIs/final/sts_pSyl

#### FG2/FG4 ####

3dcalc -a glasser_${subj}+orig'<L_Area_TE2_posterior>' -expr 'step(a)' -prefix indROIs/fg2_TE2p
3dcalc -a glasser_${subj}+orig'<L_Area_TF>' -expr 'step(a)' -prefix indROIs/fg4_TF
3dcalc -a glasser_${subj}+orig'<L_Fusiform_Face_Complex>' -expr 'step(a)' -prefix indROIs/FFC   # Shared by fg2 and fg4


# Extract FG2 and FG4 from AAL for masking

#### FG2 ####

3dcalc -a aal22_${subj}+orig'<Area_FG2>' -expr 'step(a)' -prefix indROIs/aal_fg2

#### FG4 ####

3dcalc -a aal22_${subj}+orig'<Area_FG4>' -expr 'step(a)' -prefix indROIs/aal_fg4


# ----- Create the final ROIs ----- #

cd indROIs

# Orbitalis 
3dcalc -a orb_47l+orig -b orb_47rAnt+orig -c orb_47s+orig -d orb_47m+orig -e orb_47rPos+orig -expr '(a+b+c+d+e)' -prefix final/orbitalis

# Triangularis
3dcalc -a tri_45+orig -b tri_IFSa+orig -c tri_IFSp+orig -expr '(a+b+c)' -prefix final/triangularis

# Opercularis
3dcalc -a oper_44+orig -b oper_IFJa+orig -c oper_IFJp+orig -d oper_FOp+orig -expr '(a+b+c+d)' -prefix final/opercularis

# ATL
3dcalc -a atl_TGd+orig -b atl_TE1+orig -expr '(a+b)' -prefix final/atl

# FG2
3dcalc -a aal_fg2+orig -b fg2_TE2p+orig -c FFC+orig -expr 'a*(b+c)' -prefix final/fg2

# FG4
3dcalc -a aal_fg4+orig -b fg4_TF+orig -c FFC+orig -expr 'a*(b+c)' -prefix final/fg4


# ------ Convert to Nifti ------ #

cd final

for i in `ls *.BRIK.gz`
do
    3dAFNItoNIFTI ${i}
done

rm *.BRIK.gz *.HEAD

cd ../../../../..

echo "execution of indiv_ROImaker finished `date`"
