<#
	.SYNOPSIS
	MOLIK WINLIK - System Backup, Restore Point & Rollback Engine

	.DESCRIPTION
	Creates Windows System Restore Points, exports critical Registry branches, BCD store,
	and Power Schemes before applying deep optimizations, and provides 1-click Rollback.
#>

function New-SophiaSystemBackup
{
	[CmdletBinding()]
	param
	(
		[string]$Label = "MOLIK WINLIK Backup"
	)

	$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$BackupRoot = "$env:SystemDrive\MOLIK_WINLIK_Backups\Backup_$Timestamp"
	New-Item -Path $BackupRoot -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "  ║  ĐANG TẠO BẢN SAO LƯU HỆ THỐNG AN TOÀN (RESTORE POINT + REGISTRY)   ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

	# 1. Create Windows System Restore Point (official upstream method)
	try
	{
		Enable-ComputerRestore -Drive $env:SystemDrive -ErrorAction SilentlyContinue
		New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
		Get-Service -Name vss, swprv -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue
		Checkpoint-Computer -Description $Label -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
		Write-Host "  [✓] Đã tạo Điểm Khôi Phục Hệ Thống (System Restore Point): '$Label'" -ForegroundColor Green
	}
	catch
	{
		Write-Host "  [!] Lưu ý: Không thể tạo Restore Point (có thể chạy trên máy ảo hoặc tắt VSS): $($_.Exception.Message)" -ForegroundColor Yellow
	}

	# 2. Export Critical Registry Branches
	$RegBranches = @(
		@{ File = "MemoryManagement.reg"; Key = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" },
		@{ File = "PriorityControl.reg";  Key = "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" },
		@{ File = "GraphicsDrivers.reg";  Key = "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" },
		@{ File = "DeviceGuard.reg";      Key = "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" },
		@{ File = "MultimediaProfile.reg";Key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" },
		@{ File = "TcpipParams.reg";      Key = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" },
		@{ File = "Dwm.reg";              Key = "HKLM\SOFTWARE\Microsoft\Windows\Dwm" },
		@{ File = "GameDVR.reg";          Key = "HKCU\System\GameConfigStore" },
		@{ File = "Mouse.reg";            Key = "HKCU\Control Panel\Mouse" },
		@{ File = "Keyboard.reg";         Key = "HKCU\Control Panel\Keyboard" },
		@{ File = "Desktop.reg";          Key = "HKCU\Control Panel\Desktop" }
	)

	$ExportedCount = 0
	if (Test-Path "$env:SystemRoot\System32\reg.exe")
	{
		foreach ($Branch in $RegBranches)
		{
			$OutFile = Join-Path -Path $BackupRoot -ChildPath $Branch.File
			& "$env:SystemRoot\System32\reg.exe" export "$($Branch.Key)" "$OutFile" /y 2>$null | Out-Null
			if (Test-Path $OutFile) { $ExportedCount++ }
		}
		Write-Host "  [✓] Đã xuất $ExportedCount nhánh Registry quan trọng vào: $BackupRoot" -ForegroundColor Green
	}

	# 3. Export BCD Store
	if (Test-Path "$env:SystemRoot\System32\bcdedit.exe")
	{
		$BcdBackupFile = Join-Path -Path $BackupRoot -ChildPath "bcd_backup.bcd"
		& "$env:SystemRoot\System32\bcdedit.exe" /export "$BcdBackupFile" 2>$null | Out-Null
		if (Test-Path $BcdBackupFile)
		{
			Write-Host "  [✓] Đã sao lưu cấu hình Boot/Timer (BCD Store): $BcdBackupFile" -ForegroundColor Green
		}
	}

	# 4. Save Metadata JSON
	$Meta = [ordered]@{
		ToolVersion = $(if ($Global:MolikWinlikVersion) { $Global:MolikWinlikVersion } else { "unknown" })
		CreatedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
		Label       = $Label
		BackupPath  = $BackupRoot
		RegExports  = $ExportedCount
	}
	$Meta | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path -Path $BackupRoot -ChildPath "backup_meta.json") -Encoding UTF8 -Force

	return $BackupRoot
}

function Get-MolikBackupFolders
{
	# Chi lay cac thu muc Backup_<timestamp> that (truoc day ham Restore lay ca
	# Logs/Profiles/Benchmarks lam "backup moi nhat" -> khoi phuc rong ma van bao xong).
	$BackupsDir = "$env:SystemDrive\MOLIK_WINLIK_Backups"
	if (-not (Test-Path $BackupsDir) -and (Test-Path "$env:SystemDrive\Sophia_Backups")) { $BackupsDir = "$env:SystemDrive\Sophia_Backups" }
	if (-not (Test-Path $BackupsDir)) { return @() }
	return @(Get-ChildItem -Path $BackupsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Backup_*" } | Sort-Object LastWriteTime -Descending)
}

function Show-MolikBackupList
{
	$folders = Get-MolikBackupFolders
	if ($folders.Count -eq 0)
	{
		Write-Host "  [!] Chưa có backup nào trong $env:SystemDrive\MOLIK_WINLIK_Backups (chạy -BackupOnly hoặc áp dụng tweak để tạo)." -ForegroundColor Yellow
		return
	}
	Write-Host ""
	Write-Host "  ══════ DANH SÁCH BACKUP MOLIK WINLIK ($($folders.Count) bản, mới nhất trước) ══════" -ForegroundColor Cyan
	foreach ($f in $folders)
	{
		$regCount = @(Get-ChildItem -Path $f.FullName -Filter "*.reg" -File -ErrorAction SilentlyContinue).Count
		$hasBcd = Test-Path (Join-Path $f.FullName "bcd_backup.bcd")
		Write-Host ("  {0}  |  {1} file .reg  |  BCD: {2}" -f $f.FullName, $regCount, $(if ($hasBcd) { "có" } else { "không" })) -ForegroundColor Gray
	}
	Write-Host "  Khôi phục bản mới nhất: -RestoreBackup (chỉ nạp Registry; file bcd_backup.bcd dùng bcdedit /import khi cần)." -ForegroundColor DarkGray
}

function Restore-SophiaLatestBackup
{
	[CmdletBinding()]
	param()

	$LatestBackup = Get-MolikBackupFolders | Select-Object -First 1
	if (-not $LatestBackup)
	{
		Write-Host "  [!] Không tìm thấy bản sao lưu Backup_* nào trong $env:SystemDrive\MOLIK_WINLIK_Backups." -ForegroundColor Yellow
		return $false
	}

	Write-Host "  [*] Đang khôi phục Registry từ bản sao lưu: $($LatestBackup.FullName) ..." -ForegroundColor Cyan
	$RegFiles = Get-ChildItem -Path $LatestBackup.FullName -Filter "*.reg" -File
	if ($RegFiles.Count -eq 0)
	{
		Write-Host "  [!] Bản backup mới nhất không chứa file .reg nào — không khôi phục được gì." -ForegroundColor Red
		return $false
	}
	foreach ($RegFile in $RegFiles)
	{
		& "$env:SystemRoot\System32\reg.exe" import "$($RegFile.FullName)" 2>$null | Out-Null
		Write-Host "      + Đã nạp lại: $($RegFile.Name)" -ForegroundColor Green
	}
	if (Test-Path (Join-Path $LatestBackup.FullName "bcd_backup.bcd"))
	{
		Write-Host "  [i] BCD không tự nạp (tránh rủi ro boot). Khi cần: bcdedit /import `"$($LatestBackup.FullName)\bcd_backup.bcd`"" -ForegroundColor DarkGray
	}

	return $true
}

function Restore-MolikLastSession
{
	# Hoan tac phien ap dung gan nhat: doc log MOLIK_*.log moi nhat, chay
	# RestoreScript cho tung tweak da "OK" theo thu tu NGUOC lai.
	[CmdletBinding()]
	param([Parameter(Mandatory)]$Catalog, [switch]$Force)

	$logDir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Logs"
	$latestLog = Get-ChildItem -Path $logDir -Filter "MOLIK_*.log" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if (-not $latestLog)
	{
		Write-Host "  [!] Không tìm thấy log phiên áp dụng nào trong $logDir — chưa có gì để hoàn tác." -ForegroundColor Yellow
		return $false
	}
	$okIds = @()
	foreach ($line in (Get-Content $latestLog.FullName -ErrorAction SilentlyContinue))
	{
		if ($line -match '^OK\s+(\S+)') { $okIds += $Matches[1] }
	}
	$okIds = @($okIds | Select-Object -Unique)
	if ($okIds.Count -eq 0)
	{
		Write-Host "  [!] Log gần nhất ($($latestLog.Name)) không có tweak nào áp dụng thành công." -ForegroundColor Yellow
		return $false
	}
	Write-Host "  Phiên gần nhất: $($latestLog.Name) — $($okIds.Count) tweak đã áp dụng thành công." -ForegroundColor Cyan
	if (-not $Force)
	{
		$c = Read-Host "  Chạy Restore (mặc định gốc) cho $($okIds.Count) tweak này theo thứ tự ngược? (Y/N)"
		if ($c -notmatch '^[Yy]') { Write-Host "  Đã hủy hoàn tác."; return $false }
	}
	[array]::Reverse($okIds)
	$done = 0
	foreach ($id in $okIds)
	{
		$tweak = $Catalog | Where-Object { $_.Id -eq $id } | Select-Object -First 1
		if (-not $tweak) { continue }
		try { & $tweak.RestoreScript; Write-Host "  [✓] Đã khôi phục $id $($tweak.Name)" -ForegroundColor Green; $done++ }
		catch { Write-Host "  [X] $id : $($_.Exception.Message)" -ForegroundColor Red }
	}
	Write-Host "  ══════ HOÀN TÁC XONG: $done/$($okIds.Count) tweak — hãy RESTART máy để có hiệu lực hoàn toàn. ══════" -ForegroundColor Cyan
	return $true
}
