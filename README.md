# 个人alpine折腾sing-box/mihomo配置记录
# 创建lxc容器模板
## 容器创建（alpine/debian同样设置）
取消特权容器勾选
### 容器完善
创建完成后容器，不要开机，进入对应容器的选项
勾选一下选项
- 嵌套
- nfs
- smb
- fuse
### 容器配置文件
开启TUN/TAP支持
进入pve控制台，进入/etc/pve/lxc文件夹，修改对应的配置文件，可以vi /etc/pve/lxc/[ID].conf
添加以下内容
```
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop: 
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

## Alpine 系统操作流程
### 启动，更换源（alpine）
```bash
sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
```
### 1.更新系统

```bash
apk update && apk upgrade
```

### 2.安装必须插件

```bash
apk add curl git wget nano bash
```

### 3.因为 PVE 虚拟机容器，默认是没有开启远程 root 登录，如需开启使用下面命令

```bash
apk add --no-cache openssh && \
mkdir -p /etc/ssh && ssh-keygen -A && \
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
rc-update add sshd && \
rc-service sshd restart
```

### 4.开启内核转发
在alpine中编辑/etc/sysctl.conf，添加一行
```
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```
运行
```
sysctl -p
```
如果sysctl不会在开机时启动，则需要运行[rc-update add sysctl]。

# 安装sing-box/mihomo
## sing-box安装
配置文件夹路径：/etc/sing-box

文件存放路径：/usr/local/bing

## mihomo安装
配置文件夹路径：/etc/mihomo

文件存放路径：/usr/local/bing

## sing-box openRC启动文件
```
cat /etc/init.d/singbox
```
```
#!/sbin/openrc-run

command="/usr/local/bin/sing-box"
command_args="run -c /etc/sing-box/config.json" #是您的配置文件位置
description="sing-box service"

depend() {
  need net
  use logger
}

start() {
  ebegin "Starting sing-box"
  start-stop-daemon --start --background --exec $command -- $command_args
  eend $?
}

stop() {
  ebegin "Stopping sing-box"
  start-stop-daemon --stop --exec $command
  eend $?
}
```

赋权&添加启动
```
chmod +x /etc/init.d/sing-box
rc-update add sing-box default
```
启动
```
service sing-box start
```
## mihomo openRC启动文件
```
cat /etc/init.d/mihomo
```
```
#!/sbin/openrc-run
command="/usr/local/bin/mihomo"
command_args="-d /etc/mihomo"
command_background="yes"
command_user="root"
respawn="true"
pidfile="/var/run/mihomo.pid"

depend() {
    need net
}
```
赋权&添加默认启动
```
chmod +x /etc/init.d/mihomo
rc-update add mihomo default
```
启动命令
```
service mihomo start
```
# alpine折腾IPlist
## 安装BIRD
```
apk add bird
```
## 添加启动
```
rc-update add bird default
service bird start
```
## 非本地ip表获取
```
cd /home
```
IPlist内容

```
#!/bin/bash

# 下载 routes4.conf 文件
echo "下载 routes4.conf 文件..."
curl -L -o routes4.conf https://github.com/cerellean/nchnroutes-k/releases/download/v1.0.0/routes4.conf

# 下载 routes6.conf 文件
echo "下载 routes6.conf 文件..."
curl -L -o routes6.conf https://github.com/cerellean/nchnroutes-k/releases/download/v1.0.0/routes6.conf

# 获取文件大小（单位为 KB）
filesize_routes4=$(stat -c%s routes4.conf)
filesize_routes6=$(stat -c%s routes6.conf)
filesize_routes4_kb=$((filesize_routes4/1024))
filesize_routes6_kb=$((filesize_routes6/1024))

# 如果两个文件大小都大于 400KB，则将它们复制到 /etc 文件夹下，并执行 birdc configure 命令
if [ "$filesize_routes4_kb" -gt "400" ] && [ "$filesize_routes6_kb" -gt "400" ]; then
  echo "复制 routes4.conf 文件到 /etc 文件夹..."
  cp -f routes4.conf /etc/routes4.conf
  
  echo "复制 routes6.conf 文件到 /etc 文件夹..."
  cp -f routes6.conf /etc/routes6.conf
  
  # 循环执行 birdc configure 命令，直到出现 Reconfigured 为止
  echo "执行 birdc configure 命令..."
  while true; do
    if birdc configure | grep -q "Reconfigured"; then
      echo "BIRD 配置已重新加载！"
      break
    fi
    sleep 1
  done
else
  echo "文件大小不满足要求，未执行复制和 birdc configure 命令。"
fi
```
赋予权限并执行
```
chmod +x iplist.sh
./iplist.sh
```
定时更新
```
crontab -e
0 5 * * * /bin/bash /home/iplist.sh
```
## 路由地址宣告
修改bird2配置文件为以下内容 ，文件在/etc/bird.conf
```
log syslog all;

router id 192.168.1.10;

protocol device {
        scan time 60;
}

protocol kernel {
        ipv4 {
              import none;
              export all;
        };
}

protocol static {
        ipv4;
        include "routes4.conf";
}

protocol bgp {
        local as 65531;
        neighbor 192.168.1.1 as 65530;
        source address 192.168.1.10;
        ipv4 {
                import none;
                export all;
        };
}
```
# ros的设置


```
首先打开routing选项，在table选项卡下，添加名称为bypass的路由表，勾选fib完成后，执行下一步

/ip route
add distance=1 gateway=pppoe-out1 routing-table=bypass comment=pass
# 添加一条路由规则，距离为1，网关为pppoe-out1，路由表为bypass，注释为pass

/routing/bgp/connection
add name=clash local.role=ebgp remote.address=192.168.1.10 .as=65531 routing-table=bypass router-id=192.168.1.1 as=65530 multihop=yes
# 添加一个BGP连接，名称为clash，本地角色为ebgp，远程地址为192.168.1.10，自治系统号为65531，路由表为bypass，路由器ID为192.168.1.1，自治系统号为65530，启用多跳选项

/ip firewall mangle add action=accept chain=prerouting src-address=192.168.1.10
# 添加一个防火墙Mangle规则，动作为接受，链为prerouting，源地址为192.168.1.253

/ip firewall address-list add list=proxy address=192.168.1.32
# 添加一个地址列表，名称为proxy，包含地址192.168.1.32
# 该地址支持ip段 例如 192.168.1.1-192.168.1.255


/ip firewall mangle add action=mark-routing chain=prerouting src-address-list=proxy dst-port=80,443 dst-address-type=!local protocol=tcp new-routing-mark=bypass
# 添加一个防火墙Mangle规则，动作为标记路由，链为prerouting，源地址列表为proxy，连接类型tcp。目标端口为80和443，目标地址类型不是本地地址，新的路由标记为bypass

重启路由
```
