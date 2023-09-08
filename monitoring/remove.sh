#!/bin/bash

# check arguments
if [ $# != 1 ]; then
    echo "$USAGE"
    exit 1
fi

MONITOR_ID=$1

# iterate over hosts
while read -r LINE; do
    # parse host and log directory
    HOST=$(echo "$LINE" | awk '{print $1}')
    DIRECTORY=$(echo "$LINE" | awk '{print $2}')

    if [ "$HOST" == "$(hostname)" ]; then
        # Remove local monitor data and pid files
        (rm $DIRECTORY/${HOST}*${MONITOR_ID}*.*) &
    else
        # Remove remote monitors data and pid files
        (ssh "$HOST" -n -o ConnectTimeout=500 "rm $DIRECTORY/${HOST}*${MONITOR_ID}*.*") &
    fi
done < "$HOST_FILE"

# Wait for all to complete
wait

echo "[-] removed monitor with id '$MONITOR_ID'"
