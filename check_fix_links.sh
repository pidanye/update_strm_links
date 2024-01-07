#!/bin/bash

# 设置源目录和链接目录
SOURCE_DIR="/path/to/source"
LINK_DIR="/path/to/links"
MISSED_LINKS=0

find "$SOURCE_DIR" -type f ! -name "*.strm" -print0 | while IFS= read -r -d '' file; do
    relative_path="${file#$SOURCE_DIR/}"

    link_path="$LINK_DIR/$relative_path"

    if [ ! -L "$link_path" ]; then
        echo "缺失软链接，正在创建: $link_path"
        mkdir -p "$(dirname "$link_path")"
        ln -s "$file" "$link_path"
        MISSED_LINKS=$((MISSED_LINKS+1))
    fi
done

# 输出结果
if [ $MISSED_LINKS -eq 0 ]; then
    echo "文件完整，未发现缺失的软链接。"
else
    echo "共修复 $MISSED_LINKS 个缺失的软链接。"
fi
