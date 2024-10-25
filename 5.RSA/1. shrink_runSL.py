
#%% Setup and imports

import os
pwd = os.path.abspath(os.path.dirname(__file__))    # Setup working path
datadir = "/".join(pwd.split("/")[0:-1])  # Mother directory, moved 1 dir up

os.chdir(pwd)

# Dependencies
import argparse
import pandas as pd, numpy as np
import nibabel as nib
from scipy import stats
import scipy.spatial.distance as sp_distance
from joblib import Parallel, delayed
from tqdm import tqdm
from simplyRSA.searchlight import *
from simplyRSA.searchlight import get_sphere_RDM, get_sphere_similarity


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

# %% Read images and create mask

for i in tqdm(subjlist, desc="Processing Subjects"):

    sub = i
    if sub.split("-")[-1].startswith("0"):
        code = subjcodes[subjcodes["code"]==int(sub[-1])]["folder"].item().split("_")[-1]
    else:
        code = subjcodes[subjcodes["code"]==int(sub.split("-")[-1])]["folder"].item().split("_")[-1]

    brikpath = os.path.join(pwd, f"{sub}.results_native", "regress", "rall_func+orig.BRIK.gz")
    headpath = os.path.join(pwd, f"{sub}.results_native", "regress", "rall_func+orig.HEAD")

    brikdata = nib.load(brikpath).get_fdata()[:,:,:,1:960:2]
    labels = nib.brikhead.parse_AFNI_header(headpath)["BRICK_LABS"].split("~")[1:960:2]
    labels = [element.replace("#", "").replace("_Coef", "") for element in labels]

    # Mask
    onevol = brikdata[:,:,:,0]
    mask = onevol!=0

    # Sphere details
    sphere_radius = 5  # Adjust the radius as needed
    voxel_size_mm = 2  # Adjust the voxel size if it's different

    # Get spheres

    spheres_info = searchlight_spheres_parallel(
        mask, sphere_radius, voxel_size_mm, jobs=36
    )

    # Read models and arrange them according to participant's CTB

    wordspath = os.path.join(datadir, f"logs/{code}-LDT_words.csv")

    subj_words = pd.read_csv(wordspath)
    subj_words = subj_words[~subj_words["Code_ed"].str.contains("nonword")]

    # Create ordered words for each model based on relevant properties for that model
    phon_order = subj_words.sort_values(by= ["num_let", "lev_n"])
    sem_order = subj_words.sort_values(by= ["concreteness", "zipf", "familiarity"])

    # Read the models 
    model_phon = pd.read_excel(f"{datadir}/t_models/model_norm_phon.xlsx", index_col="Item")
    model_sem = pd.read_excel(f"{datadir}/t_models/model_norm_sem.xlsx",index_col="Item")
    model_w2vec = pd.read_excel(f"{datadir}/t_models/model_w2vec.xlsx", index_col="Item")

    # Order the models according to their relevant features
    model_phon = model_phon.reindex(list(phon_order["Item"]))
    model_phon = model_phon[list(phon_order["Item"])]

    model_sem = model_sem.reindex(list(sem_order["Item"]))
    model_sem = model_sem[list(sem_order["Item"])]

    model_w2vec = model_w2vec.reindex(list(sem_order["Item"]))
    model_w2vec = model_w2vec[list(sem_order["Item"])]

    # Create variables to iterate over
    models = [model_phon, model_sem, model_w2vec]
    mod_names = ["model_phon", "model_sem", "model_w2vec"]
    mod_orders = [phon_order, sem_order, sem_order]

    # Get model similarities

    method_similarities= "spearman"

    def get_sphere_sims(model, model_order, brain_data, center,neighbors,labels_data, sim_method=method_similarities):
        # Obtain brain RDMs
        cent, sphere_rdm = get_sphere_RDM(brain_data,labels_data, center, neighbors)
        
        # Shrink and normalise the model 
        mod_shrink = minmaxscl(shrink_rdm(model,6))

        # Reorder the labells of the sphere RDM according to the model
        sphere_rdm = sphere_rdm.reindex(list(model_order["Code_ed"]))
        sphere_rdm = sphere_rdm[list(model_order["Code_ed"])]

        # Shrink and normalise it
        sphere_rdm= minmaxscl(shrink_rdm(sphere_rdm,6))
        
        # Compute model similarity
        model_similarity = get_sphere_similarity(sphere_rdm, mod_shrink, sim_method)

        return cent, model_similarity
    

    for m, mnam, mord in zip(models,mod_names,mod_orders):
        results = Parallel(n_jobs=36)(
            delayed(get_sphere_sims)(m, mord, brikdata, sphere.center, sphere.neighbors, labels) for sphere in tqdm(spheres_info, desc="Computing RDMS and similarities")
        ) 

        simil = {center: similarity for center, similarity in results}

        sims_to_nifti(
            brikpath,
            simil,
            prefix = f"{pwd}/{sub}.results_native/regress/RSAsearchlight_shrink_{mnam}_{method_similarities}_{str(sphere_radius)}mm"
        )

# %%
