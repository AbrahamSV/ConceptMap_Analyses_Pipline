#%% Setup and imports

import os
pwd = os.path.abspath(os.path.dirname(__file__))    # Setup working path
datadir = "/".join(pwd.split("/")[0:-1])  # Mother directory, moved 1 dir up

outdir = f"{pwd}/group_results/roiRSA"

os.chdir(pwd)

# Dependencies
import argparse
import random
import pandas as pd, numpy as np
import nibabel as nib
from scipy import stats
import scipy.spatial.distance as sp_distance
import plotly.express as px
from tqdm import tqdm
from simplyRSA.searchlight import rsm, minmaxscl
from simplyRSA.roiRSA import *

#%% Define arguments to take when using the script

parser = argparse.ArgumentParser(

    description='Given a subject(s) code, run RSA searchlight and save the output Nifti in native space')


parser.add_argument('--sub', type=str, nargs='+', help='Subject BIDS code', default="all")

args = parser.parse_args()


#%% Create a list of subjects, provided the script is in the project data folder, and it's in BIDS format

subs = []

for i in os.listdir():
    if "sub-" in i and "." not in i:
        subs.append(i)

subjcodes = pd.read_csv(datadir + "/raw/subjects_codes.csv")    # BIDS codes correspondence


if args.sub== "all":
    subjlist = subs
else:
    subjlist = args.sub

# Little feedback

print(f"Subject(s): {args.sub}")

#%% Read images iterating over subjects

parts_roi_rdms = {}
parts_results = pd.DataFrame()

for i in tqdm(subjlist, desc="Processing Subjects"):
    sub = i
    if sub.split("-")[-1].startswith("0"):
        code = subjcodes[subjcodes["code"]==int(sub[-1])]["folder"].item().split("_")[-1]
    else:
        code = subjcodes[subjcodes["code"]==int(sub.split("-")[-1])]["folder"].item().split("_")[-1]

    
    brikpath = os.path.join(pwd, f"{sub}.results_native", "regress", "rall_func+orig.BRIK.gz")
    headpath = os.path.join(pwd, f"{sub}.results_native", "regress", "rall_func+orig.HEAD")
    roidir = os.path.join(pwd, f"{sub}.results_native", "warp", "natROIs", "indROIs", "final")

    try:
        brikdata = nib.load(brikpath).get_fdata()[:,:,:,1:960:2]
    except FileNotFoundError:
        brikpath = os.path.join(pwd, f"{sub}.results_native", "regress", "rall_func+orig.BRIK")
        brikdata = nib.load(brikpath).get_fdata()[:,:,:,1:960:2]

    labels = nib.brikhead.parse_AFNI_header(headpath)["BRICK_LABS"].split("~")[1:960:2]
    labels = [element.replace("#", "").replace("_Coef", "") for element in labels]

    # Read models and arrange them according to participant's CTB
    wordspath = os.path.join(datadir, f"logs/{code}-LDT_words.csv")

    subj_words = pd.read_csv(wordspath)
    subj_words = subj_words[~subj_words["Code_ed"].str.contains("nonword")]
    
    # Read simple models
    model_con = pd.read_excel(f"{datadir}/t_models/model_norm_con.xlsx",index_col="Item")
    model_fam = pd.read_excel(f"{datadir}/t_models/model_norm_fam.xlsx",index_col="Item")
    model_freq = pd.read_excel(f"{datadir}/t_models/model_norm_freq.xlsx",index_col="Item")

    # Adjust simple models
    model_con = model_con.reindex(list(subj_words["Item"]))
    model_con = model_con[list(subj_words["Item"])]

    model_fam = model_fam.reindex(list(subj_words["Item"]))
    model_fam = model_fam[list(subj_words["Item"])]

    model_freq = model_freq.reindex(list(subj_words["Item"]))
    model_freq = model_freq[list(subj_words["Item"])]

    # Read combinatorial models
    model_phon = pd.read_excel(f"{datadir}/t_models/model_norm_phon.xlsx", index_col="Item")
    model_sem = pd.read_excel(f"{datadir}/t_models/model_norm_sem.xlsx",index_col="Item")
    model_w2vec = pd.read_excel(f"{datadir}/t_models/model_w2vec.xlsx", index_col="Item")

    # Adjust combinatorial models
    model_phon = model_phon.reindex(list(subj_words["Item"]))
    model_phon = model_phon[list(subj_words["Item"])]

    model_sem = model_sem.reindex(list(subj_words["Item"]))
    model_sem = model_sem[list(subj_words["Item"])]

    model_w2vec = model_w2vec.reindex(list(subj_words["Item"]))
    model_w2vec = model_w2vec[list(subj_words["Item"])]

    models = [model_con, model_fam, model_freq, model_phon, model_sem, model_w2vec]
    mod_names = ["model_con", "model_fam", "model_freq", "model_phon", "model_sem", "model_w2vec"]

    # Get ROI masks
    roi_masks = getROIs(
        roidir,
        brikpath
    )

    # Get ROI RDMs
    roi_rdms = get_roi_RDMs(
        brikdata,
        roi_masks,
        labels,
        jobs=24
    )

    model_sims = pd.DataFrame()
    for m, mnam in zip(models,mod_names):
        roi_simil = roi_model_similarities(
            roi_rdms,
            m,
            jobs=36
        )
        roi_simil["model"] = mnam
        
        model_sims = pd.concat([model_sims,roi_simil])
    
    model_sims["sub"] = sub

    parts_roi_rdms[sub] = roi_rdms
    parts_results = pd.concat([parts_results,model_sims])

#%% Define the bootstrap from a random subject

print("Running bootstrap...")
permutations = bootstrap_rdm(
    parts_roi_rdms[random.sample(subs,1)[0]]["sts_pSyl"],
    model_w2vec,
    jobs=36
)

permutations.to_csv(f"{outdir}/bootstrap_results.csv",index=False)

parts_results["Z-value"] = np.nan
parts_results["Z_p-value"] = np.nan

# Calculate Z contrast for each ROI, each model, each participant
for i in parts_results.index:
    per95 = np.percentile(permutations["r_val"],95)
    brain_r = parts_results.iloc[i]["r_val"].item()

    contrast = fisherZ(brain_r, per95, 480*480,480*480)
    zval = contrast[0]
    Z_pval = contrast[1]

    parts_results.loc[parts_results.index==i, "Z-value"] = zval
    parts_results.loc[parts_results.index==i, "Z_p-value"] = Z_pval


parts_results.to_csv(f"{outdir}/final_roi_RSA_results.csv", index=False)

