# ✅ Alpine LXC 部署 AirConnect（AirCast + AirUPnP）完整教程

---

## 📌 一、准备工作

### 1. 安装 Alpine LXC 容器（已完成）

确保你的 LXC 容器是基于 Alpine，且已更新：

```sh
apk update && apk upgrade
```

### 2. 安装必要依赖

```sh
apk add curl bash openrc
```

---

## 📦 二、下载 AirConnect 可执行文件

### 1. 创建目录

```sh
mkdir -p /opt/airconnect
cd /opt/airconnect
```

### 2. 下载 x86\_64 静态编译版本

前往 [AirConnect GitHub Releases](https://github.com/philippe44/AirConnect/releases)，或使用如下命令下载：

```sh
# 替换为最新版链接
wget https://github.com/philippe44/AirConnect/releases/download/v1.8.3.0/aircast-linux-x86_64-static.tgz
wget https://github.com/philippe44/AirConnect/releases/download/v1.8.3.0/airupnp-linux-x86_64-static.tgz
```

### 3. 解压并重命名

```sh
tar xzf aircast-linux-x86_64-static.tgz
tar xzf airupnp-linux-x86_64-static.tgz

mv aircast-linux-x86_64-static aircast-linux-x86_64-static
mv airupnp-linux-x86_64-static airupnp-linux-x86_64-static

chmod +x aircast-linux-x86_64-static airupnp-linux-x86_64-static
```

---

## ⚙️ 三、创建 OpenRC 启动服务

---

### 📄 1. AirCast 服务：`/etc/init.d/aircast`

```sh
#!/sbin/openrc-run

description="AirCast bridge (x86_64, static build)"

command="/opt/airconnect/aircast-linux-x86_64-static"
command_args="-l 1000:2000 -Z -x /opt/airconnect/aircast.xml"
command_background=true
pidfile="/run/aircast.pid"

start_post() {
    pidof aircast-linux-x86_64-static > "$pidfile"
}

output_log="/var/log/aircast.log"
error_log="/var/log/aircast.err"

depend() {
    need net
    after firewall
}
```

---

### 📄 2. AirUPnP 服务：`/etc/init.d/airupnp`

```sh
#!/sbin/openrc-run

description="AirUPnP bridge (x86_64, static build)"

command="/opt/airconnect/airupnp-linux-x86_64-static"
command_args="-l 1000:2000 -Z -x /opt/airconnect/airupnp.xml"
command_background=true
pidfile="/run/airupnp.pid"

start_post() {
    pidof airupnp-linux-x86_64-static > "$pidfile"
}

output_log="/var/log/airupnp.log"
error_log="/var/log/airupnp.err"

depend() {
    need net
    after firewall
}
```

---

### 📂 3. 设置脚本权限并创建日志文件

```sh
chmod +x /etc/init.d/aircast /etc/init.d/airupnp

touch /var/log/aircast.log /var/log/aircast.err
touch /var/log/airupnp.log /var/log/airupnp.err

chmod 644 /var/log/air*.*
```

---

## 🚀 四、启用并启动服务

```sh
# 添加到开机启动
rc-update add aircast default
rc-update add airupnp default

# 启动服务
rc-service aircast start
rc-service airupnp start
```

---

## ✅ 五、检查服务状态

```sh
rc-service aircast status
rc-service airupnp status

# 查看实时日志输出
tail -f /var/log/aircast.log
tail -f /var/log/airupnp.log
```

---

## 📌 六、验证功能

* 使用 iOS 或 macOS 设备查看是否出现 AirPlay 投射设备（AirCast）
* 用支持 DLNA/UPnP 的客户端检测设备（AirUPnP）
* 配置文件（可选）：可通过 `-x` 指定路径自动生成 `/opt/airconnect/aircast.xml` 和 `airupnp.xml`

---

## 🧼 七、卸载方式（如需）

```sh
rc-service aircast stop
rc-service airupnp stop

rc-update del aircast
rc-update del airupnp

rm /etc/init.d/aircast /etc/init.d/airupnp
rm -rf /opt/airconnect
rm /var/log/aircast.* /var/log/airupnp.*
```

---

