$proxyUrl = "http://127.0.0.1:7897"
$configDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$currentPath = (Get-Location).Path

if ($currentPath -like "C:\Windows*" -or $currentPath -like "C:\Program Files*" -or $currentPath -like "C:\Program Files (x86)*") {
    Write-Host "Refusing to run Gemini CLI in system directory:" -ForegroundColor Red
    Write-Host $currentPath -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please switch to a project folder first, for example:" -ForegroundColor Cyan
    Write-Host 'cd "C:\DIY\Gemini CLI\playground"' -ForegroundColor Cyan
    Write-Host "gemini" -ForegroundColor Cyan
    exit 1
}

$hadHttpProxy  = Test-Path Env:\HTTP_PROXY
$hadHttpsProxy = Test-Path Env:\HTTPS_PROXY
$hadAllProxy   = Test-Path Env:\ALL_PROXY
$hadNoProxy    = Test-Path Env:\NO_PROXY

$oldHttpProxy  = $env:HTTP_PROXY
$oldHttpsProxy = $env:HTTPS_PROXY
$oldAllProxy   = $env:ALL_PROXY
$oldNoProxy    = $env:NO_PROXY

try {
    $env:HTTP_PROXY  = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
    $env:ALL_PROXY   = $proxyUrl

    # 只在 Gemini CLI 运行期间生效。
    # 避免本地地址和常见中国大陆域名被错误代理。
    $env:NO_PROXY = "localhost,127.0.0.1,::1,.local,.lan,.cn"

    Write-Host "Gemini CLI proxy enabled: $proxyUrl" -ForegroundColor Green

    $geminiCmd = Get-Command gemini.cmd -CommandType Application -ErrorAction SilentlyContinue

    if (-not $geminiCmd) {
        Write-Host "Cannot find gemini.cmd. Please check Gemini CLI installation." -ForegroundColor Red
        exit 1
    }

    & $geminiCmd.Source --include-directories $configDir @args
}
finally {
    if ($hadHttpProxy) {
        $env:HTTP_PROXY = $oldHttpProxy
    } else {
        Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue
    }

    if ($hadHttpsProxy) {
        $env:HTTPS_PROXY = $oldHttpsProxy
    } else {
        Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue
    }

    if ($hadAllProxy) {
        $env:ALL_PROXY = $oldAllProxy
    } else {
        Remove-Item Env:\ALL_PROXY -ErrorAction SilentlyContinue
    }

    if ($hadNoProxy) {
        $env:NO_PROXY = $oldNoProxy
    } else {
        Remove-Item Env:\NO_PROXY -ErrorAction SilentlyContinue
    }

    Write-Host "Gemini CLI proxy restored." -ForegroundColor Yellow
}
