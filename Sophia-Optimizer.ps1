<#
	.SYNOPSIS
	Sophia Ultra Optimizer — Interactive Tick-Select CLI (Tối ưu sâu Windows)

	.DESCRIPTION
	Tool tick-chọn [✓]/[ ] tối ưu Windows cực sâu cho Treo Giả Lập 24/7, Hardcore Gaming,
	Workstation/Streaming, Low-Spec và Sophia Standard/Privacy. Xây trên Sophia Script gốc
	(src/Sophia_Script_for_Windows_*) + 112 tweak kernel/BCD/MSI/timer/GPU/network riêng (Optimizer/).

	.EXAMPLE
	.\Sophia-Optimizer.ps1
	# Mở giao diện tick-chọn (mặc định tick sẵn Mode Treo Giả Lập)

	.EXAMPLE
	.\Sophia-Optimizer.ps1 -Mode HardcoreGaming
	.\Sophia-Optimizer.ps1 -Mode EmulatorFarm -Apply -Yes
	.\Sophia-Optimizer.ps1 -ListModes
	.\Sophia-Optimizer.ps1 -ListTweaks
	.\Sophia-Optimizer.ps1 -PurgeRAM
	.\Sophia-Optimizer.ps1 -BoostEmulators
	.\Sophia-Optimizer.ps1 -RestoreDefaults -Yes

	.NOTES
	Yêu cầu: Windows 10/11, PowerShell 5.1+ (hoặc PS7), chạy với quyền Administrator.
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
	[ValidateSet("EmulatorFarm","HardcoreGaming","Workstation","LowSpec","SophiaStandard","GodMode")]
	[string]$Mode = "EmulatorFarm",

	[switch]$Apply,
	[switch]$Yes,
	[switch]$NoBackup,
	[switch]$ListModes,
	[switch]$ListTweaks,
	[switch]$PurgeRAM,
	[switch]$BoostEmulators,
	[switch]$RestoreDefaults,
	[switch]$Benchmark,
	[string]$BenchmarkLabel = "Manual",
	[switch]$CompareBenchmarks,
	[switch]$DryRun,
	[switch]$ExportReport,
	[string]$Search = ""
)

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ── Self-elevate to Administrator ─────────────────────────────────────────────
try
{
	$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Host "  [!] Tool cần quyền Administrator — đang tự nâng quyền (UAC)..." -ForegroundColor Yellow
		$argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
		if ($Mode) { $argList += @("-Mode", $Mode) }
		if ($Apply) { $argList += "-Apply" }
		if ($Yes) { $argList += "-Yes" }
		if ($Benchmark) { $argList += "-Benchmark" }
		if ($DryRun) { $argList += "-DryRun" }
		if ($PurgeRAM) { $argList += "-PurgeRAM" }
		if ($BoostEmulators) { $argList += "-BoostEmulators" }
		if ($RestoreDefaults) { $argList += "-RestoreDefaults" }
		Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs
		exit
	}
} catch {}

$RepoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# ── Load engine ───────────────────────────────────────────────────────────────
$engineFiles = @(
	"Optimizer\Core\HardwareDetector.ps1",
	"Optimizer\Core\RamCleanerDaemon.ps1",
	"Optimizer\Core\ExtremeEngine.ps1",
	"Optimizer\Core\Benchmark.ps1",
	"Optimizer\Core\BackupRestore.ps1",
	"Optimizer\Core\SophiaBridge.ps1",
	"Optimizer\Catalog\TweaksCatalog.ps1",
	"Optimizer\UI\InteractiveCLI.ps1"
)
foreach ($rel in $engineFiles)
{
	$full = Join-Path $RepoRoot $rel
	if (Test-Path $full) { . $full }
	else { Write-Host "  [!] Thiếu file engine: $rel" -ForegroundColor Red }
}

$catalog = Get-SophiaTweaksCatalog
$modes = Get-SophiaOptimizationModes
$snapshot = $null
try { $snapshot = Get-SophiaSystemSnapshot } catch {}

