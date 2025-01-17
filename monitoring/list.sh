#!/bin/bash

# Calls the format.sh script with the .pid files found on each host.

# Check arguments
if [ $# != 0 ]; then
  echo "$USAGE"
  exit 1
fi

# Iterate over hosts
while read -r LINE; do

  # Parse host and log directory
  HOST=$(echo "$LINE" | awk '{print $1}')
  DIRECTORY=$(echo "$LINE" | awk '{print $2}')

  if [ "$HOST" == "$(hostname)" ]; then
    # List local monitors
    ($SCRIPT_DIR/monitor_statuses.sh $DIRECTORY) &
  else
    # List remote monitors
    (ssh "$HOST" -n -o ConnectTimeout=500 "$SCRIPT_DIR/monitor_statuses.sh $DIRECTORY") &
  fi
done <"$HOST_FILE"

# wait for all to complete
wait
