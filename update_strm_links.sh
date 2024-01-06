#!/bin/bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

SCRIPT_NAME="update_strm_links"
PROCESS_SCRIPT_URL="https://raw.githubusercontent.com/pidanye/update_strm_links/main/update_strm_links_process.sh"

read -p "请输入源媒体库地址: " SOURCE_DIR
read -p "请输入目标地址: " LINK_DIR
read -p "请输入NAS地址: " NAS_ADDRESS

export SOURCE_DIR LINK_DIR NAS_ADDRESS

if ! command -v screen &> /dev/null; then
    echo "未安装 screen。请尝试安装：sudo apt-get install screen"
    exit 1
fi

if ! command -v inotifywait &> /dev/null; then
    echo "未安装 inotify-tools。请尝试安装：sudo apt-get install inotify-tools"
    exit 1
fi

if screen -list | grep -q "\.$SCRIPT_NAME"; then
    echo "发现已存在的 $SCRIPT_NAME screen 会话，正在终止它。"
    screen -S "$SCRIPT_NAME" -X quit
fi

# 从GitHub获取子脚本并在screen会话中直接执行
PROCESS_SCRIPT_COMMAND="$(curl -s "$PROCESS_SCRIPT_URL")"
screen -dmS "$SCRIPT_NAME" /bin/bash -c "$PROCESS_SCRIPT_COMMAND" _ "$SOURCE_DIR" "$LINK_DIR" "$NAS_ADDRESS"

echo "Screen 会话 '$SCRIPT_NAME' 已启动。您可以使用 'screen -r $SCRIPT_NAME' 命令查看运行状态。"
