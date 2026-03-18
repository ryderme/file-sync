# image-sync

把本地图片自动重命名并同步到 VPS。

## 安装

```bash
git clone git@github.com:ryderme/image-sync.git
cd image-sync
chmod +x image-sync.sh

# 添加到 PATH（加到 ~/.zshrc）
export PATH="$PATH:$HOME/github/image-sync"
```

## 配置

```bash
cp image-sync.conf.example image-sync.conf
# 编辑 image-sync.conf，填入 VPS 地址
```

## 使用

```bash
# 手动同步
image-sync.sh

# 自动监听（需要 fswatch：brew install fswatch）
image-sync.sh watch
```

图片放入 `~/uploads/images/`，文件名自动按时间戳重命名（`20260318_143022.png`），未上传的文件自动传到 VPS `~/outputs/images/`。
