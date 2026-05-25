Gemini CLI 登录管理器 v3

放置位置：
把本压缩包里的文件全部复制到：
C:\DIY\Gemini CLI

推荐保留你原来的：
- gemini.ps1
- GEMINI.md

然后双击：
启动-Gemini-登录管理器.cmd

你也可以直接双击：
启动-Gemini-账号登录.cmd
启动-Gemini-临时API.cmd
检查-Gemini-环境.cmd

这版修复/优化：
1. CMD 窗口不会一闪而过，出错也会停住。
2. PowerShell 脚本使用 UTF-8 BOM 保存，更适合 Windows PowerShell 5.1。
3. 优先调用当前目录里的 gemini.ps1，因此会继承你原来的代理和 GEMINI.md 配置。
4. 账号登录模式会清理 GEMINI_API_KEY / GOOGLE_API_KEY / GOOGLE_GENAI_USE_VERTEXAI。
5. API 模式默认只临时使用一次，不保存。
6. 继续使用临时进程级代理：http://127.0.0.1:7897。
7. 会检查当前目录和工具目录里的 .env 是否含有 API Key 配置。

当前你已经完成 Google 账号授权时：
如果终端出现：
You've successfully signed in with Google. Gemini CLI needs to be restarted. Press R to restart...
直接按 R。

如果要重新选择登录方式：
进入 Gemini CLI 后输入：
/auth

如果要切换模型：
/model

日常建议：
- 日常用 Google 账号登录
- 只有需要 API Key 时，用“临时 API Key 启动一次”
- 不建议长期保存 API Key，除非你明确想长期走 API
