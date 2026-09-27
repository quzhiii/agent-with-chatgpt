# ChatGPT Brain — ZCode 端安装脚本（Windows PowerShell）
# 用法：在仓库根目录执行  powershell -ExecutionPolicy Bypass -File install\install-zcode.ps1
# 作用：环境自检 → 构建桥 → 安装 skill 到 ~\.zcode\skills\chatgpt-brain\

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$SkillName = "chatgpt-brain"

function Fail($msg) { Write-Host "[x] $msg" -ForegroundColor Red; exit 1 }
function Info($msg) { Write-Host "[*] $msg" }
function Ok($msg)   { Write-Host "[+] $msg" -ForegroundColor Green }

Info "仓库：$RepoRoot"

# 1. Node >= 20
try { $nodeV = (& node -v).TrimStart("v") } catch { Fail "未检测到 node，请先安装 Node.js 20+（https://nodejs.org）" }
$nodeMajor = [int]($nodeV.Split(".")[0])
if ($nodeMajor -lt 20) { Fail "Node 版本 $nodeV 过低，需要 >= 20" }
Ok "Node v$nodeV"

# 2. pnpm（经 corepack）
try { & corepack pnpm --version *> $null; Ok "pnpm（corepack）可用" }
catch { Info "启用 corepack..."; & corepack enable; if ($LASTEXITCODE -ne 0) { Fail "corepack 启用失败，请手动安装 pnpm" } }

# 3. cloudflared（缺失不阻塞安装，setup 时才需要；winget 可能被 UAC 拦，兜底走官方 release）
if (Get-Command cloudflared -ErrorAction SilentlyContinue) { Ok "cloudflared 已安装" }
else {
    $cfExe = Join-Path $env:USERPROFILE "bin\cloudflared.exe"
    if (Test-Path $cfExe) {
        Ok "cloudflared 已存在：$cfExe"
    } else {
        Write-Host "[!] 未检测到 cloudflared，尝试从官方 GitHub release 下载到 ~\bin ..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Force -Path (Split-Path $cfExe) | Out-Null
            Invoke-WebRequest -UseBasicParsing `
                -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" `
                -OutFile $cfExe
            [Environment]::SetEnvironmentVariable("C2C_CLOUDFLARED_PATH", $cfExe, "User")
            $env:C2C_CLOUDFLARED_PATH = $cfExe
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$(Split-Path $cfExe)*") {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$(Split-Path $cfExe)", "User")
            }
            Ok "cloudflared 已下载：$cfExe（C2C_CLOUDFLARED_PATH 已写入用户环境变量）"
        } catch {
            Write-Host "[!] 自动下载失败，请手动安装后重跑本脚本：" -ForegroundColor Yellow
            Write-Host "    winget install Cloudflare.cloudflared        （可能弹 UAC，请点允许）"
            Write-Host "    或手动下载 https://github.com/cloudflare/cloudflared/releases"
        }
    }
}

# 4. 构建桥
Push-Location $RepoRoot
try {
    Info "安装依赖（corepack pnpm install）..."
    & corepack pnpm install
    if ($LASTEXITCODE -ne 0) { Fail "依赖安装失败" }
    Info "构建（corepack pnpm build）..."
    & corepack pnpm build
    if ($LASTEXITCODE -ne 0) { Fail "构建失败" }
    Ok "桥构建完成（dist/）"
} finally { Pop-Location }

# 5. 安装 skill 到 ZCode 用户目录（回填仓库路径）
$skillDir = Join-Path $env:USERPROFILE ".zcode\skills\$SkillName"
New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
$src = Get-Content -Raw (Join-Path $RepoRoot "skills\zcode\SKILL.md")
$dst = Join-Path $skillDir "SKILL.md"
$src.Replace("<ACTUAL_CHECKOUT_PATH>", $RepoRoot) | Set-Content -NoNewline -Encoding UTF8 $dst
Ok "Skill 已安装：$dst"

# 6. 下一步
Write-Host ""
Ok "安装完成。下一步："
Write-Host "  1. 重开一个 ZCode 会话（skill 在新会话加载）"
Write-Host "  2. 对 ZCode 说：用 chatgpt-brain 完成首次配置   （在你的项目目录下）"
Write-Host "  3. 浏览器登录 ChatGPT / 输配对码时按提示一次一个动作即可"
