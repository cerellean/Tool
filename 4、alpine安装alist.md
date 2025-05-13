##手动装alpine 用musl版本
```bash
akp add wget
cd /opt~
wget https://github.com/alist-org/alist/releases/download/v3.11.0/alist-linux-musl-amd64.tar.gz
tar -zxvf alist-*.tar.gz && rm alist-*.tar.gz
chmod +x alist
cd /alist
./alist server  # 运行程序 查看有没有异常
./alist admin # 获得管理员用户名和密码信息 kT0voJRZ
./alist server & # 临时后台运行，然后去后台配置  配置完成后 killall alist
./alist admin set NEW_PASSWORD #手动设置一个密码 `NEW_PASSWORD`是指你需要设置的密码
```

创建openRC启动文件
```bash
vi /etc/init.d/alist
```
内容如下：
```bash
#!/sbin/openrc-run

name="alist"
command="/opt/alist/alist"
command_args="server"
command_background="yes"
pidfile="/var/run/alist.pid"
directory="/opt/alist"
```
设置权限并启用服务：
```bash
chmod +x /etc/init.d/alist
rc-update add alist default
rc-service alist start
```
