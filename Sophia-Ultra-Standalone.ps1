<#
	.SYNOPSIS
	Sophia Ultra Optimizer — Single-file launcher (irm | iex)

	.DESCRIPTION
	Chạy 1 lệnh từ bất kỳ máy Windows nào, không cần clone repo thủ công:
	  irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Standalone.ps1 | iex
	File này tự tải bản Sophia Script + Ultra Optimizer mới nhất từ GitHub của bạn,
	giải nén vào %TEMP%\SophiaUltraOptimizer và mở giao diện tick-chọn CLI.
	Nếu máy đã có sẵn Sophia-Optimizer.ps1 ở thư mục hiện tại thì chạy trực tiếp, không tải lại.

	.EXAMPLE
	& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Standalone.ps1'))) -Mode HardcoreGaming
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
	[ValidateSet("EmulatorFarm","HardcoreGaming","Workstation","LowSpec","SophiaStandard","GodMode")]
	[string]$Mode = "EmulatorFarm",
	[switch]$Apply,
	[switch]$Yes
)

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# Self-elevate
try
{
	$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Host "  [!] Đang nâng quyền Administrator..." -ForegroundColor Yellow
		$cmd = "irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Standalone.ps1 | iex"
		Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $cmd) -Verb RunAs
		return
	}
} catch {}

# 1) Đã ở trong repo? Chạy trực tiếp.
$localLauncher = Join-Path (Get-Location).Path "Sophia-Optimizer.ps1"
if (Test-Path $localLauncher)
{
	& $localLauncher -Mode $Mode -Apply:$Apply -Yes:$Yes
	return
}

# 2) Tải repo mới nhất
$workDir = Join-Path $env:TEMP "SophiaUltraOptimizer"
$zipPath = Join-Path $env:TEMP "SophiaUltraOptimizer.zip"
$zipUrl  = "https://codeload.github.com/NggKhaiz/Sophia-Script-for-Windows/zip/refs/heads/main"

Write-Host "  Đang tải Sophia Ultra Optimizer từ GitHub (NggKhaiz/Sophia-Script-for-Windows)..." -ForegroundColor Cyan
try
{
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
	if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
	Expand-Archive -Path $zipPath -DestinationPath $workDir -Force
	$root = Get-ChildItem $workDir -Directory | Select-Object -First 1
	$launcher = Join-Path $root.FullName "Sophia-Optimizer.ps1"
	if (Test-Path $launcher)
	{
		Push-Location $root.FullName
		try { & $launcher -Mode $Mode -Apply:$Apply -Yes:$Yes } finally { Pop-Location }
	}
	else { Write-Host "  [!] Không tìm thấy Sophia-Optimizer.ps1 trong gói đã tải." -ForegroundColor Red }
}
catch
{
	Write-Host "  [X] Tải thất bại: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host "  Hãy clone thủ công: git clone https://github.com/NggKhaiz/Sophia-Script-for-Windows rồi chạy .\Sophia-Optimizer.ps1" -ForegroundColor Yellow
}
