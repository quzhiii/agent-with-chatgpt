#!/usr/bin/env bash
# ChatGPT Brain — ZCode 端安装脚本（Git Bash / macOS / Linux）
# 用法：bash install/install-zcode.sh
# 作用：环境自检 → 构建桥 → 安装 skill 到 ~/.zcode/skills/chatgpt-brain/

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_NAME="chatgpt-brain"

info() { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
fail() { echo "[x] $*" >&2; exit 1; }

info "仓库：$REPO_ROOT"

# 1. Node >= 20
command -v node >/dev/null 2>&1 || fail "未检测到 node，请先安装 Node.js 20+"
NODE_MAJOR="$(node -v | sed 's/^v//' | cut -d. -f1)"
[ "$NODE_MAJOR" -ge 20 ] || fail "Node $(node -v) 过低，需要 >= 20"
ok "Node $(node -v)"

# 2. pnpm（经 corepack）
if corepack pnpm --version >/dev/null 2>&1; then
  ok "pnpm（corepack）可用"
else
  info "启用 corepack..."
  corepack enable || fail "corepack 启用失败，请手动安装 pnpm"
fi

# 3. cloudflared（缺失不阻塞安装，setup 时才需要）
if command -v cloudflared >/dev/null 2>&1; then
  ok "cloudflared 已安装"
else
  echo "[!] 未检测到 cloudflared。首次配置（c2c setup）前请安装：" >&2
  echo "    macOS:  brew install cloudflared" >&2
  echo "    Windows: winget install Cloudflare.cloudflared" >&2
fi

# 4. 构建桥
cd "$REPO_ROOT"
info "安装依赖（corepack pnpm install）..."
corepack pnpm install >/dev/null
info "构建（corepack pnpm build）..."
corepack pnpm build >/dev/null
ok "桥构建完成（dist/）"

# 5. 安装 skill 到 ZCode 用户目录（回填仓库路径）
SKILL_DIR="$HOME/.zcode/skills/$SKILL_NAME"
mkdir -p "$SKILL_DIR"
sed "s|<ACTUAL_CHECKOUT_PATH>|$REPO_ROOT|g" "$REPO_ROOT/skills/zcode/SKILL.md" > "$SKILL_DIR/SKILL.md"
ok "Skill 已安装：$SKILL_DIR/SKILL.md"

# 6. 下一步
echo ""
ok "安装完成。下一步："
echo "  1. 重开一个 ZCode 会话（skill 在新会话加载）"
echo "  2. 对 ZCode 说：用 chatgpt-brain 完成首次配置   （在你的项目目录下）"
echo "  3. 浏览器登录 ChatGPT / 输配对码时按提示一次一个动作即可"
