<#
	.SYNOPSIS
	MOLIK WINLIK — Interactive Tick-Select CLI (Tối ưu sâu Windows)

	.DESCRIPTION
	Tool tick-chọn [✓]/[ ] tối ưu Windows cực sâu cho Treo Giả Lập 24/7, Hardcore Gaming,
	Workstation/Streaming, Low-Spec và MOLIK Standard/Privacy. Xây trên bản gốc upstream
	(src/Sophia_Script_for_Windows_*) + catalog tweak kernel/BCD/MSI/timer/GPU/network
	riêng trong Optimizer/ (xem -ListTweaks để biết tổng số hiện tại).

	MOLIK WINLIK chạy OFFLINE 100%: không tải code khi chạy. Cách chạy chuẩn là
	double-click MOLIK_WINLIK.bat (tự xin quyền Administrator). File này cũng tự
	nâng quyền khi thao tác cần Admin; các lệnh chỉ-đọc (-ListTweaks, -SelfTest...)
	chạy ngay không cần UAC.

	.EXAMPLE
	.\MolikWinlik.ps1
	# Mở giao diện tick-chọn (mặc định tick sẵn Mode Treo Giả Lập)

	.EXAMPLE
	.\MolikWinlik.ps1 -Mode HardcoreGaming
	.\MolikWinlik.ps1 -Mode EmulatorFarm -Apply -Yes
	.\MolikWinlik.ps1 -ListModes
	.\MolikWinlik.ps1 -ListTweaks
	.\MolikWinlik.ps1 -PurgeRAM
	.\MolikWinlik.ps1 -BoostEmulators
	.\MolikWinlik.ps1 -RestoreDefaults -Yes

	.NOTES
	Yêu cầu: Windows 10/11, PowerShell 5.1+ (hoặc PS7). Nên chạy qua
	MOLIK_WINLIK.bat để ExecutionPolicy chỉ được Bypass cho đúng tiến trình này.
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
	[string]$Profile = "",
	[switch]$Menu,
	[switch]$Smart,
	[switch]$Plan,
	[switch]$ListApps,
	[string]$InstallApps = "",
	[switch]$AppsMenu,
	[switch]$SelfTest,
	[switch]$ExportReport,
	[switch]$LoadNativeSophia,
	[switch]$Version,
	[switch]$ListPresets,
	[string]$Preset = "",
	[string]$ApplyIds = "",
	[string]$RestoreIds = "",
	[string]$Status = "__none__",
	[switch]$BackupOnly,
	[switch]$RestoreBackup,
	[switch]$Doctor,
	[switch]$UndoLast,
	[switch]$ListBackups,
	[switch]$ListProfiles,
	[string]$Search = ""
)

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$Global:MolikWinlikVersion = "3.2.0"

