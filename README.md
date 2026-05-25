# Gemini CLI Windows Launcher

Windows launcher and login manager scripts for Gemini CLI.

这个仓库主要用于在 Windows 上更方便地启动和管理 Gemini CLI，支持：

- Google 账号登录
- 临时 Gemini API Key 启动
- Gemini CLI 环境检查
- 临时进程级代理
- 保留本地 `GEMINI.md` 使用偏好
- 避免长期污染 Windows 全局环境变量

---

## 1. 项目定位

这个项目不是 Gemini CLI 本体，而是一个 Windows 辅助启动器。

它适合以下场景：

- 想在 Windows 上更方便地启动 Gemini CLI
- 想在 Google 账号登录和 API Key 登录之间切换
- 想临时使用 API Key，但不想永久保存
- 想让 Gemini CLI 临时走代理
- 想集中管理 Gemini CLI 的本地启动脚本
- 想减少 PowerShell 命令输入

推荐定位：

```text
Gemini CLI：备用 AI CLI / 快速问答 / 轻量代码分析 / 对比其他 AI 工具结果
```

---

## 2. 推荐目录

建议把本仓库文件放到：

```text
C:\DIY\Gemini CLI
```

推荐目录结构：

```text
C:\DIY\Gemini CLI
├── GEMINI.md
├── gemini.ps1
├── gemini-login-manager-v3.ps1
├── README-请先看.txt
├── 启动-Gemini-登录管理器.cmd
├── 启动-Gemini-账号登录.cmd
├── 启动-Gemini-临时API.cmd
└── 检查-Gemini-环境.cmd
```

---

## 3. 文件说明

| 文件 | 作用 |
|---|---|
| `GEMINI.md` | Gemini CLI 使用偏好，例如默认中文回答、Windows 命令习惯、安全规则等 |
| `gemini.ps1` | 核心启动器，负责临时代理、环境恢复和调用 Gemini CLI |
| `gemini-login-manager-v3.ps1` | 登录管理器主脚本，提供账号登录、临时 API、环境检查等功能 |
| `启动-Gemini-登录管理器.cmd` | 打开完整菜单 |
| `启动-Gemini-账号登录.cmd` | 使用 Google 账号登录方式启动 Gemini CLI |
| `启动-Gemini-临时API.cmd` | 临时输入 API Key 启动一次，不保存 |
| `检查-Gemini-环境.cmd` | 检查代理、认证变量、`.env` 等环境状态 |
| `README-请先看.txt` | 给 Windows 用户看的简短说明 |

---

## 4. 最常用入口

### 4.1 日常使用：Google 账号登录

双击：

```text
启动-Gemini-账号登录.cmd
```

适合日常使用 Gemini CLI。

如果终端提示：

```text
You've successfully signed in with Google.
Gemini CLI needs to be restarted.
Press R to restart...
```

直接按：

```text
R
```

---

### 4.2 临时使用 API Key

双击：

```text
启动-Gemini-临时API.cmd
```

这个模式会让你临时输入 `GEMINI_API_KEY`。

特点：

```text
只在本次运行中生效
不会长期保存到 Windows 用户环境变量
退出后会恢复环境变量
```

适合：

- 临时测试 Gemini API
- 临时使用 API Key
- 不想永久保存 API Key
- 账号登录不可用时临时备用

---

### 4.3 打开完整菜单

双击：

```text
启动-Gemini-登录管理器.cmd
```

菜单通常包括：

```text
1. Google 账号登录启动 Gemini CLI
2. 临时 API Key 启动一次，不保存
3. 普通启动，保留当前认证方式
4. 单次提问：gemini -p
5. 查看环境状态 / 检查 .env
6. 删除已保存的 API 认证变量
7. 保存 API Key 到用户环境变量
8. 常用命令
0. 退出
```

---

### 4.4 检查环境

双击：

```text
检查-Gemini-环境.cmd
```

适合排查：

- 为什么 Gemini CLI 仍然走 API Key
- 为什么账号登录没有生效
- 为什么 Gemini CLI 网络失败
- 当前代理变量是否异常
- `.env` 中是否残留 API Key

---

## 5. 认证方式说明

Gemini CLI 常见认证方式有两种：

```text
Google 账号登录
Gemini API Key 登录
```

### 5.1 Google 账号登录

推荐日常使用。

优点：

- 不需要管理 API Key
- 适合个人手动使用
- 安全风险较低
- 操作更简单

启动方式：

```text
启动-Gemini-账号登录.cmd
```

进入 Gemini CLI 后，也可以输入：

```text
/auth
```

重新选择登录方式。

---

### 5.2 API Key 登录

适合开发和临时测试。

推荐使用：

```text
启动-Gemini-临时API.cmd
```

不推荐长期把 API Key 写入系统环境变量，除非你明确知道自己需要这样做。

API Key 相关变量包括：

```text
GEMINI_API_KEY
GOOGLE_API_KEY
GOOGLE_GENAI_USE_VERTEXAI
```

