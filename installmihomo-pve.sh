#!/bin/bash
apt update
apt install git curl vim bird2 -y

echo "开始下载 mihomo"
wget https://github.com/MetaCubeX/mihomo/releases/download/v1.18.7/mihomo-linux-amd64-v1.18.7.gz

echo "mihomo 下载完成"

echo "开始解压"
gunzip mihomo-linux-amd64-v1.18.7.gz
echo "解压完成"

echo "开始重命名"
mv mihomo-linux-amd64-v1.18.7 mihomo
echo "重命名完成"

echo "开始添加执行权限"
chmod u+x mihomo
echo "执行权限添加完成"

echo "开始创建 /etc/mihomo 目录"
mkdir /etc/mihomo
echo "/etc/mihomo 目录创建完成"

echo "开始复制 mihomo 到 /usr/local/bin"
cp mihomo /usr/local/bin
echo "复制完成"

echo "开始添加执行权限"
chmod u+x /usr/local/bin/mihomo
echo "执行权限添加完成"

echo "开始下载前端压缩包"
wget https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip
echo "前端压缩包下载完成"

echo "开始解压前端压缩包"
unzip gh-pages.zip
echo "解压完成"

echo "开始安装ui界面"
mv metacubexd-gh-pages/ metacubexd/
mv metacubexd /etc/mihomo/metacubexd
echo "ui界面安装完成"

echo "开始设置 转发"
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
echo "转发设置完成"

echo "开始创建 systemd 服务"

tee /etc/systemd/system/mihomo.service > /dev/null <<EOF
[Unit]
Description=mihomo Daemon, Another Clash Kernel.
After=network.target NetworkManager.service systemd-networkd.service iwd.service

[Service]
Type=simple
LimitNPROC=500
LimitNOFILE=1000000
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME
Restart=always
ExecStartPre=/usr/bin/sleep 1s
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

echo "systemd 服务创建完成"
