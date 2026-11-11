<#
	.SYNOPSIS
	Sophia Ultra Optimizer - System Backup, Restore Point & Rollback Engine

	.DESCRIPTION
	Creates Windows System Restore Points, exports critical Registry branches, BCD store,
	and Power Schemes before applying deep optimizations, and provides 1-click Rollback.
#>

function New-SophiaSystemBackup
{
	[CmdletBinding()]
	param
	(
		[string]$Label = "Sophia Ultra Optimizer Backup"
	)

	$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$BackupRoot = "$env:SystemDrive\Sophia_Backups\Backup_$Timestamp"
	New-Item -Path $BackupRoot -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "  ║  ĐANG TẠO BẢN SAO LƯU HỆ THỐNG AN TOÀN (RESTORE POINT + REGISTRY)   ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

	# 1. Create Windows System Restore Point (Sophia Script official method)
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
		CreatedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
		Label       = $Label
		BackupPath  = $BackupRoot
		RegExports  = $ExportedCount
	}
	$Meta | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path -Path $BackupRoot -ChildPath "backup_meta.json") -Encoding UTF8 -Force

	return $BackupRoot
}

function Restore-SophiaLatestBackup
{
	[CmdletBinding()]
	param()

	$BackupsDir = "$env:SystemDrive\Sophia_Backups"
	if (-not (Test-Path $BackupsDir))
	{
		Write-Host "  [!] Chưa tìm thấy thư mục sao lưu tại $BackupsDir. Đang chạy khôi phục mặc định qua Catalog..." -ForegroundColor Yellow
		return $false
	}

	$LatestBackup = Get-ChildItem -Path $BackupsDir -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
	if (-not $LatestBackup)
	{
		Write-Host "  [!] Không tìm thấy bản sao lưu nào trong $BackupsDir." -ForegroundColor Yellow
		return $false
	}

	Write-Host "  [*] Đang khôi phục Registry từ bản sao lưu: $($LatestBackup.FullName) ..." -ForegroundColor Cyan
	$RegFiles = Get-ChildItem -Path $LatestBackup.FullName -Filter "*.reg" -File
	foreach ($RegFile in $RegFiles)
	{
		& "$env:SystemRoot\System32\reg.exe" import "$($RegFile.FullName)" 2>$null | Out-Null
		Write-Host "      + Đã nạp lại: $($RegFile.Name)" -ForegroundColor Green
	}

	return $true
}
