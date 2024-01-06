#!/bin/bash

SOURCE_DIR="$1"
LINK_DIR="$2"
NAS_ADDRESS="$3"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_FILE="$SCRIPT_DIR/update_strm_links.log"
TIME_LOG="$SCRIPT_DIR/time_log.txt"
SCREEN_SESSION="update_strm_links"

trap 'echo "捕获到 SIGINT，正在退出。"; screen -S "$SCREEN_SESSION" -X quit; exit 0' SIGINT

process_file() {
    file="$1"
    event="$2"
    relative_path="${file#$SOURCE_DIR/}"
    target_file="$LINK_DIR/$relative_path"
    temp_log="$LOG_FILE.tmp"

    mkdir -p "$(dirname "$target_file")"
    if [[ $file == *.strm ]]; then
        sed "s#DOCKER_ADDRESS#$NAS_ADDRESS#g" "$file" > "$target_file"
    else
        ln -sfn "$file" "$target_file"
    fi
    echo "$file" >> "$temp_log" && mv "$temp_log" "$LOG_FILE"
}

export -f process_file
export SOURCE_DIR LINK_DIR LOG_FILE

start_time=$(date +%s)
find "$SOURCE_DIR" -type f -print0 | xargs -0 -n 1 -P 0 -I {} bash -c 'process_file "$@"' _ {}
end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "扫描和处理执行时间: $((execution_time / 60)) 分钟." | tee "$TIME_LOG"

inotifywait -m -e create -e modify -e delete "$SOURCE_DIR" --format '%w%f %e' | while read file event
do
    process_file "$file" "$event"
done

while true; do
    sleep 1
done
