# IBmon

IBmon is set of scripts and tools for capturing real-time InfiniBand metrics,
performance counters, and stats.

## Usage

1. Create a directory where you want the collected metrics to reside.
   - This is usually a temporary directory under `/tmp`.
2. Run the [`ibmon.sh` script](./ibmon.sh) as root user or using `sudo`.
   - [`ibmon.sh` usage](#ibmonsh)
3. Wait for the monitor to finish its snapshots or kill it using `Ctrl+C`.
4. Install prerequisite Python3 libraries: `python3 -m pip install -r requirements.txt`
5. Aggregate the results to a single CSV file by running `aggregate.py`.

### ibmon.sh

To run the `ibmon.sh` script you'll need to provide it with a few pieces of information as positional arguments:

```bash
ibmon.sh <output_dir> <monitor_id> <snapshot_seconds> <total_snapshots> <ib_devices> <device_port>
```

- `output_dir`: The directory you want the snapshot results to go to.
  - Example: `/tmp/ibmon/`
- `monitor_id`: The unique ID of the monitor session. This could be either a number, date string, or UUID -- really whatever you want.
  - Example: Using `date +%F`: `2023-09-08`
  - Example: Using `date +%s`: `1694189032` (seconds since epoch)
- `snapshot_seconds`: The interval between snapshots in seconds. Default is usually `1`.
- `total_snapshots`: The total amount of snapshots you wish to take before exiting.
  - Example: `300` At 1-second snapshots, this takes 300 1-second snapshots.
- `ib_devices`: A comma-separated string of mlx5 device names you wish to monitor.
  - Example: `"mlx5_0,mlx5_1,mlx5_2"` Capture information about 3 HCA devices.
  - Example: `mlx5_0` Capture information about only `mlx5_0`.
- `device_port`: The port ID on each device you wish to monitor. Only 1 port is supported for monitoring currently. Default is `1` for the first port.
  - Example: `1`

Example:

```console
# ./ibmon.sh /tmp/omniscient/ root-20230911-200447 1 5 "mlx5_0,mlx5_1,mlx5_2,mlx5_4" 1
Port LID for mlx5_0, port 1: 152
Port LID for mlx5_1, port 1: 147
Port LID for mlx5_2, port 1: 154
Port LID for mlx5_4, port 1: 155
```

Results in:

```console
# tree /tmp/omniscient/
/tmp/omniscient/
├── o186i221_1694189342.ibmon.pid
├── o186i221_mlx5_0_152_root-20230911-200447.ibmon.csv
├── o186i221_mlx5_1_147_root-20230911-200447.ibmon.csv
├── o186i221_mlx5_2_154_root-20230911-200447.ibmon.csv
└── o186i221_mlx5_4_155_root-20230911-200447.ibmon.csv

0 directories, 5 files
```

To see what an example individual CSV capture looks like for a single device, check out [this result](example_multi_nodes/o186i221_mlx5_4_155_root-20230911-200447.ibmon.csv).

### aggregate.py

This Python program imports the individual CSV captures for each device and aggregates their information into a single aggregate CSV file with columns for the
summed data. It outputs one aggregate CSV file per host, and relies on Pandas DataFrame operations to merge, transform, and sum the data. It then takes the host-aggregated files, and merges them
together to a single file for the total monitor session (which may span multiple hosts). This file contains 

To run this script, you just need to provide it with two positional arguments:

```bash
python3 aggregate.py <directory> <monitor_id> --log-level=[DEBUG|INFO|WARNING|ERROR]
```

- `directory`: Directory where the individual device-based CSV captures reside.
This is also where your aggregate CSV file will be output.
- `monitor_id`: The session monitor ID to distinguish against other session monitor files.

Example:

```bash
python3 aggregate.py example_multi_nodes/ root-20230911-200447 --log-level=INFO
```

Results in:

- Host aggregate files:
   - [example_multi_nodes/o186i221_root-20230911-200447_host_aggregate.ibmon.csv](example_multi_nodes/o186i221_root-20230911-200447_host_aggregate.ibmon.csv)
   - [example_multi_nodes/o186i222_root-20230911-200447_host_aggregate.ibmon.csv](example_multi_nodes/o186i222_root-20230911-200447_host_aggregate.ibmon.csv)
- Cluster-wide monitor session aggregate file:
   - [example_multi_nodes/root-20230911-200447_total_aggregate.ibmon.csv](example_multi_nodes/root-20230911-200447_total_aggregate.ibmon.csv)
