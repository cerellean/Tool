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
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
  sysctl -p
  ```

  并运行：

  ```bash
  sysctl -p
  rc-update add sysctl
  ```
* 加载 TUN 模块：
  添加tun支持：

  ```
  modprobe tun
  ```

  验证：

  ```bash
  lsmod | grep tun
  ```
  确认 `/dev/net/tun `存在：

  ```bash
  ls -l /dev/net/tun
  ```
  开机自动加载 TUN：

  ```bash
  echo tun >> /etc/modules
  ```
---
