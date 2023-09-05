#!/bin/bash

# Get the list of all running droplets
droplets=$(doctl compute droplet list --format "ID,Name,Status" --no-header | grep -v 'jump-server-1' | grep -v '^347233147')

# Check if there are any droplets to delete
if [ -z "$droplets" ]; then
    echo "No droplets to delete."
    exit 0
fi

# Loop through the droplets
while IFS= read -r droplet; do
  droplet_id=$(echo "$droplet" | awk '{print $1}')
  droplet_name=$(echo "$droplet" | awk '{print $2}')

  # Skip droplets with name "jump-server-1" and ID "347233147"
  if [[ "$droplet_name" == "jump-server-1" && "$droplet_id" == "347233147" ]]; then
    continue
  fi

  # Stop the droplet
  echo "Stopping droplet: $droplet_name"
  doctl compute droplet-action shutdown "$droplet_id"

  # Wait for the droplet to shut down
  while true; do
    status=$(doctl compute droplet get "$droplet_id" --format "Status" --no-header)
    if [["$status" == "off" ]]; then
      break
    fi
    sleep 5
  done

  # Create a snapshot
  snapshot_name="snapshot-$(date +"%Y%m%d%H%M%S")-$droplet_name"
  echo "Creating snapshot: $snapshot_name"
  doctl compute droplet-action snapshot "$droplet_id" --snapshot-name "$snapshot_name"

  # Delete the droplet
  echo "Deleting droplet: $droplet_name"
  doctl compute droplet delete "$droplet_id" --force
done <<< "$droplets"