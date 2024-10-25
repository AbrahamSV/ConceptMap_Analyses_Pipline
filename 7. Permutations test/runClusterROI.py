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
from simplyRSA.searchlight import rsm, minmaxscl, shrink_rdm
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

# Function to reorder and shrink the RDMs in smaller, theoretically relevant chunks
def reorder_and_shrink(df,order):
    reordered_df = df.reindex(order)
    reordered_df = reordered_df[order]

    return shrink_rdm(reordered_df,10)


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
    roidir = os.path.join(pwd, f"{sub}.results_native", "warp", "clusters", "nifti")

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

    # Create ordered words for each model based on relevant properties for that model
    con_order = subj_words.sort_values(by="concreteness")
    freq_order = subj_words.sort_values(by= "zipf")
    fam_order = subj_words.sort_values(by= "familiarity")
    sem_order = subj_words.sort_values(by= ["concreteness", "zipf", "familiarity"])
    phon_order = subj_words.sort_values(by= ["num_let", "lev_n"])
    
    # Read simple models
    model_con = pd.read_excel(f"{datadir}/t_models/model_norm_con.xlsx",index_col="Item")
    model_fam = pd.read_excel(f"{datadir}/t_models/model_norm_fam.xlsx",index_col="Item")
    model_freq = pd.read_excel(f"{datadir}/t_models/model_norm_freq.xlsx",index_col="Item")

    # Adjust simple models
    model_con = model_con.reindex(list(con_order["Item"]))
    model_con = model_con[list(con_order["Item"])]
    model_con = shrink_rdm(model_con,10)

    model_fam = model_fam.reindex(list(fam_order["Item"]))
    model_fam = model_fam[list(fam_order["Item"])]
    model_fam = shrink_rdm(model_fam,10)

    model_freq = model_freq.reindex(list(freq_order["Item"]))
    model_freq = model_freq[list(freq_order["Item"])]
    model_freq = shrink_rdm(model_freq,10)

    # Read combinatorial models
    model_phon = pd.read_excel(f"{datadir}/t_models/model_norm_phon.xlsx", index_col="Item")
    model_sem = pd.read_excel(f"{datadir}/t_models/model_norm_sem.xlsx",index_col="Item")
    model_w2vec = pd.read_excel(f"{datadir}/t_models/model_w2vec.xlsx", index_col="Item")

    # Adjust combinatorial models
    model_phon = model_phon.reindex(list(phon_order["Item"]))
    model_phon = model_phon[list(phon_order["Item"])]
    model_phon = shrink_rdm(model_phon,10)

    model_sem = model_sem.reindex(list(sem_order["Item"]))
    model_sem = model_sem[list(sem_order["Item"])]
    model_sem = shrink_rdm(model_sem,10)

    model_w2vec = model_w2vec.reindex(list(sem_order["Item"]))
    model_w2vec = model_w2vec[list(sem_order["Item"])]
    model_w2vec = shrink_rdm(model_w2vec,10)

    models = [model_con, model_fam, model_freq, model_phon, model_sem, model_w2vec]
    mod_names = ["model_con", "model_fam", "model_freq", "model_phon", "model_sem", "model_w2vec"]
    mod_orders = [con_order, fam_order, freq_order, phon_order, sem_order, sem_order]

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
        jobs=12
    )

    print(f"Example of ROI RDM... {roi_rdms.get('phon_cluster_1')}")

    print(f"And labels are... {labels}")

    model_sims = pd.DataFrame()
    for m, mnam,m_ord in zip(models,mod_names,mod_orders):
        current_ord = m_ord["Code_ed"]
        current_rdms = {
                roi_lab:reorder_and_shrink(df,current_ord) for roi_lab,df in roi_rdms.items()
                }
        
        roi_simil = roi_model_similarities(
            current_rdms,
            m,
            jobs=12
        )
        roi_simil["model"] = mnam
        
        model_sims = pd.concat([model_sims,roi_simil])
    
    model_sims["sub"] = sub

    parts_roi_rdms[sub] = current_rdms
    parts_results = pd.concat([parts_results,model_sims])

print(parts_results)
parts_results.to_csv(f"{outdir}/debug_df.csv")

#%% Define the bootstrap from a random subject

print("Running bootstrap...")

rand_roi = random.choice(list(parts_roi_rdms[sub].keys()))
print(rand_roi)

permutations = bootstrap_rdm(
    parts_roi_rdms[sub][rand_roi],
    model_w2vec,
    bts_iters=10000,
    jobs=12
)

permutations.to_csv(f"{outdir}/bootstrap_results_clust.csv",index=False)

parts_results["percentile_threshold"] = np.nan
parts_results["Z-value"] = np.nan
parts_results["Z_p-value"] = np.nan

parts_results.reset_index(drop=True,inplace=True)

# Calculate Z contrast for each ROI, each model, each participant
for i in parts_results.index:
    alpha = np.percentile(permutations["r_val"],95)
    brain_r = parts_results.loc[parts_results.index==i, "r_val"]

    contrast = fisherZ(brain_r, alpha, 48*48,48*48)
    zval = contrast[0]
    Z_pval = contrast[1]

    parts_results.loc[parts_results.index==i, "percentile_threshold"] = alpha
    parts_results.loc[parts_results.index==i, "Z-value"] = zval
    parts_results.loc[parts_results.index==i, "Z_p-value"] = Z_pval


parts_results.to_csv(f"{outdir}/final_cluster_RSA_results.csv", index=False)

