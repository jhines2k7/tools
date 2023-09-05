#!/bin/bash

# Get a list of all snapshot names
SNAPSHOT_NAMES=$(doctl compute snapshot list --format Name | grep -oP '.*(?=-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2})' | sort -u)

# Start looping through each snapshot name
for SNAPSHOT_NAME in $SNAPSHOT_NAMES
do
    # Get a list of all snapshot IDs sorted by date with the oldest first.
    SNAPSHOT_IDS=$(doctl compute snapshot list --format ID,Name,Created | grep $SNAPSHOT_NAME | sort -k3 | awk '{ print $1 }')

    # Count the number of snapshots.
    SNAPSHOT_COUNT=$(echo "$SNAPSHOT_IDS" | wc -l)

    if [ "$SNAPSHOT_COUNT" -gt "1" ]; then
        DELETE_COUNT=$(expr $SNAPSHOT_COUNT - 1)
        DELETE_SNAPSHOTS=$(echo "$SNAPSHOT_IDS" | head -n $DELETE_COUNT)

    for SNAPSHOT in $DELETE_SNAPSHOTS; do
                doctl compute snapshot delete $SNAPSHOT --force
            done

            echo "Done. Latest snapshot for $SNAPSHOT_NAME kept. Other old snapshots deleted."
        else
            echo "There is only one snapshot with the name $SNAPSHOT_NAME. No snapshots were deleted."
        fi
    done
