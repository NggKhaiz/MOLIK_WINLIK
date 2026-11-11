<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Application Installer (winutil-style, via built-in winget)

	.DESCRIPTION
	Install popular applications by ticking names/numbers, using the winget package manager
	built into Windows 10/11 (fallback: Chocolatey if present). Application data (239 apps)
	is vendored from ChrisTitusTech/winutil config/applications.json (MIT) in
	Optimizer/Data/WinUtilApps.ps1 — no winutil download required.
#>

function Find-SophiaApp
{
	param([string]$Query, $Apps)
	if (-not $Apps) { $Apps = Get-SophiaAppsCatalog }
	$q = $Query.Trim().ToLower()
	return @($Apps | Where-Object { $_.Id.ToLower() -eq $q -or $_.Name.ToLower() -eq $q -or $_.Winget.ToLower() -eq $q -or $_.Name.ToLower() -match [regex]::Escape($q) -or $_.Id.ToLower() -match [regex]::Escape($q) })
}

function Install-SophiaApps
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][string[]]$Queries)

	$apps = Get-SophiaAppsCatalog
	$winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
	$choco = Get-Command "choco.exe" -ErrorAction SilentlyContinue
	if (-not $winget -and -not $choco)
	{
		Write-Host "  [!] Không tìm thấy winget (Windows App Installer) hay Chocolatey trên máy này." -ForegroundColor Red
		Write-Host "      Cài 'App Installer' từ Microsoft Store (miễn phí) rồi chạy lại — tool không tự tải winutil/winget từ nguồn lạ." -ForegroundColor Yellow
		return
	}

	foreach ($q in $Queries)
	{
		$found = Find-SophiaApp -Query $q -Apps $apps
		if ($found.Count -eq 0) { Write-Host "  [?] Không tìm thấy ứng dụng khớp '$q' — dùng -ListApps để xem danh sách." -ForegroundColor Yellow; continue }
		$app = $found[0]
		Write-Host "  [*] Đang cài $($app.Name) ($($app.Winget)) ..." -ForegroundColor Cyan
		try
		{
			if ($winget)
			{
				& winget install --id $app.Winget -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
			}
			else
			{
				& choco install $app.Choco -y 2>&1 | Out-Null
			}
			if ($LASTEXITCODE -eq 0) { Write-Host "      [✓] Xong: $($app.Name)" -ForegroundColor Green }
			else { Write-Host "      [!] Trình cài trả mã $LASTEXITCODE cho $($app.Name) (có thể đã cài rồi hoặc cần tương tác)." -ForegroundColor Yellow }
		}
		catch { Write-Host "      [X] Lỗi cài $($app.Name): $($_.Exception.Message)" -ForegroundColor Red }
	}
}

function Show-SophiaAppInstallerMenu
{
	$apps = Get-SophiaAppsCatalog
	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "  ║  📦 CÀI ỨNG DỤNG (winutil-style, qua winget) — $($apps.Count) app có sẵn dữ liệu  ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
	$apps | Group-Object Category | Sort-Object Name | ForEach-Object {
		Write-Host ""
		Write-Host "  [$($_.Name)]" -ForegroundColor Magenta
		$_.Group | Sort-Object Name | ForEach-Object { Write-Host ("    - {0}  ({1})" -f $_.Name, $_.Winget) -ForegroundColor Gray }
	}
	Write-Host ""
	Write-Host "  Nhập TÊN app cách nhau bằng dấu phẩy (vd: steam, vlc, chrome), hoặc ENTER để quay lại." -ForegroundColor Yellow
	$inputLine = Read-Host "  App cần cài"
	if ([string]::IsNullOrWhiteSpace($inputLine)) { return }
	$queries = @($inputLine -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
	if ($queries.Count -gt 0) { Install-SophiaApps -Queries $queries }
}
