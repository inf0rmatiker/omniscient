# Omniscient

A collection of scripts to facilitate distributed resource monitoring. This is a modified version of 
[hamersaw/omniscient](https://github.com/hamersaw/omniscient); credit goes to [Dan Rammer](https://github.com/hamersaw)
for authoring the original version.

The tool uses the [nmon](https://nmon.sourceforge.io/pmwiki.php) binary to capture stats for many different metrics, like CPU usage, network usage, disk I/O, etc.
For InfiniBand metrics, it uses `perfquery` and `ibv_devinfo` to capture information about
InfiniBand traffic counters and device LIDs.
For memory pressure, `free` is used.

## Installation

Clone the repo to a directory shared across your nodes you're monitoring, i.e. on an NFS share.
This means you'll only have to clone the repo _once_, and the same config is used by all
instances of the underlying scripts and binaries.

```bash
git clone https://github.com/inf0rmatiker/omniscient
```

Add `omni` to your `$PATH`:

```bash
export PATH="$PATH:/home/ccarlson/omniscient"
```

### Configuration

Configuration is performed by editing the files in the [config/](config) directory. The files in this directory are:

1. [**config.sh**](config/config.sh): This is a simple bash script used to export and provide easy modification of configuration variables.
   * `SNAPSHOT_SECONDS` Interval between snapshots (in seconds).
   * `TOTAL_SNAPSHOTS` How many snapshots to take of the system before terminating.
   * `CAPTURE_NMON` Whether or not to capture `nmon` metrics.
   * `CAPTURE_FREE` Whether or not to capture memory pressure metrics.
   * `CAPTURE_IBMON` Whether or not to capture InfiniBand metrics.
   * `NMON_METRICS` Which `nmon` metrics you'd like to capture
   * `INFINIBAND_DEVS` Comma-separated list of IB device names to monitor.
   * `INFINIBAND_PORT` Port on the devices you want to monitor.
   
2. [**hosts.txt**](config/hosts.txt): A file containing cluster host information. Each line is a `hostname log_directory` pair.
   * `log_directory` is the local directory on the machines you're monitoring where you wish to store the monitoring output. 
     A good value for this is `/tmp/omniscient`. These logs will be collected after monitoring is completed and aggregated to 
     a single location for post-processing.

## Usage

### Start Monitor

Launch a monitor by running:

```bash
omni start
```

Starting monitors is performed by remotely SSHing into each node and launching the monitor binaries. Example:

```console
[ccarlson@n01 omniscient]$ ./omni start
[+] started monitor with id 'ccarlson-20230822-163709'
```

> *Take note of the monitor id that was generated; you'll need this to stop the monitor.*

### Synopsis

Use `omni help` to view a synopsis:

```console
USAGE omni <COMMAND> [ARGS...]
COMMANDS:
    collect <monitor-id> <directory>    retrieve and compile monitor results.
    help                                display this menu.
    init                                initialize environment DEPRECATED.
    list                                list all monitors.
    remove <monitor-id>                 remove a monitor.
    start                               start a monitor.
    stop <monitor-id>                   stop a monitor.
    cleanup                             clean up omni logs/directories.
    version                             print application version.
```

### Listing Monitors

List running and stopped monitors:

```bash
omni list
```

Example:

```console
root@o186i221:~/ccarlson# omni list

Monitors for host o186i221:

Monitor Id		Type	Status
------------------------------------
root-20230911-175831	nmon	stopped
root-20230911-175831	ibmon	stopped
root-20230911-180135	nmon	stopped
root-20230911-180135	ibmon	stopped
root-20230911-190838	nmon	running
root-20230911-190838	ibmon	running


Monitors for host o186i222:

Monitor Id		Type	Status
------------------------------------
root-20230911-175831	nmon	stopped
root-20230911-175831	ibmon	stopped
root-20230911-180135	nmon	stopped
root-20230911-180135	ibmon	stopped
root-20230911-190838	nmon	running
root-20230911-190838	ibmon	running

```

### Stopping Monitor

Stop a running monitor by referencing its monitor id:

```bash
omni stop <monitor_id>
```
Example:

```console
root@o186i221:~/ccarlson# omni stop root-20230911-191505
Stopping nmon on host o186i221
Stopping ibmon on host o186i221
Stopping free monitor on host o186i221
Stopping nmon on host o186i222
Stopping ibmon on host o186i222
Stopping free monitor on host o186i222
[/] stopped monitor with id 'root-20230911-191505'
```

> *You can use this to stop a monitor before it has completed all its snapshots.*

## Collecting Monitor Data

After the monitors have been stopped, they will have left `.nmon`, `ibmon.csv`, and `.free.csv` output files
in their local directories specified by the `hosts.txt` file. As it stands, these files
are very data rich and need to be processed and aggregated to provide more concise
metrics before we try to analyze them with Python or other tools.

To do this, use:

```bash
omni collect <monitor_id> <output_directory>
```

Example:

```console
root@o186i221:~/ccarlson# omni collect root-20230911-191505 /root/ccarlson/tempdir2
[+] compiled nmon to csv files
o186i222_root-20230911-191505.nmon.csv                                                                                                   100%  278   195.7KB/s   00:00
o186i222_mlx5_0_158_root-20230911-191505.ibmon.csv
o186i222_mlx5_1_156_root-20230911-191505.ibmon.csv
o186i222_mlx5_2_157_root-20230911-191505.ibmon.csv
o186i222_mlx5_4_159_root-20230911-191505.ibmon.csv
o186i222_root-20230911-191505.tar                                                                                                        100%   10KB  14.0MB/s   00:00
o186i222_mlx5_0_158_root-20230911-191505.ibmon.csv
o186i222_mlx5_1_156_root-20230911-191505.ibmon.csv
o186i222_mlx5_2_157_root-20230911-191505.ibmon.csv
o186i222_mlx5_4_159_root-20230911-191505.ibmon.csv
[+] downloaded host monitor files
{'o186i221': ['/root/ccarlson/tempdir2/o186i221_mlx5_0_152_root-20230911-191505.ibmon.csv',
              '/root/ccarlson/tempdir2/o186i221_mlx5_1_147_root-20230911-191505.ibmon.csv',
              '/root/ccarlson/tempdir2/o186i221_mlx5_2_154_root-20230911-191505.ibmon.csv',
              '/root/ccarlson/tempdir2/o186i221_mlx5_4_155_root-20230911-191505.ibmon.csv'],
 'o186i222': ['/root/ccarlson/tempdir2/o186i222_mlx5_0_158_root-20230911-191505.ibmon.csv',
              '/root/ccarlson/tempdir2/o186i222_mlx5_1_156_root-20230911-191505.ibmon.csv',
              '/root/ccarlson/tempdir2/o186i222_mlx5_2_157_root-20230911-191505.ibmon.csv',
              '/root/ccarlson/tempdir2/o186i222_mlx5_4_159_root-20230911-191505.ibmon.csv']}
INFO:root:Saving /root/ccarlson/tempdir2/o186i221_root-20230911-191505_aggregate.csv
INFO:root:Saving /root/ccarlson/tempdir2/o186i222_root-20230911-191505_aggregate.csv
[+] combined host monitor files
```

This will create the directory `/root/ccarlson/tempdir2/` with a `.csv` file for
each of the monitors, and an aggregated `.csv` file with all the combined data.

### Remove Monitor

Monitors may be deleted using the `remove` command:

```bash
omni remove <monitor_id>
```

Example:

```console
[ccarlson@n01 omniscient]$ ./omni remove ccarlson-20230823-110229
[-] removed monitor with id 'ccarlson-20230823-110229'
```

Be sure to stop a monitor before it is removed, less 
it will execute indefinitely unless manually stopped.

### Cleanup

To remove all the `.pid`, `.nmon`, and `.nmon.csv` files created by `omni` in each
of the monitors log directories:

```bash
omni cleanup
```

Example:

```console
root@o186i221:~/ccarlson# omni cleanup
o186i221: Cleaning up directory /tmp/omniscient
o186i222: Cleaning up directory /tmp/omniscient
```
