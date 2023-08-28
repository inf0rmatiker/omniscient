# FREE - Memory Monitor Tool

---

### Introduction

The `free` command is a Linux command that allows you to check for memory `RAM` on your system or to check the memory statics of the Linux operating system.

This tool utilizes the `free` command to monitor and display all the memory metrics of the target system. It provides an extensive overview of how the memory is utilized during each timestamps. The following metrics are obtained: 

- Total Memory (MB)
- Memory Used (MB)
- Free Memory (MB)
- Memory Shared (MB)
- Buffered / Cached Memory (MB)
- Available Memory (MB)

### Running the Memory Monitor Tool

Before running the FREE tool, it is important understand what each of the scripts is used for. The three scripts are,

- `memory_monitor.sh` : Runs a `free --mega` command and stores the headers and value in a separate log file
- `start_all.sh` : Begins running `memory_monitor.sh` on host stores the results in the desired directory
- `stop_all.sh` : Kills the `memory_monitor.sh` process and saves output of csv file in a separate path

The process of running the tool is fairly straightforward. If you would like to monitor the memory during any process, run this tool prior to running that process. 

1. Grab the scripts and move it a directory in your system
2. Untar the .TAR file containing the scripts:
    
    ```bash
    tar -xvf free.tar
    ```
    
3. Run the start script:
    
    ```bash
    free/start_all.sh
    ```
    
4. Once the process completes, you can kill the monitor using the stop script and save the output in a separate csv file:
    
    ```bash
    free/stop_all.sh
    ```
    

### Output

An output of the CSV file will provided all the necessary details of the tool as mentioned above. The example below can be used as a reference.

```bash
timestamp,total,used,free,shared,buff/cache,available
0,1081436,24122,779487,373,277826,1051877
1,1081436,24119,779489,373,277826,1051880
2,1081436,24120,779489,373,277826,1051880
3,1081436,24124,779485,373,277826,1051876
4,1081436,24124,779485,373,277826,1051876
5,1081436,24125,779484,373,277826,1051875
6,1081436,24128,779481,373,277826,1051872
7,1081436,24128,779481,373,277826,1051871
8,1081436,24128,779481,373,277826,1051871
9,1081436,24129,779480,373,277826,1051870
10,1081436,24130,779479,373,277826,1051869
11,1081436,24131,779478,373,277826,1051868
12,1081436,24132,779477,373,277826,1051867
13,1081436,24132,779477,373,277826,1051867
14,1081436,24129,779480,373,277826,1051871
15,1081436,24129,779480,373,277826,1051870
16,1081436,24127,779482,373,277826,1051873
17,1081436,24127,779482,373,277826,1051872
18,1081436,24128,779480,373,277826,1051871
19,1081436,24128,779481,373,277826,1051871
20,1081436,24128,779480,373,277826,1051871
```