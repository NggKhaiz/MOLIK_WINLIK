<#
	.SYNOPSIS
	Sophia Ultra Optimizer — ONLINE LAUNCHER (dùng như winutil, KHÔNG cần tải/cài tool)

	.DESCRIPTION
	Gõ 1 lệnh trong PowerShell là tool chạy ngay trong bộ nhớ, không tải file về máy:

	  irm "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1" | iex

	Hoặc link ngắn qua GitHub Pages (nếu đã bật):

	  irm "nggkhaiz.github.io/MOLIK_WINLIK/win.ps1" | iex

	Script siêu nhẹ này chỉ làm 2 việc: tự nâng quyền Admin (mở cửa sổ mới, không đóng shell của bạn),
	rồi nạp bản Sophia-Ultra-Portable.ps1 mới nhất từ GitHub của bạn vào bộ nhớ và chạy.
	Không cài đặt, không giải nén, không để lại file tool nào trên máy.

	.EXAMPLE
	& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1"))) -Mode HardcoreGaming
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
	[ValidateSet("EmulatorFarm","HardcoreGaming","Workstation","LowSpec","SophiaStandard","GodMode")]
	[string]$Mode = "EmulatorFarm",
	[switch]$Menu,
	[switch]$Smart,
	[switch]$SelfTest
)

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$WinUrl = "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1"
$PortableUrl = "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Portable.ps1"

# ── Tự nâng quyền Admin (giữ nguyên shell hiện tại như winutil) ───────────────
try
{
	$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Host "  Sophia Ultra Optimizer cần quyền Admin — đang mở cửa sổ PowerShell mới (UAC)..." -ForegroundColor Yellow
		$cmd = "& ([scriptblock]::Create((Invoke-RestMethod '$WinUrl'))) -Mode $Mode"
		if ($Menu) { $cmd += " -Menu" }
		if ($Smart) { $cmd += " -Smart" }
		if ($SelfTest) { $cmd += " -SelfTest" }
		Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $cmd) -Verb RunAs
		return
	}
} catch {}

# ── Nạp Portable vào bộ nhớ và chạy (không ghi file) ──────────────────────────
try
{
	Write-Host "  Đang nạp Sophia Ultra Optimizer (online, không cần cài đặt)..." -ForegroundColor Cyan
	$code = Invoke-RestMethod -Uri $PortableUrl -UseBasicParsing
	if ($code -is [byte[]]) { $code = [System.Text.Encoding]::UTF8.GetString($code) }
	$code = ([string]$code).TrimStart([char]0xFEFF)
	$scriptBlock = [scriptblock]::Create($code)
	& $scriptBlock -Mode $Mode -Menu:$Menu -Smart:$Smart -SelfTest:$SelfTest
}
catch
{
	Write-Host "  [X] Không nạp được bản online: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host "  Kiểm tra mạng rồi thử lại lệnh irm ở trên. Máy đã có sẵn file thì chạy .\Sophia-Ultra-Portable.ps1" -ForegroundColor Yellow
}
