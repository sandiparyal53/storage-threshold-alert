#!/bin/bash

# Set the threshold for disk usage at 85%
FILESYSTEM=/dev/mapper/middleware--vg-root
THRESHOLD=85                      #Don't include percentage
CLIENT_NAME=SERVER_NAME_HERE      # Don't use Spaces you can use underscore
WEBHOOK_URL="https://examplehookhere"  # WEBHOOK

# Get the current usage of the root partition
USAGE=$(df -P $FILESYSTEM | awk '{ gsub("%",""); capacity = $5 }; END { print capacity }')

# Check if the usage is greater than the threshold
if [[ "$USAGE" -gt "$THRESHOLD" ]]; then
  # Check if an alert has already been sent
  if [[ -f /tmp/disk_alert_sent ]]; then
    # Check if the usage has increased by 5% or more since the last alert
    PREVIOUS_USAGE=$(cat /tmp/disk_alert_sent)
    if [[ "$USAGE" -gt "$((PREVIOUS_USAGE + 5))" ]]; then
      # Send the alert
      curl -X POST -H 'Content-Type: application/json' -d '{"text": " @here :warning: ```'$CLIENT_NAME' Disk usage has increased to '$USAGE'%!``` "}' "$WEBHOOK_URL"
      # Update the usage in the sent alert file
      echo "$USAGE" > /tmp/disk_alert_sent
    fi
  else
    # Send the initial alert
    curl -X POST -H 'Content-Type: application/json' -d '{"text": "@here  :warning: ``` '$CLIENT_NAME' Disk usage is currently at '$USAGE'%! ``` "}' "$WEBHOOK_URL"
    # Create a file to store the usage in the sent alert
    echo "$USAGE" > /tmp/disk_alert_sent
  fi
else
  # Usage is below the threshold, so delete the sent alert file if it exists
  [[ -f /tmp/disk_alert_sent ]] && rm /tmp/disk_alert_sent
fi

