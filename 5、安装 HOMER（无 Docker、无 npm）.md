

# ✅ Alpine LXC 容器中部署 HOMER Dashboard（使用预编译版本）

## 🧱 一、前提条件

你已经：

* 在 PVE 中创建了基于 Alpine Linux 的 LXC 容器
* 容器能正常联网

---

## ⚙️ 二、安装 nginx 和 unzip 工具

登录 LXC 容器执行：

```sh
apk update
apk add nginx unzip curl
```

---

## 📥 三、下载并解压 HOMER 编译好的发布包

选择部署目录，例如 `/opt/homer`：

```sh
mkdir -p /opt/homer
cd /opt/homer

# 下载官方预编译包
wget https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip

# 解压
unzip homer.zip

cd homer
cp assets/config.yml.dist assets/config.yml
```

现在目录下应该有 `index.html`, `assets/config.yml` 等文件。

---

## 🌐 四、配置 nginx

Alpine 的 nginx 配置目录为 `/etc/nginx/http.d/`，你需要新建一个配置文件：

```sh
vi /etc/nginx/http.d/homer.conf
```

内容如下：

```nginx
server {
    listen 80;
    server_name _;

    root /opt/homer;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### （可选）删除默认欢迎页配置

```sh
rm /etc/nginx/http.d/default.conf
```

---

## 🚀 五、启动 nginx 并设置开机自启

```sh
rc-service nginx start
rc-update add nginx
```

---

## 🔧 六、配置 HOMER（自定义你的面板）

配置文件位于：

```sh
/opt/homer/assets/config.yml
```

你可以直接编辑它：

```sh
vi /opt/homer/assets/config.yml
```

修改后保存并刷新浏览器即可生效，不需要重启服务。

---

## 🌐 七、访问你的 HOMER 面板

打开浏览器，访问容器 IP：

```
http://<容器IP>
```

即可看到 HOMER 仪表盘界面。

---

