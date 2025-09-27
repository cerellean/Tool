好的，我将根据你提供的文件，整理出一份在 Alpine Linux 系统中配置 `nftables` 实现 `TPROXY` (透明代理) 的详细教程。

---

## 在 Alpine Linux 上配置 nftables TPROXY 透明代理教程

本教程将引导你在 Alpine Linux 系统上配置 `nftables` 防火墙规则和路由表，以实现 `TPROXY` 透明代理。`TPROXY` 允许你的代理服务（例如 `sing-box` 或 Clash 等）透明地拦截并处理所有出站流量，而无需客户端应用程序进行额外配置。

**目标用户:** 运行 Alpine Linux 的服务器管理员或高级用户。

**前置条件:**

*   运行中的 Alpine Linux 系统。
*   拥有 `root` 权限或 `sudo` 权限。
*   已安装并配置好一个支持 `TPROXY` 的代理服务（例如 `sing-box`），且其 `TPROXY` 或 `redirect` 监听端口为 `7895`。

---

### 第一步：安装 nftables

首先，我们需要安装 `nftables` 包并设置它随系统启动。

1.  **更新软件包列表并安装 `nftables`:**
    ```bash
    apk update
    apk add nftables
    ```

2.  **设置 `nftables` 服务开机自启：**
    ```bash
    rc-update add nftables
    ```

3.  **立即启动 `nftables` 服务：**
    ```bash
    rc-service nftables start
    ```

---

### 第二步：检查内核 TPROXY 支持

`TPROXY` 功能需要 Linux 内核的支持。在配置规则之前，建议检查你的内核是否已编译入 `TPROXY` 模块。

1.  **查询内核配置文件：**
    ```bash
    grep TPROXY /boot/config-$(uname -r)
    ```

2.  **预期输出：**
    你应该会看到类似 `CONFIG_NETFILTER_TPROXY=y` 或 `CONFIG_NETFILTER_TPROXY=m` 的输出。
    *   `=y` 表示 `TPROXY` 功能已直接编译进内核。
    *   `=m` 表示 `TPROXY` 功能作为模块编译，会在需要时加载。
    *   如果没有任何输出或输出中没有 `TPROXY` 相关的行，可能需要重新编译内核或使用不同的内核版本来启用此功能。

---

### 第三步：配置 nftables 规则

接下来，我们将创建或修改 `nftables` 规则文件，以定义 `TPROXY` 的流量转发逻辑。

1.  **创建或修改规则文件：**
    在 Alpine Linux 中，`nftables` 的额外规则通常存放在 `/etc/nftables.d/` 目录下。我们将创建一个名为 `singbox.nft` 的文件。

    使用你喜欢的文本编辑器（如 `vi` 或 `nano`）打开并创建文件：
    ```bash
    # 使用 nano 编辑器
    nano /etc/nftables.d/singbox.nft

    # 或者使用 vi 编辑器
    vi /etc/nftables.d/singbox.nft
    ```

