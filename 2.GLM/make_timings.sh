#!/bin/bash

#Create subject and conditions lists
if [ ! -f subjlist.txt ]; then
	ls logs/ | grep LDT | grep -v _ > subjlist.txt
fi

if [ ! -f condlist.txt ]; then
    echo "abs_lfam_low
abs_lfam_hi
abs_hfam_low
abs_hfam_hi
con_lfam_low
con_lfam_hi
con_hfam_low
con_hfam_hi
nonword" >> condlist.txt
fi

#Create AFNI timing files for each condition for each subject
for subj in `cat subjlist.txt`; do
    for cond in `cat condlist.txt`; do
        cd logs/$subj
        timing_tool.py -fsl_timing_files $cond*.txt -write_timing $cond.1D
        cd ../..
    done
done

