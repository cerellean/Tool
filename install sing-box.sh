#!/bin/bash
apt update
apt install git curl vim unzip bird2 -y

echo "开始下载 sing-box"
wget https://github.com/SagerNet/sing-box/releases/download/v1.11.11/sing-box-1.11.11-linux-amd64.tar.gz

echo "sing-box 下载完成"

echo "开始解压"
tar -zxvf sing-box-1.11.11-linux-amd64.tar.gz
echo "解压完成"

echo "开始重命名"
cd sing-box-1.11.11-linux-amd64
echo "重命名完成"

echo "开始添加执行权限"
chmod u+x sing-box
echo "执行权限添加完成"

echo "开始创建 /etc/sing-box 目录"
mkdir /etc/sing-box
echo "/etc/sing-box 目录创建完成"

echo "开始复制 sing-box 到 /usr/local/bin"
cp sing-box /usr/local/bin
echo "复制完成"

echo "开始添加执行权限"
chmod u+x /usr/local/bin/sing-box
echo "执行权限添加完成"

echo "开始设置 转发"
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
echo "转发设置完成"

echo "开始创建 systemd 服务"

tee /etc/systemd/system/sing-box.service > /dev/null <<EOF
[Unit]
Description=Sing-Box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=1800s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

echo "systemd 服务创建完成"

echo "清清除现有的nftables规则"
nft flush ruleset
echo "清空 nftalbes 规则完成"

echo "应用新的nftables配置"
nft -f <<EOF
table inet filter {
    chain input { type filter hook input priority 0; policy accept; }
    chain forward { type filter hook forward priority 0; policy accept; }
    chain output { type filter hook output priority 0; policy accept; }
}
EOF
echo "nftables规则写入完成"
