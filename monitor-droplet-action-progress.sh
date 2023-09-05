#!/bin/bash
action_id="$1"

while true; do
    output=$(doctl compute action get $action_id)
    status=$(echo "$output" | awk 'NR==2 {print $2}')

    if [[ "$status" == "completed" ]]; then
        echo "The status has changed to 'completed'."
        break
    elif [[ "$status" == "in-progress" ]]; then
        echo "The status is still 'in-progress'."
    else
        echo "Unexpected status: $status"
    fi

    sleep 5
done

echo "Script has finished."
