#!/usr/bin/env bash
# 轨言轨语（kiseki-style）· 一键部署 / 卸载
# 把风格细则与开关脚本装到本机，并把常驻挂载块并入 agent 的指令文件。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_SRC="$SCRIPT_DIR/agents-block.md"

STYLE_DIR=""
AGENTS=""
MODE="install"
DRY=0

usage() {
  cat <<'EOF'
用法: bash install.sh [选项]

  --dir <路径>       风格文件落地目录（默认：有 ~/.dsh 则 ~/.dsh/style，否则 ~/.kiseki）
  --agents <路径>    要挂载的常驻指令文件（默认自动探测）
  --uninstall        只摘掉挂载块，风格文件保留
  --dry-run          只打印计划，不写盘
  -h, --help         显示本帮助

自动探测顺序：~/AGENTS.md > ~/.claude/CLAUDE.md > ~/.codex/AGENTS.md > 新建 ~/AGENTS.md
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       STYLE_DIR="${2:?--dir 需要一个路径}"; shift 2 ;;
    --agents)    AGENTS="${2:?--agents 需要一个路径}"; shift 2 ;;
    --uninstall) MODE="uninstall"; shift ;;
    --dry-run)   DRY=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# shellcheck disable=SC2088  # 这里匹配的是字面量 "~/"，本来就不该展开
expand() { case "$1" in "~/"*) printf '%s\n' "$HOME/${1#\~/}" ;; *) printf '%s\n' "$1" ;; esac; }

if [ -z "$STYLE_DIR" ]; then
  if [ -d "$HOME/.dsh" ]; then STYLE_DIR="$HOME/.dsh/style"; else STYLE_DIR="$HOME/.kiseki"; fi
fi
STYLE_DIR="$(expand "$STYLE_DIR")"

detect_agents() {
  for c in "$HOME/AGENTS.md" "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    if [ -f "$c" ]; then printf '%s\n' "$c"; return 0; fi
  done
  printf '%s\n' "$HOME/AGENTS.md"
}
if [ -z "$AGENTS" ]; then AGENTS="$(detect_agents)"; fi
AGENTS="$(expand "$AGENTS")"

# 摘掉 <kiseki_style>…</kiseki_style>（含标记行），其余原样保留
strip_block() {
  awk '
    /<kiseki_style/ { skip=1; next }
    skip==1 && /<\/kiseki_style>/ { skip=0; next }
    skip!=1 { print }
  ' "$1"
}

render_block() { sed "s@{{KISEKI_DIR}}@$STYLE_DIR@g" "$BLOCK_SRC"; }

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

echo "轨言轨语 · ${MODE}"
echo "  风格目录 : $STYLE_DIR"
echo "  指令文件 : $AGENTS"
if grep -q '<kiseki_style' "$AGENTS" 2>/dev/null; then
  echo "  挂载动作 : 替换已存在的 <kiseki_style> 块"
else
  echo "  挂载动作 : 新增 <kiseki_style> 块"
fi
echo

if [ "$MODE" = "uninstall" ]; then
  if [ ! -f "$AGENTS" ] || ! grep -q '<kiseki_style' "$AGENTS"; then
    echo "未发现挂载块，无事可做。"
    exit 0
  fi
  if [ "$DRY" = "1" ]; then
    echo "[dry-run] 将从 $AGENTS 摘除挂载块（风格文件保留）。"
    exit 0
  fi
  cp "$AGENTS" "$AGENTS.bak-$(date +%Y%m%d-%H%M%S)-$$"
  strip_block "$AGENTS" > "$TMPD/agents"
  mv "$TMPD/agents" "$AGENTS"
  echo "已摘除挂载块。备份留在 $AGENTS.bak-*"
  echo "风格文件仍在 ${STYLE_DIR}，想清干净就 rm -rf \"$STYLE_DIR\""
  exit 0
fi

if [ "$DRY" = "1" ]; then
  echo "[dry-run] 将写入："
  echo "  $STYLE_DIR/kiseki.md"
  echo "  $STYLE_DIR/kiseki-state"
  echo "  $STYLE_DIR/kiseki-toggle"
  echo "  $STYLE_DIR/kiseki-level"
  echo "[dry-run] 将更新 $AGENTS"
  exit 0
fi

[ -f "$BLOCK_SRC" ] || { echo "缺少 $BLOCK_SRC" >&2; exit 1; }

# 1) 风格文件
mkdir -p "$STYLE_DIR"
cp "$SCRIPT_DIR/kiseki.md"     "$STYLE_DIR/kiseki.md"
cp "$SCRIPT_DIR/kiseki-state"  "$STYLE_DIR/kiseki-state"
cp "$SCRIPT_DIR/kiseki-toggle" "$STYLE_DIR/kiseki-toggle"
cp "$SCRIPT_DIR/kiseki-level"  "$STYLE_DIR/kiseki-level"
chmod 644 "$STYLE_DIR/kiseki.md"
chmod 755 "$STYLE_DIR/kiseki-state" "$STYLE_DIR/kiseki-toggle" "$STYLE_DIR/kiseki-level"

# 2) 常驻挂载块（幂等：先摘旧块，再插到标题行之后）
if [ -f "$AGENTS" ]; then
  cp "$AGENTS" "$AGENTS.bak-$(date +%Y%m%d-%H%M%S)-$$"
  strip_block "$AGENTS" > "$TMPD/stripped"
else
  mkdir -p "$(dirname "$AGENTS")"
  : > "$TMPD/stripped"
fi

{
  if [ -s "$TMPD/stripped" ]; then head -n 1 "$TMPD/stripped"; echo; fi
  render_block
  if [ -s "$TMPD/stripped" ]; then echo; tail -n +2 "$TMPD/stripped"; fi
} > "$TMPD/agents"
mv "$TMPD/agents" "$AGENTS"

echo "装好了。"
echo
echo "  读开关 : bash $STYLE_DIR/kiseki-state"
echo "  切开关 : bash $STYLE_DIR/kiseki-toggle off|on"
echo "  读浓度 : bash $STYLE_DIR/kiseki-level"
echo "  切浓度 : bash $STYLE_DIR/kiseki-level light|medium|heavy"
echo "  卸挂载 : bash $SCRIPT_DIR/install.sh --uninstall"
echo
echo "对新开的会话生效；已开着的会话重启一下最稳。"
