
---

## 一、Alpine LXC 容器模板创建与系统初始化

### 1. 创建 LXC 容器（Alpine 或 Debian）：

* 在 Proxmox VE 中创建容器时，**取消特权容器勾选**。
* 创建完成后，在容器设置中启用：

  * 嵌套
  * NFS
  * SMB
  * FUSE

### 2. 修改容器配置文件（启用 TUN）：

编辑 `/etc/pve/lxc/[ID].conf`，添加以下内容：

```bash
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop: 
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

### 3. 初始化 Alpine 系统：

* 更换镜像源：

  ```bash
  sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
  ```

* 更新系统并安装基础工具：

  ```bash
  apk update && apk upgrade
  apk add curl git wget nano bash
  ```

* 配置时区：

  ```bash
  apk add tzdata 
  cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  echo "Asia/Shanghai" > /etc/timezone
  apk del tzdata
  rm -rf /var/cache/apk/*
  ```  

* 启用 SSH 登录：

  ```bash
  apk add --no-cache openssh
  mkdir -p /etc/ssh && ssh-keygen -A
  sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  rc-update add sshd
  rc-service sshd restart
  ```

* 启用内核转发：
  编辑 `/etc/sysctl.conf` 添加：

  ```
  net.ipv4.ip_forward = 1
  net.ipv6.conf.all.forwarding = 1
  ```

  并运行：

  ```bash
  sysctl -p
  rc-update add sysctl
  ```

---

## 二、安装 Sing-Box / Mihomo 及启动配置

### 1. 路径规范：

* Sing-Box 配置路径：`/etc/sing-box`
* Mihomo 配置路径：`/etc/mihomo`
* 二进制文件存放路径：`/usr/local/bin`

### 2. openRC 启动配置（Sing-Box）：

创建 `/etc/init.d/sing-box`：

```bash
#!/sbin/openrc-run

command="/usr/local/bin/sing-box"
command_args="run -c /etc/sing-box/config.json"
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

赋权并设置开机启动：

```bash
chmod +x /etc/init.d/sing-box
rc-update add sing-box default
service sing-box start
```

### 3. openRC 启动配置（Mihomo）：

创建 `/etc/init.d/mihomo`：

```bash
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

赋权并启动：

```bash
chmod +x /etc/init.d/mihomo
rc-update add mihomo default
service mihomo start
```

---

## 三、BGP 与 RouterOS 路由配置

### 1. 安装与配置 BIRD 路由器：

```bash
apk add bird
rc-update add bird default
service bird start
```

创建获取非本地 IP 的脚本 `/home/iplist.sh`（详见原文），设置定时任务：

```bash
chmod +x /home/iplist.sh
crontab -e
0 5 * * * /bin/bash /home/iplist.sh
```

编辑 `/etc/bird.conf` 配置：

```conf
log syslog all;
router id 192.168.1.10;

protocol device { scan time 60; }

protocol kernel {
  ipv4 { import none; export all; };
}

protocol static {
  ipv4;
  include "routes4.conf";
}

protocol bgp {
  local as 65531;
  neighbor 192.168.1.1 as 65530;
  source address 192.168.1.10;
  ipv4 { import none; export all; };
}
```

---

### 2. RouterOS 设置（ROS）：

* 创建路由表 `bypass`，启用 `fib`

* 添加默认路由：

  ```bash
  /ip route add distance=1 gateway=pppoe-out1 routing-table=bypass comment=pass
  ```

* 配置 BGP：

  ```bash
  /routing/bgp/connection add name=clash local.role=ebgp remote.address=192.168.1.10 .as=65531 routing-table=bypass router-id=192.168.1.1 as=65530 multihop=yes
  ```

* 防火墙规则：

  ```bash
  /ip firewall mangle add action=accept chain=prerouting src-address=192.168.1.10
  /ip firewall address-list add list=proxy address=192.168.1.32
  /ip firewall mangle add action=mark-routing chain=prerouting src-address-list=proxy dst-port=80,443 dst-address-type=!local protocol=tcp new-routing-mark=bypass
  ```

* 最后，**重启路由器**使设置生效。

---


