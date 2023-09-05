#!/bin/bash

# List the available snapshots
snapshots=$(doctl compute snapshot list --no-header --format "ID,Name,Min Disk Size")
snapshots_count=$(echo "$snapshots" | wc -l)

# Check if any snapshots are available
if [ "$snapshots_count" -eq 0 ]; then
    echo "No snapshots found."
    exit 1
fi

# Print enumerated list of snapshots
echo "Available snapshots:"
awk 'BEGIN{FS="\t"} {print NR ". " $1 " " $2}' <<< "$snapshots" | column -t

# Prompt user to select the snapshot
read -p "Enter the number of the snapshot to restore: " snapshot_number

# Validate the snapshot number
if [[ "$snapshot_number" =~ ^[0-9]+$ && "$snapshot_number" -ge 1 && "$snapshot_number" -le "$snapshots_count" ]]; then
    snapshot_name=$(awk -v num="$snapshot_number" 'NR==num {print $2}' <<< "$snapshots")
    snapshot_id=$(awk -v num="$snapshot_number" 'NR==num {print $1}' <<< "$snapshots")
else
    echo "Invalid snapshot number. Exiting."
    exit 1
fi

# Prompt for the droplet name
read -p "Enter a name for the new droplet: " droplet_name

# Prompt for the region
echo "Please select a region:"
regions=$(doctl compute region list --format "Slug,Name" --no-header)
awk 'BEGIN{FS="\t"} {print NR ". " $1 " " $2}' <<< "$regions"
read -p "Enter the number of the region: " region_number
region_slug=$(awk -v num="$region_number" 'NR==num {print $1}' <<< "$regions")

# Prompt for the SSH key
echo "Please select an SSH key:"
ssh_keys=$(doctl compute ssh-key list --format "ID,Name" --no-header | head -n 3)
awk 'BEGIN{FS="\t"} {print NR ". " $1 " " $2}' <<< "$ssh_keys"
read -p "Enter the number of the SSH key (or leave blank for no SSH key): " ssh_key_number
if [[ -z "$ssh_key_number" ]]; then
    ssh_key=""
else
    ssh_key=$(awk -v num="$ssh_key_number" 'NR==num {print $1}' <<< "$ssh_keys")
fi

# Prompt for the droplet size
echo "Please select a droplet size:"
doctl compute size list --format "Slug,Memory,Disk,Price Monthly" --no-header | awk '{print NR ". " $1 " " $2 " " $3 " " $4}' | column -t
read -p "Enter the number of the droplet size: " size_number
size_slug=$(doctl compute size list --format "Slug" --no-header | awk -v num="$size_number" 'NR==num{print $1}')

echo "Size slug: $size_slug"
echo "Region slug: $region_slug"
echo "SSH key: $ssh_key"
echo "Snapshot ID: $snapshot_id"

# Creating the droplet from the snapshot
echo "Creating droplet..."
create_response=$(doctl compute droplet create "$droplet_name" --wait --region "$region_slug" --size "$size_slug" --image "$snapshot_id" --ssh-keys "$ssh_key" --format "ID")

# Check if the droplet creation was successful
if [[ -z "$create_response" ]]; then
    echo "Droplet creation failed."
else
    echo "Droplet creation successful. Droplet ID: $create_response"
fi