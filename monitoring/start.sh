#!/bin/bash

# Check arguments
if [ $# != 0 ]; then
  echo "$USAGE"
  exit 1
fi

# Starts an nmon monitor on a given host
function start_nmon {

  # Ensure nmon is accessible
  NMON_CMD="$SCRIPT_DIR/nmon/bin/nmon"
  [ ! -f $NMON_CMD ] && echo "$NMON_CMD not found." && exit 1
  if ! command -v $NMON_CMD > /dev/null; then
    echo "Unable to run or access '$NMON_CMD'"
    exit 1
  fi

  HOST=$1
  DIRECTORY=$2
  NMON_FILE="$DIRECTORY/$MON_ID.nmon"
  NMON_PID_FILE="$DIRECTORY/${HOST}_${MON_ID}.nmon.pid"

  if [ "$HOST" == "$(hostname)" ]; then
    # If we're on the current host, run the command locally
    ($NMON_CMD -F $NMON_FILE -c $TOTAL_SNAPSHOTS -s $SNAPSHOT_SECONDS -p >> $NMON_PID_FILE) &
  else
    # Run the command remotely
    (ssh $HOST -n -o ConnectTimeout=500 "$NMON_CMD -F $NMON_FILE -c $TOTAL_SNAPSHOTS -s $SNAPSHOT_SECONDS -p >> $NMON_PID_FILE") &
  fi
}

# Starts an infiniband monitor on a given host
function start_ibmon {

  # Ensure ibmon.sh is accessible
  IBMON_CMD="$SCRIPT_DIR/ibmon/ibmon.sh"
  [ ! -f $IBMON_CMD ] && echo "$IBMON_CMD not found." && exit 1
  if ! command -v $IBMON_CMD > /dev/null; then
    echo "Unable to run or access '$IBMON_CMD'"
    exit 1
  fi

  HOST=$1
  DIRECTORY=$2
  COMMA_SEP_IB_DEVS=$(echo $INFINIBAND_DEVICES | xargs | tr -s '[:blank:]' '[,*]')

  if [ "$HOST" == "$(hostname)" ]; then
    # If we're on the current host, run the command locally
    ($IBMON_CMD $DIRECTORY $MON_ID $SNAPSHOT_SECONDS $TOTAL_SNAPSHOTS $COMMA_SEP_IB_DEVS $INFINIBAND_PORT) &
  else
    # Run the command remotely
    (ssh $HOST -n -o ConnectTimeout=500 "$IBMON_CMD $DIRECTORY $MON_ID $SNAPSHOT_SECONDS $TOTAL_SNAPSHOTS $COMMA_SEP_IB_DEVS $INFINIBAND_PORT") &
  fi
}

# Starts a memory monitor on a given host
function start_free {

  # Ensure free is accessible
  FREE_CMD="free"
  if ! command -v $FREE_CMD > /dev/null; then
    echo "Unable to run or access '$FREE_CMD'"
    exit 1
  fi

  HOST=$1
  DIRECTORY=$2

  # Launch free monitor on host
  echo "TODO: This is just a placeholder for launching 'free' monitor on host"
}

MON_ID="$USER-$(date +%Y%m%d-%H%M%S)"

# Iterate over hosts
while read -r LINE; do

  # Parse host and output directory
  HOST=$(echo "$LINE" | awk '{print $1}')
  DIRECTORY=$(echo "$LINE" | awk '{print $2}')

  # Ensure we can access $OMNI_DIR
  [ -z $OMNI_DIR ] && echo "OMNI_DIR variable not set." && exit 1
  [ ! -d $OMNI_DIR ] && echo "$OMNI_DIR directory not accessible." && exit 1

  # Launch monitors based on configuration
  [[ $CAPTURE_NMON == "yes" ]] && start_nmon $HOST $DIRECTORY
  [[ $CAPTURE_IB == "yes" ]] && start_ibmon $HOST $DIRECTORY
  [[ $CAPTURE_FREE == "yes" ]] && start_free $HOST $DIRECTORY

done < $HOST_FILE

# Wait for all to complete
wait

echo "$MON_ID : running" > /tmp/$MON_ID.omni

echo "[+] started monitor with id '$MON_ID'"
