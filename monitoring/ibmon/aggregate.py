#!/bin/python3

import logging as log
import os
import pandas as pd
from pprint import pprint
import sys


def usage():
    print("Usage:\n\taggregate.py <directory> <monitor_id> [OPTIONS]\n")
    print("OPTIONS:\n\t--log-level\tDEBUG,INFO,WARNING,ERROR\n")


def find_csv_files(directory: str, monitor_id: str) -> dict:
    """
    Finds all CSV files associated with monitor ID, and groups them by host.

    :param directory: String directory to search in.
    :param monitor_id: String monitor ID to filter by.
    :return: Dictionary with hostnames as keys, and a list of CSV filenames as
      values.

      Example:
      {'o186i221': ['example/o186i221_mlx5_3_0_1234.csv',
                    'example/o186i221_mlx5_1_147_1234.csv',
                    'example/o186i221_mlx5_4_155_1234.csv',
                    'example/o186i221_mlx5_2_154_1234.csv',
                    'example/o186i221_mlx5_0_152_1234.csv'] }
    """
    csv_files = [x for x in os.listdir(directory) if x.endswith(".ibmon.csv")
                 and monitor_id in x and "aggregate" not in x]

    if len(csv_files) == 0:
        log.error(f"Did not find any csv files in {directory} with monitor "
                  f"id {monitor_id}")
        return {}

    # strip off trailing '/' from directory if it exists
    if directory.endswith("/"):
        directory = directory.rstrip("/")

    # mapping of { <hostname> -> [<list of csv files>] }
    grouped_by_node = {}
    for csv_file in csv_files:
        fields = csv_file.split("_")
        hostname = fields[0]
        if hostname not in grouped_by_node:
            grouped_by_node[hostname] = list()
        grouped_by_node[hostname].append(f"{directory}/{csv_file}")

    return grouped_by_node


def aggregate_results(csv_files: dict, monitor_id: str, out_dir: str) -> None:
    """
    Aggregates all the results together on a per-node basis.

    :param csv_files: Mapping of hostnames to a list of CSV files.
    :param monitor_id: String monitor ID.
    :param out_dir: String output directory for aggregate CSV file.
    :return: Nothing.
    """

    # Iterate over csv lists; for each host, there's a CSV file per device.
    # example hostname: n01
    # example csv_list: ["example/n01_mlx5_0_1234.csv", ...]
    # The first device is mlx5_0
    for hostname, csv_list in csv_files.items():
        unique_column_keys = set()
        individual_dfs = []
        for csv_file in csv_list:

            # Retrieve the device name from filename
            log.debug(f"csv_file: {csv_file}")
            basename = os.path.basename(csv_file)
            fields = basename.split("_")  # ["n01", "mlx5", "3", ...]
            device = f"{fields[1]}_{fields[2]}"
            log.debug(f"device name: {device}")

            df = pd.read_csv(csv_file, header=0)
            cols = len(df.axes[1])
            if cols < 6:
                log.debug(f"Found CSV file ({csv_file}) with only {cols} "
                          f"columns. Skipping.")
                continue

            # Rename all non-timestamp columns to append device name as suffix

            for column in df:
                if column != "timestamp":
                    if column not in unique_column_keys:
                        unique_column_keys.add(column)
                    df = df.rename(columns={column: f"{column}_{device}"})

            individual_dfs.append(df)

        log.debug(f"Set of unique columns: {unique_column_keys}")

        # Merge all DFs together, so we have a column per device
        left_df = individual_dfs[0]
        for i in range(1, len(individual_dfs)):
            right_df = individual_dfs[i]
            left_df = left_df.merge(right_df, how="left", on="timestamp")

        # Use our set of unique column keys,
        # i.e. ("PortXmitPkts", "PortRcvPkts", ...)
        # to aggregate all columns with each key name in it.
        for key in unique_column_keys:
            columns_sharing_key = [x for x in left_df.columns if key in x]
            log.debug(f"columns sharing key {key}: {columns_sharing_key}")

            # Sum all columns sharing this common key and add as new column
            left_df[f"{key}_sum"] = left_df[columns_sharing_key].sum(axis=1)

        # Save DataFrame as aggregate CSV file
        out_filename = f"{hostname}_{monitor_id}_aggregate.csv"
        out_full_path = os.path.join(out_dir, out_filename)
        log.info(f"Saving {out_full_path}")
        left_df.to_csv(out_full_path, sep=",", header=True, index=False)


def main():
    if 3 > len(sys.argv) > 4:
        usage()
        exit(1)

    log_level = log.DEBUG
    if len(sys.argv) == 4:
        string_arg = sys.argv[3]
        if "--log-level=" not in string_arg:
            usage()
            exit(1)
        value = string_arg.split("=")[1]
        if value == "DEBUG":
            log_level = log.DEBUG
        elif value == "INFO":
            log_level = log.INFO
        elif value == "WARNING":
            log_level = log.WARNING
        elif value == "ERROR":
            log_level = log.WARNING
        else:
            print("Invalid --log-level value.")
            usage()
            exit(1)

    log.basicConfig(level=log_level)

    results_dir = sys.argv[1]
    monitor_id = sys.argv[2]
    log.debug(f"results_dir='{results_dir}', monitor_id='{monitor_id}'")
    csv_files = find_csv_files(results_dir, monitor_id)
    pprint(csv_files)

    if not csv_files:
        exit(1)

    aggregate_results(csv_files, monitor_id, results_dir)


if __name__ == '__main__':
    main()
