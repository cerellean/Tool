# PVE容器创建教程
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

---
# 安装sing-box/mihomo
## sing-box安装
配置文件夹路径：/etc/sing-box

文件存放路径：/usr/local/bing

## mihomo安装
配置文件夹路径：/etc/mihomo

文件存放路径：/usr/local/bing

## sing-box openRC启动文件
cat /etc/init.d/singbox
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
