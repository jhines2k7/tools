#!/bin/bash

count=1

# The while loop continues until the count reaches 10
while true; do
  echo "Count: $count"

  # Check if the count is equal to 5
  if [[ $count -eq 5 ]]; then
    break  # Break out of the while loop when count is 5
  fi

  count=$((count + 1))
done

echo "Loop complete"