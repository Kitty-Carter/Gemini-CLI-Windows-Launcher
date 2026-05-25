# Gemini CLI Login Manager v3
# Windows PowerShell 5.1+ compatible
# Put this file in: C:\DIY\Gemini CLI

[CmdletBinding()]
param(
    [ValidateSet("menu", "account", "api-once", "normal", "status", "prompt")]
    [string]$Mode = "menu",

    [string]$PromptText = ""
)

$ErrorActionPreference = "Continue"

# =========================
# Basic config
# =========================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    $ScriptDir = (Get-Location).ProviderPath
}

$ToolRoot = $ScriptDir
$ProxyUrl = "http://127.0.0.1:7897"
$NoProxyValue = "localhost,127.0.0.1,::1,.local,.lan,.cn"

$AuthVars = @(
    "GEMINI_API_KEY",
    "GOOGLE_API_KEY",
    "GOOGLE_GENAI_USE_VERTEXAI"
)

$ProxyVars = @(
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
    "http_proxy", "https_proxy", "all_proxy", "no_proxy"
)

$BlockedDirs = @(
    "C:\",
    "C:\Windows",
    "C:\Windows\System32",
    "C:\Windows\SysWOW64",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\Users",
    "C:\Users\Public"
)

# =========================
# Console helpers
# =========================

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host (" " + $Text) -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Pause-Here {
    Write-Host ""
    Read-Host "按 Enter 继续"
}

function Set-ConsoleUtf8 {
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $OutputEncoding = [System.Text.Encoding]::UTF8
    } catch {}
}

