**官方已经打包好的静态网站文件**，直接部署即可，大大简化流程。

---

## ✅ 使用官方预编译文件安装 HOMER（无 Docker、无 npm）

### 📦 步骤一：下载并解压 homer.zip

进入你想要部署的位置，例如 `/opt/homer`：

```sh
mkdir -p /opt/homer
cd /opt/homer

# 下载最新版本的编译包
wget https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip

# 解压
unzip homer.zip
```

此时 `/opt/homer` 目录下将包含 `index.html` 和 `assets/` 等文件。

---

### ⚙️ 步骤二：配置 Nginx 以托管静态文件

> **⚠️ 注意路径：Alpine Nginx 默认使用 `/etc/nginx/http.d/` 配置虚拟主机**

```sh
vi /etc/nginx/http.d/homer.conf
```

写入以下内容：

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

### 🧹（可选）删除默认 welcome 页面配置

```sh
rm /etc/nginx/http.d/default.conf
```

---

### 🚀 步骤三：启动 nginx 并开机自启

```sh
rc-service nginx start
rc-update add nginx
```

---

### 🌐 步骤四：访问 HOMER

打开浏览器，访问容器的 IP 地址（如 `http://192.168.1.xxx/`），你将看到 HOMER 仪表盘页面。

---

## 🧩 步骤五：配置 dashboard 内容

编辑配置文件：

```sh
vi /opt/homer/assets/config.yml
```

修改后，**不需要重新构建**，直接刷新浏览器即可生效（HOMER 会自动读取 `config.yml`）。

---

