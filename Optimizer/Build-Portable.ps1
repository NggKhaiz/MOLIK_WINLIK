<#
	.SYNOPSIS
	Build MolikWinlik-Portable.ps1 - ban OFFLINE 1 FILE duy nhat cua MOLIK WINLIK.

	.DESCRIPTION
	Gop toan bo engine (Core + Catalog + UI) vao launcher MolikWinlik.ps1 ngay
	tai vi tri block nap module, tao thanh 1 file .ps1 doc lap:
	  - Nhan ban (copy/USB) thu muc chua MOLIK_WINLIK.bat + file Portable nay,
	    double-click MOLIK_WINLIK.bat la chay (tu xin quyen Administrator).
	  - Khong tai code khi chay, khong can clone repo, khong can Internet.
	File duoc ghi UTF-8 CO BOM de Windows PowerShell 5.1 doc dung tieng Viet
	khi chay bang -File. Kem file .sha256 de doi chieu toan ven khi nhan ban.

	.EXAMPLE
	.\Optimizer\Build-Portable.ps1
	# Sinh ra MolikWinlik-Portable.ps1 + .sha256 o thu muc goc repo
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
	[string]$OutputPath = ""
)

$OptimizerDir = $PSScriptRoot
$RepoRoot = Split-Path -Path $OptimizerDir -Parent
if (-not $OutputPath) { $OutputPath = Join-Path $RepoRoot "MolikWinlik-Portable.ps1" }

$engineFiles = @(
	"Core\HardwareDetector.ps1",
	"Core\RamCleanerDaemon.ps1",
	"Core\ExtremeEngine.ps1",
	"Core\Benchmark.ps1",
	"Core\PlanEngine.ps1",
	"Core\SmartAdvisor.ps1",
	"Core\WinUtilBridge.ps1",
	"Core\AppInstaller.ps1",
	"Data\WinUtilTweaks.ps1",
	"Data\WinUtilApps.ps1",
	"Core\SelfTest.ps1",
	"Core\BackupRestore.ps1",
	"Core\SophiaBridge.ps1",
	"Catalog\TweaksCatalog.ps1",
	"UI\InteractiveCLI.ps1"
)

$functionsBundle = [System.Text.StringBuilder]::new()
foreach ($rel in $engineFiles)
{
	$full = Join-Path $OptimizerDir $rel
	if (-not (Test-Path $full)) { throw "Missing engine file: $full" }
	$content = (Get-Content -Path $full -Raw -Encoding UTF8).TrimStart([char]0xFEFF)
	[void]$functionsBundle.AppendLine("")
	[void]$functionsBundle.AppendLine("# ============================================================")
	[void]$functionsBundle.AppendLine("# [PORTABLE-INLINE] Optimizer\$rel")
	[void]$functionsBundle.AppendLine("# ============================================================")
	[void]$functionsBundle.AppendLine($content)
}

$launcherPath = Join-Path $RepoRoot "MolikWinlik.ps1"
$launcher = (Get-Content -Path $launcherPath -Raw -Encoding UTF8).TrimStart([char]0xFEFF)

$pattern = '(?ms)^\$engineFiles = @\(.*?^\}$'
$replacement = "# [PORTABLE] Toan bo engine da duoc nhung truc tiep ben duoi - khong can file phu, khong tai gi khi chay.`n" + $functionsBundle.ToString()
$portable = [regex]::Replace($launcher, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })

if ($portable -eq $launcher) { throw "Khong tim thay block nap engine trong MolikWinlik.ps1 - build that bai." }

# OFFLINE purity guard: ban Portable khong duoc chua cmdlet tai code tu Internet.
$scanText = (($portable -split "`n") | Where-Object { $_ -notmatch "OFFLINE guard|-match|-notmatch" }) -join "`n"
if ($scanText -match "Invoke-RestMethod|Invoke-WebRequest|DownloadString")
{
	throw "Portable chua cmdlet tai mang - MOLIK WINLIK phai offline 100%."
}

$banner = "<#`n`tMOLIK WINLIK by @nggkhaiz - BAN OFFLINE 1 FILE (MolikWinlik-Portable.ps1)`n`tChay: double-click MOLIK_WINLIK.bat (tu xin Admin), hoac powershell -ExecutionPolicy Bypass -File .\\MolikWinlik-Portable.ps1`n`tFile nay duoc sinh tu dong boi Optimizer\\Build-Portable.ps1 - dung sua tay, hay sua nguon trong Optimizer/ roi build lai.`n#>`n"
$portable = $banner + $portable

# UTF-8 CO BOM: Windows PowerShell 5.1 doc dung tieng Viet khi chay -File.
[System.IO.File]::WriteAllText($OutputPath, $portable, (New-Object System.Text.UTF8Encoding($true)))
$portableHash = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash.ToLower()
"$portableHash  $(Split-Path $OutputPath -Leaf)" | Set-Content -Path "$OutputPath.sha256" -Encoding ASCII -Force
Write-Host "[OK] SHA256: $portableHash" -ForegroundColor DarkGray
Write-Host "[OK] Da sinh ban Portable OFFLINE: $OutputPath ($([Math]::Round((Get-Item $OutputPath).Length / 1KB, 1)) KB)" -ForegroundColor Green
