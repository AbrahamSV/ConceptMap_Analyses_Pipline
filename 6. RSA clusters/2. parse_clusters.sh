#!/bin/bash

# Check if a file argument is provided
if [ -z "$1" ]; then
    echo "Usage: bash parse_clusters.sh [file]"
    exit 1
fi

# Set the input file from the first argument
input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file not found: $input_file"
    exit 1
fi

# Set the output file name based on the second argument (prefix) or default to input filename
if [ -n "$2" ]; then
    prefix="$2"
    output_file="${prefix}_cluster_data.csv"
else
    output_file="${input_file%_clusters_info.txt}_cluster_data.csv"
fi


# Initialize the output file with the header
echo "Cluster,Atlas,Region,NVoxels" > "$output_file"

# Variables for tracking clusters and voxel counts
cluster=""
total_voxels=0
atlas=""
region=""
percentage=0

# Function to calculate the number of voxels based on percentage
calculate_voxels() {
    local percentage="$1"
    local total_voxels="$2"
    echo "scale=2; ($percentage / 100) * $total_voxels" | bc
}

# Read the input file line by line
while IFS= read -r line; do
    # Identify the start of a new cluster
    if [[ "$line" =~ \+\+[\ ]Processing[\ ]unique[\ ]value[\ ]of[\ ]([0-9]+) ]]; then
        # If there's a previous cluster, write total voxels for that cluster
        if [[ -n "$cluster" ]]; then
            echo "Cluster $cluster,$atlas,TOTAL,$total_voxels" >> "$output_file"
        fi
        # Start a new cluster
        cluster="${BASH_REMATCH[1]}"
        total_voxels=0
        atlas=""
        continue
    fi

    # Identify the total number of voxels for the cluster
    if [[ "$line" =~ \+\+[\ ]+([0-9]+)[\ ]voxels[\ ]in[\ ]ROI ]]; then
        total_voxels="${BASH_REMATCH[1]}"
        continue
    fi

    # Identify the atlas name
    if [[ "$line" =~ Intersection[\ ]of[\ ]ROI[\ ]\(valued[^\)]*\)[\ ]with[\ ]atlas[\ ]([^\ ]+)[\ ]\(sb0\): ]]; then
        atlas="${BASH_REMATCH[1]}"
        continue
    fi

    # Identify the percentage overlap and the region
    if [[ "$line" =~ ([0-9\.]+)[\ ]*%[\ ]overlap[\ ]with[\ ]([^,]+),[\ ]code ]]; then
        percentage="${BASH_REMATCH[1]}"
        region="${BASH_REMATCH[2]}"
        n_voxels=$(calculate_voxels "$percentage" "$total_voxels")
        echo "Cluster $cluster,$atlas,$region,$n_voxels" >> "$output_file"
        continue
    fi

    # Handle the end of a cluster block
    if [[ "$line" =~ \+\+[\ ]====================================================================== ]]; then
        if [[ -n "$cluster" ]]; then
            echo "Cluster $cluster,$atlas,TOTAL,$total_voxels" >> "$output_file"
            cluster=""
        fi
    fi
done < "$input_file"

# Write the last cluster's total voxels
if [[ -n "$cluster" ]]; then
    echo "Cluster $cluster,$atlas,TOTAL,$total_voxels" >> "$output_file"
fi

echo "CSV file generated: $output_file"

