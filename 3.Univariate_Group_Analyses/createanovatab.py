"""
Author: Abraham Sánchez

Created: 19.12.2023; 16:11

Purpose: Create a table with main conditions for 3dMVM
"""

#%% Setup

import os 
pwd = os.path.abspath(os.path.dirname(__file__))
os.chdir(pwd)

import pandas as pd
 
# %% Read subjects data

subjects = pd.read_csv(f"{pwd}/raw/subjects_codes.csv")

# %% Function to create a table by subject

def anovatab(sub):
    # Empty DF that will contain all 8 conditions
    anov = pd.DataFrame(columns=[
        "Subj",
        "RT",
        "concr",
        "fam",
        "freq",
        "InputFile",
        "\\"[0]     # Finish with \, as required by 3dMVM
    ])

    # Define the list of conditions to iterate over
    condlist=[
        "abs_lfam_low", "abs_lfam_hi", "abs_hfam_low", "abs_hfam_hi",
        "con_lfam_low", "con_lfam_hi", "con_hfam_low", "con_hfam_hi"
    ]

    # Get the subject ID to extract words data, including RTs 
    subid = sub.split("_")[-1]
    words = pd.read_csv(f"{pwd}/logs/{subid}-LDT_words.csv")    # Read words data

    # Get the bids code to create the "Subj" value in the table
    bidscode = str(subjects[subjects["folder"]==sub]["code"].item())
    if len(bidscode)==1:
        subcode = f"sub-0{bidscode}"
    else:
        subcode = f"sub-{bidscode}"
    
    # Iterate over all conditions, getting a line for each one
    for cond in condlist:
        condline = {}
        condline["Subj"] = subcode
        condline["RT"] = words[words["Code_ed"].str.contains(cond)]["RT"].mean().round(4)
        condline["concr"] = cond.split("_")[0]
        condline["fam"] = cond.split("_")[1]
        condline["freq"] = cond.split("_")[2]
        condline["InputFile"] = f"{subcode}.results/regress/rall_func+tlrc[{cond}#0_Coef]"
        condline["\\"[0]] = "\\"[0]

        anov = pd.concat([anov, pd.DataFrame(condline, index=[bidscode])])  # And append it to the final subject DF
    
    return anov

# %% Use the function to create the table with all conditions

all_tab = pd.DataFrame()

for f in subjects["folder"]:
    antab = anovatab(f)
    all_tab = pd.concat([all_tab,antab])

# Remove the last backslash to adequate it to 3dMVM
all_tab["\\"[0]][-1] = ""

# And export it in the format that 3dMVM requires
all_tab.to_csv(f"{pwd}/conceptbids/anova_table.txt", sep="\t", index=False)


# %% Get centering values to include RT as covariate

centers = {}
for c in ["abs","con"]:
    for f in ["lfam", "hfam"]:
        for freq in ["low", "hi"]:
            centers[f"{c}_{f}_{freq}"] = all_tab[all_tab["concr"].isin([c]) & all_tab["fam"].isin([f]) & all_tab["freq"].isin([freq])]["RT"].mean().round(3)

centers = pd.DataFrame([centers])
# %%
