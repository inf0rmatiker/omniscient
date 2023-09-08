#!/bin/bash

# Check arguments
if [ $# != 1 ]; then
  echo "$USAGE"
  exit 1
fi

# Stops the nmon monitor on a given host
function stop_nmon {

  HOST=$1
  echo "Stopping nmon on host $HOST"
  if [ "$HOST" == "$(hostname)" ]; then
    # Stop monitor locally
    kill $(ps -aux | grep '[n]mon' | awk '{print $2}')
  else
    # Stop monitor remotely
    (ssh "$HOST" -n -o ConnectTimeout=500 "kill \$(ps -aux | grep '[n]mon' | awk '{print \$2}')") &
  fi
}

# Stops the InfiniBand monitor on a given host
function stop_ibmon {

  HOST=$1
  echo "Stopping ibmon on host $HOST"
  if [ "$HOST" == "$(hostname)" ]; then
    # Stop monitor locally
    kill $(ps -aux | grep '[i]bmon.sh' | awk '{print $2}')
  else
    # Stop monitor remotely
    (ssh "$HOST" -n -o ConnectTimeout=500 "kill \$(ps -aux | grep '[i]bmon.sh' | awk '{print \$2}')") &
  fi
}

# Stops the free monitor on a given host
function stop_free {

  HOST=$1
  echo "Stopping free monitor on host $HOST"
  if [ "$HOST" == "$(hostname)" ]; then
    # Stop monitor locally
    kill $(ps -aux | grep '[f]ree.sh' | awk '{print $2}')
  else
    # Stop monitor remotely
    (ssh "$HOST" -n -o ConnectTimeout=500 "kill \$(ps -aux | grep '[f]ree.sh' | awk '{print \$2}')") &
  fi
}

# Iterate over hosts
while read -r LINE; do

  # Parse host and log directory
  HOST=$(echo "$LINE" | awk '{print $1}')

  # Stop monitors based on configuration
  [[ $CAPTURE_NMON == "yes" ]] && stop_nmon $HOST
  [[ $CAPTURE_IB == "yes" ]] && stop_ibmon $HOST
  [[ $CAPTURE_FREE == "yes" ]] && stop_free $HOST

done <"$HOST_FILE"

# wait for all to complete
wait

echo "$MON_ID : stopped" > /tmp/$MON_ID.omni

echo "[/] stopped monitor with id '$1'"
