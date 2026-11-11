<#
	.SYNOPSIS
	Build Sophia-Ultra-Portable.ps1 — bản 1 FILE duy nhất, không cần cài đặt/clone repo.

	.DESCRIPTION
	Gộp toàn bộ engine (Core + Catalog + UI) vào launcher Sophia-Optimizer.ps1
	ngay tại vị trí block nạp module, tạo thành 1 file .ps1 độc lập:
	  - Tải 1 file về, chạy trực tiếp (kể cả để trong %TEMP%)
	  - irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Portable.ps1 | iex
	Không ghi gì vào máy ngoài backup/log ở C:\Sophia_Backups (chỉ khi bạn áp dụng tweak).

	.EXAMPLE
	.\Optimizer\Build-Portable.ps1
	# Sinh ra Sophia-Ultra-Portable.ps1 ở thư mục gốc repo
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
	[string]$OutputPath = ""
)

$OptimizerDir = $PSScriptRoot
$RepoRoot = Split-Path -Path $OptimizerDir -Parent
if (-not $OutputPath) { $OutputPath = Join-Path $RepoRoot "Sophia-Ultra-Portable.ps1" }

$engineFiles = @(
	"Core\HardwareDetector.ps1",
	"Core\RamCleanerDaemon.ps1",
	"Core\ExtremeEngine.ps1",
	"Core\Benchmark.ps1",
	"Core\PlanEngine.ps1",
	"Core\SmartAdvisor.ps1",
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
	[void]$functionsBundle.AppendLine("# ════════════════════════════════════════════════════════════════════")
	[void]$functionsBundle.AppendLine("# [PORTABLE-INLINE] Optimizer\$rel")
	[void]$functionsBundle.AppendLine("# ════════════════════════════════════════════════════════════════════")
	[void]$functionsBundle.AppendLine($content)
}

$launcher = (Get-Content -Path (Join-Path $RepoRoot "Sophia-Optimizer.ps1") -Raw -Encoding UTF8).TrimStart([char]0xFEFF)

$pattern = '(?ms)^\$engineFiles = @\(.*?^\}$'
$replacement = "# [PORTABLE] Toàn bộ engine đã được nhúng trực tiếp bên dưới — không cần file phụ, không cần cài đặt.`r`n" + $functionsBundle.ToString()
$portable = [regex]::Replace($launcher, $pattern, $replacement)

if ($portable -eq $launcher) { throw "Không tìm thấy block nạp engine trong Sophia-Optimizer.ps1 — build thất bại." }

$banner = "<#`r`n`tSophia Ultra Optimizer — PORTABLE (1 file duy nhất, KHÔNG CẦN CÀI ĐẶT)`r`n`tFile này được sinh tự động bởi Optimizer\Build-Portable.ps1 — đừng sửa tay, hãy sửa nguồn trong Optimizer/ rồi build lại.`r`n`tChạy: .\Sophia-Ultra-Portable.ps1  |  irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Portable.ps1 | iex`r`n#>`r`n"
$portable = $banner + $portable

$portable | Set-Content -Path $OutputPath -Encoding UTF8 -Force
Write-Host "[✓] Đã sinh bản Portable: $OutputPath ($([Math]::Round((Get-Item $OutputPath).Length / 1KB, 1)) KB)" -ForegroundColor Green
