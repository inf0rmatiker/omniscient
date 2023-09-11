#!/bin/bash

# Create directories on each host
while read -r LINE; do

  # Parse host and log directory
  HOST=$(echo "$LINE" | awk '{print $1}')
  DIRECTORY=$(echo "$LINE" | awk '{print $2}')

  if [ "$HOST" == "$(hostname)" ]; then
    mkdir -p "$DIRECTORY"
  else
    ssh "$HOST" -n -o ConnectTimeout=500 "mkdir -p $DIRECTORY"
  fi

  echo "Created $DIRECTORY on $HOST"

done < $HOST_FILE
