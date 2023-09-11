#!/bin/bash

# Validate arguments
if [ $# != 1 ]; then
    echo -e "Usage:\n\tmonitor_statuses.sh <pid_directory>\n" && exit 1
fi

PID_DIR=$1
HOST=$(hostname)
mapfile -d $'\0' PID_FILES < <(find $PID_DIR -name "*.pid" -print0)
declare -A MONITOR_IDS

OUTPUT="\nMonitors for host $HOST:\n\n"

[[ ${#PID_FILES[@]} -eq 0 ]] && \
  OUTPUT="${OUTPUT}No monitors found for host." && \
  echo -e $OUTPUT && \
  exit 0

OUTPUT="${OUTPUT}Monitor Id\tType\tStatus\n"
OUTPUT="${OUTPUT}--------------------------------\n"
for FILE in "${PID_FILES[@]}"; do
  BASENAME=$(basename $FILE)

  # Set space as the delimiter
  IFS='_'

  #Read the split words into an array based on space delimiter
  read -a FIELDS <<< "$BASENAME"

  FILE_HOST=${FIELDS[0]}
  REMAINDER=${FIELDS[1]}
  IFS='.'
  read -a REMAINDER_FIELDS <<< "$REMAINDER"
  MONITOR_ID=${REMAINDER_FIELDS[0]}
  MONITOR_IDS[${MONITOR_ID}]+=1
  MONITOR_TYPE=${REMAINDER_FIELDS[1]}
  IFS=' '

  PID=$(cat $FILE)
  if ps -p "$PID" > /dev/null; then
    STATUS="running"
  else
    STATUS="stopped"
  fi
  OUTPUT="${OUTPUT}$MONITOR_ID\t$MONITOR_TYPE\t$STATUS\n"
done

echo -e $OUTPUT

# If you want to group monitors together by mon id:
#for KEY in "${!MONITOR_IDS[@]}"; do
#  echo -e "\nGrouped monitors: "
#  echo -e $OUTPUT | grep $KEY
#done
