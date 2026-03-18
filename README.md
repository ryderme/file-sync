# file-sync

把本地文件自动重命名并同步到 VPS 的命令行工具。

**适用场景**：Mac 本地截图、文档、导出文件 → 统一重命名 → 自动上传到远程服务器，支持多台 Mac 同时使用。

## 功能

- 自动将文件按修改时间重命名为时间戳格式（`20260318_143022.png`），避免多台机器命名冲突
- 记录已上传文件，只上传新增文件，不重复传输
- 支持按文件类型过滤，留空则同步所有文件
- 支持手动同步和自动监听两种模式
- 所有配置外部化，不同机器独立配置

## 前置条件

- macOS（使用了 macOS 的 `stat` 语法）
- SSH 密钥已配置，可免密登录 VPS
- 自动监听模式需要安装 [fswatch](https://github.com/emcee-software/fswatch)：`brew install fswatch`

## 安装

```bash
git clone git@github.com:ryderme/image-sync.git
cd image-sync
chmod +x file-sync.sh
```

添加到 PATH（在 `~/.zshrc` 中加入）：

```bash
export PATH="$PATH:$HOME/github/image-sync"
```

然后执行 `source ~/.zshrc` 生效。

## 配置

```bash
cp file-sync.conf.example file-sync.conf
```

编辑 `file-sync.conf`：

```bash
VPS_HOST="your-vps-ip"          # 必填：VPS IP 或域名
VPS_USER="ubuntu"                # VPS 登录用户名，默认 ubuntu
VPS_PATH="~/outputs/files"       # VPS 上的目标目录
SSH_KEY="$HOME/.ssh/id_ed25519"  # SSH 私钥路径
LOCAL_DIR="$HOME/uploads/files"  # 本地文件目录
FILE_TYPES=""                    # 留空同步所有文件，或指定后缀如 "png,jpg,pdf,md"
```

`file-sync.conf` 已加入 `.gitignore`，不会提交到仓库，多台机器可独立配置。

## 使用

将文件放入本地目录（默认 `~/uploads/files/`），然后：

```bash
# 手动同步：重命名 + 上传新文件
file-sync.sh

# 自动监听：有新文件时自动触发同步
file-sync.sh watch
```

## 多台 Mac 使用

每台机器独立 clone、独立配置 `file-sync.conf`，上传到同一台 VPS 的同一个目录。时间戳命名保证不同机器之间不会冲突。

```
Mac 1 ──┐
         ├── file-sync ──→ VPS ~/outputs/files/
Mac 2 ──┘
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `file-sync.sh` | 主脚本 |
| `file-sync.conf.example` | 配置模板 |
| `file-sync.conf` | 本机配置（gitignore，需自行创建） |
| `~/uploads/files/.uploaded` | 已上传记录（自动维护） |

## License

MIT