2.  **粘贴以下规则内容：**
    将以下内容完整地粘贴到 `/etc/nftables.d/singbox.nft` 文件中。

    ```nftables
    # /etc/nftables.d/singbox.nft
    table inet filter {
    	chain input {
    		type filter hook input priority filter; policy accept;
    	}

    	chain forward {
    		type filter hook forward priority filter; policy accept;
    	}

    	chain output {
    		type filter hook output priority filter; policy accept;
    	}
    }
    table inet sing-box {
    	set RESERVED_IPSET {
    		type ipv4_addr
    		flags interval
    		auto-merge
    		elements = { 10.0.0.0/8, 100.64.0.0/10,
    			     127.0.0.0/8, 169.254.0.0/16,
    			     172.16.0.0/12, 192.0.0.0/24,
    			     192.0.2.0/24, 192.88.99.0/24,
    			     192.168.0.0/16, 198.51.100.0/24,
    			     203.0.113.0/24, 224.0.0.0/3 }
    	}

    	chain prerouting_tproxy {
    		type filter hook prerouting priority mangle; policy accept;
    		meta l4proto { tcp, udp } th dport 53 tproxy to :7895 accept
    		ip daddr { 10.0.0.0/8, 192.168.0.0/16 } accept
    		fib daddr type local meta l4proto { tcp, udp } th dport 7895 reject with icmpx host-unreachable
    		fib daddr type local accept
    		ip daddr @RESERVED_IPSET accept
    		meta l4proto tcp socket transparent 1 meta mark set 0x00000001 accept
    		meta l4proto { tcp, udp } tproxy to :7895 meta mark set 0x00000001
    	}

    	chain output_tproxy {
    		type route hook output priority mangle; policy accept;
    		oifname "lo" accept
    		meta mark 0x0000029a accept
    		meta l4proto { tcp, udp } th dport 53 meta mark set 0x00000001
    		udp dport { 137, 138, 139 } accept
    		ip daddr { 10.0.0.0/8, 192.168.0.0/16 } accept
    		fib daddr type local accept
    		ip daddr @RESERVED_IPSET accept
    		meta l4proto { tcp, udp } meta mark set 0x00000001
    	}
    }
    ```

3.  **规则说明：**
    *   **`table inet filter`**: 这是一个标准的过滤表，包含 `input`, `forward`, `output` 链。这里的策略默认都是 `accept`，如果你需要更严格的防火墙，可以在这些链中添加更多规则。
    *   **`table inet sing-box`**: 这是专门为代理服务创建的表。
        *   **`set RESERVED_IPSET`**: 定义了一个 IP 地址集合，包含各种私有 IP 地址、保留 IP 地址、环回地址、多播地址等。这些地址通常不应该通过代理，因此会被特殊处理。
        *   **`chain prerouting_tproxy` (prerouting hook)**: 用于处理进入本机的流量。
            *   所有端口 53 (DNS) 的 TCP/UDP 流量都会被 `tproxy` 到本地的 `7895` 端口，并设置防火墙标记 `0x00000001`。
            *   目标地址为局域网 IP (10.0.0.0/8, 192.168.0.0/16) 的流量直接放行。
            *   目标地址是本地且端口为 `7895` 的流量会被拒绝，防止代理服务与自身形成环路。
            *   目标地址为 `RESERVED_IPSET` 中的 IP 也直接放行。
            *   其余 TCP 流量被标记 `0x00000001` 并开启透明代理 (`socket transparent 1`)。
            *   其余 UDP 流量被 `tproxy` 到本地 `7895` 端口，并标记 `0x00000001`。
        *   **`chain output_tproxy` (output hook)**: 用于处理本机发出的流量。
            *   发往 `lo` 接口的流量直接放行。
            *   带有特定标记 `0x0000029a` 的流量直接放行 (这通常是代理服务内部使用的标记)。
            *   端口 53 (DNS) 的 TCP/UDP 流量被标记 `0x00000001`。
            *   UDP 端口 137, 138, 139 (NetBIOS) 流量直接放行。
            *   目标地址为局域网 IP (10.0.0.0/8, 192.168.0.0/16) 的流量直接放行。
            *   目标地址是本地的流量直接放行。
            *   目标地址为 `RESERVED_IPSET` 中的 IP 也直接放行。
            *   其余的 TCP/UDP 流量都被标记 `0x00000001`。

4.  **保存文件并重启 `nftables` 服务：**
    ```bash
    rc-service nftables restart
    ```
    这将加载你刚刚添加的规则。

---

### 第四步：配置路由表以处理标记流量

`TPROXY` 规则通过 `meta mark set 0x00000001` 给流量打上了标记 (mark)。我们需要配置内核的路由表，让带有此标记的流量被路由到本地，以便代理服务能够处理它们。

