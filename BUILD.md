# MuTools 安装包构建指南

本文档说明如何把 MuTools 源码构建成可直接安装的程序（安装包）。

MuTools 基于 **Tauri v2**（Rust + Vanilla JS + Vite）开发，正式安装包为 Windows 平台产物：

| 安装包类型 | 文件 | 用途 |
| --- | --- | --- |
| **NSIS 安装包** | `mutools_<版本>_x64-setup.exe` | 常规安装，双击运行，引导式安装 |
| **MSI 安装包** | `mutools_<版本>_x64_en-US.msi` | 企业部署、组策略（GPO）分发 |

> 注意：Tauri 的 Windows 安装包**只能在 Windows 环境构建**（MSI 依赖微软 WiX 工具链），Linux/macOS 无法交叉编译。以下三种方式任选其一即可。

---

## 方式一：本地 Windows 一键构建（推荐）

### 1. 环境要求

| 依赖 | 版本 | 说明 |
| --- | --- | --- |
| Windows | 10 / 11 (x64) | |
| Node.js | 18+ | https://nodejs.org/ |
| Rust (MSVC) | stable | https://rustup.rs/ |
| Visual Studio Build Tools | 最新 | 安装时勾选 **「使用 C++ 的桌面开发」** 工作负载，提供 MSVC 链接器 |
| WebView2 运行时 | 已内置 | Win10/11 自带，无需额外安装 |

首次构建会编译全部 Rust 依赖，耗时 **5~15 分钟**，属正常现象。

### 2. 运行一键脚本

在项目根目录（`MuToolsProject/`）下任选其一：

```
# 方式 A：双击运行（最简单）
build-installer.cmd

# 方式 B：PowerShell（输出更友好，带完整环境检查）
.\build-installer.ps1
```

脚本会自动完成：环境检查 → `npm install` → `tauri build` → 汇总安装包位置。

### 3. 产物位置

```
MuToolsCode/src-tauri/target/release/bundle/
├── nsis/mutools_<版本>_x64-setup.exe    ← NSIS 安装包（分发用这个）
└── msi/mutools_<版本>_x64_en-US.msi     ← MSI 安装包
```

---

## 方式二：GitHub Actions 自动构建（无需本地环境）

仓库已内置工作流 `.github/workflows/build-installer.yml`：

1. 把仓库推送到 GitHub（或直接使用本项目仓库）；
2. 两种触发方式：
   - **打 tag**：`git push origin v1.1.0` —— 自动构建并生成 Draft Release，安装包随附；
   - **手动触发**：仓库 **Actions** 页 → 左侧 **Build Installer** → **Run workflow**；
3. 构建完成后：
   - 打 tag 场景：安装包出现在 Draft Release 的 Assets 中；
   - 手动场景：在 Actions 运行记录的 **Artifacts** 中下载（zip 内含 .exe 与 .msi）。

---

## 方式三：手动命令构建（进阶）

在 Windows 环境手动执行：

```bat
cd MuToolsCode
npm install
npm run tauri build          :: 默认构建 tauri.conf.json 中配置的 nsis + msi
:: 指定构建单一类型：
npm run tauri build -- --bundles nsis
npm run tauri build -- --bundles msi
```

---

## 便携版（可选）

项目附带的 `Tools_portable_builder/` 可生成免安装便携版：

```bat
cd Tools_portable_builder
python builder.py            :: 详见该目录 readme.txt
```

便携版为绿色解压即用形态，与安装包互补，分发策略可参考项目原作者的发布方式。

---

## 常见问题（FAQ）

**Q1：`link.exe` 未找到 / Rust 编译报错 `linker not found`？**
安装 Visual Studio Build Tools 并勾选「使用 C++ 的桌面开发」，或从「x64 Native Tools 命令行提示符」运行脚本。

**Q2：构建报错 `...\icons\icon.icns` 缺失？**
`tauri.conf.json` 的 icon 列表中含 macOS 用 `icon.icns`，Windows 构建实际只使用 `icon.ico`（仓库已包含）。若 Tauri 校验报错，可将该行移除后再构建，不影响 Windows 安装包。

**Q3：安装包被杀毒软件拦截？**
MuTools 涉及模拟器进程操作与注册表读写（优化、提权功能），未做代码签名时易被安全软件误报。建议：添加信任，或自行配置代码签名证书后再分发。

**Q4：如何修改安装包名称 / 版本号？**
编辑 `MuToolsCode/src-tauri/tauri.conf.json` 中的 `productName`、`version` 字段后重新构建。

**Q5：构建很慢？**
首次构建需编译全部 Rust 依赖。之后的增量构建很快；也可在 `MuToolsCode/src-tauri/Cargo.toml` 使用 release profile 优化（默认已为 release 构建）。

---

## 相关文件

| 文件 | 作用 |
| --- | --- |
| `build-installer.cmd` | Windows 一键构建脚本（批处理） |
| `build-installer.ps1` | Windows 一键构建脚本（PowerShell，带完整环境检查） |
| `.github/workflows/build-installer.yml` | GitHub Actions 自动构建工作流 |
| `build.bat` | 项目自带的基础构建脚本 |
| `MuToolsCode/src-tauri/tauri.conf.json` | Tauri 打包配置（产物类型、图标、版本） |
