#!/usr/bin/env bash
set -uo pipefail

# ── Default config ─────────────────────────────────────────────────────────────
VPS_HOST=""
VPS_USER="ubuntu"
VPS_PATH="~/uploads"
SSH_KEY="$HOME/.ssh/id_ed25519"
LOCAL_DIR="$HOME/uploads"
FILE_TYPES=""   # 留空则同步所有文件，否则填逗号分隔的后缀，如 "png,jpg,pdf"

# Load user config (overrides defaults)
CONFIG_FILE="$HOME/.file-sync.conf"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

UPLOADED_LOG="$LOCAL_DIR/.uploaded"

# ── Helpers ────────────────────────────────────────────────────────────────────
log() { echo "[file-sync] $*"; }
err() { echo "[file-sync] ERROR: $*" >&2; exit 1; }

check_config() {
  [[ -z "$VPS_HOST" ]] && err "VPS_HOST not set. Create $CONFIG_FILE (see file-sync.conf.example)"
  mkdir -p "$LOCAL_DIR"
  touch "$UPLOADED_LOG"
}

find_files() {
  if [[ -z "$FILE_TYPES" ]]; then
    # 同步所有文件
    find "$LOCAL_DIR" -maxdepth 1 -type f ! -name ".*" -print0
  else
    # 按配置的后缀过滤
    local args=()
    IFS=',' read -ra exts <<< "$FILE_TYPES"
    for i in "${!exts[@]}"; do
      local ext="${exts[$i]// /}"
      [[ $i -gt 0 ]] && args+=("-o")
      args+=("-iname" "*.${ext}")
    done
    find "$LOCAL_DIR" -maxdepth 1 -type f \( "${args[@]}" \) -print0
  fi
}

# ── Rename ─────────────────────────────────────────────────────────────────────
rename_files() {
  local renamed=0

  while IFS= read -r -d '' file; do
    local name
    name=$(basename "$file")

    # Skip already renamed (starts with YYYYMMDD_HHMMSS)
    [[ "$name" =~ ^[0-9]{8}_[0-9]{6} ]] && continue

    local ext="${name##*.}"
    ext="${ext,,}"  # lowercase extension

    # Use file modification time as timestamp
    local ts
    ts=$(stat -f "%Sm" -t "%Y%m%d_%H%M%S" "$file" 2>/dev/null || date "+%Y%m%d_%H%M%S")

    local newname="${ts}.${ext}"

    # Handle collision: append _1, _2, ...
    local i=1
    while [[ -e "$LOCAL_DIR/$newname" && "$LOCAL_DIR/$newname" != "$file" ]]; do
      newname="${ts}_${i}.${ext}"
      i=$((i + 1))
    done

    mv "$file" "$LOCAL_DIR/$newname"
    log "renamed: $name → $newname"
    renamed=$((renamed + 1))
  done < <(find_files)

  [[ $renamed -gt 0 ]] && log "renamed $renamed file(s)" || log "no files to rename"
}

# ── Upload ─────────────────────────────────────────────────────────────────────
upload_files() {
  local uploaded=0
  local failed=0

  while IFS= read -r -d '' file; do
    local name
    name=$(basename "$file")

    # Skip already uploaded
    grep -qxF "$name" "$UPLOADED_LOG" 2>/dev/null && continue

    log "uploading: $name"
    if scp -i "$SSH_KEY" -q "$file" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/"; then
      echo "$name" >> "$UPLOADED_LOG"
      uploaded=$((uploaded + 1))
    else
      log "failed: $name"
      failed=$((failed + 1))
    fi
  done < <(find_files)

  [[ $uploaded -gt 0 ]] && log "uploaded $uploaded file(s)"
  [[ $failed -gt 0 ]] && log "failed $failed file(s)"
  [[ $uploaded -eq 0 && $failed -eq 0 ]] && log "no new files to upload"
}

# ── Sync ───────────────────────────────────────────────────────────────────────
sync_all() {
  check_config
  rename_files
  upload_files
}

# ── Watch ──────────────────────────────────────────────────────────────────────
watch_mode() {
  check_config
  command -v fswatch &>/dev/null || err "fswatch not installed. Run: brew install fswatch"
  log "watching $LOCAL_DIR ..."
  log "press Ctrl+C to stop"
  fswatch -o --event Created --event Renamed "$LOCAL_DIR" | while read -r; do
    sync_all
  done
}

# ── Main ───────────────────────────────────────────────────────────────────────
case "${1:-sync}" in
  sync)  sync_all ;;
  watch) watch_mode ;;
  *)
    echo "Usage: file-sync [sync|watch]"
    echo ""
    echo "  sync   rename + upload new files (default)"
    echo "  watch  auto-sync when new files are added"
    ;;
esac
