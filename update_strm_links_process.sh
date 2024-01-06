#!/bin/bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

SOURCE_DIR="$1"
LINK_DIR="$2"
NAS_ADDRESS="$3"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROCESSED_LOG="$SCRIPT_DIR/processed_files.log"
LOG_FILE="$SCRIPT_DIR/update_strm_links.log"
TIME_LOG="$SCRIPT_DIR/time_log.txt"
SCREEN_SESSION="update_strm_links"

trap 'echo "捕获到 SIGINT，正在退出。"; screen -S "$SCREEN_SESSION" -X quit; exit 0' SIGINT

# 检查文件是否已处理
has_been_processed() {
    local file="$1"
    grep -Fqe "$file" "$PROCESSED_LOG"
}

# 记录处理过的文件
log_processed_file() {
    local file="$1"
    echo "$file" >> "$PROCESSED_LOG"
}

process_file() {
    file="$1"
    event="$2"
    relative_path="${file#$SOURCE_DIR/}"
    target_file="$LINK_DIR/$relative_path"
    temp_log="$LOG_FILE.tmp"

    if has_been_processed "$file"; then
        return
    fi

    mkdir -p "$(dirname "$target_file")"
    if [[ $file == *.strm ]]; then
        sed "s#DOCKER_ADDRESS#$NAS_ADDRESS#g" "$file" > "$target_file"
    else
        ln -sfn "$file" "$target_file"
    fi

    echo "$file" >> "$temp_log" && mv "$temp_log" "$LOG_FILE"
    log_processed_file "$file"
}

export -f process_file has_been_processed log_processed_file
export SOURCE_DIR LINK_DIR LOG_FILE PROCESSED_LOG

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