function Get-PlainTextFromSecureString {
    param([System.Security.SecureString]$SecureString)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Save-ProcessEnv {
    param([string[]]$Names)
    $backup = @{}
    foreach ($name in $Names) {
        $backup[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
    }
    return $backup
}

function Restore-ProcessEnv {
    param(
        [hashtable]$Backup,
        [string[]]$Names
    )
    foreach ($name in $Names) {
        if ($Backup.ContainsKey($name)) {
            [Environment]::SetEnvironmentVariable($name, $Backup[$name], "Process")
        }
    }
}

function Set-TemporaryProxy {
    [Environment]::SetEnvironmentVariable("HTTP_PROXY",  $ProxyUrl, "Process")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $ProxyUrl, "Process")
    [Environment]::SetEnvironmentVariable("ALL_PROXY",   $ProxyUrl, "Process")
    [Environment]::SetEnvironmentVariable("NO_PROXY",    $NoProxyValue, "Process")

    [Environment]::SetEnvironmentVariable("http_proxy",  $ProxyUrl, "Process")
    [Environment]::SetEnvironmentVariable("https_proxy", $ProxyUrl, "Process")
    [Environment]::SetEnvironmentVariable("all_proxy",   $ProxyUrl, "Process")
    [Environment]::SetEnvironmentVariable("no_proxy",    $NoProxyValue, "Process")
}

function Clear-ProcessAuthVars {
    foreach ($name in $AuthVars) {
        [Environment]::SetEnvironmentVariable($name, $null, "Process")
    }
}

function Clear-UserAuthVars {
    foreach ($name in $AuthVars) {
        [Environment]::SetEnvironmentVariable($name, $null, "User")
    }
}

function Clear-AllAuthVars {
    Clear-ProcessAuthVars
    Clear-UserAuthVars
}

function Get-EnvState {
    param([string]$Name)
    $processValue = [Environment]::GetEnvironmentVariable($Name, "Process")
    $userValue = [Environment]::GetEnvironmentVariable($Name, "User")

    $p = if ([string]::IsNullOrWhiteSpace($processValue)) { "空" } else { "已设置" }
    $u = if ([string]::IsNullOrWhiteSpace($userValue)) { "空" } else { "已设置" }

    return ("{0,-28} Process={1,-8} User={2,-8}" -f $Name, $p, $u)
}

function Test-BlockedDirectory {
    $current = (Get-Location).ProviderPath
    if ([string]::IsNullOrWhiteSpace($current)) { return $false }

    $current = $current.TrimEnd("\")
    foreach ($dir in $BlockedDirs) {
        $d = $dir.TrimEnd("\")
        if ($current -ieq $d) {
            return $true
        }
    }
    return $false
}

function Stop-IfBlockedDirectory {
    if (Test-BlockedDirectory) {
        Write-Host ""
        Write-Host "已拦截：当前目录不适合运行 Gemini CLI。" -ForegroundColor Red
        Write-Host ("当前目录：" + (Get-Location).ProviderPath) -ForegroundColor Yellow
        Write-Host ""
        Write-Host "请先进入具体项目目录，例如：" -ForegroundColor Yellow
        Write-Host '  cd "C:\DIY\Gemini CLI"'
        Write-Host '  gemini'
        Write-Host ""
        return $true
    }
    return $false
}

function Get-GeminiLauncher {
    $localWrapper = Join-Path $ToolRoot "gemini.ps1"

    if (Test-Path $localWrapper) {
        return @{
            Kind = "LocalWrapper"
            Path = $localWrapper
            Display = $localWrapper
        }
    }

    $geminiCmd = Get-Command "gemini.cmd" -CommandType Application -ErrorAction SilentlyContinue
    if ($geminiCmd) {
        return @{
            Kind = "GeminiCmd"
            Path = $geminiCmd.Source
            Display = $geminiCmd.Source
        }
    }

    $geminiAny = Get-Command "gemini" -ErrorAction SilentlyContinue
    if ($geminiAny) {
        return @{
            Kind = "GeminiAny"
            Path = $geminiAny.Source
            Display = $geminiAny.Source
        }
    }

    return $null
}

function Invoke-GeminiLauncher {
    param(
        [string[]]$GeminiArgs = @()
    )

    if (Stop-IfBlockedDirectory) {
        return 100
    }

    $launcher = Get-GeminiLauncher
    if (-not $launcher) {
        Write-Host ""
        Write-Host "找不到 Gemini CLI 启动命令。" -ForegroundColor Red
        Write-Host "请确认 Gemini CLI 已安装，并重新打开 PowerShell。"
        return 101
    }

    Write-Host ""
    Write-Host ("使用启动器：" + $launcher.Display) -ForegroundColor Green

    if ($launcher.Kind -eq "LocalWrapper") {
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $launcher.Path @GeminiArgs
        return $LASTEXITCODE
    }

    if ($launcher.Kind -eq "GeminiCmd") {
        & $launcher.Path --include-directories $ToolRoot @GeminiArgs
        return $LASTEXITCODE
    }

    & $launcher.Path @GeminiArgs
    return $LASTEXITCODE
}

function Test-EnvFileWarning {
    $candidates = @()

    try {
        $currentEnv = Join-Path (Get-Location).ProviderPath ".env"
        $candidates += $currentEnv
    } catch {}

    $toolEnv = Join-Path $ToolRoot ".env"
    if ($candidates -notcontains $toolEnv) {
        $candidates += $toolEnv
    }

    $hasWarning = $false

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $hit = Select-String -Path $path -Pattern "GEMINI_API_KEY|GOOGLE_API_KEY|GOOGLE_GENAI_USE_VERTEXAI" -ErrorAction SilentlyContinue
            if ($hit) {
                if (-not $hasWarning) {
                    Write-Host ""
                    Write-Host "注意：发现 .env 文件中可能含有 Gemini API 认证变量。" -ForegroundColor Yellow
                    $hasWarning = $true
                }
                Write-Host ("  " + $path) -ForegroundColor Yellow
                Write-Host "  如果你选择账号登录但仍然走 API，优先检查这个文件。"
            }
        }
    }
}

function Show-Status {
    Write-Title "环境检查"

    Write-Host ("脚本目录：" + $ToolRoot)
    Write-Host ("当前目录：" + (Get-Location).ProviderPath)
    Write-Host ("临时代理：" + $ProxyUrl)
    Write-Host ""

    Write-Host "认证变量：" -ForegroundColor Yellow
    foreach ($name in $AuthVars) {
        Write-Host ("  " + (Get-EnvState $name))
    }

    Write-Host ""
    Write-Host "代理变量：" -ForegroundColor Yellow
    foreach ($name in @("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY")) {
        Write-Host ("  " + (Get-EnvState $name))
    }

    Write-Host ""
    $launcher = Get-GeminiLauncher
    if ($launcher) {
        Write-Host ("Gemini 启动器：已找到 - " + $launcher.Display) -ForegroundColor Green
    } else {
        Write-Host "Gemini 启动器：未找到" -ForegroundColor Red
    }

    Test-EnvFileWarning
}

function Start-GeminiWithAuthMode {
    param(
        [ValidateSet("account", "api-once", "normal", "prompt")]
        [string]$RunMode,

        [string]$PromptText = ""
    )

    $allVars = $ProxyVars + $AuthVars
    $backup = Save-ProcessEnv -Names $allVars

    try {
        Set-TemporaryProxy

        if ($RunMode -eq "account") {
            Clear-AllAuthVars

            Write-Title "Google 账号登录模式"
            Write-Host "已清除 Process 和 User 层面的 API Key 认证变量。" -ForegroundColor Green
            Write-Host ""
            Write-Host "接下来如果出现认证菜单，请选择：Sign in with Google / Login with Google"
            Write-Host "如果已经进入聊天界面，输入：/auth"
            Write-Host "如果提示 Press R to restart，请按 R。"
            Write-Host ""
            Test-EnvFileWarning
            Pause-Here

            Invoke-GeminiLauncher
            return
        }

        if ($RunMode -eq "api-once") {
            Clear-ProcessAuthVars

            Write-Title "临时 API Key 模式"
            Write-Host "API Key 只在这一次运行中生效，不会保存到 Windows 用户环境变量。" -ForegroundColor Yellow
            $secure = Read-Host "请粘贴 GEMINI_API_KEY（输入时不显示）" -AsSecureString
            $plain = Get-PlainTextFromSecureString $secure

            if ([string]::IsNullOrWhiteSpace($plain)) {
                Write-Host "未输入 API Key，已取消。" -ForegroundColor Yellow
                return
            }

            [Environment]::SetEnvironmentVariable("GEMINI_API_KEY", $plain, "Process")
            [Environment]::SetEnvironmentVariable("GOOGLE_API_KEY", $null, "Process")
            [Environment]::SetEnvironmentVariable("GOOGLE_GENAI_USE_VERTEXAI", $null, "Process")
            Remove-Variable plain -ErrorAction SilentlyContinue

            Invoke-GeminiLauncher
            return
        }

        if ($RunMode -eq "prompt") {
            if ([string]::IsNullOrWhiteSpace($PromptText)) {
                $PromptText = Read-Host '请输入问题，脚本会执行 gemini -p "你的问题"'
            }

            if ([string]::IsNullOrWhiteSpace($PromptText)) {
                Write-Host "问题为空，已取消。" -ForegroundColor Yellow
                return
            }

            $finalPrompt = "请用中文回答。先给结论，再给步骤。$PromptText"
            Invoke-GeminiLauncher -GeminiArgs @("-p", $finalPrompt)
            return
        }

        Write-Title "普通启动"
        Write-Host "保留当前认证方式，只临时设置代理。" -ForegroundColor Green
        Invoke-GeminiLauncher
    }
    finally {
        Restore-ProcessEnv -Backup $backup -Names $allVars
        Write-Host ""
        Write-Host "已恢复本窗口启动前的临时环境变量。" -ForegroundColor DarkGray
    }
}

function Save-ApiKeyToUserEnvironment {
    Write-Title "保存 API Key 到用户环境变量"

    Write-Host "注意：保存后，新开的 PowerShell 可能默认走 API Key 登录。" -ForegroundColor Yellow
    Write-Host "日常更推荐账号登录；只有你确定经常用 API 时才保存。"
    $confirm = Read-Host "确认保存请输入 YES"

    if ($confirm -ne "YES") {
        Write-Host "已取消。"
        return
    }

    $secure = Read-Host "请粘贴 GEMINI_API_KEY（输入时不显示）" -AsSecureString
    $plain = Get-PlainTextFromSecureString $secure

    if ([string]::IsNullOrWhiteSpace($plain)) {
        Write-Host "未输入 API Key，已取消。" -ForegroundColor Yellow
        return
    }

    [Environment]::SetEnvironmentVariable("GEMINI_API_KEY", $plain, "User")
    [Environment]::SetEnvironmentVariable("GOOGLE_API_KEY", $null, "User")
    [Environment]::SetEnvironmentVariable("GOOGLE_GENAI_USE_VERTEXAI", $null, "User")
    Remove-Variable plain -ErrorAction SilentlyContinue

    Write-Host "已保存 GEMINI_API_KEY 到 Windows 用户环境变量。" -ForegroundColor Green
    Write-Host "建议关闭并重新打开 PowerShell 后使用。"
}

function Remove-SavedApiAuth {
    Write-Title "删除保存的 Gemini API 认证变量"

    Clear-AllAuthVars

    Write-Host "已删除 User 层面的 Gemini API 认证变量，并清空当前进程变量。" -ForegroundColor Green
    Write-Host "建议关闭旧 PowerShell 窗口，重新打开后再试。"
    Test-EnvFileWarning
}

function Show-Tips {
    Write-Title "常用命令"

    Write-Host "进入交互模式："
    Write-Host '  gemini'
    Write-Host ""
    Write-Host "单次提问："
    Write-Host '  gemini -p "请用中文回答。你的问题"'
    Write-Host ""
    Write-Host "认证切换："
    Write-Host "  /auth"
    Write-Host ""
    Write-Host "模型切换："
    Write-Host "  /model"
    Write-Host "  日常优先：gemini-2.5-flash / gemini-2.5-flash-lite"
    Write-Host ""
    Write-Host "退出："
    Write-Host "  /quit 或 Ctrl + C"
}

function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " Gemini CLI 懒人启动器 / 登录管理器 v3" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host ("目录：" + $ToolRoot)
        Write-Host ("代理：仅运行期间临时使用 " + $ProxyUrl)
        Write-Host ""
        Write-Host "1. Google 账号登录启动 Gemini CLI"
        Write-Host "2. 临时 API Key 启动一次，不保存"
        Write-Host "3. 普通启动，保留当前认证方式"
        Write-Host "4. 单次提问：gemini -p"
        Write-Host "5. 查看环境状态 / 检查 .env"
        Write-Host "6. 删除已保存的 API 认证变量"
        Write-Host "7. 保存 API Key 到用户环境变量"
        Write-Host "8. 常用命令"
        Write-Host "0. 退出"
        Write-Host ""

        $choice = Read-Host "请选择"

        switch ($choice) {
            "1" { Start-GeminiWithAuthMode -RunMode account; Pause-Here }
            "2" { Start-GeminiWithAuthMode -RunMode "api-once"; Pause-Here }
            "3" { Start-GeminiWithAuthMode -RunMode normal; Pause-Here }
            "4" { Start-GeminiWithAuthMode -RunMode prompt; Pause-Here }
            "5" { Show-Status; Pause-Here }
            "6" { Remove-SavedApiAuth; Pause-Here }
            "7" { Save-ApiKeyToUserEnvironment; Pause-Here }
            "8" { Show-Tips; Pause-Here }
            "0" { return }
            default {
                Write-Host "无效选择。" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    }
}

# =========================
# Entry
# =========================

Set-ConsoleUtf8

switch ($Mode) {
    "account" { Start-GeminiWithAuthMode -RunMode account }
    "api-once" { Start-GeminiWithAuthMode -RunMode "api-once" }
    "normal" { Start-GeminiWithAuthMode -RunMode normal }
    "status" { Show-Status }
    "prompt" { Start-GeminiWithAuthMode -RunMode prompt -PromptText $PromptText }
    default { Show-Menu }
}
