#!/bin/bash


# Prompt for the droplet name
read -p "Enter a name for the droplet: " droplet_name

# Prompt for the region
echo "Please select a region:"
regions=$(doctl compute region list --format "Slug,Name" --no-header)
awk 'BEGIN{FS="\t"} {print NR ". " $1 " " $2}' <<< "$regions"
read -p "Enter the number of the region: " region_number
region_slug=$(awk -v num="$region_number" 'NR==num {print $1}' <<< "$regions")

# Prompt for the droplet size
echo "Please select a droplet size:"
doctl compute size list --format "Slug,Memory,Disk,Price Monthly" --no-header | awk '{print NR ". " $1 " " $2 " " $3 " " $4}' | column -t
read -p "Enter the number of the droplet size: " size_number
size_slug=$(doctl compute size list --format "Slug" --no-header | awk -v num="$size_number" 'NR==num{print $1}')

# Prompt for the SSH key
echo "Please select an SSH key:"
doctl compute ssh-key list --format "ID,Name" --no-header | head -n 3 | awk 'BEGIN{OFS="\t"} {print NR,$2}'
read -p "Enter the number of the SSH key (or leave blank for no SSH key): " ssh_key_number
if [[ -z "$ssh_key_number" ]]; then
    ssh_key=""
else
    ssh_key=$(doctl compute ssh-key list --format "ID" --no-header | awk -v num="$ssh_key_number" 'NR==num{print $1}')
fi

# Retrieve Ubuntu image options
ubuntu_images=$(doctl compute image list-distribution --public --format "ID,Name,Distribution,Slug" --no-header | grep -i "ubuntu")

# Check if any Ubuntu image options are available
if [[ -z "$ubuntu_images" ]]; then
    echo "No Ubuntu image options found."
    exit 1
fi

# Prompt for the droplet image
echo "Please select an Ubuntu image:"
awk 'BEGIN{FS="\t"}{print NR ". " $1 "  " $2}' <<< "$ubuntu_images"
read -p "Enter the number of the Ubuntu image: " image_number
image_id=$(awk -v num="$image_number" 'NR==num{print $1}' <<< "$ubuntu_images")

# Create the droplet
echo "Creating droplet..."
create_response=$(doctl compute droplet create "$droplet_name" --wait --region "$region_slug" --size "$size_slug" --image "$image_id" --ssh-keys "$ssh_key" --format "ID")

# Check if the doctl create command was successful
if [[ $create_response ]]; then
    echo "Droplet creation successful. Droplet ID: $create_response"
else
    echo "Droplet creation failed. Please check your inputs and try again."
fi