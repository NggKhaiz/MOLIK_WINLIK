<#
	.SYNOPSIS
	MOLIK WINLIK - ONLINE LAUNCHER (dung nhu winutil, khong can cai dat)

	.DESCRIPTION
	Go 1 lenh trong PowerShell la tool chay ngay:

	  irm "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1" | iex

	Co che 2 lop de vuot Antivirus/AMSI mot cach minh bach:
	  1) Thu nap thang vao bo nho (irm | iex nhu winutil).
	  2) Neu Antivirus chan chay trong bo nho, tu dong tai 1 file loi vao
	     %TEMP%\MOLIK_WINLIK, kiem tra SHA256 voi file .sha256 tren repo,
	     Unblock-File roi chay file do (ban da chu dong go lenh nen viec nay
	     tuong duong double-click file .ps1 ban tu tai ve).
	Khong cai dat, khong giai nen, khong sua ExecutionPolicy cua may.

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
$HashUrl = "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Portable.ps1.sha256"

# Self-elevate (giu nguyen shell hien tai nhu winutil)
try
{
	$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Host "  MOLIK WINLIK can quyen Admin - dang mo cua so PowerShell moi (UAC)..." -ForegroundColor Yellow
		$cmd = "& ([scriptblock]::Create((Invoke-RestMethod '$WinUrl'))) -Mode $Mode"
		if ($Menu) { $cmd += " -Menu" }
		if ($Smart) { $cmd += " -Smart" }
		if ($SelfTest) { $cmd += " -SelfTest" }
		Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $cmd) -Verb RunAs
		return
	}
} catch {}

# Lop 1: nap thang vao bo nho
$inMemoryFailed = $false
try
{
	Write-Host "  Dang nap MOLIK WINLIK (online, khong can cai dat)..." -ForegroundColor Cyan
	$code = Invoke-RestMethod -Uri $PortableUrl -UseBasicParsing
	if ($code -is [byte[]]) { $code = [System.Text.Encoding]::UTF8.GetString($code) }
	$code = ([string]$code).TrimStart([char]0xFEFF)
	$scriptBlock = [scriptblock]::Create($code)
	& $scriptBlock -Mode $Mode -Menu:$Menu -Smart:$Smart -SelfTest:$SelfTest
}
catch
{
	$inMemoryFailed = $true
	Write-Host "  [!] Khong chay duoc trong bo nho: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Lop 2: fallback file tam + SHA256 (AV/AMSI chan bo nho thi dung cach nay)
if ($inMemoryFailed)
{
	try
	{
		Write-Host "  Dang chuyen sang che do file tam an toan (%TEMP%\MOLIK_WINLIK)..." -ForegroundColor Cyan
		$dir = Join-Path $env:TEMP "MOLIK_WINLIK"
		New-Item -Path $dir -ItemType Directory -Force | Out-Null
		$file = Join-Path $dir "MolikWinlik-Core.ps1"
		Invoke-WebRequest -Uri $PortableUrl -OutFile $file -UseBasicParsing -ErrorAction Stop

		try
		{
			$expected = ((Invoke-RestMethod -Uri $HashUrl -UseBasicParsing) -split '\s+')[0].Trim().ToLower()
			$actual = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLower()
			if ($expected -and ($expected -ne $actual))
			{
				Write-Host "  [X] SHA256 KHONG KHOP (expected $expected / actual $actual) - dung lai de an toan!" -ForegroundColor Red
				return
			}
			Write-Host "  [OK] SHA256 khop: $actual" -ForegroundColor Green
		}
		catch { Write-Host "  (Bo qua kiem tra SHA256: khong tai duoc file hash)" -ForegroundColor DarkGray }

		Unblock-File -Path $file -ErrorAction SilentlyContinue
		& $file -Mode $Mode -Menu:$Menu -Smart:$Smart -SelfTest:$SelfTest
	}
	catch
	{
		Write-Host "  [X] Ca 2 cach deu that bai: $($_.Exception.Message)" -ForegroundColor Red
		Write-Host "  Neu Antivirus van chan: tai Sophia-1Click.bat tu repo NggKhaiz/MOLIK_WINLIK roi double-click," -ForegroundColor Yellow
		Write-Host "  hoac tai Sophia-Ultra-Portable.ps1 chay truc tiep. Xem muc Security trong Optimizer/README.md" -ForegroundColor Yellow
	}
}