账号登录模式会尝试清理这些变量，避免 Gemini CLI 继续使用 API Key。

---

## 6. 代理策略

默认代理地址：

```text
http://127.0.0.1:7897
```

建议配合 Clash 使用：

```text
Clash：规则模式
系统代理：开启
端口：7897
```

本项目采用临时进程级代理：

```text
只在 Gemini CLI 运行时设置代理
Gemini CLI 退出后恢复环境变量
不长期污染 Windows 全局环境变量
```

这样可以避免影响：

- npm
- git
- pip
- curl
- 国内镜像源
- 局域网服务
- 其他开发工具

---

## 7. Gemini CLI 常用命令

进入交互模式：

```powershell
gemini
```

单次提问：

```powershell
gemini -p "请用中文回答。Say hi."
```

切换认证方式：

```text
/auth
```

切换模型：

```text
/model
```

查看帮助：

```text
/help
```

查看统计：

```text
/stats
```

退出：

```text
/quit
```

或：

```text
Ctrl + C
```

---

## 8. 推荐模型使用习惯

日常建议优先使用：

```text
gemini-2.5-flash
gemini-2.5-flash-lite
gemini-3-flash-preview
gemini-3.1-flash-lite-preview
```

建议：

```text
简单问答：Flash Lite
普通代码分析：Flash
复杂分析：Pro 或更强模型
长期日常：不要一直使用 Pro
```

如果 Pro 额度用完，可以输入：

```text
/model
```

切换到 Flash 或 Flash Lite。

---

## 9. 使用建议

### 9.1 分析当前目录

进入目标项目目录后启动 Gemini CLI：

```powershell
cd "你的项目目录"
gemini
```

然后输入：

```text
请用中文回答。先分析当前目录结构，不要修改任何文件。
```

---

### 9.2 分析指定文件

Gemini CLI 可以用 `@` 指定文件：

```text
@README.md 总结这个文件。
```

```text
@package.json 告诉我这个项目有哪些启动命令。
```

建议优先指定少量关键文件，不要一开始就让 Gemini 扫描整个大项目。

---

### 9.3 让 Gemini 修改文件前

建议先说：

```text
请先告诉我你准备修改哪些文件，不要直接修改。
```

如果涉及删除文件，建议说：

```text
如果需要删除文件，请先列出清单并解释原因，等我确认后再执行。
```

---

## 10. 安全提醒

不要公开上传：

```text
.env
*.key
*.token
*.pem
logs/
backup/
```

不要泄露：

```text
API Key
token
账号认证文件
个人密码
本机敏感路径
```

不要随便删除：

```text
%USERPROFILE%\.codex\auth.json
%USERPROFILE%\.codex\config.toml
```

不要在这些目录里运行项目级 AI CLI：

```text
C:\Windows
C:\Windows\System32
C:\Program Files
C:\Program Files (x86)
```

---

## 11. 常见问题

### 11.1 登录成功后提示 Press R

这是正常情况。

看到：

```text
You've successfully signed in with Google.
Gemini CLI needs to be restarted.
Press R to restart...
```

直接按：

```text
R
```

---

### 11.2 仍然走 API Key

处理顺序：

1. 双击 `检查-Gemini-环境.cmd`
2. 检查是否存在 `GEMINI_API_KEY`
3. 检查当前目录是否有 `.env`
4. 检查 `C:\DIY\Gemini CLI\.env`
5. 删除或注释 `.env` 中的 API Key
6. 重新启动 Gemini CLI

`.env` 中如果有：

```text
GEMINI_API_KEY=xxxx
```

可以改成：

```text
# GEMINI_API_KEY=xxxx
```

---

### 11.3 网络失败或 fetch failed

检查：

1. Clash 是否打开
2. 代理端口是否是 `7897`
3. 系统代理是否开启
4. 是否需要临时切换 Clash 全局模式排查
5. 排查完成后切回规则模式
6. 重新启动 Gemini CLI

---

### 11.4 一直 Thinking

可以尝试：

1. 按 `Esc` 取消
2. 输入 `/model`
3. 切换到 Flash 或 Flash Lite
4. 重新提问

---

### 11.5 CMD 窗口一闪而过

新版脚本会尽量让窗口停住。

如果仍然一闪而过，可以手动打开 PowerShell：

```powershell
cd "C:\DIY\Gemini CLI"
.\启动-Gemini-登录管理器.cmd
```

然后查看报错信息。

---

## 12. 与 Codex CLI 的区别

Gemini CLI 单次提问：

```powershell
gemini -p "问题"
```

Codex CLI 单次任务：

```powershell
codex exec "问题"
```

不要混用：

```powershell
codex -p "问题"
```

---

## 13. 下载方式

点击 GitHub 页面上的绿色按钮：

```text
Code → Download ZIP
```

下载后解压，把文件放到：

```text
C:\DIY\Gemini CLI
```

然后双击：

```text
启动-Gemini-登录管理器.cmd
```

---

## 14. License

This project is released under the MIT License.
