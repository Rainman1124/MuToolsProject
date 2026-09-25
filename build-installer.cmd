@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title MuTools - 安装包一键构建

REM ============================================================
REM  MuTools 一键构建安装包脚本 (Windows)
REM  产物: NSIS 安装包 (mutools_<version>_x64-setup.exe)
REM        MSI  安装包 (mutools_<version>_x64_en-US.msi)
REM  输出目录: MuToolsCode\src-tauri\target\release\bundle\
REM ============================================================

cd /d "%~dp0"
set "ROOT=%~dp0"
set "CODE=%ROOT%MuToolsCode"

echo.
echo  ==========================================================
echo    MuTools 安装包一键构建
echo  ==========================================================
echo.

REM ---------- 1. 检查 Node.js ----------
where node >nul 2>nul
if errorlevel 1 (
    echo  [错误] 未检测到 Node.js。
    echo         请先安装 Node.js 18 或更高版本: https://nodejs.org/
    echo         安装后重新运行本脚本。
    pause
    exit /b 1
)
for /f "delims=" %%v in ('node -v') do set "NODE_VER=%%v"
echo  [1/5] Node.js          : !NODE_VER!

REM ---------- 2. 检查 npm ----------
where npm >nul 2>nul
if errorlevel 1 (
    echo  [错误] 未检测到 npm。
    pause
    exit /b 1
)

REM ---------- 3. 检查 Rust / Cargo ----------
where cargo >nul 2>nul
if errorlevel 1 (
    echo  [错误] 未检测到 Rust 工具链。
    echo         请安装 Rust (MSVC 工具链): https://rustup.rs/
    echo         安装完成后请重启终端再运行本脚本。
    pause
    exit /b 1
)
for /f "delims=" %%v in ('cargo --version') do set "CARGO_VER=%%v"
echo  [2/5] Rust 工具链      : !CARGO_VER!

REM ---------- 4. 检查 MSVC 链接器 (link.exe) ----------
where link.exe >nul 2>nul
if errorlevel 1 (
    echo  [警告] 未检测到 MSVC 链接器 link.exe。
    echo         Rust 需要 "Visual Studio Build Tools" 中的
    echo         "使用 C++ 的桌面开发" 工作负载才能编译。
    echo         链接: https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo         若已安装请从 "x64 Native Tools 命令行提示符" 中运行本脚本。
    pause
    exit /b 1
)
echo  [3/5] MSVC 链接器     : 已就绪

REM ---------- 5. 安装前端依赖 ----------
echo  [4/5] 安装前端依赖 (npm install)...
pushd "%CODE%"
call npm install --no-audit --no-fund
if errorlevel 1 (
    echo  [错误] npm install 失败，请检查网络后重试。
    popd
    pause
    exit /b 1
)
popd

REM ---------- 6. 构建安装包 ----------
echo  [5/5] 开始构建安装包 (tauri build: NSIS + MSI)...
echo        首次编译需要下载并编译 Rust 依赖，耗时较长，请耐心等待。
echo.
pushd "%CODE%"
call npm run tauri build
if errorlevel 1 (
    echo.
    echo  [错误] 构建失败，请查看上方错误信息。
    popd
    pause
    exit /b 1
)
popd

echo.
echo  ==========================================================
echo    构建成功！
echo  ==========================================================
echo.
echo  安装包位置:
set "BUNDLE=%CODE%\src-tauri\target\release\bundle"
if exist "%BUNDLE%\nsis\*.exe" (
    echo    NSIS 安装包: "%BUNDLE%\nsis\"
    for %%f in ("%BUNDLE%\nsis\*.exe") do echo      - %%~nxf
)
if exist "%BUNDLE%\msi\*.msi" (
    echo    MSI 安装包  : "%BUNDLE%\msi\"
    for %%f in ("%BUNDLE%\msi\*.msi") do echo      - %%~nxf
)
echo.
echo  直接运行 NSIS 安装包 (.exe) 即可完成安装。
echo.
pause
exit /b 0
