#!/bin/bash

# Script to extract clusters that exceed 97.5 percentile (from the RSA searchlight) at the group level, for each of the models (Semantic, Phonological, W2vec)

if [ ! -d clusters ]
then
	mkdir clusters
	echo "clusters folder created"
else
	echo "clusters folder already exists. Doing nothing"
	exit
fi


# Semantic
# Define the value that corresponds to 97.5 perc, after excluding 0 voxels
p975sem=`3dBrickStat -percentile 97.5 0.5 97.5 -non-zero semantic+tlrc'[0]' | awk '{print $2}'`

# Extract clusters while excluding those smaller than the 3dclustSim output for an alpha of 0.05
3dClusterize -nosum -1Dformat -inset semantic+tlrc.HEAD -idat 0 -ithr 0 -NN 1 -clust_nvox 872 -bisided -$p975sem $p975sem -pref_map semantic_clusters


# Create a report of overlap with atlas ROIs (AAL, Glasser)
whereami -omask semantic_clusters+tlrc.HEAD -atlas MNI_Glasser_HCP_v1.0 -atlas CA_MPM_22_MNI -atlas CA_ML_18_MNI > semantic_clusters_info.txt

n_clust_sem=`3dBrickStat -max semantic_clusters+tlrc`

# Iterate over all clusters found and create a separate brik
for i in $(seq 1 $n_clust_sem)
do
	3dcalc -a semantic_clusters+tlrc -expr "equals(${i},a)" -prefix clusters/sem_cluster_${i}
	3dAFNItoNIFTI -prefix clusters/sem_cluster_${i} clusters/sem_cluster_${i}*
done

# Phonological
# Define the value that corresponds to 97.5 perc, after excluding 0 voxels
p975phon=`3dBrickStat -percentile 97.5 0.5 97.5 -non-zero phonological+tlrc'[0]' | awk '{print $2}'`

# Extract clusters while excluding those smaller than the 3dclustSim output for an alpha of 0.05
3dClusterize -nosum -1Dformat -inset phonological+tlrc.HEAD -idat 0 -ithr 0 -NN 1 -clust_nvox 905 -bisided -$p975phon $p975phon -pref_map phonological_clusters


# Create a report of overlap with atlas ROIs (AAL, Glasser) 
whereami -omask phonological_clusters+tlrc.HEAD -atlas MNI_Glasser_HCP_v1.0 -atlas CA_MPM_22_MNI -atlas CA_ML_18_MNI > phonological_clusters_info.txt

n_clust_phon=`3dBrickStat -max phonological_clusters+tlrc`

# Iterate over all clusters found and create a separate brik
for i in $(seq 1 $n_clust_phon)
do
        3dcalc -a phonological_clusters+tlrc -expr "equals(${i},a)" -prefix clusters/phon_cluster_${i}
	3dAFNItoNIFTI -prefix clusters/phon_cluster_${i} clusters/phon_cluster_${i}*
done


# Word2vec
p975w2vec=`3dBrickStat -percentile 97.5 0.5 97.5 -non-zero w2vec+tlrc'[0]' | awk '{print $2}'`

# Extract clusters while excluding those smaller than the 3dclustSim output for an alpha of 0.05
3dClusterize -nosum -1Dformat -inset w2vec+tlrc.HEAD -idat 0 -ithr 0 -NN 1 -clust_nvox 925 -bisided -$p975w2vec $p975w2vec -pref_map word2vec_clusters

# Create a report of overlap with atlas ROIs (AAL, Glasser)
whereami -omask word2vec_clusters+tlrc.HEAD -atlas MNI_Glasser_HCP_v1.0 -atlas CA_MPM_22_MNI -atlas CA_ML_18_MNI > word2vec_clusters_info.txt

n_clust_w2vec=`3dBrickStat -max word2vec_clusters+tlrc`

# Iterate over all clusters found and create a separate brik
for i in $(seq 1 $n_clust_w2vec)
do
        3dcalc -a word2vec_clusters+tlrc -expr "equals(${i},a)" -prefix clusters/w2vec_cluster_${i}
	3dAFNItoNIFTI -prefix clusters/w2vec_cluster_${i} clusters/w2vec_cluster_${i}*
done


# Remove BRIK clusters
rm clusters/*.BRIK* clusters/*.HEAD*

