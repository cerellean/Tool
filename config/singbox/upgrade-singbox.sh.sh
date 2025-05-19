#!/bin/bash

# 停止sing-box
rc-service sing-box stop

echo "开始复制 sing-box 到 /usr/local/bin"
cp sing-box /usr/local/bin
echo "复制完成"

echo "开始添加执行权限"
chmod u+x /usr/local/bin/sing-box
echo "执行权限添加完成"

# 启动sing-box
rc-service sing-box start