#!/bin/bash

# Copyright (C) 2023 Caleb Carlson
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see http://www.gnu.org/licenses/.
#
# This script uses perfquery and ibv_devinfo to monitor IB performance counters and query device info.
# https://linux.die.net/man/8/perfquery
# https://linux.die.net/man/1/ibv_devinfo
#
# These should be installed when you install the rdma-core package.

if [[ $# -ne 6 ]]; then
  echo -e "Usage:\n\tibmon.sh <output_directory> <monitor_id> <snapshot_seconds> <total_snapshots> <infiniband_devices> <infiniband_port>\n"
  echo -e "Arguments:"
  echo -e "\toutput_dir: The directory you want the snapshot results to go to."
  echo -e "\tmonitor_id: The unique ID of the monitor session."
  echo -e "\t\tThis could be either a number, date string, or UUID -- really whatever you want."
  echo -e "\tsnapshot_seconds: The interval between snapshots in seconds. Default is usually 1."
  echo -e "\ttotal_snapshots: The total amount of snapshots you wish to take before exiting."
  echo -e "\tib_devices: A comma-separated string of mlx5 device names you wish to monitor."
  echo -e "\tdevice_port: The port ID on each device you wish to monitor. Only 1 port is supported for monitoring currently."
  echo -e "\t\tDefault is 1 for the first port.\n"
  echo -e "Example:"
  echo -e "\t./ibmon.sh /tmp/ccarlson/ \$(date +%s) 1 5 mlx5_0,mlx5_1,mlx5_2,mlx5_3,mlx5_4 1"
  exit 1
fi

OUT_DIR=$1
MON_ID=$2
SNAPSHOT_SECONDS=$3
TOTAL_SNAPSHOTS=$4
INFINIBAND_DEVICES=$5
INFINIBAND_PORT=$6

# Transform comma-separated device list to space-separated
INFINIBAND_DEVICES=$(echo $INFINIBAND_DEVICES | tr -s ',' ' ')

# Sanity checking
[ -z "$SNAPSHOT_SECONDS" ] && echo "Need to set SNAPSHOT_SECONDS env" && exit 1
[ -z "$TOTAL_SNAPSHOTS" ] && echo "Need to set TOTAL_SNAPSHOTS env" && exit 1
[ -z "$INFINIBAND_DEVICES" ] && echo "Need to set INFINIBAND_DEVICES env" && exit 1
[ -z "$INFINIBAND_PORT" ] && echo "Need to set INFINIBAND_PORT env" && exit 1
[ ! -d $OUT_DIR ] && echo "'$OUT_DIR' is not a directory or does not exist" && exit 1

# Check that perfquery is installed
if ! command -v perfquery > /dev/null; then
  echo "Error: perfquery is not installed on the system."
  echo "Please install the rdma-core package which includes it in the infiniband-diags library."
  exit 1
fi

# Check that ibv_devinfo is installed
if ! command -v ibv_devinfo > /dev/null; then
  echo "Error: ibv_devinfo is not installed on the system."
  echo "Please install the rdma-core package which includes it in the infiniband-diags library."
  exit 1
fi

# Check we are running as root
USER_ID=$(id -u)
if [[ $USER_ID -ne 0 ]]; then
  echo "Must run ibmon.sh as root user; perfquery requires it to reset the counters."
  exit 1
fi

# Write this script's process id to a file
HOST=$(hostname)
PID_FILE="$OUT_DIR/${HOST}_${MON_ID}.ibmon.pid"
echo $$ > $PID_FILE

declare -A IB_LIDS  # mapping IB device -> port LID e.g.) {"mlx5_0": 103}

# Iterate over all $INFINIBAND_DEVICES (mlx5_0, mlx5_1, etc), and find the LID
# of the port requested by $INFINIBAND_PORT. Store it in $IB_LIDS.
for IB_DEV in $INFINIBAND_DEVICES; do

  PORT_LID=$(ibv_devinfo --ib-dev=$IB_DEV --ib-port=$INFINIBAND_PORT | grep port_lid | xargs | awk '{print $2}')
  IB_LIDS["$IB_DEV"]=$PORT_LID
  echo "Port LID for $IB_DEV, port $INFINIBAND_PORT: $PORT_LID"
  # Capture headers to CSV file
  OUT_FILE="$OUT_DIR/${HOST}_${IB_DEV}_${PORT_LID}_${MON_ID}.csv"
  echo -n "timestamp," > $OUT_FILE
  perfquery $PORT_LID $INFINIBAND_PORT | tail -5 | grep -o -P "^Port\w+" | xargs | tr -s '[:blank:]' '[,*]' >> $OUT_FILE
done

# Loop for $TOTAL_SNAPSHOTS, with a sleep interval of $SNAPSHOT_SECONDS.
i=0
while [[ i -lt $TOTAL_SNAPSHOTS ]]; do

  # Iterate over all IB devices and capture perfquery output for each one.
  for IB_DEV in "${!IB_LIDS[@]}"; do
    PORT_LID=${IB_LIDS[$IB_DEV]}
    OUT_FILE="$OUT_DIR/${HOST}_${IB_DEV}_${PORT_LID}_${MON_ID}.csv"

    # Write the snapshot index, followed by the 5 values separated by commas
    echo -en "$i," >> $OUT_FILE
    perfquery --reset_after_read $PORT_LID $INFINIBAND_PORT | tail -5 | grep -o -P "\d+" | xargs | tr -s '[:blank:]' '[,*]' >> $OUT_FILE
  done
  (( i = i + 1 ))
  sleep $SNAPSHOT_SECONDS
done
