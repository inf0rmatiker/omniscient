#!/bin/bash

# Check arguments
if [ $# != 2 ]; then
  echo "$USAGE"
  exit 1
fi

OUTPUT_DIR=$2
MONITOR_ID=$1

# If doesn't exist -> create destination directory
if [ ! -d $OUTPUT_DIR ]; then
  mkdir -p $OUTPUT_DIR
fi

# Iterate over hosts and convert nmon to csv
while read -r LINE; do

  # Parse host and log directory
  HOST=$(echo "$LINE" | awk '{print $1}')
  DIRECTORY=$(echo "$LINE" | awk '{print $2}')

  if [ "$HOST" == "$(hostname)" ]; then

    # Convert local nmon to csv
    (python3 "$SCRIPT_DIR/nmon/nmon2csv.py" "${DIRECTORY}/${MONITOR_ID}.nmon" \
      --metrics="$NMON_METRICS" > "${DIRECTORY}/${HOST}_${MONITOR_ID}.nmon.csv") &

  else

    # Convert remote nmon to csv
    (ssh "$HOST" -n -o ConnectTimeout=500 \
      "python3 $SCRIPT_DIR/nmon/nmon2csv.py ${DIRECTORY}/${MONITOR_ID}.nmon \
        --metrics=\"$NMON_METRICS\" > ${DIRECTORY}/${HOST}_${MONITOR_ID}.nmon.csv") &

  fi
done <"$HOST_FILE"

# Wait for all to complete
wait

echo "[+] compiled nmon to csv files"

# Iterate over hosts
while read -r LINE; do

  # parse host and log directory
  HOST=$(echo "$LINE" | awk '{print $1}')
  DIRECTORY=$(echo "$LINE" | awk '{print $2}')

  if [ "$HOST" == "$(hostname)" ]; then
    # Copy local data to collect directory
    cp ${DIRECTORY}/${HOST}_${MONITOR_ID}.nmon.csv ${OUTPUT_DIR}/${HOST}.nmon.csv
    cp ${DIRECTORY}/${HOST}_*${MONITOR_ID}.csv $OUTPUT_DIR
  else
    # Copy remote data to collect directory
    scp "${HOST}:${DIRECTORY}/${HOST}_${MONITOR_ID}.nmon.csv" "${OUTPUT_DIR}/${HOST}.nmon.csv"
    ssh $HOST -n -o ConnectTimeout=500 \
      "cd $DIRECTORY && tar -cvf \"${HOST}_${MONITOR_ID}.tar\" ${HOST}_*${MONITOR_ID}.csv"
    scp "${HOST}:${DIRECTORY}/${HOST}_${MONITOR_ID}.tar" $OUTPUT_DIR
    cd $OUTPUT_DIR && tar -xvf "${OUTPUT_DIR}/${HOST}_${MONITOR_ID}.tar" && rm "${OUTPUT_DIR}/${HOST}_${MONITOR_ID}.tar"
  fi

done < $HOST_FILE

echo "[+] downloaded host monitor files"

# Combine host monitor files
python3 $SCRIPT_DIR/nmon/csv-merge.py $OUTPUT_DIR/*nmon.csv > "$OUTPUT_DIR/aggregate.nmon.csv"
python3 $SCRIPT_DIR/ibmon/aggregate.py $OUTPUT_DIR $MONITOR_ID --log-level=INFO

echo "[+] combined host monitor files"
