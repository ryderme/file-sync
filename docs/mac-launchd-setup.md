# Mac Launchd Setup

用 `launchd` 让 `file-sync.sh watch` 在 Mac 登录后自动启动并常驻运行。

## 前提

- 已完成 `README.md` 里的基础配置
- `file-sync.conf` 已正确填写
- 已安装 `fswatch`

```bash
brew install fswatch
```

## 1. 创建 LaunchAgent

在 Mac 上执行：

```bash
cat > ~/Library/LaunchAgents/com.ryderme.file-sync.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ryderme.file-sync</string>
  <key>ProgramArguments</key>
  <array>
    <string>/path/to/file-sync/file-sync.sh</string>
    <string>watch</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>WorkingDirectory</key>
  <string>/path/to/file-sync</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/Users/yourname/Library/Logs/file-sync.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/yourname/Library/Logs/file-sync.log</string>
</dict>
</plist>
EOF
```

把 `/path/to/file-sync` 和 `/Users/yourname/Library/Logs/file-sync.log` 改成你自己的绝对路径。

## 2. 校验 plist

```bash
plutil -lint ~/Library/LaunchAgents/com.ryderme.file-sync.plist
```

输出 `OK` 才说明语法正确。

## 3. 加载并启动

推荐使用新版 `launchctl bootstrap` / `bootout`：

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist
launchctl kickstart -k gui/$(id -u)/com.ryderme.file-sync
```

含义：

- `bootstrap`：加载 LaunchAgent
- `kickstart -k`：立即重启并拉起服务
- `bootout`：在重载前先卸载旧版本

## 4. 确认已运行

```bash
launchctl print gui/$(id -u)/com.ryderme.file-sync
```

看到类似下面内容表示正常：

```text
state = running
```

## 5. 查看日志

```bash
tail -f ~/Library/Logs/file-sync.log
```

正常会看到类似：

```text
[file-sync] watching /Users/yourname/uploads ...
[file-sync] press Ctrl+C to stop
```

当有新文件进入 `LOCAL_DIR` 时，还会看到：

```text
[file-sync] renamed: xxx.png → 20260318_163000.png
[file-sync] uploading: 20260318_163000.png
[file-sync] uploaded 1 file(s)
```

## 6. 停止或移除

只停止当前运行：

```bash
launchctl bootout gui/$(id -u)/com.ryderme.file-sync
```

停止并删除配置：

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist
rm ~/Library/LaunchAgents/com.ryderme.file-sync.plist
```

## 常见问题

### 1. 日志里报 `fswatch not installed`

通常是 `launchd` 的 `PATH` 太干净，找不到 Homebrew。上面的 plist 已经显式加了：

```text
/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

如果你改过 plist，记得重新执行：

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist
launchctl kickstart -k gui/$(id -u)/com.ryderme.file-sync
```

### 2. watch 已运行，但没有上传

按顺序检查：

```bash
launchctl print gui/$(id -u)/com.ryderme.file-sync
tail -n 100 ~/Library/Logs/file-sync.log
```

再确认：

- 文件放在 `LOCAL_DIR` 顶层，不是子目录
- SSH 私钥路径正确
- VPS 可通过 `ssh` 免密登录
- `VPS_PATH` 指向的远端目录正确

### 3. 上传到了哪里

如果配置是：

```bash
VPS_USER="ubuntu"
VPS_PATH="~/uploads"
```

那么远端实际目录通常是：

```text
/home/ubuntu/uploads
```
