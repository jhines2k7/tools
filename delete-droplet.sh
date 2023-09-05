#!/bin/bash

# Get the list of running droplets with their names and status
droplets_output="$(doctl compute droplet list --format "ID,Name,Status" --no-header | grep -v 'jump-server-1' | grep -v '^347233147')"

# Check if there are any droplets to delete
if [ -z "$droplets_output" ]; then
    echo "No droplets to delete."
    exit 0
fi

# Check if the doctl command was successful
if [ $? -eq 0 ]; then
    # Print enumerated list of droplets with status
    echo "Currently running droplets:"
    awk 'BEGIN{FS="\t"} {print NR ". " $2 "\t" $3 "\t" $1}' <<< "$droplets_output"

    # Prompt user to select droplet to delete
    read -p "Enter the number of the droplet you want to delete: " droplet_number

    # Get droplet ID and status based on user selection
    droplet_info="$(awk -v num="$droplet_number" 'NR==num{print $1,$3,$2}' <<< "$droplets_output")"
    droplet_id="$(cut -d ' ' -f 1 <<< "$droplet_info")"
    droplet_status="$(cut -d ' ' -f 2 <<< "$droplet_info")"
    droplet_name="$(cut -d ' ' -f 3 <<< "$droplet_info")"

    # Check if the droplet ID is valid
    if [[ $droplet_id ]]; then
        # Check if the droplet is active
        if [[ $droplet_status == "active" ]]; then
            # Shut down the selected droplet
            echo "Shutting down the droplet..."
            if doctl compute droplet-action shutdown "$droplet_id" --wait; then
                echo "Droplet shutdown successful."

                # Prompt user for snapshot creation
                read -p "Do you want to create a snapshot before deleting the droplet? (y/n): " create_snapshot

                if [[ $create_snapshot == "y" || $create_snapshot == "Y" ]]; then
                    # Create a snapshot of the droplet
                    snapshot_name="$droplet_name-snapshot-$(date +%Y-%m-%d-%H-%M-%S)"
                    echo "Creating a snapshot of the droplet..."
                    if doctl compute droplet-action snapshot "$droplet_id" --snapshot-name "$snapshot_name" --wait; then
                        echo "Snapshot creation successful. Snapshot Name: $snapshot_name"
                    else
                        echo "Snapshot creation failed. Unable to proceed with droplet deletion."
                        exit 1
                    fi
                fi

                # Delete the droplet and check if deletion was successful
                echo "Deleting the droplet..."
                if doctl compute droplet delete "$droplet_id" -f; then
                    echo "Droplet deletion successful. Droplet ID: $droplet_id"
                else
                    echo "Droplet deletion failed."
                fi
            else
                echo "Failed to shutdown the droplet. Unable to proceed with snapshot creation and droplet deletion."
            fi
        else
            echo "Selected droplet is not active. No action will be performed."
        fi
    else
        echo "Invalid droplet number. No droplet will be deleted."
    fi
else
    echo "Failed to retrieve droplet list. Error: $(awk 'BEGIN{FS="\t"} {print $NF}' <<< "$droplets_output")"
fi