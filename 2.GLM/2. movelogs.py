"""
Created on Thu Sep 29 2022

@author: Abraham Sanchez

Purpose: Move AFNI logs to their corresponding subject folder
"""

#%% Setup: Define working directory, change to current directory

import os
pwd = os.path.abspath(os.path.dirname(__file__))    # Define the working directory at file location

os.chdir(pwd)   # Move to working directory

import pandas as pd
import shutil as sh
#%% Read subjects codes csv

codes = pd.read_csv(pwd + "/raw/subjects_codes.csv")

# %% Move all 1D files (AFNI) to the corresponding folder
# !!! Preprocessing must have been run before this !!!

for s, c in zip(codes["folder"], codes["code"]):
    os.chdir(pwd + "/logs/" + s.split("_")[-1] + "-LDT")
    for f in os.listdir():
        if f.endswith("1D"):
            if len(str(c))==1:
                sh.copyfile(f, pwd + "/conceptbids/sub-0%s.results/stimuli/" % str(c) + f)
            else:
                sh.copyfile(f, pwd + "/conceptbids/sub-%s.results/stimuli/" % str(c) + f)
    os.chdir(pwd)

# Move files with word properties to each subject's folder

for s, c in zip(codes["folder"], codes["code"]):
    os.chdir(pwd + "/logs/")
    for f in os.listdir():
        if f.endswith("words.csv"):
            if str(s.split("_")[-1]) in str(f):
                print(f)
                if len(str(c))==1:
                    sh.copyfile(f, pwd + "/conceptbids/sub-0%s.results/stimuli/" % str(c) + f)
                else:
                    sh.copyfile(f, pwd + "/conceptbids/sub-%s.results/stimuli/" % str(c) + f)
    os.chdir(pwd)