1.  **添加 IP 规则和路由：**
    执行以下命令，这些命令会告诉系统将带有防火墙标记 `1` (即 `0x00000001`) 的流量查找路由表 `100`，并在该路由表中将所有目标地址的流量都视为本地流量并发送到 `lo` (loopback) 设备。
    ```bash
    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100
    ```

2.  **设置开机自启：**
    上述 `ip rule` 和 `ip route` 命令在系统重启后会失效。你需要将它们添加到开机启动脚本中以确保持久化。在 Alpine Linux 中，你可以使用 `/etc/local.d/` 目录。

    创建或修改 `/etc/local.d/tproxy.start` 文件：
    ```bash
    nano /etc/local.d/tproxy.start
    ```
    粘贴以下内容：
    ```bash
    #!/bin/sh
    # 配置 TPROXY 路由规则
    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100
    ```

    保存文件。

3.  **赋予脚本执行权限：**
    ```bash
    chmod +x /etc/local.d/tproxy.start
    ```

4.  **将脚本添加到开机启动服务：**
    ```bash
    rc-update add local
    ```
    这样，每次系统启动时，`/etc/local.d/tproxy.start` 脚本都会被执行。

---

### 第五步：验证配置

配置完成后，重要的是验证 `nftables` 规则是否已加载，以及流量是否正在被正确标记和转发。

1.  **检查 `nftables` 规则是否加载：**
    ```bash
    nft list ruleset
    ```
    你应该能看到 `table inet filter` 和 `table inet sing-box` 以及它们各自的链和规则。

2.  **检查 `ip rule` 和 `ip route`：**
    ```bash
    ip rule show
    ip route show table 100
    ```
    *   `ip rule show` 应该包含 `1: from all fwmark 0x1 lookup 100`。
    *   `ip route show table 100` 应该包含 `local 0.0.0.0/0 dev lo proto kernel scope host src 0.0.0.0`。

3.  **使用 `tcpdump` 验证流量是否到达代理端口：**
    假设你的代理服务通过 `TPROXY` 监听端口 `7895`。你可以使用 `tcpdump` 监听这个端口。

    ```bash
    # 安装 tcpdump (如果未安装)
    apk add tcpdump

    # 开始监听
    tcpdump -nn -i any 'tcp port 7895 or udp port 7895'
    ```
    *   在运行 `tcpdump` 的同时，尝试从**本机**或**通过本机**（如果本机是网关）访问一个外部网站或进行 DNS 查询。
    *   如果你看到 `tcpdump` 输出显示有流量到达 `7895` 端口，则说明 `nftables` `TPROXY` 重定向成功。

    **注意:** `tcpdump` 命令中使用了 `7895` 端口，因为它与 `nftables` 规则中的 `tproxy to :7895` 相对应。如果你代理的实际监听端口不同，请相应调整 `tcpdump` 的端口号。原始文件中的 `tcpdump` 例使用了 `7896` 端口，这可能是代理服务最终暴露给客户端的端口，但 `nftables` 重定向的端口是 `7895`。

---

### 额外提示：代理服务配置

请确保你的代理服务（如 `sing-box`）已正确配置以支持 `TPROXY`。通常，这意味着：
1.  代理服务应该监听在端口 `7895`（或者你在 `nftables` 规则中指定的其他端口）。
2.  代理服务的入站连接类型需要设置为 `tproxy` 或 `redirect` 相关的模式，以处理透明代理流量并获取原始目标地址。

例如，对于 `sing-box`，其配置通常会有类似 `inbound` (入站) 部分：

```json
{
  "inbounds": [
    {
      "type": "tproxy", // 或者 "redirect"
      "listen": "0.0.0.0",
      "listen_port": 7895,
      // 其他配置...
    }
  ],
  // ... 其他部分
}
```

---

至此，你已成功在 Alpine Linux 上配置了 `nftables` 的 `TPROXY` 透明代理。现在所有符合规则的流量都将被透明地转发到你的代理服务进行处理。
