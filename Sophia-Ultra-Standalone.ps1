<#
	.SYNOPSIS
	Sophia Ultra Optimizer — Chạy NGAY không cần cài đặt (tải bản Portable 1 file vào %TEMP% rồi chạy)

	.DESCRIPTION
	  irm https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Standalone.ps1 | iex
	Script này chỉ tải đúng 1 file Sophia-Ultra-Portable.ps1 (141KB, chứa toàn bộ engine)
	vào thư mục tạm %TEMP%, chạy nó với tham số của bạn, KHÔNG cài đặt, KHÔNG giải nén,
	KHÔNG cần clone repo. File tạm có thể xóa bất cứ lúc nào.
	Nếu thư mục hiện tại đã có Sophia-Ultra-Portable.ps1 / Sophia-Optimizer.ps1 thì chạy luôn bản local.

	.EXAMPLE
	& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Standalone.ps1'))) -Mode HardcoreGaming
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
	[ValidateSet("EmulatorFarm","HardcoreGaming","Workstation","LowSpec","SophiaStandard","GodMode")]
	[string]$Mode = "EmulatorFarm",
	[switch]$Apply,
	[switch]$Yes,
	[switch]$Menu,
	[switch]$Benchmark
)

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# 1) Có sẵn bản local? Chạy luôn, khỏi tải.
foreach ($localName in @("Sophia-Ultra-Portable.ps1", "Sophia-Optimizer.ps1"))
{
	$local = Join-Path (Get-Location).Path $localName
	if (Test-Path $local)
	{
		& $local -Mode $Mode -Apply:$Apply -Yes:$Yes -Menu:$Menu -Benchmark:$Benchmark
		return
	}
}

# 2) Tải đúng 1 file Portable vào TEMP rồi chạy (không cài đặt)
$portablePath = Join-Path $env:TEMP "Sophia-Ultra-Portable.ps1"
$portableUrl = "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Portable.ps1"
Write-Host "  Đang tải Sophia Ultra Optimizer PORTABLE (1 file, không cần cài đặt)..." -ForegroundColor Cyan
try
{
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Invoke-WebRequest -Uri $portableUrl -OutFile $portablePath -UseBasicParsing -ErrorAction Stop
	Write-Host "  [✓] Đã tải: $portablePath — đang khởi chạy..." -ForegroundColor Green
	& $portablePath -Mode $Mode -Apply:$Apply -Yes:$Yes -Menu:$Menu -Benchmark:$Benchmark
}
catch
{
	Write-Host "  [X] Tải thất bại: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host "  Cách khác: tải thủ công 1 file Sophia-Ultra-Portable.ps1 từ https://github.com/NggKhaiz/MOLIK_WINLIK rồi chạy .\Sophia-Ultra-Portable.ps1" -ForegroundColor Yellow
}
