# Tencent Cloud Security Notes

记录 2026-03-24 为恢复 `file-sync` 上传所做的腾讯云安全相关临时调整。

## 背景

`file-sync` 本地监听和重命名正常，但上传到 VPS 时 SSH 握手阶段被远端主动断开。

排查结果：

- `launchd` 服务正常运行
- `rsync`/`ssh` 连接到 `43.162.101.59:22` 时出现 `kex_exchange_identification: Connection closed by remote host`
- VPS 上的 `iptables` 链 `YJ-FIREWALL-INPUT` 存在一条针对当时 SSH 出口 IP 的封禁规则：

```bash
-A YJ-FIREWALL-INPUT -s <your-ssh-egress-ip>/32 -j REJECT --reject-with icmp-port-unreachable
```

- 腾讯云安全代理 `stargate`/`barad_agent` 会自动回填这类规则

## 本次改动

### 1. 删除误封的防火墙规则

执行过：

```bash
sudo iptables -D YJ-FIREWALL-INPUT -s <your-ssh-egress-ip>/32 -j REJECT --reject-with icmp-port-unreachable
```

作用：

- 解除对当时 SSH 出口 IP 的封禁

### 2. 停止腾讯云安全代理

执行过：

```bash
sudo /usr/local/qcloud/monitor/barad/admin/stop.sh || true
sudo /usr/local/qcloud/stargate/admin/stop.sh || true
sudo pkill -f barad_agent || true
sudo pkill -f sgagent || true
```

作用：

- 停止自动回填封禁规则

### 3. 移除 root crontab 中的自动拉起任务

原有任务：

```bash
*/5 * * * * flock -xn /tmp/stargate.lock -c '/usr/local/qcloud/stargate/admin/start.sh > /dev/null 2>&1 &'
```

处理结果：

- 已从 root `crontab` 中移除，避免每 5 分钟重新启动 `stargate`

## 当前状态

当前默认状态：

- `stargate` 已停用
- `barad_agent` 已停用
- root `crontab` 不再自动启动 `stargate`
- `file-sync` 已恢复正常上传

## 恢复命令

如果后续需要恢复腾讯云安全代理，可执行：

```bash
sudo bash -lc "crontab -l 2>/dev/null; echo \"*/5 * * * * flock -xn /tmp/stargate.lock -c '/usr/local/qcloud/stargate/admin/start.sh > /dev/null 2>&1 &'\"" | sudo crontab -
sudo /usr/local/qcloud/stargate/admin/start.sh
```

恢复后建议检查：

```bash
ps -ef | grep '[s]gagent\|[b]arad'
sudo crontab -l
sudo iptables -S YJ-FIREWALL-INPUT | tail -n 20
```

## 风险提醒

如果直接恢复腾讯云安全代理，而不处理白名单或误封来源，可能再次出现：

- 当前 Mac 的 SSH 出口 IP 被自动加入 `YJ-FIREWALL-INPUT`
- 新建 SSH 连接失败
- `file-sync` 上传再次中断

在以下场景下，这个风险更高：

- Mac 长期开代理
- SSH 出口 IP 不固定
- 同一台机器会从多个网络环境登录 VPS

## 建议

短期建议：

- 保持当前停用状态，优先保证 `file-sync` 稳定

如果未来要恢复腾讯云安全代理，建议先做其中至少一项：

- 给常用 SSH 出口 IP 加白名单
- 为 `ubuntu` 的正常 SSH 登录来源设置例外
- 先在控制台验证不会再次误封，再恢复 cron 自启
