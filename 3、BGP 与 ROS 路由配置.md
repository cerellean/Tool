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
0 5 * * * /home/iplist.sh
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
