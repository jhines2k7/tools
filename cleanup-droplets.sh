#!/bin/bash

# This script uses doctl to interact with the DigitalOcean API.
# Make sure it's available in PATH

# setenv DIGITALOCEAN_ACCESS_TOKEN abc123abc123abc123abc123
# Change above line with your personal access token

DATE=$(date +%Y-%m-%d)

IFS=$'\n'
for droplet in $(doctl compute droplet list --format "ID,Name,Status" --no-header); do
  droplet_id=$(echo $droplet | cut -d ' ' -f1)
  droplet_name=$(echo $droplet | cut -d ' ' -f2)
  droplet_status=$(echo $droplet | cut -d ' ' -f3)

  if [ $droplet_name != 'jump-server-1' ] && [ $droplet_id != 347233147 ] && [ $droplet_status == 'active' ]; then
    echo "Working on Droplet:  id: $droplet_id  name: $droplet_name  status: $droplet_status"
    echo "==================================================================================="

    # Snapshot the droplet, wait for the task, and log the produced snapshot ID
    echo "Creating a snapshot of the droplet..."
    snapshot=$(doctl compute droplet-action snapshot "$droplet_id" --snapshot-name "$droplet_name-$DATE" --wait)

    if [ $? -eq 0 ]; then
      snapshot_id=$(echo $snapshot | tail -1 | awk '{print $3}')
      echo "Snapshot successful. Snapshot ID: $snapshot_id"

      # Delete the droplet and check if deletion was successful
      echo "Deleting the droplet..."
      if doctl compute droplet delete "$droplet_id" -f; then
        echo "Droplet deletion successful. Droplet ID: $droplet_id"
      else
        echo "Droplet deletion failed."
      fi
    else
      echo "Snapshot creation failed."
    fi
    echo "==================================================================================="
    echo
  fi
done