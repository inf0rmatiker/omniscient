#!/bin/bash

# General configuration
export SNAPSHOT_SECONDS=1  # how often to take a snapshot
export TOTAL_SNAPSHOTS=30  # how many snapshots before exiting

export CAPTURE_FREE="yes"  # "yes" if you want to capture memory-pressure metrics. "no" if not.
export CAPTURE_NMON="yes"  # "yes" if you want to capture nmon metrics. "no" if not.
export CAPTURE_IB="yes"  # "yes" if you want to capture InfiniBand metrics. "no" if not.

## nmon configuration (CPU, disk I/O, normal network stack)
export NMON_METRICS="CPU_ALL:User% CPU_ALL:Sys% DISKBUSY:nvme0n1 DISKREAD:nvme0n1 DISKWRITE:nvme0n1"

## ibmon configuration
export INFINIBAND_DEVS="mlx5_0,mlx5_1"  # which IB devices do we want to monitor, comma-separated
export INFINIBAND_PORT=1  # which port on the IB devices do we want to monitor (recommend 1).

