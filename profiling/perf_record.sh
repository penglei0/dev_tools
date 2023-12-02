#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <work_dir> <tools_dir>"
    echo "work_dir: the directory where the perf_* files are located"
    echo "tools_dir: the directory where the flamegraph.pl and stackcollapse-perf.pl are located"
    exit 1
fi
work_dir=$1
tools_dir=$work_dir/tools/
if [ ! -d "$work_dir" ]; then
    echo "work_dir $work_dir does not exist!"
    exit 1
fi

if [ -d "$tools_dir" ]; then
    rm "$tools_dir" -rf
    mkdir "$tools_dir"
fi
flamegraph_dir="$tools_dir"/FlameGraph
 # download tools/FlameGraph
if [ ! -d "$flamegraph_dir" ]; then
    git clone https://github.com/brendangregg/FlameGraph.git "$flamegraph_dir"
fi


perf_results_dir="perf_results"
if [ ! -d "$perf_results_dir" ]; then
    mkdir "$perf_results_dir"
else
    rm "$perf_results_dir" -rf
    mkdir "$perf_results_dir"
fi

echo "########### start perf record ###########"

file_list=$(find "$work_dir" -maxdepth 1 -type f -name "perf_*" -printf "%f\n")
echo "file_list: $file_list"

# do perf record for each file
for file in $file_list; do
    echo "### processing $file"
    # check version string 
    "$work_dir"/"$file" --version > version.txt
    # check if the version.txt contains "RelWithDebInfo"
    has_debug_info=$(grep "RelWithDebInfo" version.txt || true)
    if [ -z "$has_debug_info" ]; then
        echo "No debug info in $file, perf cannot be measured!"
        cat version.txt
        rm version.txt
        exit 0
    else
        echo "### Run $file with debug info! FlameGraph will be generated!"
    fi
    rm version.txt
    # 0. start run `file`
    set -x
    "$work_dir""$file" &
    set +x
    # 1. check if `file` is running
    while [ -z "$(pidof "$file")" ]; do
        echo "${file} is not running, wait!"
        sleep 1
    done
    local_perf_data="$perf_results_dir""/perf_""$file"".data"
    local_out_perf="$perf_results_dir""/out_""$file"".perf"
    local_out_perf_folded="$perf_results_dir""/out_""$file"".perf-folded"
    local_perf_svg="$perf_results_dir""/out_""$file"".svg"

    # 2. start perf record
    nohup perf record -F 99 -p "$(pidof "$file")" -o "$local_perf_data" -g -- sleep 10 &

    sleep 1 # wait perf start.

    # 3. check if perf is running, wait for perf record finish
    perf_pid=$(pidof perf)
    echo "perf_pid running: $perf_pid"
    while [ -n "$perf_pid" ]; do 
        echo "[$file] wait perf finish! $perf_pid"
        sleep 1
        perf_pid=$(pidof perf)
    done

    # check if `file` is running, then kill it
    if [ -n "$(pidof "$file")" ]; then
        echo "kill $file"
        kill -9 "$(pidof "$file")"
    fi

    if [ ! -f "$local_perf_data" ]; then
        echo "perf record failed! no perf data file $local_perf_data"
        exit 1
    fi

    # 3. if yes, gerneate perf svg
    perf script -i "$local_perf_data" > "$local_out_perf"
    if [ -f "$local_out_perf" ]; then
        "$flamegraph_dir"/stackcollapse-perf.pl "$local_out_perf"  > "$local_out_perf_folded"
    else 
        echo "No out.perf"
        exit 1
    fi

    if [ -f "$local_out_perf_folded" ]; then
        "$flamegraph_dir"/flamegraph.pl "$local_out_perf_folded" > "$local_perf_svg"
    else 
        echo "No out.perf-folded"
        exit 1
    fi

    if [ ! -f "$local_perf_svg" ]; then
        echo "perf record failed! no perf svg file $local_perf_svg"
        exit 1
    fi

    echo "perf svg is generated: $local_perf_svg"
    # 4. clean the files belongs to current host
    rm "$local_perf_data"  "$local_out_perf" "$local_out_perf_folded" -rf || true
done


echo "########### end perf record ###########"