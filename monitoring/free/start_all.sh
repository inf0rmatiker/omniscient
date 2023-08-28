#!/bin/bash

OUT_DIR="/s/$HOSTNAME/a/nobackup/galileo/memory_monitor"

SCRIPT_DIR="$PROJECT_MANAGEMENT/cluster/monitoring/free"
readarray -t HOSTS < "$SCRIPT_DIR/hosts.txt"

for HOST in ${HOSTS[@]}; do
  if [[ "$HOST" == "$(hostname)" ]]; then
    nohup "$SCRIPT_DIR/memory_monitor.sh" & disown
  else
    nohup ssh "$HOST" "$SCRIPT_DIR/memory_monitor.sh" & disown
  fi
done
