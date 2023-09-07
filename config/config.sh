#!/bin/bash

# General configuration
export SNAPSHOT_SECONDS=1  # how often to take a snapshot
export TOTAL_SNAPSHOTS=30  # how many snapshots before exiting

## nmon configuration (CPU, disk I/O, normal network stack)
export CAPTURE_NMON="yes"
export NMON_METRICS="CPU_ALL:User% CPU_ALL:Sys% DISKBUSY:nvme0n1 DISKREAD:nvme0n1 DISKWRITE:nvme0n1"

## InfiniBand configuration
export CAPTURE_IB="yes"
export INFINIBAND_DEVS="mlx5_0 mlx5_1"  # which IB cards do we want to monitor
export INFINIBAND_PORT=1

## free configuration (memory pressure)
export CAPTURE_FREE="yes"
