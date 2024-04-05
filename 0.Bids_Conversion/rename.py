# -*- coding: utf-8 -*-
"""
Created on Thu Sep 29 2022

@author: Abraham Sánchez

Purpose: Rename folders for CONCEPTMAP, so that 
BidsCoin can read them and convert the data
    
"""

#%% Setup: Define working directory, change to current directory

import os
pwd = os.path.abspath(os.path.dirname(__file__))    # Define the working directory at file location

os.chdir(pwd)   # Move to working directory

#%% Imports

import pandas as pd

#%% Get the list of folders

subjects = pd.DataFrame(columns=["folder", "code"])
fold = os.listdir(pwd + "/images/")

for i in fold:
    if ".py" in i:
        fold.remove(i)  # Remove this python script from the list

    elif ".csv" in i:
        fold.remove(i)

subjects["folder"] = fold
subjects = subjects.sort_values(by="folder").reset_index(drop=True)
# %% Create a list of names 

codes = []

cds = []

for i in subjects.index:
    if len(str(int(i))) == 1:
        codes.append("0" + (str(int(i))))
    elif len(str(int(i))) == 2:
        codes.append("" + (str(int(i))))


subjects["code"] = codes + cds  # Add it to the dataset "original folder"-"code"



# %% Rename folders 

for f, c in zip(subjects["folder"], subjects["code"]):
    print(pwd + "/images/" + str(c) + "_sub-" + str(c))

    os.rename(pwd + "/images/" + str(f), pwd + "/images/" + "sub-" + str(c)) # This directly renames the folders!!!)

#%% Export the csv with codes matching

subjects.to_csv("subjects_codes.csv", index=False)

# %%