# ── Self-elevate to Administrator (chi khi thao tac that su can Admin) ───────
# Cac lenh chi-doc duoi day chay ngay khong can UAC cho khoi dong nhanh:
$readOnlyRequest = ($ListModes -or $ListTweaks -or $ListApps -or $SelfTest -or $Plan -or $CompareBenchmarks -or $Version -or $ListPresets -or $Doctor -or $ListBackups -or $ListProfiles -or ($Status -ne "__none__"))
if (-not $readOnlyRequest)
{
	try
	{
		$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
		{
			if (-not $PSCommandPath)
			{
				Write-Host "  [X] MOLIK WINLIK la ban OFFLINE: hay chay MOLIK_WINLIK.bat (double-click, tu xin Admin)" -ForegroundColor Red
				Write-Host "      hoac chay file MolikWinlik-Portable.ps1 / MolikWinlik.ps1 tu o dia." -ForegroundColor Yellow
				return
			}
			Write-Host "  [!] Tool cần quyền Administrator — đang tự nâng quyền (UAC)..." -ForegroundColor Yellow
			$argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
			if ($Mode) { $argList += @("-Mode", $Mode) }
			if ($Apply) { $argList += "-Apply" }
			if ($Yes) { $argList += "-Yes" }
			if ($NoBackup) { $argList += "-NoBackup" }
			if ($Benchmark) { $argList += "-Benchmark" }
			if ($BenchmarkLabel -and $BenchmarkLabel -ne "Manual") { $argList += @("-BenchmarkLabel", "`"$BenchmarkLabel`"") }
			if ($DryRun) { $argList += "-DryRun" }
			if ($PurgeRAM) { $argList += "-PurgeRAM" }
			if ($Profile) { $argList += @("-Profile", "`"$Profile`"") }
			if ($Menu) { $argList += "-Menu" }
			if ($Smart) { $argList += "-Smart" }
			if ($Plan) { $argList += "-Plan" }
			if ($SelfTest) { $argList += "-SelfTest" }
			if ($ListApps) { $argList += "-ListApps" }
			if ($AppsMenu) { $argList += "-AppsMenu" }
			if ($InstallApps) { $argList += @("-InstallApps", "`"$InstallApps`"") }
			if ($BoostEmulators) { $argList += "-BoostEmulators" }
			if ($RestoreDefaults) { $argList += "-RestoreDefaults" }
			if ($ExportReport) { $argList += "-ExportReport" }
			if ($LoadNativeSophia) { $argList += "-LoadNativeSophia" }
			if ($Preset) { $argList += @("-Preset", "`"$Preset`"") }
			if ($ApplyIds) { $argList += @("-ApplyIds", "`"$ApplyIds`"") }
			if ($RestoreIds) { $argList += @("-RestoreIds", "`"$RestoreIds`"") }
			if ($BackupOnly) { $argList += "-BackupOnly" }
			if ($RestoreBackup) { $argList += "-RestoreBackup" }
			if ($UndoLast) { $argList += "-UndoLast" }
			if ($Search) { $argList += @("-Search", "`"$Search`"") }
			Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs
			return
		}
	} catch {}
}

$RepoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# ── Load engine ───────────────────────────────────────────────────────────────
$engineFiles = @(
	"Optimizer\Core\HardwareDetector.ps1",
	"Optimizer\Core\RamCleanerDaemon.ps1",
	"Optimizer\Core\ExtremeEngine.ps1",
	"Optimizer\Core\Benchmark.ps1",
	"Optimizer\Core\PlanEngine.ps1",
	"Optimizer\Core\SmartAdvisor.ps1",
	"Optimizer\Core\Presets.ps1",
	"Optimizer\Core\ReportEngine.ps1",
	"Optimizer\Core\WinUtilBridge.ps1",
	"Optimizer\Core\AppInstaller.ps1",
	"Optimizer\Data\WinUtilTweaks.ps1",
	"Optimizer\Data\WinUtilApps.ps1",
	"Optimizer\Core\SelfTest.ps1",
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

# Bridge vao module goc upstream la TUY CHON (mac dinh TAT de khoi dong nhanh va
# tranh import module lon khong can thiet). Bat bang -LoadNativeSophia khi can.
if ($LoadNativeSophia)
{
	try { Initialize-SophiaNativeModule -RepoRoot $RepoRoot | Out-Null } catch {}
}

$smartRec = $null
if (Get-Command Get-SophiaSmartRecommendation -ErrorAction SilentlyContinue)
{
	try { $smartRec = Get-SophiaSmartRecommendation -Snapshot $snapshot -Catalog $catalog } catch {}
}
if ($Smart -and $smartRec)
{
	$Mode = $smartRec.Mode
	Write-Host "  Smart Advisor: Mode $Mode" -ForegroundColor Green
	$smartRec.Reasons | ForEach-Object { Write-Host "      - $_" -ForegroundColor Cyan }
	$smartRec.Warnings | ForEach-Object { Write-Host "      [!] $_" -ForegroundColor Yellow }
}
if ($Plan)
{
	$ids = Get-SophiaModeTweakIds -ModeKey $Mode -Catalog $catalog
	if ($Smart -and $smartRec) { $ids = @($ids + $smartRec.ExtraIds | Select-Object -Unique) }
	$planObj = Get-SophiaOptimizationPlan -Catalog $catalog -SelectedIds $ids -Snapshot $snapshot
	Show-SophiaOptimizationPlan -Plan $planObj -Title "KẾ HOẠCH SIÊU SÂU - Mode $Mode (chưa áp dụng)"
	Write-Host "  Để thực thi: chạy lại với -Apply (và -Smart nếu muốn Smart Advisor chọn hộ)." -ForegroundColor Yellow
	return
}
if ($SelfTest)
{
	Test-SophiaOptimizerHealth -RepoRoot $RepoRoot -Catalog $catalog | Out-Null
	return
}
if ($Version)
{
	Write-Host "  MOLIK WINLIK v$Global:MolikWinlikVersion by @nggkhaiz - OFFLINE optimizer" -ForegroundColor Cyan
	Write-Host "  Catalog: $($catalog.Count) tweak | 6 Mode | $(if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue) { (Get-MolikPresets).Count } else { 0 }) Preset | 239 app (winutil data, winget)" -ForegroundColor Gray
	return
}
if ($ListPresets)
{
	Write-Host ""
	if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue)
	{
		foreach ($preset in (Get-MolikPresets))
		{
			$resolved = Resolve-MolikPreset -Preset $preset -Catalog $catalog
			Write-Host ("  [{0}] {1} {2} ({3} tweak, Mode {4})" -f $preset.Name, $preset.Icon, $preset.Title, $resolved.Count, $preset.Mode) -ForegroundColor Cyan
			Write-Host "      $($preset.Description)" -ForegroundColor Gray
		}
		Write-Host ""
		Write-Host "  Dung: .\MolikWinlik.ps1 -Preset <ten> -Plan   hoac   -Preset <ten> -Apply -Yes" -ForegroundColor Yellow
	}
	return
}
if ($Status -ne "__none__")
{
	$statusIds = @($Status -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
	if (Get-Command Get-MolikAppliedStatus -ErrorAction SilentlyContinue)
	{
		$map = Get-MolikAppliedStatus -Catalog $catalog -Ids $statusIds
		$applied = @($map.Keys | Where-Object { $map[$_] }).Count
		$catalog | Where-Object { $map.ContainsKey($_.Id) } | Group-Object Category | ForEach-Object {
			Write-Host ""; Write-Host "  $($_.Name)" -ForegroundColor Magenta
			$_.Group | ForEach-Object { $mark = if ($map[$_.Id]) { "[DA AP ]" } else { "[CHUA  ]" }; Write-Host ("    {0} {1} [{2}] {3}" -f $mark, $_.Id, $_.Risk, $_.Name) }
		}
		Write-Host ""; Write-Host "  Tong: $applied/$($map.Count) tweak dang o trang thai DA AP DUNG" -ForegroundColor Cyan
	}
	return
}
if ($BackupOnly)
{
	if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue) { New-SophiaSystemBackup -Label "Manual MOLIK WINLIK backup" | Out-Null }
	return
}
if ($RestoreBackup)
{
	if (-not $Yes) { $c = Read-Host "  Khoi phuc Registry/BCD tu backup moi nhat? (Y/N)"; if ($c -notmatch '^[Yy]') { Write-Host "  Da huy."; return } }
	if (Get-Command Restore-SophiaLatestBackup -ErrorAction SilentlyContinue) { Restore-SophiaLatestBackup | Out-Null }
	return
}
if ($Doctor)
{
	if (Get-Command Show-MolikSystemDoctor -ErrorAction SilentlyContinue) { Show-MolikSystemDoctor -Snapshot $snapshot -Catalog $catalog }
	return
}
if ($UndoLast)
{
	if (Get-Command Restore-MolikLastSession -ErrorAction SilentlyContinue) { Restore-MolikLastSession -Catalog $catalog -Force:$Yes | Out-Null }
	return
}
if ($ListBackups)
{
	if (Get-Command Show-MolikBackupList -ErrorAction SilentlyContinue) { Show-MolikBackupList }
	return
}
if ($ListProfiles)
{
	$profileDir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Profiles"
	$profiles = Get-ChildItem -Path $profileDir -Filter "*.json" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
	if (-not $profiles) { Write-Host "  [!] Chưa có Profile nào trong $profileDir (lưu bằng phím S trong giao diện tick-chọn)." -ForegroundColor Yellow }
	else
	{
		Write-Host ""
		Write-Host "  ══════ PROFILES ĐÃ LƯU ($($profiles.Count)) ══════" -ForegroundColor Cyan
		foreach ($pf in $profiles)
		{
			$info = ""
			try { $po = Get-Content $pf.FullName -Raw | ConvertFrom-Json; $info = "Mode $($po.Mode), $($po.TweakIds.Count) tweak, $($po.CreatedAt)" } catch {}
			Write-Host ("  {0}  |  {1}" -f $pf.FullName, $info) -ForegroundColor Gray
		}
		Write-Host "  Áp dụng: .\MolikWinlik.ps1 -Profile <duong-dan-file> -Apply -Yes" -ForegroundColor DarkGray
	}
	return
}
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
	$reportPath = Join-Path $RepoRoot ("MolikWinlik-System-Report-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
	$reportObj = @{ Snapshot = $snapshot; Modes = $modes; TweakCount = $catalog.Count; Catalog = @($catalog | Select-Object Id, Name, Category, Risk, Modes, Detail) }
	$reportObj | ConvertTo-Json -Depth 6 | Set-Content $reportPath -Encoding UTF8
	Write-Host "  [✓] Đã xuất báo cáo JSON: $reportPath" -ForegroundColor Green
	if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue)
	{
		$htmlPath = [System.IO.Path]::ChangeExtension($reportPath, "html")
		Export-MolikHtmlReport -Snapshot $snapshot -Catalog $catalog -Path $htmlPath | Out-Null
	}
	return
}
if ($ListApps)
{
	Get-SophiaAppsCatalog | Group-Object Category | Sort-Object Name | ForEach-Object {
		Write-Host ""; Write-Host "  [$($_.Name)]" -ForegroundColor Magenta
		$_.Group | Sort-Object Name | ForEach-Object { Write-Host ("    {0} ({1})" -f $_.Name, $_.Winget) }
	}
	Write-Host ""; Write-Host "  Tổng: $((Get-SophiaAppsCatalog).Count) ứng dụng (dữ liệu winutil, cài qua winget)" -ForegroundColor Cyan
	return
}
if ($InstallApps)
{
	Install-SophiaApps -Queries @($InstallApps -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
	return
}
if ($AppsMenu)
{
	Show-SophiaAppInstallerMenu
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
if ($Profile)
{
	$profileObj = Get-SophiaSelectionProfile -Path $Profile
	if (-not $profileObj) { return }
	$ids = @($profileObj.TweakIds | ForEach-Object { [string]$_ } | Where-Object { $catalog.Id -contains $_ })
	Write-Host "  Profile: $($ids.Count) tweak (Mode $($profileObj.Mode))" -ForegroundColor Yellow
	if ($DryRun)
	{
		$catalog | Where-Object { $ids -contains $_.Id } | ForEach-Object { Write-Host ("    [{0}] [{1}] {2}" -f $_.Id, $_.Risk, $_.Name) }
		return
	}
	if (-not $Yes)
	{
		$confirm = Read-Host "  Áp dụng Profile này? (Y/N)"
		if ($confirm -notmatch '^[Yy]') { Write-Host "  Đã hủy."; return }
	}
	Invoke-SophiaSelectedTweaks -Catalog $catalog -SelectedIds $ids -SkipBackup:$NoBackup -Force:$Yes -Snapshot $snapshot
	return
}
if ($Preset)
{
	if ($Profile) { Write-Host "  [!] Không dùng đồng thời -Preset và -Profile. Hãy chọn 1 nguồn danh sách tweak." -ForegroundColor Red; return }
	$presetObj = $null
	if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue) { $presetObj = Get-MolikPresets | Where-Object { $_.Name -eq $Preset } | Select-Object -First 1 }
	if (-not $presetObj)
	{
		Write-Host "  [!] Không tìm thấy Preset '$Preset'. Chạy -ListPresets để xem danh sách." -ForegroundColor Red
		return
	}
	$presetIds = Resolve-MolikPreset -Preset $presetObj -Catalog $catalog
	Write-Host "  Preset: $($presetObj.Icon) $($presetObj.Title) - $($presetIds.Count) tweak (Mode nền $($presetObj.Mode))" -ForegroundColor Yellow
	Write-Host "  $($presetObj.Description)" -ForegroundColor Gray
	if ($Plan)
	{
		$presetPlan = Get-SophiaOptimizationPlan -Catalog $catalog -SelectedIds $presetIds -Snapshot $snapshot
		Show-SophiaOptimizationPlan -Plan $presetPlan -Title "KE HOACH PRESET $($presetObj.Name) (chua ap dung)"
		return
	}
	if ($DryRun)
	{
		$catalog | Where-Object { $presetIds -contains $_.Id } | ForEach-Object { Write-Host ("    [{0}] [{1}] {2}" -f $_.Id, $_.Risk, $_.Name) }
		return
	}
	if (-not $Apply)
	{
		Write-Host "  Them -Apply de thuc thi Preset nay (hoac -Plan/-DryRun de xem truoc)." -ForegroundColor Yellow
		return
	}
	if (-not $Yes) { $c = Read-Host "  Ap dung Preset nay? (Y/N)"; if ($c -notmatch '^[Yy]') { Write-Host "  Da huy."; return } }
	Invoke-SophiaSelectedTweaks -Catalog $catalog -SelectedIds $presetIds -SkipBackup:$NoBackup -Force:$Yes -Snapshot $snapshot
	return
}
if ($ApplyIds)
{
	$wanted = @($ApplyIds -split ',' | ForEach-Object { $_.Trim().ToUpper() } | Where-Object { $_ })
	$unknown = @($wanted | Where-Object { $catalog.Id -notcontains $_ })
	if ($unknown.Count -gt 0) { Write-Host "  [!] ID khong ton tai: $($unknown -join ', ') - chay -ListTweaks de tra cuu." -ForegroundColor Red; return }
	if ($Plan)
	{
		$idsPlan = Get-SophiaOptimizationPlan -Catalog $catalog -SelectedIds $wanted -Snapshot $snapshot
		Show-SophiaOptimizationPlan -Plan $idsPlan -Title "KE HOACH ApplyIds (chua ap dung)"
		return
	}
	if ($DryRun)
	{
		$catalog | Where-Object { $wanted -contains $_.Id } | ForEach-Object { Write-Host ("    [{0}] [{1}] {2}" -f $_.Id, $_.Risk, $_.Name) }
		return
	}
	if (-not $Yes) { $c = Read-Host "  Ap dung $($wanted.Count) tweak theo ID? (Y/N)"; if ($c -notmatch '^[Yy]') { Write-Host "  Da huy."; return } }
	Invoke-SophiaSelectedTweaks -Catalog $catalog -SelectedIds $wanted -SkipBackup:$NoBackup -Force:$Yes -Snapshot $snapshot
	return
}
if ($RestoreIds)
{
	$wanted = @($RestoreIds -split ',' | ForEach-Object { $_.Trim().ToUpper() } | Where-Object { $_ })
	$unknown = @($wanted | Where-Object { $catalog.Id -notcontains $_ })
	if ($unknown.Count -gt 0) { Write-Host "  [!] ID khong ton tai: $($unknown -join ', ')" -ForegroundColor Red; return }
	if (-not $Yes) { $c = Read-Host "  Khoi phuc mac dinh $($wanted.Count) tweak theo ID? (Y/N)"; if ($c -notmatch '^[Yy]') { Write-Host "  Da huy."; return } }
	foreach ($tweak in ($catalog | Where-Object { $wanted -contains $_.Id }))
	{
		try { & $tweak.RestoreScript; Write-Host "  [✓] Da khoi phuc $($tweak.Id) $($tweak.Name)" -ForegroundColor Green }
		catch { Write-Host "  [X] $($tweak.Id): $($_.Exception.Message)" -ForegroundColor Red }
	}
	return
}
if ($Apply)
{
	$ids = Get-SophiaModeTweakIds -ModeKey $Mode -Catalog $catalog
	if ($Smart -and $smartRec) { $ids = @($ids + $smartRec.ExtraIds | Select-Object -Unique) }
	$modeObj = $modes | Where-Object Key -eq $Mode | Select-Object -First 1
	Write-Host "  Mode: $($modeObj.Icon) $($modeObj.Name) — sẽ áp dụng $($ids.Count) tweak." -ForegroundColor Yellow
	if ($DryRun)
	{
		Write-Host "  [DRY-RUN] $($ids.Count) tweak sẽ được áp dụng (chưa thực thi):" -ForegroundColor Cyan
		$catalog | Where-Object { $ids -contains $_.Id } | ForEach-Object { Write-Host ("    [{0}] [{1}] {2}" -f $_.Id, $_.Risk, $_.Name) }
		return
	}
	if (-not $Yes)
	{
		$confirm = Read-Host "  Tiếp tục? (Y/N)"
		if ($confirm -notmatch '^[Yy]') { Write-Host "  Đã hủy. Chạy không có -Apply để mở giao diện tick-chọn."; return }
	}
	Invoke-SophiaSelectedTweaks -Catalog $catalog -SelectedIds $ids -SkipBackup:$NoBackup -Force:$Yes -Snapshot $snapshot
	return
}

# ── Interactive tick-select UI (tự fallback Menu đơn giản nếu host không hỗ trợ ReadKey) ──
if ($Menu)
{
	Show-SophiaSimpleMenu -Catalog $catalog -Snapshot $snapshot -LauncherPath $PSCommandPath
	return
}
try
{
	if ([Console]::IsInputRedirected) { throw "Input redirected" }
	Show-SophiaOptimizerUI -Catalog $catalog -Snapshot $snapshot -InitialMode $Mode
}
catch
{
	Write-Host "  [!] Host hiện tại không hỗ trợ giao diện phím trực tiếp ($($_.Exception.Message)) — chuyển sang MENU ĐƠN GIẢN." -ForegroundColor Yellow
	Show-SophiaSimpleMenu -Catalog $catalog -Snapshot $snapshot -LauncherPath $PSCommandPath
}
