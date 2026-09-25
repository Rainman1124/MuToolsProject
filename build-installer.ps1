<#
.SYNOPSIS
    MuTools 安装包一键构建脚本 (PowerShell / Windows)
.DESCRIPTION
    自动检查构建环境 -> 安装前端依赖 -> 调用 tauri build
    产出 NSIS 安装包 (.exe) 与 MSI 安装包 (.msi)
    输出目录: MuToolsCode\src-tauri\target\release\bundle\
.USAGE
    右键"使用 PowerShell 运行"，或在 PowerShell 中执行:
        .\build-installer.ps1
#>

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'MuTools - 安装包一键构建'

$ROOT  = Split-Path -Parent $MyInvocation.MyCommand.Path
$CODE  = Join-Path $ROOT 'MuToolsCode'

function Write-Step  { param($Text) Write-Host "`n=== $Text ===" -ForegroundColor Cyan }
function Write-OK    { param($Text) Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Warn  { param($Text) Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Write-Fail  { param($Text) Write-Host "  [XX] $Text" -ForegroundColor Red }

Write-Host ''
Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host '   MuTools 安装包一键构建' -ForegroundColor Cyan
Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host ''

# ---------- 0. 路径检查 ----------
if (-not (Test-Path (Join-Path $CODE 'package.json'))) {
    Write-Fail "未找到 MuToolsCode 目录，请确认脚本位于项目根目录。"
    exit 1
}

# ---------- 1. Node.js ----------
Write-Step '检查构建环境 [1/6] Node.js'
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Fail "未检测到 Node.js，请安装 Node.js 18+ : https://nodejs.org/"
    exit 1
}
$nodeVer = & node -v
Write-OK "Node.js $nodeVer"

# ---------- 2. npm ----------
Write-Step '检查构建环境 [2/6] npm'
$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npm) { Write-Fail "未检测到 npm。"; exit 1 }
Write-OK "npm $(& npm -v | Select-Object -First 1)"

# ---------- 3. Rust ----------
Write-Step '检查构建环境 [3/6] Rust 工具链'
$cargo = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargo) {
    Write-Fail "未检测到 Rust 工具链，请安装 (MSVC 工具链): https://rustup.rs/"
    Write-Warn  "安装完成后请重新打开终端再运行本脚本。"
    exit 1
}
$cargoVer = & cargo --version
Write-OK $cargoVer

# ---------- 4. MSVC 链接器 ----------
Write-Step '检查构建环境 [4/6] MSVC 链接器 (link.exe)'
$link = Get-Command link.exe -ErrorAction SilentlyContinue
if (-not $link) {
    Write-Warn "未检测到 link.exe，请安装 Visual Studio Build Tools 并勾选"使用 C++ 的桌面开发"："
    Write-Warn "  https://visualstudio.microsoft.com/visual-cpp-build-tools/"
    Write-Warn "  或从「x64 Native Tools 命令行提示符」中运行本脚本。"
    Write-Fail "缺少 MSVC 链接器，Rust 无法编译，终止构建。"
    exit 1
}
Write-OK 'MSVC 链接器已就绪'

# ---------- 5. WebView2 ----------
Write-Step '检查构建环境 [5/6] WebView2 运行时'
$wv2 = Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-161E-4CBE-B5A6-E953FF8C647F}' -ErrorAction SilentlyContinue
if ($wv2) {
    Write-OK "WebView2 运行时已安装 (版本 $($wv2.pv))"
} else {
    Write-Warn '未检测到 WebView2 运行时（Win10/11 一般已内置），若目标机器缺少可下载：'
    Write-Warn '  https://developer.microsoft.com/microsoft-edge/webview2/'
}

# ---------- 6. 磁盘空间 ----------
Write-Step '检查构建环境 [6/6] 磁盘空间'
$drive = Get-PSDrive -Name (Split-Path -Qualifier $CODE).TrimEnd(':')
$freeGB = [math]::Round($drive.Free / 1GB, 1)
if ($freeGB -lt 10) {
    Write-Warn "剩余磁盘空间仅 $freeGB GB，建议至少保留 10 GB（Rust 依赖+构建产物）。"
} else {
    Write-OK "磁盘剩余 $freeGB GB，空间充足"
}

# ---------- 安装依赖 ----------
Write-Step '安装前端依赖 (npm install)'
Push-Location $CODE
try {
    npm install --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw "npm install 失败" }
    Write-OK '前端依赖安装完成'
} finally {
    Pop-Location
}

# ---------- 构建安装包 ----------
Write-Step '构建安装包 (tauri build: NSIS + MSI)'
Write-Warn  '首次构建需编译全部 Rust 依赖，约 5~15 分钟，请耐心等待...'
Push-Location $CODE
try {
    npm run tauri build
    if ($LASTEXITCODE -ne 0) { throw "tauri build 失败" }
} finally {
    Pop-Location
}

# ---------- 汇总产物 ----------
Write-Step '构建结果'
$bundle = Join-Path $CODE 'src-tauri\target\release\bundle'
$found  = $false

foreach ($dir in @('nsis', 'msi')) {
    $full = Join-Path $bundle $dir
    if (Test-Path $full) {
        Get-ChildItem $full -File | Where-Object { $_.Extension -in '.exe', '.msi' } | ForEach-Object {
            Write-OK "安装包: $($_.FullName)  ($([math]::Round($_.Length/1MB,1)) MB)"
            $found = $true
        }
    }
}

if (-not $found) {
    Write-Fail '未找到安装包产物，请检查上方构建日志。'
    exit 1
}

Write-Host ''
Write-Host '===========================================================' -ForegroundColor Green
Write-Host '   构建成功！双击运行 .exe 安装包即可安装 MuTools' -ForegroundColor Green
Write-Host '===========================================================' -ForegroundColor Green
Write-Host ''
Read-Host '按回车键退出'
exit 0