# Bridge vào module Sophia gốc (không chặn bởi InitialActions/LGPO/UBR)
try { Initialize-SophiaNativeModule -RepoRoot $RepoRoot | Out-Null } catch {}

if ($ListModes)
{
	Write-Host ""
	$modes | ForEach-Object { Write-Host ("  [{0}] {1} {2} — {3}" -f $_.Key, $_.Icon, $_.Name, $_.Sub) -ForegroundColor Cyan; Write-Host "      $($_.Description)" -ForegroundColor Gray }
	return
}
if ($ListTweaks)
{
	$list = if ($Search) { $catalog | Where-Object { $_.Name -match $Search -or $_.Id -match $Search -or $_.Category -match $Search } } else { $catalog }
	$list | Group-Object Category | ForEach-Object {
		Write-Host ""; Write-Host "  $($_.Name) ($($_.Count))" -ForegroundColor Magenta
		$_.Group | ForEach-Object { Write-Host ("    {0} [{1,-8}] {2}" -f $_.Id, $_.Risk, $_.Name) }
	}
	Write-Host ""; Write-Host "  Tổng: $($list.Count)/$($catalog.Count) tweak" -ForegroundColor Cyan
	return
}
if ($ExportReport)
{
	$reportPath = Join-Path $RepoRoot ("Sophia-System-Report-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
	$reportObj = @{ Snapshot = $snapshot; Modes = $modes; TweakCount = $catalog.Count; Catalog = @($catalog | Select-Object Id, Name, Category, Risk, Modes, Detail) }
	$reportObj | ConvertTo-Json -Depth 6 | Set-Content $reportPath -Encoding UTF8
	Write-Host "  [✓] Đã xuất báo cáo: $reportPath" -ForegroundColor Green
	return
}
if ($Benchmark)
{
	Invoke-SophiaBenchmark -Label $BenchmarkLabel | Out-Null
	return
}
if ($CompareBenchmarks)
{
	Compare-SophiaBenchmarks
	return
}
if ($PurgeRAM)
{
	Invoke-SophiaRamPurge
	return
}
if ($BoostEmulators)
{
	Invoke-EmulatorAutoBooster
	return
}
if ($RestoreDefaults)
{
	if (-not $Yes)
	{
		$confirm = Read-Host "  Khôi phục MẶC ĐỊNH toàn bộ $($catalog.Count) tweak? Gõ 'yes' để xác nhận"
		if ($confirm -ne 'yes') { Write-Host "  Đã hủy."; return }
	}
	Invoke-SophiaRestoreTweaks -Catalog $catalog
	return
}
if ($Apply)
{
	$ids = Get-SophiaModeTweakIds -ModeKey $Mode -Catalog $catalog
	$modeObj = $modes | Where-Object Key -eq $Mode | Select-Object -First 1
	Write-Host "  Mode: $($modeObj.Icon) $($modeObj.Name) — sẽ áp dụng $($ids.Count) tweak." -ForegroundColor Yellow
	if (-not $Yes)
	{
		$confirm = Read-Host "  Tiếp tục? (Y/N)"
		if ($confirm -notmatch '^[Yy]') { Write-Host "  Đã hủy. Chạy không có -Apply để mở giao diện tick-chọn."; return }
	}
	if ($DryRun)
	{
		Write-Host "  [DRY-RUN] $($ids.Count) tweak sẽ được áp dụng (chưa thực thi):" -ForegroundColor Cyan
		$catalog | Where-Object { $ids -contains $_.Id } | ForEach-Object { Write-Host ("    [{0}] [{1}] {2}" -f $_.Id, $_.Risk, $_.Name) }
		return
	}
	Invoke-SophiaSelectedTweaks -Catalog $catalog -SelectedIds $ids -SkipBackup:$NoBackup -Force:$Yes
	return
}

# ── Interactive tick-select UI ────────────────────────────────────────────────
Show-SophiaOptimizerUI -Catalog $catalog -Snapshot $snapshot -InitialMode $Mode
