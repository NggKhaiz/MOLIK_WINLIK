<#
	MOLIK WINLIK by @nggkhaiz v3.1.0 - BAN OFFLINE 1 FILE (MolikWinlik-Portable.ps1)
	Chay: double-click MOLIK_WINLIK.bat (tu xin Admin), hoac powershell -ExecutionPolicy Bypass -File .\MolikWinlik-Portable.ps1
	File nay duoc sinh tu dong boi Optimizer\Build-Portable.ps1 - dung sua tay, hay sua nguon trong Optimizer/ roi build lai.
#>
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
$Global:MolikWinlikVersion = "3.1.0"

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
# [PORTABLE] Toan bo engine da duoc nhung truc tiep ben duoi - khong can file phu, khong tai gi khi chay.

# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\HardwareDetector.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Hardware, OS, Virtualization & Emulator Detection Engine

	.DESCRIPTION
	Scans CPU, RAM, GPU, Storage (SSD/NVMe/HDD), Windows Build, VBS/HVCI/Hyper-V status,
	Active Power Plan, Process count, and automatically locates installed Android Emulators
	(LDPlayer, NoxPlayer, MuMu Player, BlueStacks, MEmu, VirtualBox, VMware).

	.NOTES
	Compatible with Windows PowerShell 5.1 & PowerShell 7+ (Windows 10 & Windows 11)
#>

function Get-SophiaSystemSnapshot
{
	[CmdletBinding()]
	param()

	$Snapshot = [ordered]@{
		Timestamp            = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
		IsAdmin              = $false
		OSName               = "Windows"
		OSBuild              = 0
		OSUBR                = 0
		OSDisplayVersion     = ""
		IsWindows11          = $false
		PSVersion            = "$($PSVersionTable.PSVersion)"
		CPUName              = "Unknown CPU"
		CPUCores             = 0
		CPUThreads           = 0
		VTxEnabled           = $true
		RAMTotalGB           = 0.0
		RAMFreeGB            = 0.0
		RAMUsedGB            = 0.0
		RAMUsagePercent      = 0
		GPUName              = "Unknown GPU"
		GPUVendor            = "Generic"
		WDDMVersion          = 0.0
		HAGSEnabled          = $false
		MPODisabled          = $false
		TdrDelay             = 2
		SystemDriveType      = "SSD/NVMe"
		SystemDriveFreeGB    = 0.0
		VBSRunning           = $false
		HVCIEnabled          = $false
		HypervisorLaunchType = "Auto"
		SpectreMitigated     = $true
		ActivePowerPlan      = "Balanced"
		ProcessCount         = 0
		InstalledEmulators   = @()
		PendingReboot        = $false
		IsLaptop             = $false
		EmulatorExePaths     = @()
		EmulatorFolders      = @()
	}

	try
	{
		$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
		$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
		$Snapshot.IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	}
	catch
	{
		$Snapshot.IsAdmin = $false
	}

	# Process Count
	try
	{
		$Snapshot.ProcessCount = @(Get-Process -ErrorAction SilentlyContinue).Count
	}
	catch {}

	# OS Info
	try
	{
		$CurrentVersionReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
		if ($CurrentVersionReg)
		{
			$Snapshot.OSBuild          = [int]$CurrentVersionReg.CurrentBuild
			$Snapshot.OSUBR            = [int]$CurrentVersionReg.UBR
			$Snapshot.OSDisplayVersion = "$($CurrentVersionReg.DisplayVersion)"
			$Snapshot.IsWindows11      = ($Snapshot.OSBuild -ge 22000)
			$Snapshot.OSName           = if ($Snapshot.IsWindows11) { ($CurrentVersionReg.ProductName -replace "Windows 10", "Windows 11") } else { $CurrentVersionReg.ProductName }
		}
	}
	catch {}

	# CPU & RAM via CIM
	try
	{
		$CPU = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
		if ($CPU)
		{
			$Snapshot.CPUName    = ($CPU.Name -replace "\s+", " ").Trim()
			$Snapshot.CPUCores   = [int]$CPU.NumberOfCores
			$Snapshot.CPUThreads = [int]$CPU.NumberOfLogicalProcessors
			if ($null -ne $CPU.VirtualizationFirmwareEnabled)
			{
				$Snapshot.VTxEnabled = [bool]$CPU.VirtualizationFirmwareEnabled
			}
		}

		$OS = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
		if ($OS)
		{
			$TotalGB = [Math]::Round(($OS.TotalVisibleMemorySize / 1MB), 1)
			$FreeGB  = [Math]::Round(($OS.FreePhysicalMemory / 1MB), 1)
			$UsedGB  = [Math]::Round(($TotalGB - $FreeGB), 1)
			$Snapshot.RAMTotalGB      = $TotalGB
			$Snapshot.RAMFreeGB       = $FreeGB
			$Snapshot.RAMUsedGB       = $UsedGB
			if ($TotalGB -gt 0)
			{
				$Snapshot.RAMUsagePercent = [Math]::Round(($UsedGB / $TotalGB) * 100, 0)
			}
		}
	}
	catch {}

	# GPU & Graphics Settings
	try
	{
		$GPUs = @(Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_VideoController -ErrorAction SilentlyContinue)
		$DedicatedGPU = $GPUs | Where-Object { $_.Name -notmatch "Microsoft Basic|Parsec|Virtual|Indirect|Luminon" } | Select-Object -First 1
		if (-not $DedicatedGPU) { $DedicatedGPU = $GPUs | Select-Object -First 1 }

		if ($DedicatedGPU)
		{
			$Snapshot.GPUName = $DedicatedGPU.Name
			if ($DedicatedGPU.Name -match "NVIDIA|GeForce|RTX|GTX|Quadro") { $Snapshot.GPUVendor = "NVIDIA" }
			elseif ($DedicatedGPU.Name -match "AMD|Radeon|RX") { $Snapshot.GPUVendor = "AMD" }
			elseif ($DedicatedGPU.Name -match "Intel|Arc|Iris|UHD|HD Graphics") { $Snapshot.GPUVendor = "Intel" }
		}

		$WddmMin = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\FeatureSetUsage", "WddmVersion_Min", 0)
		if ($WddmMin -gt 0)
		{
			$Snapshot.WDDMVersion = [Math]::Round(($WddmMin / 1000), 1)
		}

		$HwSchMode = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers", "HwSchMode", 1)
		$Snapshot.HAGSEnabled = ($HwSchMode -eq 2)

		$TdrDelayVal = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers", "TdrDelay", 2)
		if ($null -ne $TdrDelayVal) { $Snapshot.TdrDelay = [int]$TdrDelayVal }

		$OverlayTestMode = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Dwm", "OverlayTestMode", 0)
		$Snapshot.MPODisabled = ($OverlayTestMode -eq 5)
	}
	catch {}

	# Storage / Disk Type
	try
	{
		$SysDriveLetter = ($env:SystemDrive -replace ":", "")
		$SysVol = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction SilentlyContinue
		if ($SysVol)
		{
			$Snapshot.SystemDriveFreeGB = [Math]::Round(($SysVol.FreeSpace / 1GB), 1)
		}

		if (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue)
		{
			$Partition = Get-Partition -DriveLetter $SysDriveLetter -ErrorAction SilentlyContinue
			if ($Partition)
			{
				$PhysDisk = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq "$($Partition.DiskNumber)" } | Select-Object -First 1
				if ($PhysDisk)
				{
					$Snapshot.SystemDriveType = if ($PhysDisk.BusType -eq "NVMe") { "NVMe SSD" } elseif ($PhysDisk.MediaType -eq "SSD") { "SSD" } else { "$($PhysDisk.MediaType)" }
				}
			}
		}
	}
	catch {}

	# VBS / HVCI / Virtualization & Spectre Mitigations
	try
	{
		$DeviceGuard = Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
		if ($DeviceGuard)
		{
			$Snapshot.VBSRunning = ($DeviceGuard.VirtualizationBasedSecurityStatus -gt 0)
		}
		else
		{
			$EnableVBS = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard", "EnableVirtualizationBasedSecurity", 0)
			$Snapshot.VBSRunning = ($EnableVBS -eq 1)
		}

		$HVCI = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity", "Enabled", 0)
		$Snapshot.HVCIEnabled = ($HVCI -eq 1)

		$FeatureOverride = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management", "FeatureSettingsOverride", 0)
		$Snapshot.SpectreMitigated = ($FeatureOverride -ne 3)

		if ($Snapshot.IsAdmin -and (Test-Path "$env:SystemRoot\System32\bcdedit.exe"))
		{
			$BcdOut = & "$env:SystemRoot\System32\bcdedit.exe" /enum "{current}" 2>$null
			$HypLine = $BcdOut | Where-Object { $_ -match "hypervisorlaunchtype" } | Select-Object -First 1
			if ($HypLine)
			{
				$Snapshot.HypervisorLaunchType = ($HypLine -split "\s+")[-1]
			}
		}
	}
	catch {}

	# Active Power Plan
	try
	{
		if (Test-Path "$env:SystemRoot\System32\powercfg.exe")
		{
			$ActiveScheme = & "$env:SystemRoot\System32\powercfg.exe" /GETACTIVESCHEME 2>$null
			if ($ActiveScheme -match "\((.+)\)")
			{
				$Snapshot.ActivePowerPlan = $Matches[1]
			}
		}
	}
	catch {}

	# Laptop form factor + Pending reboot (dung cho UI canh bao va Smart/Plan)
	try
	{
		$Snapshot.IsLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)
		$pending = $false
		if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $pending = $true }
		if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $pending = $true }
		$pfro = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations
		if ($pfro) { $pending = $true }
		$Snapshot.PendingReboot = $pending
	}
	catch {}

	# Detect Installed Android Emulators & Hypervisors
	$EmulatorInfo = Find-InstalledEmulators
	$Snapshot.InstalledEmulators = $EmulatorInfo.Names
	$Snapshot.EmulatorExePaths   = $EmulatorInfo.ExePaths
	$Snapshot.EmulatorFolders    = $EmulatorInfo.Folders

	return [PSCustomObject]$Snapshot
}

function Find-InstalledEmulators
{
	[CmdletBinding()]
	param()

	$FoundNames   = [System.Collections.Generic.List[string]]::new()
	$FoundExes    = [System.Collections.Generic.List[string]]::new()
	$FoundFolders = [System.Collections.Generic.List[string]]::new()

	# Common Emulator Process & Directory Signatures
	$EmulatorSignatures = @(
		@{
			Name         = "LDPlayer (LD4 / LD9)"
			SubPaths     = @("LDPlayer\LDPlayer9", "LDPlayer\LDPlayer4.0", "LDPlayer9", "LDPlayer4", "XuanZhi\LDPlayer", "ChangZhi\dnplayer2")
			Executables  = @("dnplayer.exe", "LdVBoxHeadless.exe", "Ld9BoxHeadless.exe", "LdBoxHeadless.exe", "dnmultiplayer.exe")
			RegistryKeys = @("HKCU:\Software\XuanZhi", "HKLM:\SOFTWARE\WOW6432Node\XuanZhi")
		},
		@{
			Name         = "MuMu Player (MuMu 12 / Nebula)"
			SubPaths     = @("Program Files\Netease\MuMuPlayer-12.0", "Program Files\Netease\MuMuPlayerGlobal-12.0", "Netease\MuMuPlayer-12.0", "Netease\MuMu9", "MuMuPlayer-12.0")
			Executables  = @("MuMuPlayer.exe", "MuMuVMMHeadless.exe", "MuMuVMMSVC.exe", "NemuPlayer.exe", "NemuHeadless.exe")
			RegistryKeys = @("HKCU:\Software\Netease\MuMuPlayer-12.0", "HKLM:\SOFTWARE\WOW6432Node\Netease")
		},
		@{
			Name         = "NoxPlayer"
			SubPaths     = @("Nox\bin", "Program Files\Nox\bin", "Program Files (x86)\Nox\bin", "Bignox\BigNoxVM\RT")
			Executables  = @("Nox.exe", "NoxVMHandle.exe", "BignoxVMMgr.exe", "MultiPlayerManager.exe")
			RegistryKeys = @("HKCU:\Software\BigNox", "HKLM:\SOFTWARE\WOW6432Node\BigNox")
		},
		@{
			Name         = "BlueStacks 5 / MSI App Player"
			SubPaths     = @("Program Files\BlueStacks_nxt", "Program Files\BlueStacks_msi2", "Program Files\BlueStacks", "ProgramData\BlueStacks_nxt")
			Executables  = @("HD-Player.exe", "BstkSVC.exe", "HD-MultiInstanceManager.exe")
			RegistryKeys = @("HKLM:\SOFTWARE\BlueStacks_nxt", "HKLM:\SOFTWARE\BlueStacks_msi2")
		},
		@{
			Name         = "MEmu Play"
			SubPaths     = @("Program Files\Microvirt\MEmu", "Microvirt\MEmu", "Microvirt\MEmuHyperv")
			Executables  = @("MEmu.exe", "MEmuHeadless.exe", "MEmuConsole.exe")
			RegistryKeys = @("HKCU:\Software\Microvirt", "HKLM:\SOFTWARE\WOW6432Node\Microvirt")
		},
		@{
			Name         = "Oracle VirtualBox / VMware"
			SubPaths     = @("Program Files\Oracle\VirtualBox", "Program Files (x86)\VMware\VMware Workstation")
			Executables  = @("VBoxHeadless.exe", "VirtualBoxVM.exe", "vmware-vmx.exe")
			RegistryKeys = @("HKLM:\SOFTWARE\Oracle\VirtualBox", "HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.")
		}
	)

	# Get fixed drives (C:, D:, E:, F:, etc.)
	$DriveRoots = @("C:\")
	try
	{
		$FixedDrives = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
		if ($FixedDrives)
		{
			$DriveRoots = @($FixedDrives | ForEach-Object { "$($_.DeviceID)\" })
		}
	}
	catch {}

	foreach ($Sig in $EmulatorSignatures)
	{
		$DetectedThisEmulator = $false

		# Check common paths on all fixed drives
		foreach ($Root in $DriveRoots)
		{
			foreach ($SubPath in $Sig.SubPaths)
			{
				$CandidateFolder = Join-Path -Path $Root -ChildPath $SubPath
				if (Test-Path -Path $CandidateFolder -PathType Container -ErrorAction SilentlyContinue)
				{
					$DetectedThisEmulator = $true
					if (-not $FoundFolders.Contains($CandidateFolder))
					{
						$FoundFolders.Add($CandidateFolder)
					}

					foreach ($ExeName in $Sig.Executables)
					{
						$ExeFull = Join-Path -Path $CandidateFolder -ChildPath $ExeName
						if ((Test-Path -Path $ExeFull -PathType Leaf -ErrorAction SilentlyContinue) -and (-not $FoundExes.Contains($ExeFull)))
						{
							$FoundExes.Add($ExeFull)
						}
					}
				}
			}
		}

		# Check Registry keys
		foreach ($RegKey in $Sig.RegistryKeys)
		{
			if (Test-Path -Path $RegKey -ErrorAction SilentlyContinue)
			{
				$DetectedThisEmulator = $true
			}
		}

		if ($DetectedThisEmulator -and (-not $FoundNames.Contains($Sig.Name)))
		{
			$FoundNames.Add($Sig.Name)
		}
	}

	return [PSCustomObject]@{
		Names    = $FoundNames.ToArray()
		ExePaths = $FoundExes.ToArray()
		Folders  = $FoundFolders.ToArray()
	}
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\RamCleanerDaemon.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Native Kernel Standby List & Working Set RAM Cleaner Engine

	.DESCRIPTION
	Uses native Win32 & NTAPI P/Invoke (ntdll.dll NtSetSystemInformation & psapi.dll EmptyWorkingSet)
	to flush Modified Page Lists, purge Standby RAM Cache, and trim Working Sets without external .exe binaries.
	Also supports registering a 24/7 background Scheduled Task for unattended Emulator Farming ("Treo Giả Lập").
#>

function Initialize-SophiaMemoryNativeAPI
{
	[CmdletBinding()]
	param()

	if ("SophiaMemory.NativeCleaner" -as [type])
	{
		return
	}

	$CSharpSource = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace SophiaMemory
{
	public static class NativeCleaner
	{
		[DllImport("psapi.dll", SetLastError = true)]
		public static extern bool EmptyWorkingSet(IntPtr hProcess);

		[DllImport("ntdll.dll", SetLastError = true)]
		public static extern uint NtSetSystemInformation(int InfoClass, ref int Info, int Length);

		[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
		public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);

		[DllImport("advapi32.dll", SetLastError = true)]
		public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

		[DllImport("advapi32.dll", SetLastError = true)]
		public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool CloseHandle(IntPtr hObject);

		[StructLayout(LayoutKind.Sequential, Pack = 1)]
		public struct TOKEN_PRIVILEGES
		{
			public int PrivilegeCount;
			public long Luid;
			public int Attributes;
		}

		private const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
		private const uint TOKEN_QUERY = 0x0008;
		private const int SE_PRIVILEGE_ENABLED = 0x00000002;
		private const int SystemMemoryListInformation = 80;

		public static bool EnablePrivilege(string privilegeName)
		{
			IntPtr hToken = IntPtr.Zero;
			try
			{
				if (!OpenProcessToken(Process.GetCurrentProcess().Handle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out hToken))
					return false;

				long luid;
				if (!LookupPrivilegeValue(null, privilegeName, out luid))
					return false;

				TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES
				{
					PrivilegeCount = 1,
					Luid = luid,
					Attributes = SE_PRIVILEGE_ENABLED
				};

				return AdjustTokenPrivileges(hToken, false, ref tp, Marshal.SizeOf(tp), IntPtr.Zero, IntPtr.Zero);
			}
			catch
			{
				return false;
			}
			finally
			{
				if (hToken != IntPtr.Zero)
					CloseHandle(hToken);
			}
		}

		public static int TrimAllWorkingSets()
		{
			EnablePrivilege("SeProfileSingleProcessPrivilege");
			int trimmed = 0;

			foreach (Process proc in Process.GetProcesses())
			{
				try
				{
					if (proc.Handle != IntPtr.Zero)
					{
						if (EmptyWorkingSet(proc.Handle))
							trimmed++;
					}
				}
				catch
				{
					// Ignore protected/system processes
				}
				finally
				{
					proc.Dispose();
				}
			}
			return trimmed;
		}

		public static bool PurgeStandbyAndModifiedLists()
		{
			try
			{
				EnablePrivilege("SeProfileSingleProcessPrivilege");
				EnablePrivilege("SeIncreaseQuotaPrivilege");

				// 2 = MemoryEmptyWorkingSets
				int cmdEmptyWS = 2;
				NtSetSystemInformation(SystemMemoryListInformation, ref cmdEmptyWS, sizeof(int));

				// 3 = MemoryFlushModifiedList
				int cmdFlushModified = 3;
				NtSetSystemInformation(SystemMemoryListInformation, ref cmdFlushModified, sizeof(int));

				// 4 = MemoryPurgeStandbyList
				int cmdPurgeStandby = 4;
				uint status = NtSetSystemInformation(SystemMemoryListInformation, ref cmdPurgeStandby, sizeof(int));

				// 5 = MemoryPurgeLowPriorityStandbyList
				int cmdPurgeLowStandby = 5;
				NtSetSystemInformation(SystemMemoryListInformation, ref cmdPurgeLowStandby, sizeof(int));

				return (status == 0);
			}
			catch
			{
				return false;
			}
		}
	}
}
"@

	try
	{
		if ($PSVersionTable.PSVersion.Major -eq 5)
		{
			$CompilerParams                  = [System.CodeDom.Compiler.CompilerParameters]::new("System.dll")
			$CompilerParams.TempFiles        = [System.CodeDom.Compiler.TempFileCollection]::new($env:TEMP, $false)
			$CompilerParams.GenerateInMemory = $true
			Add-Type -TypeDefinition $CSharpSource -CompilerParameters $CompilerParams -ErrorAction SilentlyContinue
		}
		else
		{
			Add-Type -TypeDefinition $CSharpSource -ErrorAction SilentlyContinue
		}
	}
	catch {}
}

function Invoke-SophiaRamPurge
{
	[CmdletBinding()]
	param
	(
		[switch]$Silent
	)

	Initialize-SophiaMemoryNativeAPI

	$BeforeFreeMB = 0
	try
	{
		$OSBefore = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
		if ($OSBefore)
		{
			$BeforeFreeMB = [Math]::Round($OSBefore.FreePhysicalMemory / 1024, 0)
		}
	}
	catch {}

	$TrimmedProcesses = 0
	$StandbyPurged    = $false

	if ("SophiaMemory.NativeCleaner" -as [type])
	{
		$TrimmedProcesses = [SophiaMemory.NativeCleaner]::TrimAllWorkingSets()
		$StandbyPurged    = [SophiaMemory.NativeCleaner]::PurgeStandbyAndModifiedLists()
	}

	[System.GC]::Collect()
	[System.GC]::WaitForPendingFinalizers()

	Start-Sleep -Milliseconds 350

	$AfterFreeMB = $BeforeFreeMB
	try
	{
		$OSAfter = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
		if ($OSAfter)
		{
			$AfterFreeMB = [Math]::Round($OSAfter.FreePhysicalMemory / 1024, 0)
		}
	}
	catch {}

	$FreedMB = [Math]::Max(0, ($AfterFreeMB - $BeforeFreeMB))

	if (-not $Silent)
	{
		Write-Host "  [✓] Đã giải phóng Working Set của $TrimmedProcesses tiến trình & Purge Standby List Cache!" -ForegroundColor Green
		Write-Host "      RAM Trống trước: $BeforeFreeMB MB -> Sau khi dọn: $AfterFreeMB MB (Giải phóng +$FreedMB MB)" -ForegroundColor Cyan
	}

	return [PSCustomObject]@{
		TrimmedProcesses = $TrimmedProcesses
		StandbyPurged    = $StandbyPurged
		BeforeFreeMB     = $BeforeFreeMB
		AfterFreeMB      = $AfterFreeMB
		FreedMB          = $FreedMB
	}
}

function Register-SophiaAutoRamCleanerTask
{
	[CmdletBinding()]
	param
	(
		[int]$IntervalMinutes = 15,
		[int]$ThresholdPercent = 70
	)

	$CleanerScriptDir = "$env:ProgramData\MOLIK_WINLIK"
	if (-not (Test-Path -Path $CleanerScriptDir))
	{
		New-Item -Path $CleanerScriptDir -ItemType Directory -Force | Out-Null
	}

	$DaemonScriptPath = Join-Path -Path $CleanerScriptDir -ChildPath "MolikRamCleaner.ps1"

	$DaemonScriptContent = @"
# MOLIK WINLIK - 24/7 Smart RAM & Standby List Auto-Cleaner Daemon
`$OS = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
if (`$OS) {
	`$Total = [double]`$OS.TotalVisibleMemorySize
	`$Free  = [double]`$OS.FreePhysicalMemory
	`$UsagePct = if (`$Total -gt 0) { ((`$Total - `$Free) / `$Total) * 100 } else { 0 }
	if (`$UsagePct -lt $ThresholdPercent) { exit 0 }
}

`$Code = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class RamDaemon {
	[DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr hProcess);
	[DllImport("ntdll.dll")] public static extern uint NtSetSystemInformation(int InfoClass, ref int Info, int Length);
	[DllImport("advapi32.dll", CharSet = CharSet.Unicode)] public static extern bool LookupPrivilegeValue(string s, string n, out long l);
	[DllImport("advapi32.dll")] public static extern bool AdjustTokenPrivileges(IntPtr t, bool d, ref TP ns, int bl, IntPtr ps, IntPtr rl);
	[DllImport("advapi32.dll")] public static extern bool OpenProcessToken(IntPtr p, uint a, out IntPtr t);
	[StructLayout(LayoutKind.Sequential, Pack = 1)] public struct TP { public int Count; public long Luid; public int Attr; }
	public static void Run() {
		IntPtr hTok;
		if (OpenProcessToken(Process.GetCurrentProcess().Handle, 0x0028, out hTok)) {
			long luid;
			if (LookupPrivilegeValue(null, "SeProfileSingleProcessPrivilege", out luid)) {
				TP tp = new TP { Count = 1, Luid = luid, Attr = 2 };
				AdjustTokenPrivileges(hTok, false, ref tp, Marshal.SizeOf(tp), IntPtr.Zero, IntPtr.Zero);
			}
		}
		foreach (Process p in Process.GetProcesses()) {
			try { EmptyWorkingSet(p.Handle); } catch {} finally { p.Dispose(); }
		}
		int cmd3 = 3; NtSetSystemInformation(80, ref cmd3, 4);
		int cmd4 = 4; NtSetSystemInformation(80, ref cmd4, 4);
	}
}
'@
Add-Type -TypeDefinition `$Code -ErrorAction SilentlyContinue
[RamDaemon]::Run()
"@

	Set-Content -Path $DaemonScriptPath -Value $DaemonScriptContent -Encoding UTF8 -Force

	$Action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$DaemonScriptPath`""
	$Trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 3650)
	$Settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
	$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest -LogonType ServiceAccount

	Register-ScheduledTask -TaskName "MOLIK_WINLIK_RAM_Cleaner" -TaskPath "\MOLIK_WINLIK\" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Auto-purges Windows Standby List & Working Set RAM every $IntervalMinutes minutes when RAM > $ThresholdPercent% (Ideal for 24/7 Emulator Farming & Gaming)" -Force | Out-Null
}

function Unregister-SophiaAutoRamCleanerTask
{
	[CmdletBinding()]
	param()

	Unregister-ScheduledTask -TaskName "MOLIK_WINLIK_RAM_Cleaner" -TaskPath "\MOLIK_WINLIK\" -Confirm:$false -ErrorAction SilentlyContinue
	Unregister-ScheduledTask -TaskName "Sophia_Auto_RAM_Cleaner" -TaskPath "\Sophia\" -Confirm:$false -ErrorAction SilentlyContinue
	Remove-Item -Path "$env:ProgramData\MOLIK_WINLIK\MolikRamCleaner.ps1" -Force -ErrorAction SilentlyContinue
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\ExtremeEngine.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Extreme Engine (MSI interrupts, timer daemon, process affinity, per-exe priority)

	.DESCRIPTION
	Low-level helpers used by the EXTREME LAB catalog section:
	MSI Mode for GPU/NVMe/NIC, 0.5ms Timer Resolution daemon, periodic Process Booster
	(priority + affinity off Core 0), IFEO CpuPriorityClass, per-exe GPU preference &
	Fullscreen-Optimizations, NIC advanced properties, USB/NIC power-off lockdown,
	full powercfg profile, NTFS/storage tuning and AMD ULPS disable.
	Every setter has a matching remover/restore and is safe to run when hardware is absent.
#>

$script:SophiaDataDir = "$env:ProgramData\MOLIK_WINLIK"

function Get-SophiaDataDir
{
	if (-not (Test-Path $script:SophiaDataDir)) { New-Item -Path $script:SophiaDataDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
	return $script:SophiaDataDir
}

function Get-SophiaEmulatorExeNames
{
	return @("dnplayer.exe","LdVBoxHeadless.exe","Ld9BoxHeadless.exe","LdBoxHeadless.exe","HD-Player.exe","Nox.exe","NoxVMHandle.exe","MuMuPlayer.exe","NemuPlayer.exe","NemuHeadless.exe","MEmu.exe","MEmuHeadless.exe","VBoxHeadless.exe","BlueStacks.exe","HD-Agent.exe")
}

function Get-SophiaEmulatorProcessNames
{
	return @("dnplayer","LdVBoxHeadless","Ld9BoxHeadless","LdBoxHeadless","HD-Player","Nox","NoxVMHandle","MuMuPlayer","NemuPlayer","NemuHeadless","MEmu","MEmuHeadless","VBoxHeadless")
}

function Set-SophiaExeCpuPriority
{
	param([switch]$Remove)
	$ifeoRoot = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	foreach ($exe in (Get-SophiaEmulatorExeNames))
	{
		$perfKey = Join-Path (Join-Path $ifeoRoot $exe) "PerfOptions"
		if ($Remove)
		{
			Remove-ItemProperty -Path $perfKey -Name "CpuPriorityClass" -Force -ErrorAction SilentlyContinue
		}
		else
		{
			Set-SophiaRegValue -Path $perfKey -Name "CpuPriorityClass" -Value 3 -Type "DWord"
		}
	}
}

function Test-SophiaExeCpuPriority
{
	$key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dnplayer.exe\PerfOptions"
	return ((Get-SophiaRegValue -Path $key -Name "CpuPriorityClass") -eq 3)
}

function Get-SophiaDiscoveredEmulatorPaths
{
	$paths = @()
	$candidates = @(
		"$env:SystemDrive\LDPlayer\LDPlayer9\dnplayer.exe", "$env:SystemDrive\LDPlayer\LDPlayer4.0\dnplayer.exe",
		"${env:ProgramFiles}\LDPlayer\LDPlayer9\dnplayer.exe",
		"${env:ProgramFiles}\BlueStacks_nxt\HD-Player.exe", "${env:ProgramFiles(x86)}\Nox\bin\Nox.exe",
		"${env:ProgramFiles}\MuMuPlayer-12.0\shell\MuMuPlayer.exe", "${env:ProgramFiles(x86)}\Microvirt\MEmu\MEmu.exe"
	)
	foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { $paths += $c } }
	foreach ($name in (Get-SophiaEmulatorProcessNames))
	{
		Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
			try { if ($_.Path -and ($paths -notcontains $_.Path)) { $paths += $_.Path } } catch {}
		}
	}
	return $paths
}

function Set-SophiaExeGpuPreference
{
	param([switch]$Remove)
	$key = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
	foreach ($path in (Get-SophiaDiscoveredEmulatorPaths))
	{
		if ($Remove) { Remove-ItemProperty -Path $key -Name $path -Force -ErrorAction SilentlyContinue }
		else { Set-SophiaRegValue -Path $key -Name $path -Value "GpuPreference=2;" -Type "String" }
	}
}

function Set-SophiaExeDisableFSO
{
	param([switch]$Remove)
	$key = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
	foreach ($path in (Get-SophiaDiscoveredEmulatorPaths))
	{
		if ($Remove) { Remove-ItemProperty -Path $key -Name $path -Force -ErrorAction SilentlyContinue }
		else { Set-SophiaRegValue -Path $key -Name $path -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" -Type "String" }
	}
}

function Get-SophiaPciDeviceParamKeys
{
	param([string[]]$ClassGuids)
	$results = @()
	$enumRoot = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"
	if (-not (Test-Path $enumRoot)) { return $results }
	Get-ChildItem -Path $enumRoot -ErrorAction SilentlyContinue | ForEach-Object {
		Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
			$dev = $_
			try
			{
				$classGuid = (Get-ItemProperty -Path $dev.PSPath -Name "ClassGUID" -ErrorAction SilentlyContinue).ClassGUID
				if ($classGuid -and ($ClassGuids -contains $classGuid))
				{
					$results += ($dev.PSPath + "\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties")
				}
			} catch {}
		}
	}
	return $results
}

function Enable-SophiaMsiMode
{
	# Display {4d36e968} + SCSIAdapter/NVMe {4d36e97b} + Net {4d36e972}
	$keys = Get-SophiaPciDeviceParamKeys -ClassGuids @("{4d36e968-e325-11ce-bfc1-08002be10318}", "{4d36e97b-e325-11ce-bfc1-08002be10318}", "{4d36e972-e325-11ce-bfc1-08002be10318}")
	$count = 0
	foreach ($k in $keys) { Set-SophiaRegValue -Path $k -Name "MSISupported" -Value 1 -Type "DWord"; $count++ }
	return $count
}

function Disable-SophiaMsiMode
{
	$keys = Get-SophiaPciDeviceParamKeys -ClassGuids @("{4d36e968-e325-11ce-bfc1-08002be10318}", "{4d36e97b-e325-11ce-bfc1-08002be10318}", "{4d36e972-e325-11ce-bfc1-08002be10318}")
	foreach ($k in $keys) { Remove-ItemProperty -Path $k -Name "MSISupported" -Force -ErrorAction SilentlyContinue }
}

function Test-SophiaMsiMode
{
	$keys = Get-SophiaPciDeviceParamKeys -ClassGuids @("{4d36e968-e325-11ce-bfc1-08002be10318}")
	foreach ($k in $keys) { if ((Get-SophiaRegValue -Path $k -Name "MSISupported") -eq 1) { return $true } }
	return $false
}

function Set-SophiaDeviceClassNoPowerOff
{
	param([switch]$Restore)
	# Net {4d36e972} + USB {36fc9e60}
	foreach ($guid in @("{4d36e972-e325-11ce-bfc1-08002be10318}", "{36fc9e60-c465-11cf-8056-444553540000}"))
	{
		$classRoot = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$guid"
		if (-not (Test-Path $classRoot)) { continue }
		Get-ChildItem -Path $classRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
			if ($Restore) { Remove-ItemProperty -Path $_.PSPath -Name "PnPCapabilities" -Force -ErrorAction SilentlyContinue }
			else { Set-SophiaRegValue -Path $_.PSPath -Name "PnPCapabilities" -Value 24 -Type "DWord" }
		}
	}
}

function Set-SophiaNetAdapterExtreme
{
	param([switch]$Restore)
	try
	{
		Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Disabled' } | ForEach-Object {
						$props = @(
				@{ K = "*InterruptModeration"; On = "0"; Off = "1" },
				@{ K = "*RSS"; On = "1"; Off = "1" },
				@{ K = "*LsoV2IPv4"; On = "0"; Off = "1" },
				@{ K = "*LsoV2IPv6"; On = "0"; Off = "1" },
				@{ K = "*EEE"; On = "0"; Off = "1" },
				@{ K = "*SelectiveSuspend"; On = "0"; Off = "1" },
				@{ K = "*JumboPacket"; On = "1514"; Off = "1514" }
			)
			foreach ($p in $props)
			{
				$val = if ($Restore) { $p.Off } else { $p.On }
				try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword $p.K -RegistryValue $val -NoRestart -ErrorAction SilentlyContinue } catch {}
			}
			try { Enable-NetAdapterRss -Name $_.Name -ErrorAction SilentlyContinue } catch {}
		}
	} catch {}
}

function Set-SophiaStorageExtreme
{
	param([switch]$Restore)
	if ($Restore)
	{
		& fsutil behavior set disablelastaccess 2 2>$null | Out-Null
		& fsutil behavior set disable8dot3 0 2>$null | Out-Null
		& fsutil behavior set memoryusage 1 2>$null | Out-Null
	}
	else
	{
		& fsutil behavior set disablelastaccess 1 2>$null | Out-Null
		& fsutil behavior set disable8dot3 1 2>$null | Out-Null
		& fsutil behavior set memoryusage 2 2>$null | Out-Null
		& fsutil behavior set disabledeletenotify 0 2>$null | Out-Null
	}
}

function Test-SophiaStorageExtreme
{
	try
	{
		$out = & fsutil behavior query disablelastaccess 2>$null
		return ($out -match '=\s*1')
	} catch { return $false }
}

function Set-SophiaAmdUlps
{
	param([switch]$Restore)
	$classRoot = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
	if (-not (Test-Path $classRoot)) { return }
	$ulpsValue = 0
	if ($Restore) { $ulpsValue = 1 }
	Get-ChildItem -Path $classRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
		if (Get-ItemProperty -Path $_.PSPath -Name "EnableUlps" -ErrorAction SilentlyContinue)
		{
			Set-SophiaRegValue -Path $_.PSPath -Name "EnableUlps" -Value $ulpsValue -Type "DWord"
		}
	}
}

function Set-SophiaPowerSetting
{
	param([string]$SubGroup, [string]$Setting, $Value)
	& powercfg /setacvalueindex SCHEME_CURRENT $SubGroup $Setting $Value 2>$null | Out-Null
}

function Import-SophiaUltimatePowerProfile
{
	& powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
	$lineMatch = & powercfg /list 2>$null | Select-String "Ultimate Performance" | Select-Object -First 1
	$line = if ($lineMatch) { $lineMatch.ToString() } else { "" }
	if ($line -match '([0-9a-f]{8}-[0-9a-f-]+)') { & powercfg /setactive $Matches[1] 2>$null | Out-Null }
	# SUB_PROCESSOR 54533251-82be-4824-96c1-47b60b740d00
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "893dee8e-2bef-41e0-89c6-b55d0929964c" 100   # PROCTHROTTLEMIN
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "bc5038f7-23e0-4960-96da-33abaf5935ec" 100   # PROCTHROTTLEMAX
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "0cc5b647-c1df-4637-891a-dec35c318583" 100   # CPMINCORES
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "ea062031-0e34-4ff1-9b6d-eb1059334028" 100   # CPMAXCORES
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "be337238-0d82-4146-a960-4f3749d470c7" 2     # PERFBOOSTMODE Aggressive
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "94d3a615-a899-4ac5-ae2b-e4d8f634367f" 1     # SYSCOOLPOL Active
	Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "36687f9e-e3a5-4dbf-b1dc-15eb381c6863" 0     # PERFEPP Performance
	# SUB_DISK 0012ee47-9041-4b5d-9b77-535fba8b1442 / DISKIDLE 6738e2c4-e8a5-4a42-b16a-e040e769756e
	Set-SophiaPowerSetting "0012ee47-9041-4b5d-9b77-535fba8b1442" "6738e2c4-e8a5-4a42-b16a-e040e769756e" 0
	# SUB_PCIE 501a4d13-42af-4429-9fd1-a8218c268e20 / ASPM ee12f906-d277-404b-b6da-e5fa1a576df5
	Set-SophiaPowerSetting "501a4d13-42af-4429-9fd1-a8218c268e20" "ee12f906-d277-404b-b6da-e5fa1a576df5" 0
	# SUB_SLEEP 238c9fa8-0aad-41ed-83f4-97be242c8f20 / STANDBYIDLE 29f6c1db-86da-48c5-9fdb-f2b67b1f44da
	Set-SophiaPowerSetting "238c9fa8-0aad-41ed-83f4-97be242c8f20" "29f6c1db-86da-48c5-9fdb-f2b67b1f44da" 0
	& powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
}

function Invoke-SophiaProcessBoostNow
{
	$boosted = 0
	$cores = [Environment]::ProcessorCount
	$allButCore0 = $null
	if ($cores -gt 4) { $allButCore0 = [IntPtr]([Int64]([Math]::Pow(2, $cores) - 2)) }
	foreach ($name in (Get-SophiaEmulatorProcessNames))
	{
		Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
			try
			{
				$_.PriorityClass = "AboveNormal"
				if ($allButCore0) { $_.ProcessorAffinity = $allButCore0 }
				$boosted++
			} catch {}
		}
	}
	return $boosted
}

function Register-SophiaProcessBoosterTask
{
	$dir = Get-SophiaDataDir
	$scriptPath = Join-Path $dir "MolikBooster.ps1"
	$script = @'
$names = @("dnplayer","LdVBoxHeadless","Ld9BoxHeadless","LdBoxHeadless","HD-Player","Nox","NoxVMHandle","MuMuPlayer","NemuPlayer","NemuHeadless","MEmu","MEmuHeadless","VBoxHeadless")
$cores = [Environment]::ProcessorCount
$mask = $null
if ($cores -gt 4) { $mask = [IntPtr]([Int64]([Math]::Pow(2, $cores) - 2)) }
foreach ($n in $names) {
	Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
		try { $_.PriorityClass = "AboveNormal"; if ($mask) { $_.ProcessorAffinity = $mask } } catch {}
	}
}
'@
	Set-Content -Path $scriptPath -Value $script -Encoding UTF8 -Force
	$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
	$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
	$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
	$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest -LogonType ServiceAccount
	Register-ScheduledTask -TaskName "MOLIK_WINLIK_Booster" -TaskPath "\MOLIK_WINLIK\" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Every 5 min: AboveNormal priority + affinity off Core 0 for Android emulator processes" -Force | Out-Null
	Invoke-SophiaProcessBoostNow | Out-Null
}

function Unregister-SophiaProcessBoosterTask
{
	Unregister-ScheduledTask -TaskName "MOLIK_WINLIK_Booster" -TaskPath "\MOLIK_WINLIK\" -Confirm:$false -ErrorAction SilentlyContinue
	Unregister-ScheduledTask -TaskName "Sophia_Process_Booster" -TaskPath "\Sophia\" -Confirm:$false -ErrorAction SilentlyContinue
}

function Start-MolikTimerDaemon
{
	$dir = Get-SophiaDataDir
	$scriptPath = Join-Path $dir "MolikTimer.ps1"
	$script = @'
$code = @"
using System;
using System.Runtime.InteropServices;
public static class TimerRes {
	[DllImport("ntdll.dll", SetLastError = true)] public static extern int NtSetTimerResolution(int DesiredResolution, bool SetResolution, out int CurrentResolution);
	public static void Run() { int cur; NtSetTimerResolution(5000, true, out cur); }
}
"@
Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
[TimerRes]::Run()
while ($true) { Start-Sleep -Seconds 3600 }
'@
	Set-Content -Path $scriptPath -Value $script -Encoding UTF8 -Force
	$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
	$trigger = New-ScheduledTaskTrigger -AtLogOn
	$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 3650)
	$principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -RunLevel Highest -LogonType Interactive
	Register-ScheduledTask -TaskName "MOLIK_WINLIK_Timer" -TaskPath "\MOLIK_WINLIK\" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Holds Windows timer resolution at 0.5ms (NtSetTimerResolution 5000) for minimum game/emulator latency" -Force | Out-Null
	Start-ScheduledTask -TaskName "MOLIK_WINLIK_Timer" -TaskPath "\MOLIK_WINLIK\" -ErrorAction SilentlyContinue
}

function Stop-MolikTimerDaemon
{
	Stop-ScheduledTask -TaskName "MOLIK_WINLIK_Timer" -TaskPath "\MOLIK_WINLIK\" -ErrorAction SilentlyContinue
	Unregister-ScheduledTask -TaskName "MOLIK_WINLIK_Timer" -TaskPath "\MOLIK_WINLIK\" -Confirm:$false -ErrorAction SilentlyContinue
	Unregister-ScheduledTask -TaskName "Sophia_Timer_Resolution" -TaskPath "\Sophia\" -Confirm:$false -ErrorAction SilentlyContinue
	try
	{
		Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
			Where-Object { $_.CommandLine -match 'MolikTimer' } |
			ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
	} catch {}
}

function Set-SophiaInterruptPriority
{
	param([switch]$Restore)
	# Display {4d36e968} + SCSIAdapter/NVMe {4d36e97b}: DevicePriority 3 = High interrupt priority
	$enumRoot = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"
	if (-not (Test-Path $enumRoot)) { return }
	$guids = @("{4d36e968-e325-11ce-bfc1-08002be10318}", "{4d36e97b-e325-11ce-bfc1-08002be10318}")
	Get-ChildItem -Path $enumRoot -ErrorAction SilentlyContinue | ForEach-Object {
		Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
			try
			{
				$cg = (Get-ItemProperty -Path $_.PSPath -Name "ClassGUID" -ErrorAction SilentlyContinue).ClassGUID
				if ($cg -and ($guids -contains $cg))
				{
					$intKey = $_.PSPath + "\Device Parameters\Interrupt Management"
					if ($Restore) { Remove-ItemProperty -Path $intKey -Name "DevicePriority" -Force -ErrorAction SilentlyContinue }
					else { Set-SophiaRegValue -Path $intKey -Name "DevicePriority" -Value 3 -Type "DWord" }
				}
			} catch {}
		}
	}
}

function Set-SophiaNetAdapterBuffers
{
	param([switch]$Restore)
	try
	{
		Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Disabled' } | ForEach-Object {
			$rx = if ($Restore) { "512" } else { "2048" }
			$tx = if ($Restore) { "512" } else { "2048" }
			try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*ReceiveBuffers" -RegistryValue $rx -NoRestart -ErrorAction SilentlyContinue } catch {}
			try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*TransmitBuffers" -RegistryValue $tx -NoRestart -ErrorAction SilentlyContinue } catch {}
		}
	} catch {}
}

function Set-SophiaNvidiaPowerLimit
{
	param([switch]$Restore)
	$smi = $null
	$cmd = Get-Command "nvidia-smi.exe" -ErrorAction SilentlyContinue
	if ($cmd) { $smi = $cmd.Source }
	elseif (Test-Path "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe") { $smi = "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe" }
	if (-not $smi) { return $false }
	try
	{
		if ($Restore)
		{
			$def = (& $smi "--query-gpu=power.default_limit" "--format=csv,noheader" 2>$null | Select-Object -First 1).ToString().Trim() -replace '[^0-9.]', ''
			if ($def) { & $smi -pl $def 2>$null | Out-Null }
		}
		else
		{
			$max = (& $smi "--query-gpu=power.max_limit" "--format=csv,noheader" 2>$null | Select-Object -First 1).ToString().Trim() -replace '[^0-9.]', ''
			if ($max) { & $smi -pl $max 2>$null | Out-Null }
		}
		return $true
	} catch { return $false }
}

function Set-SophiaPagefileFastestDrive
{
	param([switch]$Restore)
	try
	{
		if ($Restore)
		{
			$cs = Get-CimInstance Win32_ComputerSystem
			$cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $true } -ErrorAction SilentlyContinue
			Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Remove-CimInstance -ErrorAction SilentlyContinue
			return
		}
		$best = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue |
			Sort-Object FreeSpace -Descending | Select-Object -First 1
		if (-not $best) { return }
		$totalGB = [Math]::Ceiling((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
		$size = [Math]::Max(16384, [int]($totalGB * 1024 * 1.5))
		$cs = Get-CimInstance Win32_ComputerSystem
		$cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $false } -ErrorAction SilentlyContinue
		Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Remove-CimInstance -ErrorAction SilentlyContinue
		New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = "$($best.DeviceID)\pagefile.sys"; InitialSize = $size; MaximumSize = $size } -ErrorAction SilentlyContinue | Out-Null
	} catch {}
}

function Set-SophiaExeIoPriority
{
	param([switch]$Remove)
	$ifeoRoot = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	foreach ($exe in (Get-SophiaEmulatorExeNames))
	{
		$perfKey = Join-Path (Join-Path $ifeoRoot $exe) "PerfOptions"
		if ($Remove)
		{
			Remove-ItemProperty -Path $perfKey -Name "IoPriority" -Force -ErrorAction SilentlyContinue
			Remove-ItemProperty -Path $perfKey -Name "PagePriority" -Force -ErrorAction SilentlyContinue
		}
		else
		{
			Set-SophiaRegValue -Path $perfKey -Name "IoPriority" -Value 3 -Type "DWord"
			Set-SophiaRegValue -Path $perfKey -Name "PagePriority" -Value 5 -Type "DWord"
		}
	}
}

function Unhide-SophiaPowerSettings
{
	param([switch]$Restore)
	$attrValue = 0
	if (-not $Restore) { $attrValue = 2 }
	$settings = @(
		"54533251-82be-4824-96c1-47b60b740d00\5d76a2ca-e8c0-402f-a133-2158492d58ad",
		"54533251-82be-4824-96c1-47b60b740d00\36687f9e-e3a5-4dbf-b1dc-15eb381c6863",
		"54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7",
		"54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583",
		"54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028",
		"54533251-82be-4824-96c1-47b60b740d00\94d3a615-a899-4ac5-ae2b-e4d8f634367f",
		"54533251-82be-4824-96c1-47b60b740d00\8baa4a8a-2c72-4c7e-8035-b6cf9943bda7"
	)
	foreach ($s in $settings)
	{
		Set-SophiaRegValue -Path ("HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\" + $s) -Name "Attributes" -Value $attrValue -Type "DWord"
	}
}

function Set-SophiaNetAdapterCoalescing
{
	param([switch]$Restore)
	try
	{
		Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Disabled' } | ForEach-Object {
			$val = "1"
			if (-not $Restore) { $val = "0" }
			try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*PacketCoalescing" -RegistryValue $val -NoRestart -ErrorAction SilentlyContinue } catch {}
			try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*DmaCoalescing" -RegistryValue $val -NoRestart -ErrorAction SilentlyContinue } catch {}
		}
	} catch {}
}

function Set-SophiaNicWakeOff
{
	param([switch]$Restore)
	try
	{
		Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Disabled' } | ForEach-Object {
			$val = "0"
			if ($Restore) { $val = "1" }
			try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*WakeOnMagicPacket" -RegistryValue $val -NoRestart -ErrorAction SilentlyContinue } catch {}
			try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*WakeOnPattern" -RegistryValue $val -NoRestart -ErrorAction SilentlyContinue } catch {}
		}
	} catch {}
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\Benchmark.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Before/After Performance Benchmark

	.DESCRIPTION
	Lightweight repeatable benchmark (CPU single + multi via Jobs, disk 128MB sequential,
	RAM/process snapshot) saved as JSON so users can measure the real gain after optimizing.
	Results: $env:SystemDrive\MOLIK_WINLIK_Backups\Benchmarks\bench_<label>_<time>.json
#>

function Invoke-SophiaBenchmark
{
	[CmdletBinding()]
	param([string]$Label = "After")

	Write-Host ""
	Write-Host "  ══════════ MOLIK WINLIK BENCHMARK [$Label] — đang đo, vui lòng không thao tác... ══════════" -ForegroundColor Cyan

	# CPU single-thread: integer/hash loop
	$swSingle = [System.Diagnostics.Stopwatch]::StartNew()
	$acc = [Int64]0
	for ($i = 0; $i -lt 3000000; $i++) { $acc += ($i * 31) % 97 }
	$swSingle.Stop()
	$singleOps = [Math]::Round(3000000 / $swSingle.Elapsed.TotalSeconds, 0)

	# CPU multi-thread: one Job per logical core (hash workload)
	$multiOps = 0
	try
	{
		$cores = [Environment]::ProcessorCount
		$jobBlock = {
			$h = 0
			for ($i = 0; $i -lt 4000; $i++)
			{
				$bytes = [System.Text.Encoding]::UTF8.GetBytes("molikwinlik-bench-$i-$h")
				$h = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Length + $i
			}
			return 4000
		}
		$swMulti = [System.Diagnostics.Stopwatch]::StartNew()
		$jobs = @()
		for ($c = 0; $c -lt $cores; $c++) { $jobs += Start-Job -ScriptBlock $jobBlock }
		$done = $jobs | Wait-Job -Timeout 120 | Receive-Job
		$jobs | Remove-Job -Force -ErrorAction SilentlyContinue
		$swMulti.Stop()
		$totalIter = ($done | Measure-Object -Sum).Sum
		if ($totalIter -gt 0) { $multiOps = [Math]::Round($totalIter / $swMulti.Elapsed.TotalSeconds, 0) }
	}
	catch { $multiOps = 0 }

	# Disk sequential 128MB
	$diskWrite = 0; $diskRead = 0
	$tmpFile = Join-Path $env:TEMP "molikwinlik_bench_$([Guid]::NewGuid().ToString('N')).bin"
	try
	{
		$data = New-Object byte[] (1MB)
		(New-Object Random).NextBytes($data)
		$swW = [System.Diagnostics.Stopwatch]::StartNew()
		$fs = [System.IO.File]::Create($tmpFile)
		for ($i = 0; $i -lt 128; $i++) { $fs.Write($data, 0, $data.Length) }
		$fs.Flush(); $fs.Close(); $swW.Stop()
		$diskWrite = [Math]::Round(128 / $swW.Elapsed.TotalSeconds, 1)
		$swR = [System.Diagnostics.Stopwatch]::StartNew()
		$fs = [System.IO.File]::OpenRead($tmpFile)
		$buf = New-Object byte[] (1MB)
		while ($fs.Read($buf, 0, $buf.Length) -gt 0) {}
		$fs.Close(); $swR.Stop()
		$diskRead = [Math]::Round(128 / $swR.Elapsed.TotalSeconds, 1)
	} catch {}
	finally { Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue }

	# System snapshot
	$os = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
	$freeMB = 0; $totalMB = 0; $procCount = 0
	if ($os)
	{
		$freeMB = [Math]::Round($os.FreePhysicalMemory / 1024, 0)
		$totalMB = [Math]::Round($os.TotalVisibleMemorySize / 1024, 0)
	}
	try { $procCount = (Get-Process -ErrorAction SilentlyContinue).Count } catch {}

	$result = [PSCustomObject]@{
		Label        = $Label
		Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
		CpuSingleOps = $singleOps
		CpuMultiOps  = $multiOps
		CpuScore     = [Math]::Round(($singleOps / 1000) + ($multiOps / 10), 1)
		DiskWriteMBs = $diskWrite
		DiskReadMBs  = $diskRead
		RamFreeMB    = $freeMB
		RamTotalMB   = $totalMB
		ProcessCount = $procCount
	}

	Write-Host ("  CPU Single : {0} ops/s" -f $singleOps) -ForegroundColor Green
	Write-Host ("  CPU Multi  : {0} hash/s ({1} luồng)" -f $multiOps, [Environment]::ProcessorCount) -ForegroundColor Green
	Write-Host ("  Disk Write : {0} MB/s | Read: {1} MB/s" -f $diskWrite, $diskRead) -ForegroundColor Green
	Write-Host ("  RAM trống  : {0}/{1} MB | Tiến trình đang chạy: {2}" -f $freeMB, $totalMB, $procCount) -ForegroundColor Green
	Write-Host ("  ★ ĐIỂM CPU TỔNG: {0}" -f $result.CpuScore) -ForegroundColor Yellow

	$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Benchmarks"
	New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	$file = Join-Path $dir ("bench_{0}_{1}.json" -f ($Label -replace '\W', '_'), (Get-Date -Format "yyyyMMdd_HHmmss"))
	$result | ConvertTo-Json | Set-Content -Path $file -Encoding UTF8 -Force
	Write-Host "  [✓] Đã lưu benchmark: $file" -ForegroundColor Cyan
	Write-Host "  Mẹo: chạy -Benchmark -BenchmarkLabel Before TRƯỚC khi tối ưu, rồi After để so sánh % cải thiện." -ForegroundColor Gray

	return $result
}

function Compare-SophiaBenchmarks
{
	$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Benchmarks"
	if (-not (Test-Path $dir)) { Write-Host "  [!] Chưa có benchmark nào trong $dir" -ForegroundColor Yellow; return }
	$files = Get-ChildItem -Path $dir -Filter "bench_*.json" | Sort-Object LastWriteTime
	if ($files.Count -lt 2) { Write-Host "  [!] Cần ít nhất 2 benchmark (Before/After) để so sánh. Hiện có: $($files.Count)" -ForegroundColor Yellow; return }
	$first = Get-Content $files[0].FullName -Raw | ConvertFrom-Json
	$last = Get-Content $files[-1].FullName -Raw | ConvertFrom-Json
	function Show-Delta($name, $a, $b, $unit, $invert)
	{
		if ($a -and $b)
		{
			$pct = [Math]::Round((($b - $a) / $a) * 100, 1)
			$arrow = if ($pct -ge 0) { "▲" } else { "▼" }
			if ($invert) { $arrow = if ($pct -ge 0) { "▼ (nhiều hơn)" } else { "▲ (ít hơn = tốt)" } }
			Write-Host ("  {0,-12} {1} -> {2} {3}  ({4} {5}%)" -f $name, $a, $b, $unit, $arrow, $pct) -ForegroundColor Cyan
		}
	}
	Write-Host ""
	Write-Host "  ══════════ SO SÁNH BENCHMARK: [$($first.Label)] $($first.Timestamp)  vs  [$($last.Label)] $($last.Timestamp) ══════════" -ForegroundColor Cyan
	Show-Delta "CPU Score" $first.CpuScore $last.CpuScore "điểm" $false
	Show-Delta "CPU Single" $first.CpuSingleOps $last.CpuSingleOps "ops/s" $false
	Show-Delta "CPU Multi" $first.CpuMultiOps $last.CpuMultiOps "hash/s" $false
	Show-Delta "Disk Write" $first.DiskWriteMBs $last.DiskWriteMBs "MB/s" $false
	Show-Delta "Disk Read" $first.DiskReadMBs $last.DiskReadMBs "MB/s" $false
	Show-Delta "RAM trống" $first.RamFreeMB $last.RamFreeMB "MB" $false
	Show-Delta "Tiến trình" $first.ProcessCount $last.ProcessCount "process" $true
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\PlanEngine.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Optimization Plan Engine (phân tích siêu sâu trước khi áp dụng)

	.DESCRIPTION
	Nhận danh sách tweak đã chọn và trả về KẾ HOẠCH thực thi tối ưu:
	- Tự bổ sung tweak phụ thuộc (EXT02 -> EXT23 trên Win11, CPU04 -> EXT22)
	- Loại bỏ tweak bị thay thế/mâu thuẫn (EXT07 thay GAM01, EXT39 thay EMU06, EXT03 thay EMU13)
	- Sắp xếp theo PHA an toàn: Backup -> Tasks/Services -> Registry/Privacy -> GPU/Display
	  -> Power -> Network -> Storage/Pagefile -> Kernel/BCD (cuối cùng, gần reboot nhất)
	- Đánh dấu tweak cần RESTART, tính Impact Score và cảnh báo theo ngữ cảnh.
#>

function Get-SophiaRebootTweakIds
{
	return @(
		"EMU01","EMU02","EMU03","EMU04","EMU06","CPU01","CPU04","CPU05","RAM01","RAM02","RAM03","RAM09",
		"GPU01","GPU03","GPU04","GPU05","NET01","NET08","NET09","SYS04","EXT01","EXT21","EXT22","EXT38","EXT39","EXT51","EXT54"
	)
}

function Get-SophiaTweakPhase
{
	param($Tweak)
	$id = $Tweak.Id
	if ($id -in @("EMU07","SYS02","SYS01","EXT14","EXT15","EXT27","EXT77","EXT79","EXT80")) { return 2 }
	if ($id -match '^EXT3[89]$|^EMU06$') { return 7 }
	if ($id -match '^CPU0[145]$|^EMU0[1234]$|^EXT(01|22|23|46|48)$|^RAM09$') { return 8 }
	if ($Tweak.Category -match 'PRIVACY|SYSTEM') { return 3 }
	if ($Tweak.Category -match 'GPU') { return 4 }
	if ($id -match '^GAM01$|^EXT0[789]$|^CPU0[2368]$|^EMU09$|^EXT(33|47)$') { return 5 }
	if ($Tweak.Category -match 'NETWORK') { return 6 }
	if ($Tweak.Category -match 'RAM|CPU|GAMING') { return 4 }
	return 3
}

function Get-SophiaOptimizationPlan
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]$Catalog,
		[Parameter(Mandatory)][string[]]$SelectedIds,
		$Snapshot = $null
	)

	$notes = @()
	$warnings = @()
	$ids = [System.Collections.Generic.List[string]]::new()
	foreach ($id in $SelectedIds) { if (-not $ids.Contains($id)) { $ids.Add($id) } }

	$byId = @{}
	foreach ($t in $Catalog) { $byId[$t.Id] = $t }
	$ids = @($ids | Where-Object { $byId.ContainsKey($_) })

	# ── Dependencies ──────────────────────────────────────────────────────────
	$osBuild = 0
	try { $osBuild = [int](Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild -ErrorAction SilentlyContinue) } catch {}
	if (($ids -contains "EXT02") -and $osBuild -ge 22621 -and ($ids -notcontains "EXT23"))
	{
		$ids += "EXT23"
		$notes += "[Phụ thuộc] EXT02 (Timer 0.5ms) trên Windows 11 cần EXT23 GlobalTimerResolutionRequests — đã tự bổ sung."
	}
	if (($ids -contains "CPU04") -and ($ids -notcontains "EXT22"))
	{
		$ids += "EXT22"
		$notes += "[Phụ thuộc] CPU04 tắt Spectre/Meltdown cần EXT22 (OverrideMask=3) đi cặp — đã tự bổ sung."
	}
	if (($ids -contains "EXT01"))
	{
		$notes += "[Lưu ý] EXT01 MSI Mode chỉ có hiệu lực sau RESTART và nên kiểm tra Device Manager nếu có thiết bị hoạt động lạ."
	}

	# ── Superseded / conflicts ────────────────────────────────────────────────
	if (($ids -contains "EXT07") -and ($ids -contains "GAM01"))
	{
		$ids = @($ids | Where-Object { $_ -ne "GAM01" })
		$notes += "[Mâu thuẫn] EXT07 Power Profile CỰC HẠN đã bao gồm Ultimate Performance — loại GAM01 khỏi kế hoạch."
	}
	if (($ids -contains "EXT39") -and ($ids -contains "EMU06"))
	{
		$ids = @($ids | Where-Object { $_ -ne "EMU06" })
		$notes += "[Mâu thuẫn] EXT39 (Pagefile ổ nhanh nhất) thay thế EMU06 (Pagefile ổ hệ thống) — đã loại EMU06."
	}
	if (($ids -contains "EMU03") -and ($ids -contains "EMU02"))
	{
		$ids = @($ids | Where-Object { $_ -ne "EMU02" })
		$notes += "[Mâu thuẫn] EMU03 (gỡ Hyper-V features) đã bao gồm BCD hypervisorlaunchtype=Off của EMU02 — đã loại EMU02."
	}
	if (($ids -contains "EXT03") -and ($ids -contains "EMU13"))
	{
		$ids = @($ids | Where-Object { $_ -ne "EMU13" })
		$notes += "[Trùng lặp] EXT03 Process Booster Task đã tự boost định kỳ — loại EMU13 (boost thủ công 1 lần)."
	}

	# ── Context warnings ──────────────────────────────────────────────────────
	$isLaptop = $false
	if ($Snapshot -and ($Snapshot.PSObject.Properties.Name -contains "IsLaptop")) { $isLaptop = [bool]$Snapshot.IsLaptop }
	else { try { $isLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) } catch {} }
	if ($isLaptop -and ($ids -match 'EXT08|EXT07|CPU03'))
	{
		$warnings += "Máy có pin (laptop): nhóm khóa xung/idle (EXT07/EXT08/CPU03) sẽ RẤT NÓNG và hao pin — cân nhắc bỏ tick nếu không cắm điện cố định."
	}
	if ($Snapshot -and $Snapshot.RAMTotalGB -gt 0 -and $Snapshot.RAMTotalGB -lt 32 -and ($ids -contains "CPU10"))
	{
		$warnings += "RAM < 32GB: CPU10 (tắt Page Combining) sẽ tốn thêm RAM đáng kể — Plan Engine khuyên BỎ tick CPU10 trên máy này."
	}
	if ($Snapshot -and $Snapshot.RAMTotalGB -gt 0 -and $Snapshot.RAMTotalGB -le 8 -and ($ids -contains "RAM01"))
	{
		$warnings += "RAM <= 8GB: tắt Memory Compression (RAM01) có thể làm máy dễ tràn RAM — Plan Engine khuyên GIỮ tweak này ở trạng thái tắt trên máy RAM ít."
	}
	if (($ids | Where-Object { $byId[$_].Risk -eq "Extreme" }).Count -ge 5)
	{
		$warnings += "Kế hoạch chứa >= 5 tweak Extreme: hãy chắc chắn Restore Point đã tạo và bạn sẵn sàng restart + kiểm tra ổn định sau đó."
	}

	# ── Ordering + scoring ────────────────────────────────────────────────────
	$rebootIds = Get-SophiaRebootTweakIds
	$items = foreach ($id in $ids)
	{
		$t = $byId[$id]
		$score = 1
		if ($t.Risk -eq "Moderate") { $score = 2 } elseif ($t.Risk -eq "Extreme") { $score = 3 }
		if ($t.Category -match 'GIẢ LẬP|EXTREME') { $score += 1 }
		[PSCustomObject]@{
			Id = $t.Id; Name = $t.Name; Category = $t.Category; Risk = $t.Risk
			Phase = Get-SophiaTweakPhase -Tweak $t
			NeedsReboot = ($rebootIds -contains $t.Id)
			Impact = $score
			Tweak = $t
		}
	}
	$items = @($items | Sort-Object Phase, Id)
	$totalScore = ($items | Measure-Object -Property Impact -Sum).Sum
	$level = "Nhẹ"
	if ($totalScore -ge 60) { $level = "CỰC HẠN" } elseif ($totalScore -ge 35) { $level = "Sâu" } elseif ($totalScore -ge 18) { $level = "Trung bình" }

	return [PSCustomObject]@{
		Items = $items
		Count = $items.Count
		ImpactScore = $totalScore
		Level = $level
		RebootCount = @($items | Where-Object NeedsReboot).Count
		ExtremeCount = @($items | Where-Object { $_.Risk -eq "Extreme" }).Count
		Notes = $notes
		Warnings = $warnings
		Phases = @($items | Group-Object Phase | Sort-Object { [int]$_.Name })
	}
}

function Show-SophiaOptimizationPlan
{
	param([Parameter(Mandatory)]$Plan, [string]$Title = "KẾ HOẠCH TỐI ƯU SIÊU SÂU")

	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
	Write-Host "  ║  $Title" -ForegroundColor Magenta
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
	Write-Host ("  Tổng: {0} tweak | Impact Score: {1} ({2}) | Cần restart: {3} | Extreme: {4}" -f $Plan.Count, $Plan.ImpactScore, $Plan.Level, $Plan.RebootCount, $Plan.ExtremeCount) -ForegroundColor Cyan
	$phaseNames = @{ 2 = "Pha 2 - Scheduled Tasks & Services"; 3 = "Pha 3 - Registry / Privacy / System"; 4 = "Pha 4 - GPU / Display / Multimedia"; 5 = "Pha 5 - Power Profile & CPU Power"; 6 = "Pha 6 - Network Stack"; 7 = "Pha 7 - Storage & Pagefile"; 8 = "Pha 8 - Kernel / BCD / Security Mitigations (cuối cùng)" }
	foreach ($phase in $Plan.Phases)
	{
		$pName = $phaseNames[[int]$phase.Name]
		if (-not $pName) { $pName = "Pha $($phase.Name)" }
		Write-Host ""
		Write-Host "  [$pName] ($($phase.Count) tweak)" -ForegroundColor Yellow
		foreach ($item in $phase.Group)
		{
			$rebootTag = if ($item.NeedsReboot) { " (RESTART)" } else { "" }
			Write-Host ("    - [{0}] [{1}] {2}{3}" -f $item.Id, $item.Risk, $item.Name, $rebootTag) -ForegroundColor Gray
		}
	}
	foreach ($n in $Plan.Notes) { Write-Host "  $n" -ForegroundColor Cyan }
	foreach ($w in $Plan.Warnings) { Write-Host "  ⚠ $w" -ForegroundColor Red }
	Write-Host ""
	Write-Host "  Thứ tự trên được áp dụng để tweak nền (tasks/services/registry) vào trước, kernel/BCD vào sau cùng ngay trước khi restart." -ForegroundColor DarkGray
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\SmartAdvisor.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Smart Advisor (tự phân tích phần cứng -> khuyên Mode + tweak)

	.DESCRIPTION
	Dựa trên Snapshot thật của máy (giả lập đã cài, GPU vendor, RAM, NVMe, VBS, laptop/desktop)
	để đề xuất Mode chính + các tweak bổ sung + cảnh báo. Dùng cho phím G trong CLI,
	tham số -Smart, và dòng khuyến nghị trên header giao diện.
#>

function Get-SophiaSmartRecommendation
{
	[CmdletBinding()]
	param($Snapshot, $Catalog)

	$reasons = @()
	$extraIds = @()
	$warnings = @()
	$mode = "SophiaStandard"

	if (-not $Snapshot)
	{
		return [PSCustomObject]@{ Mode = $mode; ExtraIds = @(); Reasons = @("Không đọc được thông tin phần cứng — dùng Sophia Standard an toàn."); Warnings = @() }
	}

	$hasEmulator = ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0)
	$isLaptop = $false
	if ($Snapshot -and ($Snapshot.PSObject.Properties.Name -contains "IsLaptop")) { $isLaptop = [bool]$Snapshot.IsLaptop }
	else { try { $isLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) } catch {} }

	if ($hasEmulator)
	{
		$mode = "EmulatorFarm"
		$reasons += "Phát hiện giả lập: $($Snapshot.InstalledEmulators -join ', ') -> Mode TREO GIẢ LẬP 24/7."
		$extraIds += @("EXT02","EXT03","EXT04","EXT39")
		if ($Snapshot.VBSRunning -or $Snapshot.HVCIEnabled)
		{
			$reasons += "VBS/HVCI đang BẬT và tranh VT-x với giả lập -> EMU01/EMU02/EMU04 đặc biệt quan trọng."
		}
	}
	elseif ($Snapshot.RAMTotalGB -gt 0 -and $Snapshot.RAMTotalGB -le 8)
	{
		$mode = "LowSpec"
		$reasons += "RAM chỉ $($Snapshot.RAMTotalGB)GB -> Mode LOW-SPEC / POTATO PC."
		$warnings += "RAM ít: Plan Engine sẽ cảnh báo nếu bạn tick RAM01 (tắt Memory Compression)."
	}
	elseif ($Snapshot.GPUVendor -in @("NVIDIA","AMD"))
	{
		$mode = "HardcoreGaming"
		$reasons += "GPU rời $($Snapshot.GPUName) ($($Snapshot.GPUVendor)) -> Mode HARDCORE GAMING."
	}
	else
	{
		$reasons += "Không thấy giả lập/GPU rời nổi bật, RAM $($Snapshot.RAMTotalGB)GB -> Mode WORKSTATION cân bằng."
		$mode = "Workstation"
	}

	if ($Snapshot.GPUVendor -eq "AMD") { $extraIds += "EXT12" ; $reasons += "GPU AMD: bổ sung EXT12 tắt ULPS chống stutter." }
	if ($Snapshot.GPUVendor -eq "NVIDIA") { $extraIds += "EXT43" ; $reasons += "GPU NVIDIA: bổ sung EXT43 ép Power Limit tối đa qua nvidia-smi." }
	if ($Snapshot.RAMTotalGB -ge 32) { $extraIds += "CPU10" ; $reasons += "RAM $($Snapshot.RAMTotalGB)GB (>= 32GB): bổ sung CPU10 tắt Page Combining — đổi RAM lấy CPU cho farm nhiều instance giống nhau." }
	if ($Snapshot.SystemDriveType -match "NVMe") { $extraIds += @("EXT11","EXT38") ; $reasons += "Ổ NVMe: bổ sung EXT11 (NTFS sâu) + EXT38 (Interrupt Priority) để khai thác tối đa." }
	if ($Snapshot.CPUThreads -ge 8) { $extraIds += "EXT03" ; $reasons += "CPU $($Snapshot.CPUThreads) luồng: EXT03 affinity tránh Core 0 phát huy tốt." }
	if ($isLaptop)
	{
		$warnings += "Đây là LAPTOP: Smart Advisor KHÔNG tự thêm EXT08 (khóa idle) / CPU03 — tránh nóng & hao pin. Chỉ dùng khi cắm điện cố định như máy farm."
		$extraIds = @($extraIds | Where-Object { $_ -notin @("EXT08") })
	}
	if ($Snapshot.HAGSEnabled) { $reasons += "HAGS đã bật sẵn (GPU01 có thể bỏ tick)." }

	$catalogIds = @($Catalog | ForEach-Object { $_.Id })
	$extraIds = @($extraIds | Select-Object -Unique | Where-Object { $catalogIds -contains $_ })

	return [PSCustomObject]@{
		Mode = $mode
		ExtraIds = $extraIds
		Reasons = $reasons
		Warnings = $warnings
		IsLaptop = $isLaptop
	}
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\Presets.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Built-in Presets (goi toi uu theo kich ban co san)

	.DESCRIPTION
	Moi Preset = 1 Mode nen + tweak cong them (ExtraIds) + tweak loai tru
	(ExcludeIds / ExcludeRisks), duoc Resolve-MolikPreset giai ra danh sach
	ID cuoi cung theo dung thu tu Catalog. Dung qua:
	  .\MolikWinlik.ps1 -ListPresets
	  .\MolikWinlik.ps1 -Preset esports-fps -Plan
	  .\MolikWinlik.ps1 -Preset farm-max -Apply -Yes
	hoac phim X trong Menu don gian. ID duoc kiem tra ton tai trong SelfTest.
#>

function Get-MolikPresets
{
	return @(
		[PSCustomObject]@{
			Name = "farm-max"; Icon = "🖥️"; Mode = "EmulatorFarm"
			Title = "FARM CỰC HẠN (multi-instance 24/7)"
			Description = "Mode Treo Giả Lập + MSI Mode cho GPU/NVMe (EXT01), khóa driver qua Update (EXT81), tắt ARSO (EXT84). Dành cho dàn farm cắm điện cố định đã có backup."
			ExtraIds = @("EXT01", "EXT81", "EXT84"); ExcludeIds = @(); ExcludeRisks = @()
		},
		[PSCustomObject]@{
			Name = "farm-safe-247"; Icon = "🛡️"; Mode = "EmulatorFarm"
			Title = "FARM AN TOÀN 24/7 (không Extreme)"
			Description = "Toàn bộ Mode Treo Giả Lập nhưng loại mọi tweak rủi ro Extreme (không tắt VBS/HVCI/Spectre, không khóa idle). Treo ổn định lâu dài cho máy còn dùng việc khác."
			ExtraIds = @("EXT81", "EXT84"); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		},
		[PSCustomObject]@{
			Name = "esports-fps"; Icon = "🎮"; Mode = "HardcoreGaming"
			Title = "ESPORTS FPS (latency tối thiểu, giữ mát)"
			Description = "Hardcore Gaming nhưng loại EXT08 (khóa C-State gây nóng) và EXT44 (tắt HWP tự trị) — giữ frame-time ổn định cho thi đấu dài thay vì ép xung nhiệt."
			ExtraIds = @("EXT76", "EXT81"); ExcludeIds = @("EXT08", "EXT44"); ExcludeRisks = @()
		},
		[PSCustomObject]@{
			Name = "streamer-workstation"; Icon = "🎬"; Mode = "Workstation"
			Title = "STREAMER / WORKSTATION"
			Description = "Workstation + SystemResponsiveness=0 (GAM07) + MMCSS Games High (EXT16) cho OBS/game capture mượt, vẫn giữ mitigations và độ ổn định khi render dài."
			ExtraIds = @("GAM07", "EXT16", "EXT40"); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		},
		[PSCustomObject]@{
			Name = "potato-plus"; Icon = "🥔"; Mode = "LowSpec"
			Title = "POTATO PLUS (máy yếu hồi sinh)"
			Description = "LowSpec + mở app Startup tức thì (EXT76) + tắt Biometric/Agent nền (EXT82/EXT83). Cho máy RAM <=8GB, ổ chậm, cần nhẹ tối đa mà vẫn an toàn."
			ExtraIds = @("EXT76", "EXT82", "EXT83"); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		},
		[PSCustomObject]@{
			Name = "privacy-max"; Icon = "🔒"; Mode = "SophiaStandard"
			Title = "PRIVACY MAX (riêng tư tối đa, không đụng hiệu năng)"
			Description = "MOLIK Standard + chặn app nền bằng Policy (EXT49), tắt CEIP/Program Inventory (EXT56/EXT57), chặn app quảng cáo tự cài (EXT72), tắt Clipboard đám mây (PRI11)."
			ExtraIds = @("EXT49", "EXT56", "EXT57", "EXT72", "PRI11"); ExcludeIds = @(); ExcludeRisks = @()
		},
		[PSCustomObject]@{
			Name = "god-safe"; Icon = "👑"; Mode = "GodMode"
			Title = "GOD SAFE (toàn bộ tweak an toàn toàn catalog)"
			Description = "Mọi tweak trong catalog trừ nhóm Extreme — gói 'quét sạch an toàn' cho người muốn tối ưu tối đa mà không đánh đổi bảo mật/ổn định kernel."
			ExtraIds = @(); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		}
	)
}

function Resolve-MolikPreset
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]$Preset,
		[Parameter(Mandatory)]$Catalog
	)

	$ids = @(Get-SophiaModeTweakIds -ModeKey $Preset.Mode -Catalog $Catalog)
	foreach ($extra in @($Preset.ExtraIds))
	{
		if (($Catalog.Id -contains $extra) -and ($ids -notcontains $extra)) { $ids += $extra }
	}
	if (@($Preset.ExcludeIds).Count -gt 0)
	{
		$ids = @($ids | Where-Object { $Preset.ExcludeIds -notcontains $_ })
	}
	if (@($Preset.ExcludeRisks).Count -gt 0)
	{
		$riskById = @{}
		foreach ($t in $Catalog) { $riskById[$t.Id] = $t.Risk }
		$ids = @($ids | Where-Object { $Preset.ExcludeRisks -notcontains $riskById[$_] })
	}
	# Tra ve theo thu tu Catalog de UI/Plan de doc
	return @($Catalog | Where-Object { $ids -contains $_.Id } | ForEach-Object { $_.Id })
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\ReportEngine.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - HTML Dashboard Report Engine (offline, 1 file HTML doc lap)

	.DESCRIPTION
	Xuat bao cao he thong + trang thai toi uu dang HTML tu chua (CSS nhung san)
	de mo bang trinh duyet, gui cho ky thuat vien hoac luu ho so may:
	  .\MolikWinlik.ps1 -ExportReport     (sinh ca JSON lan HTML)
	Trong giao dien tick-chon: phim H. Trong Menu don gian: phim H.
	Khong can Internet, khong tai tai nguyen ngoai.
#>

function Get-MolikAppliedStatus
{
	[CmdletBinding()]
	param([Parameter(Mandatory)]$Catalog, [string[]]$Ids)

	$targets = @($Catalog)
	if ($Ids -and $Ids.Count -gt 0) { $targets = @($Catalog | Where-Object { $Ids -contains $_.Id }) }
	$status = @{}
	foreach ($t in $targets)
	{
		try { $status[$t.Id] = [bool](& $t.CheckScript) } catch { $status[$t.Id] = $false }
	}
	return $status
}

function Export-MolikHtmlReport
{
	[CmdletBinding()]
	param(
		$Snapshot,
		[Parameter(Mandatory)]$Catalog,
		[string]$Path = "",
		[switch]$SkipStatus
	)

	if (-not $Path)
	{
		$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Reports"
		New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
		$Path = Join-Path $dir ("MolikWinlik-Report-{0}.html" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
	}

	$enc = { param($v) if ($null -eq $v) { return "" } return [System.Net.WebUtility]::HtmlEncode([string]$v) }
	$ver = if ($Global:MolikWinlikVersion) { $Global:MolikWinlikVersion } else { "3.1.0" }
	$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

	$status = @{}
	$appliedCount = -1
	if (-not $SkipStatus)
	{
		$status = Get-MolikAppliedStatus -Catalog $Catalog
		$appliedCount = @($status.Keys | Where-Object { $status[$_] }).Count
	}

	$osName = & $enc $Snapshot.OSName
	$cpu = & $enc $Snapshot.CPUName
	$gpu = & $enc $Snapshot.GPUName
	$ram = & $enc $Snapshot.RAMTotalGB
	$drive = & $enc $Snapshot.SystemDriveType
	$admin = if ($Snapshot.IsAdmin) { "Administrator" } else { "Standard User" }
	$emu = if ($Snapshot.InstalledEmulators) { & $enc ($Snapshot.InstalledEmulators -join ", ") } else { "—" }
	$reboot = if ($Snapshot.PendingReboot) { '<span class="badge ext">PENDING REBOOT</span>' } else { '<span class="badge safe">OK</span>' }
	$appliedText = if ($appliedCount -ge 0) { "$appliedCount / $($Catalog.Count)" } else { "— (bỏ qua kiểm tra)" }

	$modeRows = ""
	foreach ($m in (Get-SophiaOptimizationModes))
	{
		$mIds = @(Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog)
		$impact = "—"
		try
		{
			if (Get-Command Get-SophiaOptimizationPlan -ErrorAction SilentlyContinue)
			{
				$plan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $mIds
				$impact = "$($plan.ImpactScore) ($($plan.Level))"
			}
		} catch {}
		$modeRows += "<tr><td>$(& $enc $m.Icon) $(& $enc $m.Name)</td><td>$(& $enc $m.Sub)</td><td>$($mIds.Count)</td><td>$impact</td></tr>`n"
	}

	$tweakRows = ""
	foreach ($t in $Catalog)
	{
		$riskClass = "safe"
		if ($t.Risk -eq "Extreme") { $riskClass = "ext" } elseif ($t.Risk -eq "Moderate") { $riskClass = "mod" }
		$applied = "—"
		if ($status.ContainsKey($t.Id)) { $applied = if ($status[$t.Id]) { "● Đã áp" } else { "○ Chưa" } }
		$tweakRows += "<tr><td><code>$(& $enc $t.Id)</code></td><td>$(& $enc $t.Name)</td><td>$(& $enc $t.Category)</td><td><span class=`"badge $riskClass`">$(& $enc $t.Risk)</span></td><td>$applied</td></tr>`n"
	}

	$html = @"
<!DOCTYPE html>
<html lang="vi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MOLIK WINLIK Report - $osName</title>
<style>
 body{font-family:'Segoe UI',system-ui,sans-serif;background:#0d1117;color:#e6edf3;margin:0;padding:24px}
 h1{color:#f778ba;margin:0} h2{color:#58a6ff;border-bottom:1px solid #30363d;padding-bottom:6px}
 .sub{color:#8b949e} .cards{display:flex;flex-wrap:wrap;gap:12px;margin:16px 0}
 .card{background:#161b22;border:1px solid #30363d;border-radius:10px;padding:14px 18px;min-width:170px}
 .card b{font-size:20px;color:#fff;display:block}
 table{border-collapse:collapse;width:100%;margin:12px 0} th,td{border:1px solid #30363d;padding:7px 10px;text-align:left;font-size:14px}
 th{background:#1f242e} code{color:#ffa657}
 .badge{padding:2px 8px;border-radius:20px;font-size:12px;font-weight:600}
 .safe{background:#238636;color:#fff}.mod{background:#9e6a03;color:#fff}.ext{background:#da3633;color:#fff}
 footer{color:#8b949e;font-size:13px;margin-top:24px}
</style></head><body>
<h1>👑 MOLIK WINLIK <span class="sub">v$ver — by @nggkhaiz</span></h1>
<div class="sub">Báo cáo hệ thống &amp; tối ưu — tạo lúc $now (offline)</div>
<div class="cards">
 <div class="card">Hệ điều hành<b>$osName</b></div>
 <div class="card">CPU<b>$cpu</b></div>
 <div class="card">RAM (GB)<b>$ram</b></div>
 <div class="card">GPU<b>$gpu</b></div>
 <div class="card">Ổ hệ thống<b>$drive</b></div>
 <div class="card">Quyền chạy<b>$admin</b></div>
 <div class="card">Tweak đã áp dụng<b>$appliedText</b></div>
 <div class="card">Chờ restart<b>$reboot</b></div>
</div>
<p>🖥️ Giả lập phát hiện: <b>$emu</b></p>
<h2>🎛️ 6 Mode tối ưu</h2>
<table><tr><th>Mode</th><th>Mô tả</th><th>Số tweak</th><th>Impact Score</th></tr>
$modeRows</table>
<h2>🧩 Toàn bộ catalog ($($Catalog.Count) tweak)</h2>
<table><tr><th>ID</th><th>Tên tweak</th><th>Nhóm</th><th>Rủi ro</th><th>Trạng thái</th></tr>
$tweakRows</table>
<footer>MOLIK WINLIK by @nggkhaiz — Báo cáo tĩnh, không chứa dữ liệu cá nhân ngoài thông số phần cứng trên. Backup: C:\MOLIK_WINLIK_Backups\</footer>
</body></html>
"@

	$html | Set-Content -Path $Path -Encoding UTF8 -Force
	Write-Host "  [✓] Đã xuất báo cáo HTML Dashboard: $Path" -ForegroundColor Green
	Write-Host "      Mở bằng trình duyệt để xem (offline, gửi kèm khi cần hỗ trợ)." -ForegroundColor Gray
	return $Path
}

function Show-MolikSystemDoctor
{
	# Chan doan nhanh sau toi uu: tong hop Snapshot + trang thai tweak da ap
	# thanh danh sach PASS / CANH BAO doc ngay tren terminal (khong can Admin
	# cho phan lon kiem tra; lenh -Doctor chay khong UAC).
	[CmdletBinding()]
	param($Snapshot, [Parameter(Mandatory)]$Catalog)

	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "  ║  🩺 MOLIK WINLIK DOCTOR — chẩn đoán hệ thống (chỉ đọc)              ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
	if (-not $Snapshot)
	{
		Write-Host "  [X] Không đọc được Snapshot phần cứng — không chẩn đoán được." -ForegroundColor Red
		return
	}
	Write-Host ("  {0} | Build {1}.{2} | {3} | {4} luồng | RAM {5}GB (trống {6}GB) | {7} trống {8}GB" -f $Snapshot.OSName, $Snapshot.OSBuild, $Snapshot.OSUBR, $Snapshot.CPUName, $Snapshot.CPUThreads, $Snapshot.RAMTotalGB, $Snapshot.RAMFreeGB, $Snapshot.SystemDriveType, $Snapshot.SystemDriveFreeGB) -ForegroundColor Gray
	Write-Host ("  GPU: {0} ({1}) | WDDM {2} | Power Plan: {3} | Tiến trình: {4} | Giả lập: {5}" -f $Snapshot.GPUName, $Snapshot.GPUVendor, $Snapshot.WDDMVersion, $Snapshot.ActivePowerPlan, $Snapshot.ProcessCount, $(if ($Snapshot.InstalledEmulators) { $Snapshot.InstalledEmulators -join ", " } else { "không phát hiện" })) -ForegroundColor Gray
	Write-Host ""

	function DoctorLine([bool]$Ok, [string]$OkText, [string]$WarnText)
	{
		if ($Ok) { Write-Host "  [✓] $OkText" -ForegroundColor Green } else { Write-Host "  [!] $WarnText" -ForegroundColor Yellow }
	}

	DoctorLine (-not $Snapshot.PendingReboot) "Không có cập nhật/file nào đang chờ restart." "Đang CHỜ RESTART (CBS/Windows Update/PendingFileRename) — hãy restart trước khi tối ưu tiếp."
	DoctorLine ($Snapshot.VTxEnabled) "VT-x/AMD-V đã bật trong BIOS (giả lập chạy được full tốc)." "VT-x CHƯA bật trong BIOS — giả lập sẽ rất chậm dù đã tweak Windows."
	DoctorLine (-not $Snapshot.VBSRunning -and -not $Snapshot.HVCIEnabled) "VBS/HVCI đang tắt — VT-x không bị tranh (tốt cho farm/giả lập)." "VBS/HVCI đang BẬT: tranh VT-x với giả lập (dùng EMU01/EMU04 nếu là máy farm chuyên dụng)."
	DoctorLine ($Snapshot.HAGSEnabled) "HAGS (GPU01) đã bật — GPU tự lập lịch, giảm latency." "HAGS chưa bật — tick GPU01 nếu GPU hỗ trợ (WDDM >= 2.7)."
	DoctorLine ($Snapshot.MPODisabled) "MPO đã tắt (OverlayTestMode=5) — giảm stutter khi nhiều cửa sổ/game." "MPO đang bật mặc định — một số máy bị flicker/stutter sẽ cần tắt MPO trong Catalog GPU."
	if ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0 -and $Snapshot.HypervisorLaunchType -eq "Off")
	{
		Write-Host "  [✓] Hypervisor launch đã Off — giả lập native (LD/MuMu/Nox) dùng VT-x trực tiếp." -ForegroundColor Green
	}
	elseif ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0)
	{
		Write-Host "  [!] Có giả lập nhưng Hypervisor vẫn '$($Snapshot.HypervisorLaunchType)' — EMU02/EMU03 giúp farm ổn định hơn (đọc kỹ mô tả trước khi tick)." -ForegroundColor Yellow
	}
	if ($Snapshot.SystemDriveFreeGB -gt 0 -and $Snapshot.SystemDriveFreeGB -lt 15)
	{
		Write-Host "  [!] Ổ hệ thống chỉ còn $($Snapshot.SystemDriveFreeGB)GB trống — Pagefile/Update dễ lỗi, hãy dọn ổ." -ForegroundColor Yellow
	}
	if ($Snapshot.IsLaptop)
	{
		Write-Host "  [i] Máy laptop: tránh các tweak khóa xung/idle (EXT07/EXT08/CPU03) khi không cắm điện cố định." -ForegroundColor DarkGray
	}

	Write-Host ""
	Write-Host "  Đang quét trạng thái $($Catalog.Count) tweak (chỉ đọc)..." -ForegroundColor Cyan
	$map = Get-MolikAppliedStatus -Catalog $Catalog
	$applied = @($Catalog | Where-Object { $map[$_.Id] })
	$extremeOn = @($applied | Where-Object { $_.Risk -eq "Extreme" })
	Write-Host ("  Đã áp dụng: {0}/{1} tweak | Extreme đang bật: {2}" -f $applied.Count, $Catalog.Count, $extremeOn.Count) -ForegroundColor Cyan
	if ($extremeOn.Count -gt 0)
	{
		Write-Host "  Các tweak Extreme đang có hiệu lực (đánh đổi bảo mật/ổn định — đảm bảo bạn chủ động chọn):" -ForegroundColor Yellow
		$extremeOn | ForEach-Object { Write-Host "      - [$($_.Id)] $($_.Name)" -ForegroundColor DarkYellow }
	}
	Write-Host "  Mẹo: -Status xem toàn bộ danh sách | -UndoLast hoàn tác phiên áp dụng gần nhất | -ExportReport xuất Dashboard HTML." -ForegroundColor DarkGray
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\WinUtilBridge.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - WinUtil Bridge (ChrisTitusTech/winutil integration, 100% OFFLINE)

	.DESCRIPTION
	Converts vendored winutil tweaks data (Optimizer/Data/WinUtilTweaks.ps1, converted from
	ChrisTitusTech/winutil config/tweaks.json, MIT License) into native Sophia tweak objects
	(ApplyScript/RestoreScript/CheckScript) in category "10. WINUTIL (Chris Titus Tech)".
	No download at runtime: all data is bundled in this repository / the Portable file.

	.NOTES
	Attribution: Chris Titus Tech Windows Utility - https://github.com/ChrisTitusTech/winutil (MIT)
#>

function Convert-WinUtilEntryValue
{
	param($Entry)
	if ($Entry.Type -eq "DWord") { try { return [int]$Entry.Value } catch { return 0 } }
	if ($Entry.Type -eq "QWord") { try { return [long]$Entry.Value } catch { return 0 } }
	return [string]$Entry.Value
}

function New-WinUtilConvertedTweak
{
	param($Raw)

	$entries = @($Raw.Entries)
	$apply = {
		foreach ($e in $entries)
		{
			$val = $e.Value
			if ($e.Type -eq "DWord") { try { $val = [int]$e.Value } catch { $val = 0 } }
			elseif ($e.Type -eq "QWord") { try { $val = [long]$e.Value } catch { $val = 0 } }
			Set-SophiaRegValue -Path $e.Path -Name $e.Name -Value $val -Type $e.Type
		}
	}.GetNewClosure()

	$restore = {
		foreach ($e in $entries)
		{
			if ($null -eq $e.Original)
			{
				Remove-ItemProperty -Path $e.Path -Name $e.Name -Force -ErrorAction SilentlyContinue
			}
			else
			{
				$val = $e.Original
				if ($e.Type -eq "DWord") { try { $val = [int]$e.Original } catch { $val = 0 } }
				elseif ($e.Type -eq "QWord") { try { $val = [long]$e.Original } catch { $val = 0 } }
				Set-SophiaRegValue -Path $e.Path -Name $e.Name -Value $val -Type $e.Type
			}
		}
	}.GetNewClosure()

	$check = {
		foreach ($e in $entries)
		{
			$current = Get-SophiaRegValue -Path $e.Path -Name $e.Name
			if ($null -eq $current -or "$current" -ne "$($e.Value)") { return $false }
		}
		return $true
	}.GetNewClosure()

	return [PSCustomObject]@{
		Id = $Raw.Id; Name = "[WinUtil] $($Raw.Name)"; Category = "10. 🧩 WINUTIL (Chris Titus Tech)"
		Description = "$($Raw.Description) (Nguồn: winutil/$($Raw.SourceKey), đã vendor offline)"
		Risk = $Raw.Risk; Modes = @($Raw.Modes)
		ApplyScript = $apply; RestoreScript = $restore; CheckScript = $check
		Kind = "WinUtilRegistry"; Detail = "$($entries.Count) registry entries (winutil $($Raw.SourceKey))"
	}
}

function Get-WinUtilConvertedTweaks
{
	if (-not (Get-Command Get-WinUtilRawTweaks -ErrorAction SilentlyContinue)) { return @() }
	$result = @()
	foreach ($raw in (Get-WinUtilRawTweaks))
	{
		try { $result += New-WinUtilConvertedTweak -Raw $raw } catch {}
	}
	return $result
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\AppInstaller.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Application Installer (winutil-style, via built-in winget)

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


# ============================================================
# [PORTABLE-INLINE] Optimizer\Data\WinUtilTweaks.ps1
# ============================================================
<#
	MOLIK WINLIK - WinUtil Tweaks Data (VENDORED, works OFFLINE - no download needed)
	Converted from ChrisTitusTech/winutil config/tweaks.json (commit 2ef5e5d), MIT License - see LICENSE-winutil.txt
	Only pure-registry Toggle tweaks were converted; tweaks duplicating/conflicting with the native 137-tweak catalog were excluded.
#>
function Get-WinUtilRawTweaks
{
	return @(
		[PSCustomObject]@{
			Id = 'WU01'; SourceKey = 'WPFTweaksRevertStartMenu'; Name = 'Start Menu Previous Layout - Enable'; Description = 'Bring back the old Start Menu layout from before the gradual rollout of the new one in 25H2. On newer versions of Windows !!THIS TWEAK WILL NOT WORK!!'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\3036241548'; Name = 'EnabledState'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU02'; SourceKey = 'WPFTweaksBraveDebloat'; Name = 'Brave Browser - Debloat'; Description = 'Disables various annoyances like Brave Rewards, Leo AI, Crypto Wallet and VPN.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveRewardsDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveWalletDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveVPNDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveAIChatEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveStatsPingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveNewsDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveTalkDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'TorDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveP3AEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'UrlKeyedAnonymizedDataCollectionEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'SafeBrowsingExtendedReportingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'MetricsReportingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU03'; SourceKey = 'WPFTweaksDisableWarningForUnsignedRdp'; Name = 'RDP Unsigned File Warnings - Disable'; Description = 'Disables warnings shown when launching unsigned RDP files introduced with the latest Windows 10 and 11 updates.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client'; Name = 'RedirectionWarningDialogVersion'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client'; Name = 'RdpLaunchConsentAccepted'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU04'; SourceKey = 'WPFTweaksEdgeDebloat'; Name = 'Microsoft Edge - Debloat'; Description = 'Disables various telemetry options, popups, and other annoyances in Edge.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'; Name = 'CreateDesktopShortcutDefault'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'PersonalizationReportingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallBlocklist'; Name = '1'; Value = 'ofefcgjbeghpigppfmkologfjadafddi'; Type = 'String'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowRecommendationsEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HideFirstRunExperience'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'UserFeedbackAllowed'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ConfigureDoNotTrack'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'AlternateErrorPagesEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeCollectionsEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeShoppingAssistantEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'MicrosoftEdgeInsiderPromotionEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowMicrosoftRewards'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'WebWidgetAllowed'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DiagnosticData'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeAssetDeliveryServiceEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'WalletDonationEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DefaultBrowserSettingsCampaignEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU05'; SourceKey = 'WPFTweaksConsumerFeatures'; Name = 'ConsumerFeatures - Disable'; Description = 'Stops promoted app installs and reduces app suggestions from Microsoft Store content.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsConsumerFeatures'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU06'; SourceKey = 'WPFTweaksUTC'; Name = 'Date & Time - Set Time to UTC'; Description = 'Essential for computers that are dual booting. Fixes the time sync with Linux systems.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'; Name = 'RealTimeIsUniversal'; Value = '1'; Type = 'QWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU07'; SourceKey = 'WPFTweaksRemoveHomeAndGallery'; Name = 'File Explorer Home and Gallery - Disable'; Description = 'Removes the Home and Gallery from Explorer and sets This PC as default.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'; Name = 'System.IsPinnedToNameSpaceTree'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU08'; SourceKey = 'WPFTweaksEndTaskOnTaskbar'; Name = 'End Task With Right Click - Enable'; Description = 'Enables option to end task when right-clicking a program in the taskbar.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name = 'TaskbarEndTask'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU09'; SourceKey = 'WPFTweaksWPBT'; Name = 'Windows Platform Binary Table (WPBT) - Disable'; Description = 'If enabled, WPBT allows your computer vendor to execute programs at boot time, such as anti-theft software, software drivers, as well as force install software without user consent. Poses potential security risk.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'DisableWpbtExecution'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU10'; SourceKey = 'WPFTweaksPreventDeviceMetadataFromNetwork'; Name = 'Prevent Device Companion Apps'; Description = 'Prevents additional software from being installed when plugging in devices (e.g. Ads when plugging in a monitor). Poses potential security risk.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata'; Name = 'PreventDeviceMetadataFromNetwork'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU11'; SourceKey = 'WPFTweaksDisableNotifications'; Name = 'System Tray Notifications & Calendar - Disable'; Description = 'Disables all Notifications INCLUDING Calendar.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name = 'DisableNotificationCenter'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications'; Name = 'ToastEnabled'; Value = '0'; Type = 'DWord'; Original = '1' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU12'; SourceKey = 'WPFToggleDetailedBSoD'; Name = 'BSoD Verbose Mode'; Description = 'Gives more information when you blue screen.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisplayParameters'; Value = '1'; Type = 'DWord'; Original = '0' }
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisableEmoticon'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU13'; SourceKey = 'WPFToggleBatteryPercentage'; Name = 'System Tray Battery Percentage'; Description = 'Shows numeric battery percentage next to the battery icon in the system tray.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'IsBatteryPercentageEnabled'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU14'; SourceKey = 'WPFToggleNewOutlook'; Name = 'Microsoft Outlook New Version'; Description = 'This will ensure the new Outlook application is used.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences'; Name = 'UseNewOutlook'; Value = '1'; Type = 'DWord'; Original = '0' }
				@{ Path = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\General'; Name = 'HideNewOutlookToggle'; Value = '0'; Type = 'DWord'; Original = '1' }
				@{ Path = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General'; Name = 'DoNewOutlookAutoMigration'; Value = '0'; Type = 'DWord'; Original = '0' }
				@{ Path = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences'; Name = 'NewOutlookMigrationUserSetting'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU15'; SourceKey = 'WPFToggleScrollbars'; Name = 'Scrollbars Always Visible'; Description = 'If enabled, scrollbars will always be visible. If disabled, Windows will automatically hide scrollbars when not in use.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Control Panel\Accessibility'; Name = 'DynamicScrollbars'; Value = '0'; Type = 'DWord'; Original = '1' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU16'; SourceKey = 'WPFToggleNumLock'; Name = 'Num Lock on Startup'; Description = 'Toggle the Num Lock key state when your computer starts.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKU:\.Default\Control Panel\Keyboard'; Name = 'InitialKeyboardIndicators'; Value = '2'; Type = 'String'; Original = '0' }
				@{ Path = 'HKCU:\Control Panel\Keyboard'; Name = 'InitialKeyboardIndicators'; Value = '2'; Type = 'String'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU17'; SourceKey = 'WPFToggleWindowSnapping'; Name = 'Window Snapping'; Description = 'Toggles the window snapping feature when dragging windows.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'WindowArrangementActive'; Value = '1'; Type = 'String'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU18'; SourceKey = 'WPFToggleStandbyFix'; Name = 'S0 Sleep Network Connectivity'; Description = 'Toggles network connectivity during S0 Sleep which is low power idle in modern laptops.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'; Name = 'ACSettingIndex'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU19'; SourceKey = 'WPFToggleS3Sleep'; Name = 'S3 Sleep'; Description = 'Toggles between Modern Standby and S3 Sleep, which cuts off power to the CPU while continuing to refresh the memory.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'; Name = 'PlatformAoAcOverride'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU20'; SourceKey = 'WPFToggleHideSettingsHome'; Name = 'Settings Home Page'; Description = 'Toggles the Home Page in the Windows Settings app.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility'; Value = 'show:home'; Type = 'String'; Original = 'hide:home' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU21'; SourceKey = 'WPFToggleBingSearch'; Name = 'Start Menu Bing Search'; Description = 'Toggles Bing web search results in Windows Search.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU22'; SourceKey = 'WPFToggleLoginBlur'; Name = 'Logon Screen Acrylic Blur'; Description = 'Toggles the acrylic blur effect on login screen background.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'DisableAcrylicBackgroundOnLogon'; Value = '0'; Type = 'DWord'; Original = '1' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU23'; SourceKey = 'WPFToggleDisableLockscreen'; Name = 'Lock Screen - Disable'; Description = 'Skips the lock screen entirely and goes directly to the sign-in screen on boot and wake.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoLockScreen'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU24'; SourceKey = 'WPFToggleTaskbarSearch'; Name = 'Taskbar Search Icon'; Description = 'Toggles the Search Button on the Taskbar.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU25'; SourceKey = 'WPFToggleTaskView'; Name = 'Taskbar Task View Icon'; Description = 'Toggles the Task View Button in the Taskbar.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTaskViewButton'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
	)
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Data\WinUtilApps.ps1
# ============================================================
<#
	MOLIK WINLIK - Applications Catalog (VENDORED from ChrisTitusTech/winutil config/applications.json, MIT)
	239 applications with winget/choco IDs - install via built-in winget, no winutil download needed.
#>
function Get-SophiaAppsCatalog
{
	return @(
		[PSCustomObject]@{ Id = '1password'; Name = '1Password'; Winget = 'AgileBits.1Password'; Choco = '1password'; Category = 'Utilities'; Description = '1Password is a password manager that allows you to store and manage your passwords securely.' }
		[PSCustomObject]@{ Id = '7zip'; Name = '7-Zip'; Winget = '7zip.7zip'; Choco = '7zip'; Category = 'Utilities'; Description = '7-Zip is a free and open-source file archiver utility. It supports several compression formats and provides a high compression ratio, making it a popular choice for file compressio' }
		[PSCustomObject]@{ Id = 'abdownloadmanager'; Name = 'AB Download Manager'; Winget = 'amir1376.ABDownloadManager'; Choco = 'ab-download-manager'; Category = 'Utilities'; Description = 'AB Download Manager is an open-source download accelerator and manager with multi-threaded downloads, queue scheduling, speed limiting, and browser integration.' }
		[PSCustomObject]@{ Id = 'adobe'; Name = 'Adobe Acrobat Reader'; Winget = 'Adobe.Acrobat.Reader.64-bit'; Choco = 'adobereader'; Category = 'Document'; Description = 'Adobe Acrobat Reader is a free PDF viewer with essential features for viewing, printing, and annotating PDF documents.' }
		[PSCustomObject]@{ Id = 'advancedip'; Name = 'Advanced IP Scanner'; Winget = 'Famatech.AdvancedIPScanner'; Choco = 'advanced-ip-scanner'; Category = 'Pro Tools'; Description = 'Advanced IP Scanner is a fast and easy-to-use network scanner. It is designed to analyze LAN networks and provides information about connected devices.' }
		[PSCustomObject]@{ Id = 'aimp'; Name = 'AIMP (Music Player)'; Winget = 'AIMP.AIMP'; Choco = 'aimp'; Category = 'Multimedia Tools'; Description = 'AIMP is a feature-rich music player with support for various audio formats, playlists, and customizable user interface.' }
		[PSCustomObject]@{ Id = 'angryipscanner'; Name = 'Angry IP Scanner'; Winget = 'angryziber.AngryIPScanner'; Choco = 'angryip'; Category = 'Pro Tools'; Description = 'Angry IP Scanner is an open-source and cross-platform network scanner. It is used to scan IP addresses and ports, providing information about network connectivity.' }
		[PSCustomObject]@{ Id = 'anydesk'; Name = 'AnyDesk'; Winget = 'AnyDesk.AnyDesk'; Choco = 'anydesk'; Category = 'Utilities'; Description = 'AnyDesk is a remote desktop software that enables users to access and control computers remotely. It is known for its fast connection and low latency.' }
		[PSCustomObject]@{ Id = 'audacity'; Name = 'Audacity'; Winget = 'Audacity.Audacity'; Choco = 'audacity'; Category = 'Multimedia Tools'; Description = 'Audacity is a free and open-source audio editing software known for its powerful recording and editing capabilities.' }
		[PSCustomObject]@{ Id = 'autoruns'; Name = 'Autoruns'; Winget = 'Microsoft.Sysinternals.Autoruns'; Choco = 'autoruns'; Category = 'Microsoft Tools'; Description = 'This utility shows you what programs are configured to run during system bootup or login.' }
		[PSCustomObject]@{ Id = 'rdcman'; Name = 'RDCMan'; Winget = 'Microsoft.Sysinternals.RDCMan'; Choco = 'rdcman'; Category = 'Microsoft Tools'; Description = 'RDCMan manages multiple remote desktop connections. It is useful for managing server labs where you need regular access to each machine such as automated checkin systems and data c' }
		[PSCustomObject]@{ Id = 'autohotkey'; Name = 'AutoHotkey'; Winget = 'AutoHotkey.AutoHotkey'; Choco = 'autohotkey'; Category = 'Utilities'; Description = 'AutoHotkey is a scripting language for Windows that allows users to create custom automation scripts and macros. It is often used for automating repetitive tasks and customizing ke' }
		[PSCustomObject]@{ Id = 'battlenet'; Name = 'Battle.net'; Winget = 'Blizzard.BattleNet'; Choco = 'na'; Category = 'Games'; Description = 'Battle.net is a launcher for games created and developed by Activision Blizzard' }
		[PSCustomObject]@{ Id = 'bitwarden'; Name = 'Bitwarden'; Winget = 'Bitwarden.Bitwarden'; Choco = 'bitwarden'; Category = 'Utilities'; Description = 'Bitwarden is an open-source password management solution. It allows users to store and manage their passwords in a secure and encrypted vault, accessible across multiple devices.' }
		[PSCustomObject]@{ Id = 'blender'; Name = 'Blender (3D Graphics)'; Winget = 'BlenderFoundation.Blender'; Choco = 'blender'; Category = 'Multimedia Tools'; Description = 'Blender is a powerful open-source 3D creation suite, offering modeling, sculpting, animation, and rendering tools.' }
		[PSCustomObject]@{ Id = 'brave'; Name = 'Brave'; Winget = 'Brave.Brave'; Choco = 'brave'; Category = 'Browsers'; Description = 'Brave is a privacy-focused web browser that blocks ads and trackers, offering a faster and safer browsing experience.' }
		[PSCustomObject]@{ Id = 'bruno'; Name = 'Bruno'; Winget = 'Bruno.Bruno'; Choco = 'bruno'; Category = 'Development'; Description = 'Bruno is a local-first API client that stores collections as plain text files for version control and collaboration.' }
		[PSCustomObject]@{ Id = 'bulkcrapuninstaller'; Name = 'Bulk Crap Uninstaller'; Winget = 'Klocman.BulkCrapUninstaller'; Choco = 'bulk-crap-uninstaller'; Category = 'Utilities'; Description = 'Bulk Crap Uninstaller is a free and open-source uninstaller utility for Windows. It helps users remove unwanted programs and clean up their system by uninstalling multiple applicat' }
		[PSCustomObject]@{ Id = 'blurautoclicker'; Name = 'BlurAutoClicker'; Winget = 'Blur009.BlurAutoClicker'; Choco = 'na'; Category = 'Utilities'; Description = 'An Auto-clicker with a few advanced features and generally better performance than popular alternatives.' }
		[PSCustomObject]@{ Id = 'calibre'; Name = 'Calibre'; Winget = 'calibre.calibre'; Choco = 'calibre'; Category = 'Multimedia Tools'; Description = 'Calibre is a powerful and easy-to-use e-book manager, viewer, and converter.' }
		[PSCustomObject]@{ Id = 'cemu'; Name = 'Cemu'; Winget = 'Cemu.Cemu'; Choco = 'cemu'; Category = 'Games'; Description = 'Cemu is a highly experimental software to emulate Wii U applications on PC.' }
		[PSCustomObject]@{ Id = 'chatgpt'; Name = 'ChatGPT Desktop'; Winget = 'msstore:9NT1R1C2HH7J'; Choco = 'na'; Category = 'Development'; Description = 'The official ChatGPT desktop app for Windows, distributed through the Microsoft Store.' }
		[PSCustomObject]@{ Id = 'chatterino'; Name = 'Chatterino'; Winget = 'ChatterinoTeam.Chatterino'; Choco = 'chatterino'; Category = 'Communications'; Description = 'Chatterino is a chat client for Twitch chat that offers a clean and customizable interface for a better streaming experience.' }
		[PSCustomObject]@{ Id = 'chrome'; Name = 'Chrome'; Winget = 'Google.Chrome'; Choco = 'googlechrome'; Category = 'Browsers'; Description = 'Google Chrome is a widely used web browser known for its speed, simplicity, and seamless integration with Google services.' }
		[PSCustomObject]@{ Id = 'chromium'; Name = 'Chromium'; Winget = 'Hibbiki.Chromium'; Choco = 'chromium'; Category = 'Browsers'; Description = 'Chromium is the open-source project that serves as the foundation for various web browsers, including Chrome.' }
		[PSCustomObject]@{ Id = 'cinebenchr23'; Name = 'Cinebench R23'; Winget = 'Maxon.CinebenchR23'; Choco = 'na'; Category = 'Pro Tools'; Description = 'Cinebench R23 is a benchmark tool for comparing CPU rendering performance across systems.' }
		[PSCustomObject]@{ Id = 'claude'; Name = 'Claude Desktop'; Winget = 'Anthropic.Claude'; Choco = 'claude'; Category = 'Development'; Description = 'Anthropic''s Claude desktop application for focused AI-assisted work and chat.' }
		[PSCustomObject]@{ Id = 'claude-code'; Name = 'Claude Code'; Winget = 'Anthropic.ClaudeCode'; Choco = 'claude-code'; Category = 'Development'; Description = 'Anthropic''s agentic coding tool for terminal and IDE development workflows.' }
		[PSCustomObject]@{ Id = 'cmake'; Name = 'CMake'; Winget = 'Kitware.CMake'; Choco = 'cmake'; Category = 'Development'; Description = 'CMake is an open-source, cross-platform family of tools designed to build, test and package software.' }
		[PSCustomObject]@{ Id = 'codex'; Name = 'Codex'; Winget = 'OpenAI.Codex'; Choco = 'codex'; Category = 'Development'; Description = 'Codex CLI is an OpenAI coding agent that runs locally in your terminal.' }
		[PSCustomObject]@{ Id = 'cpuz'; Name = 'CPU-Z'; Winget = 'CPUID.CPU-Z'; Choco = 'cpu-z'; Category = 'Pro Tools'; Description = 'CPU-Z is a system monitoring and diagnostic tool for Windows. It provides detailed information about the computer''s hardware components, including the CPU, memory, and motherboard.' }
		[PSCustomObject]@{ Id = 'crystaldiskinfo'; Name = 'Crystal Disk Info'; Winget = 'CrystalDewWorld.CrystalDiskInfo'; Choco = 'crystaldiskinfo'; Category = 'Utilities'; Description = 'Crystal Disk Info is a disk health monitoring tool that provides information about the status and performance of hard drives. It helps users anticipate potential issues and monitor' }
		[PSCustomObject]@{ Id = 'crystaldiskmark'; Name = 'Crystal Disk Mark'; Winget = 'CrystalDewWorld.CrystalDiskMark'; Choco = 'crystaldiskmark'; Category = 'Utilities'; Description = 'Crystal Disk Mark is a disk benchmarking tool that measures the read and write speeds of storage devices. It helps users assess the performance of their hard drives and SSDs.' }
		[PSCustomObject]@{ Id = 'cursor'; Name = 'Cursor'; Winget = 'Anysphere.Cursor'; Choco = 'cursoride'; Category = 'Development'; Description = 'AI-powered code editor (VS Code-based) with agentic coding features and integrated AI assistance for development workflows.' }
		[PSCustomObject]@{ Id = 'ddu'; Name = 'Display Driver Uninstaller'; Winget = 'Wagnardsoft.DisplayDriverUninstaller'; Choco = 'ddu'; Category = 'Pro Tools'; Description = 'Display Driver Uninstaller (DDU) is a tool for completely uninstalling graphics drivers from NVIDIA, AMD, and Intel. It is useful for troubleshooting graphics driver-related issues' }
		[PSCustomObject]@{ Id = 'discord'; Name = 'Discord'; Winget = 'Discord.Discord'; Choco = 'discord'; Category = 'Communications'; Description = 'Discord is a popular communication platform with voice, video, and text chat, designed for gamers but used by a wide range of communities.' }
		[PSCustomObject]@{ Id = 'dismtools'; Name = 'DISMTools'; Winget = 'CodingWondersSoftware.DISMTools.Stable'; Choco = 'dismtools'; Category = 'Microsoft Tools'; Description = 'DISMTools is a fast, customizable GUI for the DISM utility, supporting Windows images from Windows 7 onward. It handles installations on any drive, offers project support, and lets' }
		[PSCustomObject]@{ Id = 'ntlite'; Name = 'NTLite'; Winget = 'Nlitesoft.NTLite'; Choco = 'ntlite-free'; Category = 'Microsoft Tools'; Description = 'Integrate updates, drivers, automate Windows and application setup, speedup Windows deployment process and have it all set for the next time.' }
		[PSCustomObject]@{ Id = 'dorion'; Name = 'Dorion'; Winget = 'SpikeHD.Dorion'; Choco = 'dorion'; Category = 'Communications'; Description = 'Tiny alternative Discord client with a smaller footprint, snappier startup, themes, plugins and more!' }
		[PSCustomObject]@{ Id = 'dockerdesktop'; Name = 'Docker Desktop'; Winget = 'Docker.DockerDesktop'; Choco = 'docker-desktop'; Category = 'Development'; Description = 'Docker Desktop provides a local environment for building, running, and testing containerized applications on Windows.' }
		[PSCustomObject]@{ Id = 'dotnet6'; Name = '.NET Desktop Runtime 6'; Winget = 'Microsoft.DotNet.DesktopRuntime.6'; Choco = 'dotnet-6.0-runtime'; Category = 'Microsoft Tools'; Description = '.NET Desktop Runtime 6 is a runtime environment required for running applications developed with .NET 6.' }
		[PSCustomObject]@{ Id = 'dotnet8'; Name = '.NET Desktop Runtime 8'; Winget = 'Microsoft.DotNet.DesktopRuntime.8'; Choco = 'dotnet-8.0-runtime'; Category = 'Microsoft Tools'; Description = '.NET Desktop Runtime 8 is a runtime environment required for running applications developed with .NET 8.' }
		[PSCustomObject]@{ Id = 'dotnet9'; Name = '.NET Desktop Runtime 9'; Winget = 'Microsoft.DotNet.DesktopRuntime.9'; Choco = 'dotnet-9.0-runtime'; Category = 'Microsoft Tools'; Description = '.NET Desktop Runtime 9 is a runtime environment required for running applications developed with .NET 9.' }
		[PSCustomObject]@{ Id = 'dotnet10'; Name = '.NET Desktop Runtime 10'; Winget = 'Microsoft.DotNet.DesktopRuntime.10'; Choco = 'dotnet-10.0-runtime'; Category = 'Microsoft Tools'; Description = '.NET Desktop Runtime 10 is a runtime environment required for running applications developed with .NET 10.' }
		[PSCustomObject]@{ Id = 'dropbox'; Name = 'Dropbox'; Winget = 'Dropbox.Dropbox'; Choco = 'dropbox'; Category = 'Utilities'; Description = 'Dropbox is a cloud storage client for syncing files, sharing content, and keeping documents available across devices.' }
		[PSCustomObject]@{ Id = 'eaapp'; Name = 'EA App'; Winget = 'ElectronicArts.EADesktop'; Choco = 'ea-app'; Category = 'Games'; Description = 'EA App is a platform for accessing and playing Electronic Arts games.' }
		[PSCustomObject]@{ Id = 'eartrumpet'; Name = 'EarTrumpet (Audio)'; Winget = 'File-New-Project.EarTrumpet'; Choco = 'eartrumpet'; Category = 'Multimedia Tools'; Description = 'EarTrumpet is an audio control app for Windows, providing a simple and intuitive interface for managing sound settings.' }
		[PSCustomObject]@{ Id = 'edge'; Name = 'Edge'; Winget = 'Microsoft.Edge'; Choco = 'microsoft-edge'; Category = 'Browsers'; Description = 'Microsoft Edge is a modern web browser built on Chromium, offering performance, security, and integration with Microsoft services.' }
		[PSCustomObject]@{ Id = 'es-de'; Name = 'EmulationStation Desktop Edition'; Winget = 'ES-DE.EmulationStation-DE'; Choco = ''; Category = 'Games'; Description = 'EmulationStation Desktop Edition is a frontend for browsing and launching games from your multi-platform game collection.' }
		[PSCustomObject]@{ Id = 'enteauth'; Name = 'Ente Auth'; Winget = 'ente-io.auth-desktop'; Choco = 'ente-auth'; Category = 'Utilities'; Description = 'Ente Auth is a free, cross-platform, end-to-end encrypted authenticator app.' }
		[PSCustomObject]@{ Id = 'epicgames'; Name = 'Epic Games Launcher'; Winget = 'EpicGames.EpicGamesLauncher'; Choco = 'epicgameslauncher'; Category = 'Games'; Description = 'Epic Games Launcher is the client for accessing and playing games from the Epic Games Store.' }
		[PSCustomObject]@{ Id = 'files'; Name = 'Files'; Winget = 'FilesCommunity.Files'; Choco = 'files'; Category = 'Utilities'; Description = 'Alternative file explorer.' }
		[PSCustomObject]@{ Id = 'fileconverter'; Name = 'File Converter'; Winget = 'AdrienAllard.FileConverter'; Choco = 'file-converter'; Category = 'Multimedia Tools'; Description = 'File Converter converts and compresses files from the Windows Explorer context menu.' }
		[PSCustomObject]@{ Id = 'firefox'; Name = 'Firefox'; Winget = 'Mozilla.Firefox'; Choco = 'firefox'; Category = 'Browsers'; Description = 'Mozilla Firefox is an open-source web browser known for its customization options, privacy features, and extensions.' }
		[PSCustomObject]@{ Id = 'firefoxesr'; Name = 'Firefox ESR'; Winget = 'Mozilla.Firefox.ESR'; Choco = 'FirefoxESR'; Category = 'Browsers'; Description = 'Mozilla Firefox is an open-source web browser known for its customization options, privacy features, and extensions. Firefox ESR (Extended Support Release) receives major updates e' }
		[PSCustomObject]@{ Id = 'floorp'; Name = 'Floorp'; Winget = 'Ablaze.Floorp'; Choco = 'floorp'; Category = 'Browsers'; Description = 'Floorp is an open-source web browser project that aims to provide a simple and fast browsing experience.' }
		[PSCustomObject]@{ Id = 'flux'; Name = 'F.lux'; Winget = 'flux.flux'; Choco = 'f.lux'; Category = 'Utilities'; Description = 'f.lux adjusts the color temperature of your screen to reduce eye strain during nighttime use.' }
		[PSCustomObject]@{ Id = 'foobar'; Name = 'foobar2000 (Music Player)'; Winget = 'PeterPawlowski.foobar2000'; Choco = 'foobar2000'; Category = 'Multimedia Tools'; Description = 'foobar2000 is a highly customizable and extensible music player for Windows, known for its modular design and advanced features.' }
		[PSCustomObject]@{ Id = 'fnm'; Name = 'Fast Node Manager'; Winget = 'Schniz.fnm'; Choco = 'fnm'; Category = 'Development'; Description = 'Fast Node Manager (fnm) is a fast, cross-platform tool for installing and switching between Node.js versions.' }
		[PSCustomObject]@{ Id = 'foxpdfreader'; Name = 'Foxit PDF Reader'; Winget = 'Foxit.FoxitReader'; Choco = 'foxitreader'; Category = 'Document'; Description = 'Foxit PDF Reader is a free PDF viewer with a familiar ribbon-style interface.' }
		[PSCustomObject]@{ Id = 'geforcenow'; Name = 'GeForce NOW'; Winget = 'Nvidia.GeForceNow'; Choco = 'nvidia-geforce-now'; Category = 'Games'; Description = 'GeForce NOW is a cloud gaming service that allows you to play high-quality PC games on your device.' }
		[PSCustomObject]@{ Id = 'gimp'; Name = 'GIMP (Image Editor)'; Winget = 'GIMP.GIMP.3'; Choco = 'gimp'; Category = 'Multimedia Tools'; Description = 'GIMP is a versatile open-source raster graphics editor used for tasks such as photo retouching, image editing, and image composition.' }
		[PSCustomObject]@{ Id = 'git'; Name = 'Git'; Winget = 'Git.Git'; Choco = 'git'; Category = 'Development'; Description = 'Git is a distributed version control system widely used for tracking changes in source code during software development.' }
		[PSCustomObject]@{ Id = 'gitextensions'; Name = 'Git Extensions'; Winget = 'GitExtensionsTeam.GitExtensions'; Choco = 'gitextensions'; Category = 'Development'; Description = 'Git Extensions is a graphical Git client for Windows with repository, history, and commit management tools.' }
		[PSCustomObject]@{ Id = 'githubcli'; Name = 'GitHub CLI'; Winget = 'GitHub.cli'; Choco = 'gh'; Category = 'Development'; Description = 'GitHub CLI brings pull requests, issues, releases, and other GitHub workflows to the terminal.' }
		[PSCustomObject]@{ Id = 'githubdesktop'; Name = 'GitHub Desktop'; Winget = 'GitHub.GitHubDesktop'; Choco = 'git;github-desktop'; Category = 'Development'; Description = 'GitHub Desktop is a visual Git client that simplifies collaboration on GitHub repositories with an easy-to-use interface.' }
		[PSCustomObject]@{ Id = 'gog'; Name = 'GOG Galaxy'; Winget = 'GOG.Galaxy'; Choco = 'goggalaxy'; Category = 'Games'; Description = 'GOG Galaxy is a gaming client that offers DRM-free games, additional content, and more.' }
		[PSCustomObject]@{ Id = 'golang'; Name = 'Go'; Winget = 'GoLang.Go'; Choco = 'golang'; Category = 'Development'; Description = 'Go (or Golang) is a statically typed, compiled programming language designed for simplicity, reliability, and efficiency.' }
		[PSCustomObject]@{ Id = 'googledrive'; Name = 'Google Drive'; Winget = 'Google.GoogleDrive'; Choco = 'googledrive'; Category = 'Utilities'; Description = 'File syncing across devices all tied to your Google account.' }
		[PSCustomObject]@{ Id = 'gpuz'; Name = 'GPU-Z'; Winget = 'TechPowerUp.GPU-Z'; Choco = 'gpu-z'; Category = 'Pro Tools'; Description = 'GPU-Z provides detailed information about your graphics card and GPU.' }
		[PSCustomObject]@{ Id = 'gsudo'; Name = 'gsudo'; Winget = 'gerardog.gsudo'; Choco = 'gsudo'; Category = 'Pro Tools'; Description = 'gsudo is a sudo equivalent for Windows. It allows you to run commands with elevated administrative privileges directly within the current console window.' }
		[PSCustomObject]@{ Id = 'helium'; Name = 'Helium'; Winget = 'ImputNet.Helium'; Choco = 'helium'; Category = 'Browsers'; Description = 'Private, fast, and honest web browser.' }
		[PSCustomObject]@{ Id = 'hugo'; Name = 'Hugo'; Winget = 'Hugo.Hugo.Extended'; Choco = 'hugo-extended'; Category = 'Development'; Description = 'The world''s fastest framework for building websites.' }
		[PSCustomObject]@{ Id = 'handbrake'; Name = 'HandBrake'; Winget = 'HandBrake.HandBrake'; Choco = 'handbrake'; Category = 'Multimedia Tools'; Description = 'HandBrake is an open-source video transcoder, allowing you to convert video from nearly any format to a selection of widely supported codecs.' }
		[PSCustomObject]@{ Id = 'heroiclauncher'; Name = 'Heroic Games Launcher'; Winget = 'HeroicGamesLauncher.HeroicGamesLauncher'; Choco = 'heroic-games-launcher'; Category = 'Games'; Description = 'Heroic Games Launcher is an open-source alternative game launcher for Epic Games Store.' }
		[PSCustomObject]@{ Id = 'hwinfo'; Name = 'HWiNFO'; Winget = 'REALiX.HWiNFO'; Choco = 'hwinfo'; Category = 'Pro Tools'; Description = 'HWiNFO provides comprehensive hardware information and diagnostics for Windows.' }
		[PSCustomObject]@{ Id = 'hwmonitor'; Name = 'HWMonitor'; Winget = 'CPUID.HWMonitor'; Choco = 'hwmonitor'; Category = 'Pro Tools'; Description = 'HWMonitor is a hardware monitoring program that reads PC systems main health sensors.' }
		[PSCustomObject]@{ Id = 'imhex'; Name = 'ImHex'; Winget = 'WerWolv.ImHex'; Choco = 'imhex'; Category = 'Pro Tools'; Description = 'ImHex is a free and open-source hex editor for reverse engineers and programmers, featuring a custom pattern language for decoding binary formats, a disassembler, and data analysis' }
		[PSCustomObject]@{ Id = 'imageglass'; Name = 'ImageGlass (Image Viewer)'; Winget = 'DuongDieuPhap.ImageGlass'; Choco = 'imageglass'; Category = 'Multimedia Tools'; Description = 'ImageGlass is a versatile image viewer with support for various image formats and a focus on simplicity and speed.' }
		[PSCustomObject]@{ Id = 'internetdownloadmanager'; Name = 'Internet Download Manager'; Winget = 'Tonec.InternetDownloadManager'; Choco = 'internet-download-manager'; Category = 'Utilities'; Description = 'Internet Download Manager is a download manager for accelerating, resuming, and scheduling file downloads.' }
		[PSCustomObject]@{ Id = 'irfanview'; Name = 'IrfanView'; Winget = 'IrfanSkiljan.IrfanView'; Choco = 'irfanview'; Category = 'Multimedia Tools'; Description = 'IrfanView is a lightweight, fast, and free image viewer and editor. Supports multiple formats, batch processing, and powerful plugins.' }
		[PSCustomObject]@{ Id = 'itch'; Name = 'Itch.io'; Winget = 'ItchIo.Itch'; Choco = 'itch'; Category = 'Games'; Description = 'Itch.io is a digital distribution platform for indie games and creative projects.' }
		[PSCustomObject]@{ Id = 'itunes'; Name = 'iTunes'; Winget = 'Apple.iTunes'; Choco = 'itunes'; Category = 'Multimedia Tools'; Description = 'iTunes is a media player, media library, and online radio broadcaster application developed by Apple Inc.' }
		[PSCustomObject]@{ Id = 'java8'; Name = 'Amazon Corretto 8 (LTS)'; Winget = 'Amazon.Corretto.8.JDK'; Choco = 'corretto8jdk'; Category = 'Development'; Description = 'Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK).' }
		[PSCustomObject]@{ Id = 'java21'; Name = 'Amazon Corretto 21 (LTS)'; Winget = 'Amazon.Corretto.21.JDK'; Choco = 'corretto21jdk'; Category = 'Development'; Description = 'Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK).' }
		[PSCustomObject]@{ Id = 'java25'; Name = 'Amazon Corretto 25 (LTS)'; Winget = 'Amazon.Corretto.25.JDK'; Choco = 'corretto25jdk'; Category = 'Development'; Description = 'Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK).' }
		[PSCustomObject]@{ Id = 'jellyfinmediaplayer'; Name = 'Jellyfin Media Player'; Winget = 'Jellyfin.JellyfinMediaPlayer'; Choco = 'jellyfin-media-player'; Category = 'Selfhosted Tools'; Description = 'Jellyfin Media Player is a client application for the Jellyfin media server, providing access to your media library.' }
		[PSCustomObject]@{ Id = 'jellyfinserver'; Name = 'Jellyfin Server'; Winget = 'Jellyfin.Server'; Choco = 'jellyfin'; Category = 'Selfhosted Tools'; Description = 'Jellyfin Server is an open-source media server software, allowing you to organize and stream your media library.' }
		[PSCustomObject]@{ Id = 'jetbrains'; Name = 'Jetbrains Toolbox'; Winget = 'JetBrains.Toolbox'; Choco = 'jetbrainstoolbox'; Category = 'Development'; Description = 'Jetbrains Toolbox is a platform for easy installation and management of JetBrains developer tools.' }
		[PSCustomObject]@{ Id = 'jpegview'; Name = 'JPEG View'; Winget = 'sylikc.JPEGView'; Choco = 'jpegview'; Category = 'Utilities'; Description = 'JPEGView is a lean, fast and highly configurable viewer/editor for JPEG, BMP, PNG, WEBP, TGA, GIF, JXL, HEIC, HEIF, AVIF, and TIFF images with a minimal GUI.' }
		[PSCustomObject]@{ Id = 'joplin'; Name = 'Joplin'; Winget = 'Joplin.Joplin'; Choco = 'joplin'; Category = 'Document'; Description = 'Joplin is an open-source note-taking and to-do application with synchronization capabilities.' }
		[PSCustomObject]@{ Id = 'keepassxc'; Name = 'KeePassXC'; Winget = 'KeePassXCTeam.KeePassXC'; Choco = 'keepassxc'; Category = 'Utilities'; Description = 'KeePassXC is a modern, secure, and open-source password manager that stores and manages your most sensitive information. You can run KeePassXC on Windows, macOS, and Linux systems.' }
		[PSCustomObject]@{ Id = 'klite'; Name = 'K-Lite Codec Standard'; Winget = 'CodecGuide.K-LiteCodecPack.Standard'; Choco = 'k-litecodecpack-standard'; Category = 'Multimedia Tools'; Description = 'K-Lite Codec Pack Standard is a collection of audio and video codecs and related tools, providing essential components for media playback.' }
		[PSCustomObject]@{ Id = 'kodi'; Name = 'Kodi Media Center'; Winget = 'XBMCFoundation.Kodi'; Choco = 'kodi'; Category = 'Selfhosted Tools'; Description = 'Kodi is an open-source media center application that allows you to play and view most videos, music, podcasts, and other digital media files.' }
		[PSCustomObject]@{ Id = 'lazygit'; Name = 'Lazygit'; Winget = 'JesseDuffield.lazygit'; Choco = 'lazygit'; Category = 'Development'; Description = 'Simple terminal UI for git commands.' }
		[PSCustomObject]@{ Id = 'libreoffice'; Name = 'LibreOffice'; Winget = 'TheDocumentFoundation.LibreOffice'; Choco = 'libreoffice-fresh'; Category = 'Document'; Description = 'LibreOffice is a powerful and free office suite, compatible with other major office suites.' }
		[PSCustomObject]@{ Id = 'librewolf'; Name = 'LibreWolf'; Winget = 'LibreWolf.LibreWolf'; Choco = 'librewolf'; Category = 'Browsers'; Description = 'LibreWolf is a privacy-focused web browser based on Firefox, with additional privacy and security enhancements.' }
		[PSCustomObject]@{ Id = 'localsend'; Name = 'LocalSend'; Winget = 'LocalSend.LocalSend'; Choco = 'localsend.install'; Category = 'Selfhosted Tools'; Description = 'An open-source cross-platform alternative to AirDrop.' }
		[PSCustomObject]@{ Id = 'mpc-qt'; Name = 'mpc-qt'; Winget = 'mpc-qt.mpc-qt'; Choco = 'mpc-qt'; Category = 'Multimedia Tools'; Description = 'Media Player Classic Qute Theater' }
		[PSCustomObject]@{ Id = 'mpv'; Name = 'mpv'; Winget = 'shinchiro.mpv'; Choco = ''; Category = 'Multimedia Tools'; Description = 'mpv is a free, open source, and cross-platform media player supporting a wide variety of media formats, codecs, and subtitle types.' }
		[PSCustomObject]@{ Id = 'matrix'; Name = 'Element'; Winget = 'Element.Element'; Choco = 'element-desktop'; Category = 'Communications'; Description = 'Element is a client for Matrix; an open network for secure, decentralized communication.' }
		[PSCustomObject]@{ Id = 'minitoolpartitionwizard'; Name = 'MiniTool Partition Wizard'; Winget = 'MiniTool.PartitionWizard.Free'; Choco = 'partitionwizard'; Category = 'Utilities'; Description = 'Comprehensive free partition manager that performs advanced operations Windows natively cannot, such as merging partitions, converting file systems, and organizing disk capacity.' }
		[PSCustomObject]@{ Id = 'modrinth'; Name = 'Modrinth App'; Winget = 'Modrinth.ModrinthApp'; Choco = 'modrinth-app'; Category = 'Games'; Description = 'Modrinth App is a desktop application for managing Minecraft mods and modpacks.' }
		[PSCustomObject]@{ Id = 'moonlight'; Name = 'Moonlight/GameStream Client'; Winget = 'MoonlightGameStreamingProject.Moonlight'; Choco = 'moonlight-qt'; Category = 'Selfhosted Tools'; Description = 'Moonlight/GameStream Client allows you to stream PC games to other devices over your local network.' }
		[PSCustomObject]@{ Id = 'mpchc'; Name = 'Media Player Classic - Home Cinema'; Winget = 'clsid2.mpc-hc'; Choco = 'mpc-hc-clsid2'; Category = 'Multimedia Tools'; Description = 'Media Player Classic - Home Cinema (MPC-HC) is a free and open-source video and audio player for Windows. MPC-HC is based on the original Guliverkli project and contains many addit' }
		[PSCustomObject]@{ Id = 'msedgeredirect'; Name = 'MSEdgeRedirect'; Winget = 'rcmaehl.MSEdgeRedirect'; Choco = 'msedgeredirect'; Category = 'Utilities'; Description = 'A Tool to Redirect News, Search, Widgets, Weather, and More to your default browser.' }
		[PSCustomObject]@{ Id = 'msiafterburner'; Name = 'MSI Afterburner'; Winget = 'Guru3D.Afterburner'; Choco = 'msiafterburner'; Category = 'Pro Tools'; Description = 'MSI Afterburner is a graphics card overclocking utility with advanced features.' }
		[PSCustomObject]@{ Id = 'mullvadvpn'; Name = 'Mullvad VPN'; Winget = 'MullvadVPN.MullvadVPN'; Choco = 'mullvad-app'; Category = 'Pro Tools'; Description = 'This is the VPN client software for the Mullvad VPN service.' }
		[PSCustomObject]@{ Id = 'mullvadbrowser'; Name = 'Mullvad Browser'; Winget = 'MullvadVPN.MullvadBrowser'; Choco = 'na'; Category = 'Browsers'; Description = 'Mullvad Browser is a privacy-focused web browser, developed in partnership with the Tor Project.' }
		[PSCustomObject]@{ Id = 'nomacs'; Name = 'nomacs'; Winget = 'nomacs.nomacs'; Choco = 'nomacs'; Category = 'Multimedia Tools'; Description = 'nomacs is a free, open-source image viewer, which supports multiple platforms. You can use it for viewing all common image formats, including RAW and .psd images.' }
		[PSCustomObject]@{ Id = 'nanazip'; Name = 'NanaZip'; Winget = 'M2Team.NanaZip'; Choco = 'nanazip'; Category = 'Utilities'; Description = 'NanaZip is a fast and efficient file compression and decompression tool.' }
		[PSCustomObject]@{ Id = 'netbird'; Name = 'NetBird'; Winget = 'Netbird.Netbird'; Choco = 'netbird'; Category = 'Selfhosted Tools'; Description = 'NetBird is an open-source alternative comparable to TailScale that can be connected to a self-hosted server.' }
		[PSCustomObject]@{ Id = 'tailscale'; Name = 'Tailscale'; Winget = 'Tailscale.Tailscale'; Choco = 'tailscale'; Category = 'Pro Tools'; Description = 'The Tailscale client allows you to connect all your devices using WireGuard®, without the hassle. Tailscale makes it as easy as installing an app and signing in.' }
		[PSCustomObject]@{ Id = 'naps2'; Name = 'NAPS2 (Scanner)'; Winget = 'Cyanfish.NAPS2'; Choco = 'naps2'; Category = 'Document'; Description = 'NAPS2 is a document scanning application that simplifies the process of creating electronic documents.' }
		[PSCustomObject]@{ Id = 'neovim'; Name = 'Neovim'; Winget = 'Neovim.Neovim'; Choco = 'neovim'; Category = 'Development'; Description = 'Neovim is a highly extensible text editor and an improvement over the original Vim editor.' }
		[PSCustomObject]@{ Id = 'nextclouddesktop'; Name = 'Nextcloud Desktop'; Winget = 'Nextcloud.NextcloudDesktop'; Choco = 'nextcloud-client'; Category = 'Selfhosted Tools'; Description = 'Nextcloud Desktop is the official desktop client for the Nextcloud file synchronization and sharing platform.' }
		[PSCustomObject]@{ Id = 'nmap'; Name = 'Nmap'; Winget = 'Insecure.Nmap'; Choco = 'nmap'; Category = 'Pro Tools'; Description = 'Nmap (Network Mapper) is an open-source tool for network exploration and security auditing. It discovers devices on a network and provides information about their ports and service' }
		[PSCustomObject]@{ Id = 'nodejs'; Name = 'NodeJS'; Winget = 'OpenJS.NodeJS'; Choco = 'nodejs'; Category = 'Development'; Description = 'NodeJS is a JavaScript runtime built on Chrome''s V8 JavaScript engine for building server-side and networking applications.' }
		[PSCustomObject]@{ Id = 'nodejslts'; Name = 'NodeJS LTS'; Winget = 'OpenJS.NodeJS.LTS'; Choco = 'nodejs-lts'; Category = 'Development'; Description = 'NodeJS LTS provides Long-Term Support releases for stable and reliable server-side JavaScript development.' }
		[PSCustomObject]@{ Id = 'pnpm'; Name = 'pnpm'; Winget = 'pnpm.pnpm'; Choco = ''; Category = 'Development'; Description = 'pnpm is a fast and disk space efficient package manager for JavaScript and Node.js applications.' }
		[PSCustomObject]@{ Id = 'notepadplus'; Name = 'Notepad++'; Winget = 'Notepad++.Notepad++'; Choco = 'notepadplusplus'; Category = 'Development'; Description = 'Notepad++ is a free, open-source code editor and Notepad replacement with support for multiple languages.' }
		[PSCustomObject]@{ Id = 'nuget'; Name = 'NuGet'; Winget = 'Microsoft.NuGet'; Choco = 'nuget.commandline'; Category = 'Microsoft Tools'; Description = 'NuGet is a package manager for the .NET framework, enabling developers to manage and share libraries in their .NET applications.' }
		[PSCustomObject]@{ Id = 'nvclean'; Name = 'NVCleanstall'; Winget = 'TechPowerUp.NVCleanstall'; Choco = 'na'; Category = 'Utilities'; Description = 'NVCleanstall is a tool designed to customize NVIDIA driver installations, allowing advanced users to control more aspects of the installation process.' }
		[PSCustomObject]@{ Id = 'obs'; Name = 'OBS Studio'; Winget = 'OBSProject.OBSStudio'; Choco = 'obs-studio'; Category = 'Multimedia Tools'; Description = 'OBS Studio is a free and open-source software for video recording and live streaming. It supports real-time video/audio capturing and mixing, making it popular among content creato' }
		[PSCustomObject]@{ Id = 'obsidian'; Name = 'Obsidian'; Winget = 'Obsidian.Obsidian'; Choco = 'obsidian'; Category = 'Document'; Description = 'Obsidian is a powerful note-taking and knowledge management application.' }
		[PSCustomObject]@{ Id = 'okular'; Name = 'Okular'; Winget = 'KDE.Okular'; Choco = 'okular'; Category = 'Document'; Description = 'Okular is a versatile document viewer with advanced features.' }
		[PSCustomObject]@{ Id = 'onedrive'; Name = 'OneDrive'; Winget = 'Microsoft.OneDrive'; Choco = 'onedrive'; Category = 'Microsoft Tools'; Description = 'OneDrive is a cloud storage service provided by Microsoft, allowing users to store and share files securely across devices.' }
		[PSCustomObject]@{ Id = 'onlyoffice'; Name = 'ONLYOFFICE Desktop'; Winget = 'ONLYOFFICE.DesktopEditors'; Choco = 'onlyoffice'; Category = 'Document'; Description = 'ONLYOFFICE Desktop is a comprehensive office suite for document editing and collaboration.' }
		[PSCustomObject]@{ Id = 'OPAutoClicker'; Name = 'OPAutoClicker'; Winget = 'OPAutoClicker.OPAutoClicker'; Choco = 'autoclicker'; Category = 'Utilities'; Description = 'A full-fledged autoclicker with two modes of autoclicking, at your dynamic cursor location or at a prespecified location.' }
		[PSCustomObject]@{ Id = 'opencode'; Name = 'OpenCode'; Winget = 'SST.opencode'; Choco = 'opencode'; Category = 'Development'; Description = 'OpenCode is an open-source AI coding agent built for the terminal. It is provider-agnostic and supports local and hosted AI models.' }
		[PSCustomObject]@{ Id = 'openrgb'; Name = 'OpenRGB'; Winget = 'OpenRGB.OpenRGB'; Choco = 'openrgb'; Category = 'Utilities'; Description = 'OpenRGB is an open-source RGB lighting control software designed to manage and control RGB lighting for various components and peripherals.' }
		[PSCustomObject]@{ Id = 'OpenVPN'; Name = 'OpenVPN Connect'; Winget = 'OpenVPNTechnologies.OpenVPNConnect'; Choco = 'openvpn-connect'; Category = 'Pro Tools'; Description = 'OpenVPN Connect is a VPN client that allows you to connect securely to a VPN server. It provides a secure and encrypted connection for protecting your online privacy.' }
		[PSCustomObject]@{ Id = 'OVirtualBox'; Name = 'Oracle VirtualBox'; Winget = 'Oracle.VirtualBox'; Choco = 'virtualbox'; Category = 'Utilities'; Description = 'Oracle VirtualBox is a powerful and free open-source virtualization tool for x86 and AMD64/Intel64 architectures.' }
		[PSCustomObject]@{ Id = 'policyplus'; Name = 'Policy Plus'; Winget = 'Fleex255.PolicyPlus'; Choco = 'na'; Category = 'Utilities'; Description = 'Local Group Policy Editor plus more, for all Windows editions.' }
		[PSCustomObject]@{ Id = 'processexplorer'; Name = 'Process Explorer'; Winget = 'Microsoft.Sysinternals.ProcessExplorer'; Choco = 'procexp'; Category = 'Microsoft Tools'; Description = 'Process Explorer is a task manager and system monitor.' }
		[PSCustomObject]@{ Id = 'Paintdotnet'; Name = 'Paint.NET'; Winget = 'dotPDN.PaintDotNet'; Choco = 'paint.net'; Category = 'Multimedia Tools'; Description = 'Paint.NET is a free image and photo editing software for Windows. It features an intuitive user interface and supports a wide range of powerful editing tools.' }
		[PSCustomObject]@{ Id = 'parsec'; Name = 'Parsec'; Winget = 'Parsec.Parsec'; Choco = 'parsec'; Category = 'Utilities'; Description = 'Parsec is a low-latency, high-quality remote desktop sharing application for collaborating and gaming across devices.' }
		[PSCustomObject]@{ Id = 'peazip'; Name = 'PeaZip'; Winget = 'Giorgiotani.Peazip'; Choco = 'peazip'; Category = 'Utilities'; Description = 'PeaZip is a free, open-source file archiver utility that supports multiple archive formats and provides encryption features.' }
		[PSCustomObject]@{ Id = 'pdf-xchange'; Name = 'PDF-XChange Editor'; Winget = 'TrackerSoftware.PDF-XChangeEditor'; Choco = 'pdfxchangeeditor'; Category = 'Document'; Description = 'A comprehensive Windows-based software suite and editor for creating, viewing, editing, annotating, and signing PDF files.' }
		[PSCustomObject]@{ Id = 'pdf24creator'; Name = 'PDF24 Creator'; Winget = 'geeksoftwareGmbH.PDF24Creator'; Choco = 'pdf24'; Category = 'Document'; Description = 'Free and easy-to-use online/desktop PDF tools that make you more productive' }
		[PSCustomObject]@{ Id = 'pdfgear'; Name = 'PDFgear'; Winget = 'PDFgear.PDFgear'; Choco = 'pdfgear'; Category = 'Document'; Description = 'PDFgear is a piece of full-featured PDF management software for Windows, macOS, and mobile, and it''s completely free to use.' }
		[PSCustomObject]@{ Id = 'pdfsam'; Name = 'PDFsam Basic'; Winget = 'PDFsam.PDFsam'; Choco = 'pdfsam'; Category = 'Document'; Description = 'PDFsam Basic is a free and open-source tool for splitting, merging, and rotating PDF files.' }
		[PSCustomObject]@{ Id = 'playnite'; Name = 'Playnite'; Winget = 'Playnite.Playnite'; Choco = 'playnite'; Category = 'Games'; Description = 'Playnite is an open-source video game library manager with one simple goal: To provide a unified interface for all of your games.' }
		[PSCustomObject]@{ Id = 'plex'; Name = 'Plex Media Server'; Winget = 'Plex.PlexMediaServer'; Choco = 'plexmediaserver'; Category = 'Selfhosted Tools'; Description = 'Plex Media Server is a media server software that allows you to organize and stream your media library. It supports various media formats and offers a wide range of features.' }
		[PSCustomObject]@{ Id = 'plexdesktop'; Name = 'Plex Desktop'; Winget = 'Plex.Plex'; Choco = 'plex'; Category = 'Selfhosted Tools'; Description = 'Plex Desktop for Windows is the front end for Plex Media Server.' }
		[PSCustomObject]@{ Id = 'posh'; Name = 'Oh My Posh (Prompt)'; Winget = 'JanDeDobbeleer.OhMyPosh'; Choco = 'oh-my-posh'; Category = 'Development'; Description = 'Oh My Posh is a cross-platform prompt theme engine for any shell.' }
		[PSCustomObject]@{ Id = 'postman'; Name = 'Postman'; Winget = 'Postman.Postman'; Choco = 'postman'; Category = 'Development'; Description = 'Postman is an API platform and desktop client for designing, testing, documenting, and collaborating on APIs.' }
		[PSCustomObject]@{ Id = 'powershell'; Name = 'PowerShell'; Winget = 'Microsoft.PowerShell'; Choco = 'powershell-core'; Category = 'Microsoft Tools'; Description = 'PowerShell is a task automation framework and scripting language designed for system administrators, offering powerful command-line capabilities.' }
		[PSCustomObject]@{ Id = 'powertoys'; Name = 'PowerToys'; Winget = 'Microsoft.PowerToys'; Choco = 'powertoys'; Category = 'Microsoft Tools'; Description = 'PowerToys is a set of utilities for power users to enhance productivity, featuring tools like FancyZones, PowerRename, and more.' }
		[PSCustomObject]@{ Id = 'prismlauncher'; Name = 'Prism Launcher'; Winget = 'PrismLauncher.PrismLauncher'; Choco = 'prismlauncher'; Category = 'Games'; Description = 'Prism Launcher is an open-source Minecraft launcher with the ability to manage multiple instances, accounts, and mods.' }
		[PSCustomObject]@{ Id = 'processlasso'; Name = 'Process Lasso'; Winget = 'BitSum.ProcessLasso'; Choco = 'plasso'; Category = 'Utilities'; Description = 'Process Lasso is a system optimization and automation tool that improves system responsiveness and stability by adjusting process priorities and CPU affinities.' }
		[PSCustomObject]@{ Id = 'protonauth'; Name = 'Proton Authenticator'; Winget = 'Proton.ProtonAuthenticator'; Choco = 'protonauth'; Category = 'Utilities'; Description = '2FA app from Proton to securely sync and backup 2FA codes.' }
		[PSCustomObject]@{ Id = 'protonmail'; Name = 'Proton Mail'; Winget = 'Proton.ProtonMail'; Choco = 'protonmail'; Category = 'Communications'; Description = 'Proton Mail is an end-to-end encrypted email service by Proton, protecting your privacy with zero-access encryption.' }
		[PSCustomObject]@{ Id = 'protondrive'; Name = 'Proton Drive'; Winget = 'Proton.ProtonDrive'; Choco = 'protondrive'; Category = 'Utilities'; Description = 'Proton Drive is an end-to-end encrypted Swiss vault for your files that protects your data.' }
		[PSCustomObject]@{ Id = 'protonpass'; Name = 'Proton Pass'; Winget = 'Proton.ProtonPass'; Choco = 'protonpass'; Category = 'Utilities'; Description = 'Proton Pass is a cloud-based password manager with end-to-end encryption and unique email aliases.' }
		[PSCustomObject]@{ Id = 'protonvpn'; Name = 'Proton VPN'; Winget = 'Proton.ProtonVPN'; Choco = 'protonvpn'; Category = 'Pro Tools'; Description = 'Proton VPN is a no-logs VPN service that protects your privacy online with features like Secure Core and Tor over VPN.' }
		[PSCustomObject]@{ Id = 'processmonitor'; Name = 'Process Monitor'; Winget = 'Microsoft.Sysinternals.ProcessMonitor'; Choco = 'procmon'; Category = 'Microsoft Tools'; Description = 'SysInternals Process Monitor is an advanced monitoring tool that shows real-time file system, registry, and process/thread activity.' }
		[PSCustomObject]@{ Id = 'pstools'; Name = 'PsTools'; Winget = 'Microsoft.Sysinternals.PsTools'; Choco = 'pstools'; Category = 'Microsoft Tools'; Description = 'Microsoft Sysinternals PsTools provides utilities for managing local and remote Windows systems and monitoring processes. PsExec can run processes under the SYSTEM account when the' }
		[PSCustomObject]@{ Id = 'putty'; Name = 'PuTTY'; Winget = 'PuTTY.PuTTY'; Choco = 'putty'; Category = 'Pro Tools'; Description = 'PuTTY is a free and open-source terminal emulator, serial console, and network file transfer application. It supports various network protocols such as SSH, Telnet, and SCP.' }
		[PSCustomObject]@{ Id = 'python3'; Name = 'Python3'; Winget = 'Python.Python.3.14'; Choco = 'python'; Category = 'Development'; Description = 'Python is a versatile programming language used for web development, data analysis, artificial intelligence, and more.' }
		[PSCustomObject]@{ Id = 'qbittorrent'; Name = 'qBittorrent'; Winget = 'qBittorrent.qBittorrent'; Choco = 'qbittorrent'; Category = 'Utilities'; Description = 'qBittorrent is a free and open-source BitTorrent client that aims to provide a feature-rich and lightweight alternative to other torrent clients.' }
		[PSCustomObject]@{ Id = 'qownnotes'; Name = 'QOwnNotes'; Winget = 'pbek.QOwnNotes'; Choco = 'qownnotes'; Category = 'Document'; Description = 'QOwnNotes is a free open-source note-taking app with Nextcloud/ownCloud integration.' }
		[PSCustomObject]@{ Id = 'qtox'; Name = 'QTox'; Winget = 'Tox.qTox'; Choco = 'qtox'; Category = 'Communications'; Description = 'QTox is a free and open-source messaging app that prioritizes user privacy and security in its design.' }
		[PSCustomObject]@{ Id = 'revo'; Name = 'Revo Uninstaller'; Winget = 'RevoUninstaller.RevoUninstaller'; Choco = 'revo-uninstaller'; Category = 'Utilities'; Description = 'Revo Uninstaller is an advanced uninstaller tool that helps you remove unwanted software and clean up your system.' }
		[PSCustomObject]@{ Id = 'WiseProgramUninstaller'; Name = 'Wise Program Uninstaller (WiseCleaner)'; Winget = 'WiseCleaner.WiseProgramUninstaller'; Choco = 'na'; Category = 'Utilities'; Description = 'Wise Program Uninstaller is the perfect solution for uninstalling Windows programs, allowing you to uninstall applications quickly and completely using its simple and user-friendly' }
		[PSCustomObject]@{ Id = 'rufus'; Name = 'Rufus Imager'; Winget = 'Rufus.Rufus'; Choco = 'rufus'; Category = 'Pro Tools'; Description = 'Rufus is a utility that helps format and create bootable USB drives, such as USB keys or pen drives.' }
		[PSCustomObject]@{ Id = 'rustlang'; Name = 'Rust'; Winget = 'Rustlang.Rust.MSVC'; Choco = 'rust'; Category = 'Development'; Description = 'Rust is a programming language designed for safety and performance, particularly focused on systems programming.' }
		[PSCustomObject]@{ Id = 'sdio'; Name = 'Snappy Driver Installer Origin'; Winget = 'GlennDelahoy.SnappyDriverInstallerOrigin'; Choco = 'sdio'; Category = 'Utilities'; Description = 'Snappy Driver Installer Origin is a free and open-source driver updater with a vast driver database for Windows.' }
		[PSCustomObject]@{ Id = 'sharex'; Name = 'ShareX (Screenshots)'; Winget = 'ShareX.ShareX'; Choco = 'sharex'; Category = 'Multimedia Tools'; Description = 'ShareX is a free and open-source screen capture and file sharing tool. It supports various capture methods and offers advanced features for editing and sharing screenshots.' }
		[PSCustomObject]@{ Id = 'nilesoftShell'; Name = 'Nilesoft Shell'; Winget = 'Nilesoft.Shell'; Choco = 'nilesoft-shell'; Category = 'Utilities'; Description = 'Shell is an expanded context menu tool that adds extra functionality and customization options to the Windows context menu.' }
		[PSCustomObject]@{ Id = 'systeminformer'; Name = 'System Informer'; Winget = 'WinsiderSS.SystemInformer'; Choco = 'systeminformer'; Category = 'Pro Tools'; Description = 'A free, powerful, multi-purpose tool that helps you monitor system resources, debug software and detect malware.' }
		[PSCustomObject]@{ Id = 'signal'; Name = 'Signal'; Winget = 'OpenWhisperSystems.Signal'; Choco = 'signal'; Category = 'Communications'; Description = 'Signal is a privacy-focused messaging app that offers end-to-end encryption for secure and private communication.' }
		[PSCustomObject]@{ Id = 'signalrgb'; Name = 'SignalRGB'; Winget = 'WhirlwindFX.SignalRgb'; Choco = 'na'; Category = 'Utilities'; Description = 'SignalRGB lets you control and sync your favorite RGB devices with one free application.' }
		[PSCustomObject]@{ Id = 'simplenote'; Name = 'Simplenote'; Winget = 'Automattic.Simplenote'; Choco = 'simplenote'; Category = 'Document'; Description = 'Simplenote is an easy way to keep notes, lists, ideas and more.' }
		[PSCustomObject]@{ Id = 'simplewall'; Name = 'Simplewall'; Winget = 'Henry++.simplewall'; Choco = 'simplewall'; Category = 'Pro Tools'; Description = 'Simplewall is a free and open-source firewall application for Windows. It allows users to control and manage the inbound and outbound network traffic of applications.' }
		[PSCustomObject]@{ Id = 'slack'; Name = 'Slack'; Winget = 'SlackTechnologies.Slack'; Choco = 'slack'; Category = 'Communications'; Description = 'Slack is a collaboration hub that connects teams and facilitates communication through channels, messaging, and file sharing.' }
		[PSCustomObject]@{ Id = 'startallback'; Name = 'StartAllBack'; Winget = 'StartIsBack.StartAllBack'; Choco = 'StartAllBack'; Category = 'Utilities'; Description = 'StartAllBack restores and improves Windows taskbar, Start menu, File Explorer, and shell UI behavior.' }
		[PSCustomObject]@{ Id = 'starship'; Name = 'Starship (Shell Prompt)'; Winget = 'Starship.Starship'; Choco = 'starship'; Category = 'Development'; Description = 'Starship is a fast, customizable, cross-platform prompt for PowerShell and other shells.' }
		[PSCustomObject]@{ Id = 'steam'; Name = 'Steam'; Winget = 'Valve.Steam'; Choco = 'steam-client'; Category = 'Games'; Description = 'Steam is a digital distribution platform for purchasing and playing video games, offering multiplayer gaming, video streaming, and more.' }
		[PSCustomObject]@{ Id = 'roblox'; Name = 'Roblox'; Winget = 'Roblox.Roblox'; Choco = 'na'; Category = 'Games'; Description = 'Roblox is a platform and game creation system that allows users to create and play games developed by the community.' }
		[PSCustomObject]@{ Id = 'sublimetext'; Name = 'Sublime Text'; Winget = 'SublimeHQ.SublimeText.4'; Choco = 'sublimetext4'; Category = 'Development'; Description = 'Sublime Text is a sophisticated text editor for code, markup, and prose.' }
		[PSCustomObject]@{ Id = 'sumatra'; Name = 'Sumatra PDF'; Winget = 'SumatraPDF.SumatraPDF'; Choco = 'sumatrapdf'; Category = 'Document'; Description = 'Sumatra PDF is a lightweight and fast PDF viewer with minimalistic design.' }
		[PSCustomObject]@{ Id = 'sunshine'; Name = 'Sunshine/GameStream Server'; Winget = 'LizardByte.Sunshine'; Choco = 'sunshine'; Category = 'Selfhosted Tools'; Description = 'Sunshine is a GameStream server that allows you to remotely play PC games on Android devices, offering low-latency streaming.' }
		[PSCustomObject]@{ Id = 'synctrayzor'; Name = 'SyncTrayzor'; Winget = 'GermanCoding.SyncTrayzor'; Choco = 'synctrayzor'; Category = 'Selfhosted Tools'; Description = 'SyncTrayzor is a Windows tray utility that bundles and wraps Syncthing, making it behave like a native application to easily manage and monitor file synchronization.' }
		[PSCustomObject]@{ Id = 'syncthing'; Name = 'Syncthing (CLI / Web UI)'; Winget = 'Syncthing.Syncthing'; Choco = 'syncthing'; Category = 'Selfhosted Tools'; Description = 'Syncthing is a decentralized, peer-to-peer file synchronization tool that securely syncs files directly across devices without cloud servers, managed via a local web interface.' }
		[PSCustomObject]@{ Id = 'tcpview'; Name = 'TCPView'; Winget = 'Microsoft.Sysinternals.TCPView'; Choco = 'tcpview'; Category = 'Microsoft Tools'; Description = 'SysInternals TCPView is a network monitoring tool that displays a detailed list of all TCP and UDP endpoints on your system.' }
		[PSCustomObject]@{ Id = 'teams'; Name = 'Teams'; Winget = 'Microsoft.Teams'; Choco = 'microsoft-teams'; Category = 'Communications'; Description = 'Microsoft Teams is a collaboration platform that integrates with Office 365 and offers chat, video conferencing, file sharing, and more.' }
		[PSCustomObject]@{ Id = 'teamviewer'; Name = 'TeamViewer'; Winget = 'TeamViewer.TeamViewer'; Choco = 'teamviewer'; Category = 'Utilities'; Description = 'TeamViewer is a popular remote access and support software that allows you to connect to and control remote devices.' }
		[PSCustomObject]@{ Id = 'teamspeak3'; Name = 'TeamSpeak 3'; Winget = 'TeamSpeakSystems.TeamSpeakClient'; Choco = 'teamspeak'; Category = 'Communications'; Description = 'TEAMSPEAK. YOUR TEAM. YOUR RULES. Use crystal clear sound to communicate with your teammates cross-platform with military-grade security, lag-free performance & unparalleled reliab' }
		[PSCustomObject]@{ Id = 'teamspeak6'; Name = 'TeamSpeak 6'; Winget = 'TeamSpeakSystems.TeamSpeakClient.Beta.6'; Choco = 'na'; Category = 'Communications'; Description = 'TEAMSPEAK. YOUR TEAM. YOUR RULES. Use crystal clear sound to communicate with your teammates cross-platform with military-grade security, lag-free performance & unparalleled reliab' }
		[PSCustomObject]@{ Id = 'telegram'; Name = 'Telegram'; Winget = 'Telegram.TelegramDesktop'; Choco = 'telegram'; Category = 'Communications'; Description = 'Telegram is a cloud-based instant messaging app known for its security features, speed, and simplicity.' }
		[PSCustomObject]@{ Id = 'terminal'; Name = 'Windows Terminal'; Winget = 'Microsoft.WindowsTerminal'; Choco = 'microsoft-windows-terminal'; Category = 'Microsoft Tools'; Description = 'Windows Terminal is a modern, fast, and efficient terminal application for command-line users, supporting multiple tabs, panes, and more.' }
		[PSCustomObject]@{ Id = 'thunderbird'; Name = 'Thunderbird'; Winget = 'Mozilla.Thunderbird'; Choco = 'thunderbird'; Category = 'Communications'; Description = 'Mozilla Thunderbird is a free and open-source email client, news client, and chat client with advanced features.' }
		[PSCustomObject]@{ Id = 'betterbird'; Name = 'Betterbird'; Winget = 'Betterbird.Betterbird'; Choco = 'betterbird'; Category = 'Communications'; Description = 'Betterbird is a fork of Mozilla Thunderbird with additional features and bugfixes.' }
		[PSCustomObject]@{ Id = 'tor'; Name = 'Tor Browser'; Winget = 'TorProject.TorBrowser'; Choco = 'tor-browser'; Category = 'Browsers'; Description = 'Tor Browser is designed for anonymous web browsing, utilizing the Tor network to protect user privacy and security.' }
		[PSCustomObject]@{ Id = 'totalcommander'; Name = 'Total Commander'; Winget = 'Ghisler.TotalCommander'; Choco = 'TotalCommander'; Category = 'Utilities'; Description = 'Total Commander is a file manager for Windows that provides a powerful and intuitive interface for file management.' }
		[PSCustomObject]@{ Id = 'treesize'; Name = 'TreeSize Free'; Winget = 'JAMSoftware.TreeSize.Free'; Choco = 'treesizefree'; Category = 'Utilities'; Description = 'TreeSize Free is a disk space manager that helps you analyze and visualize the space usage on your drives.' }
		[PSCustomObject]@{ Id = 'ttaskbar'; Name = 'TranslucentTB'; Winget = 'CharlesMilette.TranslucentTB'; Choco = 'translucenttb'; Category = 'Utilities'; Description = 'TranslucentTB is a tool that allows you to customize the transparency of the Windows Taskbar.' }
		[PSCustomObject]@{ Id = 'ubisoft'; Name = 'Ubisoft Connect'; Winget = 'Ubisoft.Connect'; Choco = 'ubisoft-connect'; Category = 'Games'; Description = 'Ubisoft Connect is Ubisoft''s digital distribution and online gaming service, providing access to Ubisoft''s games and services.' }
		[PSCustomObject]@{ Id = 'ungoogled'; Name = 'Ungoogled Chromium'; Winget = 'eloston.ungoogled-chromium'; Choco = 'ungoogled-chromium'; Category = 'Browsers'; Description = 'Ungoogled Chromium is a version of Chromium without Google''s integration for enhanced privacy and control.' }
		[PSCustomObject]@{ Id = 'unity'; Name = 'Unity Game Engine'; Winget = 'Unity.UnityHub'; Choco = 'unity-hub'; Category = 'Development'; Description = 'Unity is a powerful game development platform for creating 2D, 3D, augmented reality, and virtual reality games.' }
		[PSCustomObject]@{ Id = 'vagrant'; Name = 'Vagrant'; Winget = 'Hashicorp.Vagrant'; Choco = 'vagrant'; Category = 'Development'; Description = 'Vagrant builds and manages reproducible virtual machine development environments from declarative configuration.' }
		[PSCustomObject]@{ Id = 'everything'; Name = 'Everything'; Winget = 'voidtools.Everything'; Choco = 'everything'; Category = 'Utilities'; Description = 'Everything is a search engine that locates files and folders by filename instantly for Windows. Unlike Windows search Everything initially displays every file and folder on your co' }
		[PSCustomObject]@{ Id = 'vc2015_32'; Name = 'Visual C++ 2015-2022 32-bit'; Winget = 'Microsoft.VCRedist.2015+.x86'; Choco = 'vcredist2015'; Category = 'Microsoft Tools'; Description = 'Visual C++ 2015-2022 32-bit redistributable package installs runtime components of Visual C++ libraries required to run 32-bit applications.' }
		[PSCustomObject]@{ Id = 'vc2015_64'; Name = 'Visual C++ 2015-2022 64-bit'; Winget = 'Microsoft.VCRedist.2015+.x64'; Choco = 'vcredist2015'; Category = 'Microsoft Tools'; Description = 'Visual C++ 2015-2022 64-bit redistributable package installs runtime components of Visual C++ libraries required to run 64-bit applications.' }
		[PSCustomObject]@{ Id = 'ventoy'; Name = 'Ventoy'; Winget = 'Ventoy.Ventoy'; Choco = 'ventoy'; Category = 'Pro Tools'; Description = 'Ventoy is an open-source tool for creating bootable USB drives. It supports multiple ISO files on a single USB drive, making it a versatile solution for installing operating system' }
		[PSCustomObject]@{ Id = 'vesktop'; Name = 'Vesktop'; Winget = 'Vencord.Vesktop'; Choco = 'na'; Category = 'Communications'; Description = 'A cross-platform electron-based desktop app aiming to give you a snappier Discord experience with Vencord pre-installed.' }
		[PSCustomObject]@{ Id = 'viber'; Name = 'Viber'; Winget = 'Rakuten.Viber'; Choco = 'viber'; Category = 'Communications'; Description = 'Viber is a free messaging and calling app with features like group chats, video calls, and more.' }
		[PSCustomObject]@{ Id = 'visualstudio2022'; Name = 'Visual Studio 2022'; Winget = 'Microsoft.VisualStudio.2022.Community'; Choco = 'visualstudio2022community'; Category = 'Development'; Description = 'Visual Studio 2022 is an integrated development environment (IDE) for building, debugging, and deploying applications.' }
		[PSCustomObject]@{ Id = 'visualstudio2026'; Name = 'Visual Studio 2026'; Winget = 'Microsoft.VisualStudio.Community'; Choco = 'visualstudio2026community'; Category = 'Development'; Description = 'Visual Studio 2026 is an integrated development environment (IDE) for building, debugging, and deploying applications.' }
		[PSCustomObject]@{ Id = 'vivaldi'; Name = 'Vivaldi'; Winget = 'Vivaldi.Vivaldi'; Choco = 'vivaldi'; Category = 'Browsers'; Description = 'Vivaldi is a highly customizable web browser with a focus on user personalization and productivity features.' }
		[PSCustomObject]@{ Id = 'vlc'; Name = 'VLC (Video Player)'; Winget = 'VideoLAN.VLC'; Choco = 'vlc'; Category = 'Multimedia Tools'; Description = 'VLC Media Player is a free and open-source multimedia player that supports a wide range of audio and video formats. It is known for its versatility and cross-platform compatibility' }
		[PSCustomObject]@{ Id = 'vrdesktopstreamer'; Name = 'Virtual Desktop Streamer'; Winget = 'VirtualDesktop.Streamer'; Choco = 'na'; Category = 'Games'; Description = 'Virtual Desktop Streamer is a tool that allows you to stream your desktop screen to VR devices.' }
		[PSCustomObject]@{ Id = 'vscode'; Name = 'VS Code'; Winget = 'Microsoft.VisualStudioCode'; Choco = 'vscode'; Category = 'Development'; Description = 'Visual Studio Code is a free, open-source code editor with support for multiple programming languages.' }
		[PSCustomObject]@{ Id = 'vscodium'; Name = 'VS Codium'; Winget = 'VSCodium.VSCodium'; Choco = 'vscodium'; Category = 'Development'; Description = 'VSCodium is a community-driven, freely-licensed binary distribution of Microsoft''s VS Code.' }
		[PSCustomObject]@{ Id = 'waterfox'; Name = 'Waterfox'; Winget = 'Waterfox.Waterfox'; Choco = 'waterfox'; Category = 'Browsers'; Description = 'Waterfox is a fast, privacy-focused web browser based on Firefox, designed to preserve user choice and privacy.' }
		[PSCustomObject]@{ Id = 'whatsapp'; Name = 'WhatsApp Desktop'; Winget = 'msstore:9NKSQGP7F2NH'; Choco = 'na'; Category = 'Communications'; Description = 'WhatsApp Desktop is the official Windows desktop messaging app from Meta, distributed through the Microsoft Store.' }
		[PSCustomObject]@{ Id = 'wingetui'; Name = 'UniGetUI'; Winget = 'Devolutions.UniGetUI'; Choco = 'wingetui'; Category = 'Utilities'; Description = 'UniGetUI is a GUI for WinGet, Chocolatey, and other Windows CLI package managers.' }
		[PSCustomObject]@{ Id = 'winrar'; Name = 'WinRAR'; Winget = 'RARLab.WinRAR'; Choco = 'winrar'; Category = 'Utilities'; Description = 'WinRAR is a powerful archive manager that allows you to create, manage, and extract compressed files.' }
		[PSCustomObject]@{ Id = 'winscp'; Name = 'WinSCP'; Winget = 'WinSCP.WinSCP'; Choco = 'winscp'; Category = 'Pro Tools'; Description = 'WinSCP is a popular open-source SFTP, FTP, and SCP client for Windows. It allows secure file transfers between a local and a remote computer.' }
		[PSCustomObject]@{ Id = 'wireguard'; Name = 'WireGuard'; Winget = 'WireGuard.WireGuard'; Choco = 'wireguard'; Category = 'Pro Tools'; Description = 'WireGuard is a fast and modern VPN (Virtual Private Network) protocol. It aims to be simpler and more efficient than other VPN protocols, providing secure and reliable connections.' }
		[PSCustomObject]@{ Id = 'wireshark'; Name = 'Wireshark'; Winget = 'WiresharkFoundation.Wireshark'; Choco = 'wireshark'; Category = 'Pro Tools'; Description = 'Wireshark is a widely-used open-source network protocol analyzer. It allows users to capture and analyze network traffic in real-time, providing detailed insights into network acti' }
		[PSCustomObject]@{ Id = 'wiztree'; Name = 'WizTree'; Winget = 'AntibodySoftware.WizTree'; Choco = 'wiztree'; Category = 'Utilities'; Description = 'WizTree is a fast disk space analyzer that helps you quickly find the files and folders consuming the most space on your hard drive.' }
		[PSCustomObject]@{ Id = 'xeheditor'; Name = 'HxD Hex Editor'; Winget = 'MHNexus.HxD'; Choco = 'HxD'; Category = 'Utilities'; Description = 'HxD is a free hex editor that allows you to edit, view, search, and analyze binary files.' }
		[PSCustomObject]@{ Id = 'xournal'; Name = 'Xournal++'; Winget = 'Xournal++.Xournal++'; Choco = 'xournalplusplus'; Category = 'Document'; Description = 'Xournal++ is an open-source handwriting notetaking software with PDF annotation capabilities.' }
		[PSCustomObject]@{ Id = 'yarn'; Name = 'Yarn'; Winget = 'Yarn.Yarn'; Choco = 'yarn'; Category = 'Development'; Description = 'Yarn is a fast, reliable, and secure dependency management tool for JavaScript projects.' }
		[PSCustomObject]@{ Id = 'zoom'; Name = 'Zoom'; Winget = 'Zoom.Zoom'; Choco = 'zoom'; Category = 'Communications'; Description = 'Zoom is a popular video conferencing and web conferencing service for online meetings, webinars, and collaborative projects.' }
		[PSCustomObject]@{ Id = 'uv'; Name = 'uv'; Winget = 'astral-sh.uv'; Choco = 'uv'; Category = 'Development'; Description = 'uv is a fast Python package and project manager written in Rust.' }
		[PSCustomObject]@{ Id = 'tightvnc'; Name = 'TightVNC'; Winget = 'GlavSoft.TightVNC'; Choco = 'TightVNC'; Category = 'Utilities'; Description = 'TightVNC is a free and open-source remote desktop software that lets you access and control a computer over the network. With its intuitive interface, you can interact with the rem' }
		[PSCustomObject]@{ Id = 'glazewm'; Name = 'GlazeWM'; Winget = 'glzr-io.glazewm'; Choco = 'glazewm'; Category = 'Utilities'; Description = 'GlazeWM is a tiling window manager for Windows inspired by i3 and Polybar.' }
		[PSCustomObject]@{ Id = 'Overwolf'; Name = 'CurseForge'; Winget = 'Overwolf.CurseForge'; Choco = ''; Category = 'Games'; Description = 'CurseForge is a desktop application for managing mods and modpacks across multiple games, powered by Overwolf.' }
		[PSCustomObject]@{ Id = 'OFGB'; Name = 'OFGB (Oh Frick Go Back)'; Winget = 'xM4ddy.OFGB'; Choco = 'ofgb'; Category = 'Utilities'; Description = 'GUI Tool to remove ads from various places around Windows 11' }
		[PSCustomObject]@{ Id = 'ZenBrowser'; Name = 'Zen Browser'; Winget = 'Zen-Team.Zen-Browser'; Choco = 'na'; Category = 'Browsers'; Description = 'The modern, privacy-focused, performance-driven browser built on Firefox.' }
		[PSCustomObject]@{ Id = 'Zed'; Name = 'Zed'; Winget = 'ZedIndustries.Zed'; Choco = 'zed'; Category = 'Development'; Description = 'Zed is a modern, high-performance code editor designed from the ground up for speed and collaboration.' }
		[PSCustomObject]@{ Id = 'zotero'; Name = 'Zotero'; Winget = 'DigitalScholar.Zotero'; Choco = 'zotero'; Category = 'Document'; Description = 'Zotero is a free, easy-to-use tool to help you collect, organize, cite, and share your research materials.' }
		[PSCustomObject]@{ Id = 'deskflow'; Name = 'Deskflow'; Winget = 'Deskflow.Deskflow'; Choco = 'deskflow'; Category = 'Utilities'; Description = 'Deskflow is a free and open-source software KVM that lets you share a single keyboard and mouse across multiple computers.' }
		[PSCustomObject]@{ Id = 'Ruby'; Name = 'Ruby'; Winget = 'RubyInstallerTeam.Ruby.4.0'; Choco = 'ruby'; Category = 'Development'; Description = 'A Ruby language execution environment with a MSYS2 installation.' }
		[PSCustomObject]@{ Id = 'Lua'; Name = 'Lua'; Winget = 'rjpcomputing.luaforwindows'; Choco = 'lua'; Category = 'Development'; Description = 'A ''batteries included environment'' for the Lua scripting language on Windows.' }
		[PSCustomObject]@{ Id = 'CloudflareWARP'; Name = 'Cloudflare WARP'; Winget = 'Cloudflare.Warp'; Choco = 'warp'; Category = 'Utilities'; Description = 'WARP is a freemium VPN service provided by Cloudflare. Includes usage of Cloudflare''s DNS' }
	)
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\SelfTest.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Self-Test / Debug toàn diện (không thay đổi hệ thống)

	.DESCRIPTION
	1) Parse cú pháp mọi file .ps1 của tool bằng PowerShell Parser chính chủ
	2) Dựng catalog, kiểm tra ID trùng, mỗi tweak đủ Apply/Restore/Check
	3) Chạy thử toàn bộ CheckScript (chỉ đọc) và báo tweak nào lỗi
	4) Kiểm tra 6 Mode có tweak, Plan Engine chạy được, Smart Advisor chạy được
	5) Kiểm tra bản Portable có đủ module inline (nếu chạy trong repo)
	Chỉ ĐỌC — không áp dụng tweak nào.
#>

function Test-SophiaOptimizerHealth
{
	[CmdletBinding()]
	param([string]$RepoRoot, $Catalog)

	$pass = 0; $fail = 0; $warn = 0
	function Report([string]$Status, [string]$Msg)
	{
		if ($Status -eq "PASS") { $script:pass++; Write-Host "  [✓ PASS] $Msg" -ForegroundColor Green }
		elseif ($Status -eq "WARN") { $script:warn++; Write-Host "  [! WARN] $Msg" -ForegroundColor Yellow }
		else { $script:fail++; Write-Host "  [X FAIL] $Msg" -ForegroundColor Red }
	}
	$script:pass = 0; $script:fail = 0; $script:warn = 0

	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "  ║  🩺 MOLIK WINLIK — SELF-TEST / DEBUG TOÀN DIỆN           ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

	# 1) Syntax parse
	$files = @()
	if ($RepoRoot)
	{
		$files += Get-ChildItem -Path (Join-Path $RepoRoot "Optimizer") -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue
		foreach ($extra in @("MolikWinlik.ps1","MolikWinlik-Portable.ps1","Sophia-Optimizer.ps1","Sophia-Ultra-Portable.ps1"))
		{
			$ef = Join-Path $RepoRoot $extra
			if (Test-Path $ef) { $files += Get-Item $ef }
		}
	}
	$parseErrors = 0
	foreach ($f in $files)
	{
		$tokens = $null; $errors = $null
		[void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)
		if ($errors -and $errors.Count -gt 0) { $parseErrors += $errors.Count; Report "FAIL" "Parse: $($f.Name) có $($errors.Count) lỗi: $($errors[0].Message)" }
	}
	if ($files.Count -eq 0) { Report "WARN" "Cú pháp PowerShell: không tìm thấy file .ps1 nguồn nào để parse (bỏ qua nếu đang chạy bản Portable độc lập)" }
	elseif ($parseErrors -eq 0) { Report "PASS" "Cú pháp PowerShell: $($files.Count) file đều parse sạch" }

	# 2) Catalog integrity
	if (-not $Catalog) { $Catalog = Get-SophiaTweaksCatalog }
	Report "PASS" "Catalog dựng thành công: $($Catalog.Count) tweak"
	$dupes = $Catalog | Group-Object Id | Where-Object Count -gt 1
	if ($dupes) { Report "FAIL" "ID trùng: $($dupes.Name -join ', ')" } else { Report "PASS" "Không có ID tweak nào trùng" }
	$incomplete = @($Catalog | Where-Object { -not $_.ApplyScript -or -not $_.RestoreScript -or -not $_.CheckScript -or -not $_.Name })
	if ($incomplete.Count -gt 0) { Report "FAIL" "Tweak thiếu script/tên: $($incomplete.Id -join ', ')" } else { Report "PASS" "Mọi tweak đủ Apply/Restore/Check/Name" }

	# 3) CheckScripts (read-only)
	$checkErrors = @()
	foreach ($t in $Catalog)
	{
		try { [void](& $t.CheckScript) } catch { $checkErrors += "$($t.Id): $($_.Exception.Message)" }
	}
	if ($checkErrors.Count -eq 0) { Report "PASS" "Toàn bộ $($Catalog.Count) CheckScript chạy không lỗi (chỉ đọc)" }
	else { Report "WARN" "$($checkErrors.Count) CheckScript báo vấn đề (thường do thiếu phần cứng/quyền): $($checkErrors[0])" }

	# 4) Modes + Plan + Smart
	foreach ($m in (Get-SophiaOptimizationModes))
	{
		$cnt = (Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog).Count
		if ($cnt -gt 0) { Report "PASS" "Mode $($m.Key): $cnt tweak" } else { Report "FAIL" "Mode $($m.Key) rỗng!" }
	}
	try
	{
		$sampleIds = (Get-SophiaModeTweakIds -ModeKey "EmulatorFarm" -Catalog $Catalog)
		$plan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $sampleIds
		Report "PASS" "Plan Engine: lập plan $($plan.Count) tweak, Impact $($plan.ImpactScore), $($plan.Notes.Count) ghi chú phụ thuộc/mâu thuẫn"
	} catch { Report "FAIL" "Plan Engine lỗi: $($_.Exception.Message)" }
	try
	{
		$snap = Get-SophiaSystemSnapshot
		$rec = Get-SophiaSmartRecommendation -Snapshot $snap -Catalog $Catalog
		Report "PASS" "Smart Advisor: máy này -> Mode $($rec.Mode) + $($rec.ExtraIds.Count) tweak bổ sung ($($snap.OSName), $($snap.CPUThreads) luồng, RAM $($snap.RAMTotalGB)GB)"
	} catch { Report "WARN" "Smart Advisor/Snapshot: $($_.Exception.Message)" }

	# 5) Encoding guard (OFFLINE): file .ps1 chay bang -File tren Windows PowerShell 5.1
	# phai co BOM UTF-8 (hoac thuan ASCII) thi tieng Viet moi hien dung. Ban Portable
	# duoc Build-Portable.ps1 ghi UTF-8 BOM nen kiem tra ca BOM lan noi dung tai mang.
	if ($RepoRoot)
	{
		foreach ($coreFile in @("MolikWinlik.ps1", "MolikWinlik-Portable.ps1"))
		{
			$of = Join-Path $RepoRoot $coreFile
			if (Test-Path $of)
			{
				$bytes = [System.IO.File]::ReadAllBytes($of)
				$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
				$hasNonAscii = $false
				foreach ($b in $bytes) { if ($b -gt 127) { $hasNonAscii = $true; break } }
				if ($hasNonAscii -and -not $hasBom) { Report "FAIL" "Encoding guard: $coreFile co ky tu khong-ASCII nhung thieu BOM UTF-8 - PowerShell 5.1 se doc sai tieng Viet!" }
				else { Report "PASS" "Encoding guard: $coreFile an toan cho PowerShell 5.1 (BOM UTF-8 hoac ASCII thuan)" }
			}
		}
		$bat = Join-Path $RepoRoot "MOLIK_WINLIK.bat"
		if (Test-Path $bat)
		{
			$batText = Get-Content $bat -Raw
			if ($batText -match "MolikWinlik-Portable\.ps1" -and $batText -match "fltmc" -and $batText -notmatch "Invoke-WebRequest|Invoke-RestMethod|DownloadString")
			{
				Report "PASS" "Offline launcher: MOLIK_WINLIK.bat tu xin Admin (fltmc/UAC), chay file local, khong tai gi khi chay"
			}
			else { Report "FAIL" "Offline launcher: MOLIK_WINLIK.bat thieu fltmc/core local hoac chua lenh tai mang!" }
		}
		else { Report "WARN" "Khong thay MOLIK_WINLIK.bat o goc repo (bo qua neu dang chay ban Portable doc lap)" }
	}

	# 6) Portable integrity + OFFLINE purity (khong cmdlet tai code khi chay)
	if ($RepoRoot)
	{
		$portable = Join-Path $RepoRoot "MolikWinlik-Portable.ps1"
		if (Test-Path $portable)
		{
			$content = Get-Content $portable -Raw
			$markers = ([regex]::Matches($content, "PORTABLE-INLINE")).Count
			if ($markers -ge 10 -and $content -match "Get-WinUtilConvertedTweaks" -and $content -match "EXT84") { Report "PASS" "Portable: $markers module inline, du WinUtil + EXT84 (offline)" }
			else { Report "WARN" "Portable co ve thieu module (markers=$markers) - chay Optimizer\\Build-Portable.ps1 de sinh lai" }
			$scanText = (($content -split "`n") | Where-Object { $_ -notmatch "OFFLINE guard|-match|-notmatch" }) -join "`n"
			if ($scanText -match "Invoke-RestMethod|Invoke-WebRequest|DownloadString") { Report "FAIL" "OFFLINE guard: Portable chua cmdlet tai code tu Internet!" }
			else { Report "PASS" "OFFLINE guard: Portable khong tai code khi chay (chi winget tuy chon cho app)" }
		}
	}

	# 7) Presets + Report Engine
	try
	{
		if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue)
		{
			$presetFail = @()
			foreach ($preset in (Get-MolikPresets))
			{
				$resolved = Resolve-MolikPreset -Preset $preset -Catalog $Catalog
				if ($resolved.Count -eq 0) { $presetFail += $preset.Name }
				if (@($preset.ExcludeRisks).Count -gt 0)
				{
					$violations = @($Catalog | Where-Object { ($resolved -contains $_.Id) -and ($preset.ExcludeRisks -contains $_.Risk) })
					if ($violations.Count -gt 0) { $presetFail += "$($preset.Name) (chứa $($violations[0].Risk) dù đã loại trừ: $($violations[0].Id))" }
				}
			}
			if ($presetFail.Count -eq 0) { Report "PASS" "Presets: $((Get-MolikPresets).Count) preset deu giai ra danh sach tweak hop le" }
			else { Report "FAIL" "Preset giai rong: $($presetFail -join ', ')" }
		}
	}
	catch { Report "FAIL" "Presets loi: $($_.Exception.Message)" }
	try
	{
		if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue)
		{
			$tmpReport = Join-Path $env:TEMP "MolikWinlik-SelfTest-Report.html"
			Export-MolikHtmlReport -Snapshot $null -Catalog $Catalog -Path $tmpReport -SkipStatus | Out-Null
			if ((Test-Path $tmpReport) -and ((Get-Content $tmpReport -Raw) -match "MOLIK WINLIK")) { Report "PASS" "Report Engine: xuat HTML Dashboard thanh cong (file tam, da xoa)" } else { Report "FAIL" "Report Engine: file HTML khong hop le" }
			Remove-Item $tmpReport -Force -ErrorAction SilentlyContinue
		}
	}
	catch { Report "FAIL" "Report Engine loi: $($_.Exception.Message)" }

	# 8) Tinh nang v3.1: Doctor / Undo / Backup list
	$missingFn = @()
	foreach ($fn in @("Show-MolikSystemDoctor", "Restore-MolikLastSession", "Get-MolikBackupFolders", "Show-MolikBackupList"))
	{
		if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) { $missingFn += $fn }
	}
	if ($missingFn.Count -eq 0) { Report "PASS" "v3.1 core: Doctor + UndoLast + Backup list đều sẵn sàng" }
	else { Report "FAIL" "Thiếu hàm v3.1: $($missingFn -join ', ')" }
	# Luu y: SelfTest la CHI DOC - khong bao gio goi Undo/Restore that o day,
	# chi kiem tra ham ton tai. Logic parse log duoc bao phu boi kiem tra tinh.

	Write-Host ""
	Write-Host ("  ══════════ KẾT QUẢ: {0} PASS / {1} FAIL / {2} WARN ══════════" -f $script:pass, $script:fail, $script:warn) -ForegroundColor Cyan
	if ($script:fail -eq 0) { Write-Host "  ✅ Tool khỏe mạnh, sẵn sàng tối ưu!" -ForegroundColor Green } else { Write-Host "  Hãy gửi log này khi báo lỗi." -ForegroundColor Yellow }
	return ($script:fail -eq 0)
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\BackupRestore.ps1
# ============================================================
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


# ============================================================
# [PORTABLE-INLINE] Optimizer\Core\SophiaBridge.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Bridge to Native Sophia Script Modules (src/Sophia_Script_for_Windows_*)

	.DESCRIPTION
	Automatically resolves the correct Sophia Script edition for the host OS (Windows 10 / 11 / LTSC / ARM / PS5.1 / PS7),
	imports localizations, WinAPI P/Invoke types, Private helpers, and Sophia.psm1 functions without being blocked
	by offline LGPO or minor Windows UBR version checks.
#>

function Resolve-SophiaEditionFolder
{
	[CmdletBinding()]
	param
	(
		[string]$RepoRoot
	)

	$SrcRoot = Join-Path -Path $RepoRoot -ChildPath "src"
	if (-not (Test-Path -Path $SrcRoot))
	{
		return $null
	}

	$BuildNumber = 19045
	$ProductName = "Windows 10 Pro"
	$Arch        = 9

	try
	{
		$BuildNumber = [int](Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild -ErrorAction SilentlyContinue)
		$ProductName = [string](Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName -ErrorAction SilentlyContinue)
		$Arch        = [int]((Get-CimInstance -Namespace root/CIMV2 -ClassName CIM_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Architecture)
	}
	catch {}

	$IsPS7 = ($PSVersionTable.PSVersion.Major -ge 7)
	$EditionName = "Sophia_Script_for_Windows_11"

	if ($BuildNumber -eq 17763 -and $ProductName -match "LTSC")
	{
		$EditionName = "Sophia_Script_for_Windows_10_LTSC_2019"
	}
	elseif ($BuildNumber -eq 19044 -and $ProductName -match "LTSC")
	{
		$EditionName = "Sophia_Script_for_Windows_10_LTSC_2021"
	}
	elseif ($BuildNumber -le 19045)
	{
		$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_10_PowerShell_7" } else { "Sophia_Script_for_Windows_10" }
	}
	else
	{
		if ($ProductName -match "LTSC")
		{
			$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_11_LTSC_2024_PowerShell_7" } else { "Sophia_Script_for_Windows_11_LTSC_2024" }
		}
		elseif ($Arch -eq 12)
		{
			$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_11_Arm_PowerShell_7" } else { "Sophia_Script_for_Windows_11_Arm" }
		}
		else
		{
			$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_11_PowerShell_7" } else { "Sophia_Script_for_Windows_11" }
		}
	}

	$EditionPath = Join-Path -Path $SrcRoot -ChildPath $EditionName
	if (Test-Path -Path $EditionPath)
	{
		return $EditionPath
	}

	# Fallback to Windows 11 or 10 folder
	$Fallback = Get-ChildItem -Path $SrcRoot -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($Fallback) { return $Fallback.FullName }
	return $null
}

function Initialize-SophiaNativeModule
{
	[CmdletBinding()]
	param
	(
		[string]$RepoRoot
	)

	if ($Global:SophiaNativeLoaded)
	{
		return $true
	}

	$EditionPath = Resolve-SophiaEditionFolder -RepoRoot $RepoRoot
	if (-not $EditionPath)
	{
		return $false
	}

	try
	{
		$LocalizationsDir = Join-Path -Path $EditionPath -ChildPath "Module\Localizations"
		if (Test-Path -Path $LocalizationsDir)
		{
			try
			{
				Import-LocalizedData -BindingVariable Localization -UICulture $PSUICulture -BaseDirectory $LocalizationsDir -FileName Sophia -ErrorAction Stop
				if ($Localization) { $Global:Localization = $Localization }
			}
			catch
			{
				Import-LocalizedData -BindingVariable Localization -UICulture en-US -BaseDirectory $LocalizationsDir -FileName Sophia -ErrorAction SilentlyContinue
				if ($Localization) { $Global:Localization = $Localization }
			}
		}

		$PrivateDir = Join-Path -Path $EditionPath -ChildPath "Module\Private"
		if (Test-Path -Path $PrivateDir)
		{
			Get-ChildItem -Path $PrivateDir -Filter "*.ps1" -File | Where-Object { $_.Name -notin @("InitialActions.ps1", "PostActions.ps1") } | ForEach-Object {
				. $_.FullName
			}
		}

		if (Get-Command -Name Import-WinAPI -ErrorAction SilentlyContinue)
		{
			Import-WinAPI -ErrorAction SilentlyContinue
		}

		$ModulePsm1 = Join-Path -Path $EditionPath -ChildPath "Module\Sophia.psm1"
		if (Test-Path -Path $ModulePsm1)
		{
			Import-Module -Name $ModulePsm1 -Global -Force -ErrorAction SilentlyContinue | Out-Null
			$Global:SophiaNativeLoaded = $true
			$Global:SophiaEditionLoaded = (Split-Path -Path $EditionPath -Leaf)
			return $true
		}
	}
	catch
	{
		return $false
	}

	return $false
}

function Invoke-SophiaNativeSafe
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$CommandName,

		[Parameter(Mandatory = $false)]
		[hashtable]$Parameters = @{}
	)

	$Cmd = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
	if ($Cmd)
	{
		try
		{
			& $Cmd @Parameters
			return $true
		}
		catch
		{
			return $false
		}
	}
	return $false
}


# ============================================================
# [PORTABLE-INLINE] Optimizer\Catalog\TweaksCatalog.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Deep Tweaks Catalog (9 categories incl. EXTREME LAB, 6 modes - run -ListTweaks for the live count)

	.DESCRIPTION
	Every tweak: Id, Name, Category, Description, Risk, Modes, ApplyScript, RestoreScript, CheckScript.
	Registry tweaks are generated via New-SophiaRegTweak (data-driven, reversible).
	Complex tweaks (BCD, powercfg, netsh, services, tasks) use explicit scriptblocks.
	All tweaks are reversible via RestoreScript or the backup in BackupRestore.ps1.

	.NOTES
	Risk: Safe = cosmetic/standard, Moderate = performance, Extreme = kernel/security trade-off.
#>

#Requires -Version 5.1

function Set-SophiaRegValue
{
	param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
	try
	{
		if (-not (Test-Path -Path $Path)) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
		New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
	} catch {}
}

function Get-SophiaRegValue
{
	param([string]$Path, [string]$Name)
	try { return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name } catch { return $null }
}

function New-SophiaRegTweak
{
	param(
		[Parameter(Mandatory)][string]$Id,
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)][string]$Category,
		[Parameter(Mandatory)][string]$Description,
		[string]$Risk = "Safe",
		[string[]]$Modes = @(),
		[Parameter(Mandatory)][string]$Path,
		[Parameter(Mandatory)][string]$ValueName,
		[Parameter(Mandatory)]$ApplyValue,
		$RestoreValue = $null,
		[string]$Type = "DWord"
	)
	$apply = {
		Set-SophiaRegValue -Path $Path -Name $ValueName -Value $ApplyValue -Type $Type
	}.GetNewClosure()
	$restore = {
		if ($null -eq $RestoreValue)
		{
			Remove-ItemProperty -Path $Path -Name $ValueName -Force -ErrorAction SilentlyContinue
		}
		else
		{
			Set-SophiaRegValue -Path $Path -Name $ValueName -Value $RestoreValue -Type $Type
		}
	}.GetNewClosure()
	$check = {
		$current = Get-SophiaRegValue -Path $Path -Name $ValueName
		return ($null -ne $current -and "$current" -eq "$ApplyValue")
	}.GetNewClosure()

	return [PSCustomObject]@{
		Id = $Id; Name = $Name; Category = $Category; Description = $Description
		Risk = $Risk; Modes = $Modes
		ApplyScript = $apply; RestoreScript = $restore; CheckScript = $check
		Kind = "Registry"; Detail = "$Path\$ValueName = $ApplyValue"
	}
}

function New-SophiaCmdTweak
{
	param(
		[Parameter(Mandatory)][string]$Id,
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)][string]$Category,
		[Parameter(Mandatory)][string]$Description,
		[string]$Risk = "Moderate",
		[string[]]$Modes = @(),
		[Parameter(Mandatory)][scriptblock]$Apply,
		[Parameter(Mandatory)][scriptblock]$Restore,
		[scriptblock]$Check = { return $false },
		[string]$Detail = ""
	)
	return [PSCustomObject]@{
		Id = $Id; Name = $Name; Category = $Category; Description = $Description
		Risk = $Risk; Modes = $Modes
		ApplyScript = $Apply; RestoreScript = $Restore; CheckScript = $Check
		Kind = "Command"; Detail = $Detail
	}
}

function Get-SophiaOptimizationModes
{
	return @(
		[PSCustomObject]@{ Key = "EmulatorFarm";     Icon = "🖥️"; Name = "TREO GIẢ LẬP 24/7";        Sub = "Multi-Instance Farm (LDPlayer/MuMu/Nox/BlueStacks)"; Description = "Tắt VBS/Hyper-V tranh VT-x, nén RAM, dọn Standby List tự động, pagefile cố định lớn, không ngủ/USB suspend, ưu tiên CPU/RAM cho hàng chục instance chạy 24/7 không crash, không leak RAM." }
		[PSCustomObject]@{ Key = "HardcoreGaming";   Icon = "🎮"; Name = "HARDCORE GAMING";         Sub = "Low-Latency FPS / Esports"; Description = "HAGS, tắt MPO/Game DVR, timer & BCD latency, Nagle off, NetworkThrottlingIndex=0, SystemResponsiveness=0, mouse 1:1, Ultimate Performance — giảm input lag & frame-time spike tối đa." }
		[PSCustomObject]@{ Key = "Workstation";      Icon = "🎬"; Name = "WORKSTATION / STREAM";    Sub = "Render, OBS, Compile, Đa nhiệm nặng"; Description = "Giữ ổn định & bảo mật hợp lý, ưu tiên foreground + GPU encode, RAM cache lớn, không tắt mitigations — mạnh nhưng không đánh đổi độ tin cậy khi render/stream dài." }
		[PSCustomObject]@{ Key = "LowSpec";          Icon = "🥔"; Name = "LOW-SPEC / POTATO PC";     Sub = "Máy yếu, RAM <=8GB, HDD/SSD chậm"; Description = "Tắt visual effects, services & background apps thừa, giảm telemetry/startup, tối ưu RAM/pagefile cho máy yếu chạy mượt, ít nóng, ít disk 100%." }
		[PSCustomObject]@{ Key = "SophiaStandard";   Icon = "🛡️"; Name = "MOLIK STANDARD";         Sub = "Privacy + Gọn gàng chuẩn bản gốc"; Description = "Tập tweak an toàn của bản upstream gốc: telemetry, quảng cáo, Copilot/Recall, GameBar tips, hiển thị đuôi file... Không đụng kernel/BCD." }
		[PSCustomObject]@{ Key = "GodMode";          Icon = "👑"; Name = "GOD MODE — CỰC HẠN";       Sub = "Tất cả tweak (kể cả Extreme)"; Description = "Bật TOÀN BỘ catalog kể cả tweak Extreme (tắt Spectre/Meltdown mitigations, Defender scan exclusions...). Chỉ dùng khi đã có backup/restore point và hiểu rõ đánh đổi bảo mật." }
	)
}

function Get-SophiaTweaksCatalog
{
	$EMU = "1. 🖥️ TREO GIẢ LẬP 24/7"
	$GAM = "2. 🎮 GAMING & LOW-LATENCY"
	$CPU = "3. ⚡ CPU / KERNEL / TIMER"
	$RAM = "4. 🧠 RAM & MEMORY"
	$GPU = "5. 🎨 GPU & DISPLAY"
	$NET = "6. 🌐 NETWORK & INTERNET"
	$SYS = "7. 🧹 SYSTEM / SERVICES / DEBLOAT"
	$PRI = "8. 🔒 PRIVACY (MOLIK WINLIK NATIVE)"
	$EXT = "9. 🚀 EXTREME LAB (CỰC HẠN)"

	$FARM = @("EmulatorFarm"); $GAME = @("HardcoreGaming"); $WORK = @("Workstation")
	$LOW  = @("LowSpec"); $STD = @("SophiaStandard")
	$FARM_GAME = @("EmulatorFarm","HardcoreGaming"); $ALL_PERF = @("EmulatorFarm","HardcoreGaming","Workstation")

	$catalog = [System.Collections.Generic.List[object]]::new()
	function Add-Reg { param($Id,$Name,$Cat,$Desc,$Risk,$Modes,$Path,$VN,$AV,$RV,$Type="DWord")
		$catalog.Add((New-SophiaRegTweak -Id $Id -Name $Name -Category $Cat -Description $Desc -Risk $Risk -Modes $Modes -Path $Path -ValueName $VN -ApplyValue $AV -RestoreValue $RV -Type $Type)) }
	function Add-Cmd { param($Id,$Name,$Cat,$Desc,$Risk,$Modes,$Apply,$Restore,$Check,$Detail)
		$catalog.Add((New-SophiaCmdTweak -Id $Id -Name $Name -Category $Cat -Description $Desc -Risk $Risk -Modes $Modes -Apply $Apply -Restore $Restore -Check $Check -Detail $Detail)) }

	# ═══════════════ 1. EMULATOR FARM ═══════════════
	Add-Reg "EMU01" "Tắt VBS / HVCI / Credential Guard (giải phóng VT-x)" $EMU "Virtualization-Based Security + Memory Integrity tranh VT-x với giả lập, gây chậm 20-40% & crash instance. Tắt để giả lập dùng VT-x trực tiếp." "Extreme" ($FARM+$GAME) "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 1
	Add-Cmd "EMU02" "Tắt Hyper-V Hypervisor KHI BOOT (bcdedit hypervisorlaunchtype=Off)" $EMU "Hyper-V chiếm VT-x khiến LDPlayer/MuMu báo 'VT bị chiếm' / chạy cực chậm. Chỉ đổi BCD launch type (không gỡ feature như EMU03) nên bật lại rất nhanh bằng Restore. Cần RESTART." "Extreme" $FARM {
		& bcdedit /set hypervisorlaunchtype off 2>$null | Out-Null
	} {
		& bcdedit /set hypervisorlaunchtype auto 2>$null | Out-Null
	} { try { return ((& bcdedit /enum '{current}' 2>$null) -match 'hypervisorlaunchtype\s+Off') } catch { return $false } } "bcdedit hypervisorlaunchtype off"
	Add-Cmd "EMU03" "Tắt tính năng Hyper-V / VirtualMachinePlatform / WindowsHypervisorPlatform" $EMU "Gỡ lớp hypervisor của Windows để giả lập Android (VirtualBox-based) độc chiếm VT-x. Khôi phục = bật lại feature." "Extreme" $FARM {
		Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue | Out-Null
		Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction SilentlyContinue | Out-Null
		Disable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart -ErrorAction SilentlyContinue | Out-Null
		& bcdedit /set hypervisorlaunchtype off 2>$null | Out-Null
	} {
		Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue | Out-Null
		& bcdedit /set hypervisorlaunchtype auto 2>$null | Out-Null
	} { try { return ((& bcdedit /enum '{current}' 2>$null) -match 'hypervisorlaunchtype\s+Off') } catch { return $false } } "bcdedit hypervisorlaunchtype + DISM features"
	Add-Reg "EMU04" "Tắt Memory Integrity (HVCI) cho driver giả lập" $EMU "HVCI chặn driver cũ của Nox/MEmu/LDPlayer (vd: lỗi load driver, BSOD). Tắt để driver giả lập nạp bình thường." "Extreme" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0 1
	Add-Cmd "EMU05" "Thêm thư mục giả lập vào Defender Exclusion (quét realtime)" $EMU "Defender quét realtime .vmdk/.vdi & process giả lập gây disk 100% + giật instance. Thêm exclusion cho LDPlayer/MuMu/Nox/BlueStacks/MEmu nếu tồn tại." "Moderate" $FARM {
		$dirs = @("$env:SystemDrive\LDPlayer","$env:SystemDrive\Program Files\LDPlayer","$env:SystemDrive\Program Files\MuMuPlayer-12.0","$env:SystemDrive\Program Files\Netease","$env:SystemDrive\Program Files (x86)\Nox","$env:SystemDrive\Program Files\BlueStacks_nxt","$env:SystemDrive\Program Files (x86)\Microvirt")
		foreach ($d in $dirs) { if (Test-Path $d) { try { Add-MpPreference -ExclusionPath $d -ErrorAction SilentlyContinue } catch {} } }
		@("LdVBoxHeadless.exe","HD-Player.exe","Nox.exe","MuMuPlayer.exe","NemuHeadless.exe") | ForEach-Object { try { Add-MpPreference -ExclusionProcess $_ -ErrorAction SilentlyContinue } catch {} }
	} {
		$dirs = @("$env:SystemDrive\LDPlayer","$env:SystemDrive\Program Files\LDPlayer","$env:SystemDrive\Program Files\MuMuPlayer-12.0","$env:SystemDrive\Program Files\Netease","$env:SystemDrive\Program Files (x86)\Nox","$env:SystemDrive\Program Files\BlueStacks_nxt")
		foreach ($d in $dirs) { try { Remove-MpPreference -ExclusionPath $d -ErrorAction SilentlyContinue } catch {} }
	} { try { return ((Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath -match 'LDPlayer|MuMu|Nox|BlueStacks') } catch { return $false } } "Add-MpPreference -ExclusionPath/Process"
	Add-Cmd "EMU06" "Pagefile CỐ ĐỊNH lớn (min=max, chống phình/thu gây stutter farm)" $EMU "Treo nhiều instance: pagefile động (system-managed) phình-thu liên tục gây stutter. Cố định = RAM vật lý x1.5 (tối thiểu 16GB) trên ổ nhanh nhất." "Moderate" $FARM {
		try {
			$cs = Get-CimInstance Win32_ComputerSystem; $cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $false } -ErrorAction SilentlyContinue
			$totalGB = [Math]::Ceiling((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
			$size = [Math]::Max(16384, [int]($totalGB * 1024 * 1.5))
			Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Remove-CimInstance -ErrorAction SilentlyContinue
			New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = "$env:SystemDrive\pagefile.sys"; InitialSize = $size; MaximumSize = $size } -ErrorAction SilentlyContinue | Out-Null
		} catch {}
	} {
		try { $cs = Get-CimInstance Win32_ComputerSystem; $cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $true } -ErrorAction SilentlyContinue; Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Remove-CimInstance -ErrorAction SilentlyContinue } catch {}
	} { try { return (-not (Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile) } catch { return $false } } "Win32_PageFileSetting fixed size"
	Add-Cmd "EMU07" "Bật Auto RAM Cleaner 24/7 (Scheduled Task SYSTEM mỗi 15 phút)" $EMU "Treo farm dài ngày: Standby List + Working Set phình gây 'RAM đầy nhưng trống ảo'. Task tự purge khi RAM >70% — chống leak/OOM crash instance." "Safe" $FARM {
		if (Get-Command Register-SophiaAutoRamCleanerTask -ErrorAction SilentlyContinue) { Register-SophiaAutoRamCleanerTask -IntervalMinutes 15 -ThresholdPercent 70 }
	} {
		if (Get-Command Unregister-SophiaAutoRamCleanerTask -ErrorAction SilentlyContinue) { Unregister-SophiaAutoRamCleanerTask }
	} { return [bool](Get-ScheduledTask -TaskName "MOLIK_WINLIK_RAM_Cleaner" -TaskPath "\MOLIK_WINLIK\" -ErrorAction SilentlyContinue) } "Register-ScheduledTask MOLIK_WINLIK_RAM_Cleaner"
	Add-Cmd "EMU08" "Purge RAM NGAY (EmptyWorkingSet + Standby List qua NTAPI)" $EMU "Dọn tức thì Working Set mọi process + Standby/Modified List bằng NtSetSystemInformation — giải phóng vài GB RAM trước khi mở thêm instance." "Safe" ($FARM+$GAME+$LOW) {
		if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge -Silent | Out-Null }
	} { return } { return $false } "NtSetSystemInformation(80) + EmptyWorkingSet"
	Add-Cmd "EMU09" "Không ngủ / Hibernate / USB Selective Suspend (treo 24/7)" $EMU "Máy ngủ, ổ/USB suspend giữa đêm làm rớt toàn bộ farm. Tắt sleep, hibernate, USB suspend, PCIe ASPM trên AC." "Safe" $FARM {
		& powercfg /change standby-timeout-ac 0 2>$null | Out-Null; & powercfg /change hibernate-timeout-ac 0 2>$null | Out-Null; & powercfg /hibernate off 2>$null | Out-Null
		& powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null
		& powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null | Out-Null; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		& powercfg /change standby-timeout-ac 30 2>$null | Out-Null; & powercfg /hibernate on 2>$null | Out-Null
	} { try { return ((& powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>$null) -match '0x00000000') } catch { return $false } } "powercfg standby/hibernate/USB/ASPM"
	Add-Reg "EMU10" "Tăng Desktop Heap & Session View Size (nhiều cửa sổ instance)" $EMU "Mở 10-30 instance dễ hết desktop heap ('failed to create window'). Tăng SharedSection 1024,20480,2048 cho session đồ họa." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems" "Windows" "%SystemRoot%\system32\csrss.exe ObjectDirectory=\Windows SharedSection=1024,20480,2048 Windows=On SubSystemType=Windows ServerDll=basesrv,1 ServerDll=winsrv:UserServerDllInitialization,3 ServerDll=sxssrv,4 ProfileControl=Off MaxRequestThreads=16" "%SystemRoot%\system32\csrss.exe ObjectDirectory=\Windows SharedSection=1024,20480,768 Windows=On SubSystemType=Windows ServerDll=basesrv,1 ServerDll=winsrv:UserServerDllInitialization,3 ServerDll=sxssrv,4 ProfileControl=Off MaxRequestThreads=16" "String"
	Add-Reg "EMU11" "Ưu tiên foreground cho process giả lập (Win32PrioritySeparation=38)" $EMU "Phân bổ quantum CPU ưu tiên ứng dụng foreground (giả lập đang focus) — giảm giật khi nhiều instance tranh CPU." "Moderate" $FARM_GAME "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38 2
	Add-Cmd "EMU12" "Tắt Windows Search Indexing (chống disk 100% khi farm)" $EMU "Search indexer quét liên tục thư mục instance gây disk/CPU spike ngẫu nhiên. Dừng hẳn service WSearch + Disabled (không chỉ ghi registry như trước). Cần tìm file bằng Everything/app khác thay thế." "Moderate" ($FARM+$GAME+$LOW) {
		Stop-Service WSearch -Force -ErrorAction SilentlyContinue; Set-Service WSearch -StartupType Disabled -ErrorAction SilentlyContinue
		Set-SophiaRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" -Name "Start" -Value 4 -Type "DWord"
	} {
		Set-SophiaRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" -Name "Start" -Value 2 -Type "DWord"
		Set-SophiaRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" -Name "DelayedAutoStart" -Value 1 -Type "DWord"
		Start-Service WSearch -ErrorAction SilentlyContinue
	} { try { return ((Get-Service WSearch -ErrorAction SilentlyContinue).StartType -eq 'Disabled') } catch { return $false } } "WSearch Stop + Disabled"
	Add-Cmd "EMU13" "Đặt CPU Priority cao cho process giả lập đang chạy" $EMU "Nâng priority LdVBoxHeadless/HD-Player/Nox/MuMu/Nemu lên AboveNormal để scheduler ưu tiên khi full-load multi-instance." "Moderate" $FARM {
		@("LdVBoxHeadless","HD-Player","Nox","NoxVMHandle","MuMuPlayer","NemuHeadless","MEmuHeadless","VBoxHeadless") | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = "AboveNormal" } catch {} } }
	} {
		@("LdVBoxHeadless","HD-Player","Nox","MuMuPlayer","NemuHeadless","MEmuHeadless","VBoxHeadless") | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = "Normal" } catch {} } }
	} { return $false } "Process.PriorityClass = AboveNormal"

	# ═══════════════ 2. GAMING ═══════════════
	Add-Cmd "GAM01" "Ultimate Performance Power Plan (bỏ giới hạn tiết kiệm điện)" $GAM "Kích hoạt plan Ultimate Performance (duplicated từ GUID e9a42b02...) — CPU/GPU luôn sẵn sàng, giảm latency do power-state transition." "Safe" ($FARM_GAME+$WORK) {
		& powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
		$ultimate = (& powercfg /list 2>$null | Select-String "Ultimate Performance" | Select-Object -First 1).ToString()
		if ($ultimate -match '([0-9a-f]{8}-[0-9a-f-]+)') { & powercfg /setactive $Matches[1] 2>$null | Out-Null }
	} { & powercfg /setactive SCHEME_BALANCED 2>$null | Out-Null } { return ((& powercfg /getactivescheme 2>$null) -match 'Ultimate') } "powercfg Ultimate Performance"
	Add-Reg "GAM02" "Tắt Game DVR / Background Recording (giảm stutter & FPS drop)" $GAM "Game DVR ghi hình nền ăn GPU/CPU và gây frame-time spike. GameDVR_Enabled=0 trong GameConfigStore." "Safe" ($GAME+$WORK+$STD) "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 1
	Add-Cmd "GAM03" "Tắt Game Bar panel/tips khi mở game (GIỮ nguyên Game Mode)" $GAM "ShowStartupPanel=0: Game Bar không tự bật panel/tip khi vào game (bớt hook/overlay phá nhịp Alt-Tab), nhưng AllowAutoGameMode=1 + AutoGameModeEnabled=1 để Game Mode vẫn tự kích hoạt." "Safe" ($GAME+$STD) {
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type "DWord"
	} {
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 1 -Type "DWord"
	} { return ((Get-SophiaRegValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel") -eq 0) } "GameBar ShowStartupPanel=0 (Game Mode kept ON)"
	Add-Reg "GAM04" "Tắt Fullscreen Optimizations toàn cục" $GAM "FSO gây input lag/stutter trên nhiều game DX11. Disable GameDVR_FSEBehaviorMode=2 cho cảm giác 'exclusive fullscreen' thật." "Moderate" $GAME "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2 0
	Add-Cmd "GAM05" "Mouse 1:1 — Tắt Enhance Pointer Precision (gia tốc chuột)" $GAM "Tắt mouse acceleration để aim 1:1 trong FPS. MouseSpeed=0, MouseThreshold1=0, MouseThreshold2=0 (bộ 3 chuẩn esports — thiếu 1 giá trị là Windows vẫn cộng gia tốc)." "Safe" $GAME {
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Type "String"
	} {
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10" -Type "String"
	} { return ((Get-SophiaRegValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed") -eq "0") } "MouseSpeed/Threshold1/Threshold2 = 0/0/0"
	Add-Cmd "GAM06" "Keyboard response nhanh (KeyboardDelay=0, KeyboardSpeed=31)" $GAM "Giảm độ trễ phím: delay trước khi lặp phím = 0 (ngắn nhất), tốc độ lặp = 31 (tối đa) — phản hồi nhanh cho game/gõ phím." "Safe" ($GAME+$LOW) {
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Type "String"
	} {
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "1" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Type "String"
	} { return ((Get-SophiaRegValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay") -eq "0") } "KeyboardDelay=0, KeyboardSpeed=31"
	Add-Reg "GAM07" "SystemResponsiveness = 0 (ưu tiên game hơn background)" $GAM "Mặc định Windows giữ 20% CPU cho background. Đặt 0 -> game/foreground nhận tối đa tài nguyên multimedia scheduler." "Moderate" $FARM_GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 20
	Add-Reg "GAM08" "NetworkThrottlingIndex = OFF (không bóp băng thông game)" $GAM "Windows throttle mạng non-multimedia 10pps mặc định. Đặt 0xffffffff để game/voice không bị bóp gói tin." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295 10
	Add-Reg "GAM09" "GPU Priority = 8 cho class 'Games' (MMCSS)" $GAM "GPU Priority=8 cho profile Games của MMCSS (đi cặp EXT16 SchedulingCategory=High và EXT74 Priority=6)." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8 0
	Add-Reg "GAM10" "Tắt Power Throttling (không giảm xung khi chơi game/treo)" $GAM "PowerThrottlingOff=1 ngăn Windows hạ xung CPU cho process 'eco' — giữ FPS & instance ổn định khi load dài." "Moderate" $ALL_PERF "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 0
	Add-Reg "GAM11" "Visual Effects = Performance (tắt animation/shadow)" $GAM "VisualFXSetting=2 (preset 'Adjust for best performance' của Windows): giảm DWM overhead, Alt-Tab nhanh, nhường GPU cho game/giả lập." "Safe" ($GAME+$LOW) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 0
	Add-Reg "GAM12" "MenuShowDelay = 0 & tăng tốc UI (không chờ menu)" $GAM "Menu mở tức thì, giảm cảm giác 'khựng' khi thao tác — tweak kinh điển của Sophia cho Explorer/Desktop." "Safe" ($GAME+$LOW+$STD) "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "400" "String"

	# ═══════════════ 3. CPU / KERNEL / TIMER ═══════════════
	Add-Cmd "CPU01" "BCD Latency: disabledynamictick + tắt HPET/platform tick ép buộc" $CPU "Dynamic tick + ép HPET gây DPC latency. Xóa useplatformclock/useplatformtick, bật disabledynamictick=yes (khôi phục bằng Restore)." "Extreme" $GAME {
		& bcdedit /deletevalue useplatformclock 2>$null | Out-Null; & bcdedit /deletevalue useplatformtick 2>$null | Out-Null; & bcdedit /set disabledynamictick yes 2>$null | Out-Null
	} {
		& bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
	} { try { return ((& bcdedit /enum '{current}' 2>$null) -match 'disabledynamictick\s+Yes') } catch { return $false } } "bcdedit disabledynamictick"
	Add-Cmd "CPU02" "Tắt Core Parking (100% core luôn sẵn sàng)" $CPU "Core parking đưa lõi ngủ gây latency khi burst load (mở instance, combat game). Đặt CPMINCORES=100% qua powercfg." "Moderate" $ALL_PERF {
		& powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null; & powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMAXCORES 100 2>$null | Out-Null; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		& powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 0 2>$null | Out-Null; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} { return $false } "powercfg CPMINCORES/CPMAXCORES 100"
	Add-Cmd "CPU03" "CPU Min/Max State = 100% trên AC (không hạ xung)" $CPU "PROCTHROTTLEMIN/MAX=100% khi cắm điện: CPU luôn ở xung cao, loại bỏ latency do P-state transition khi treo/game." "Moderate" $FARM_GAME {
		& powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 2>$null | Out-Null; & powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>$null | Out-Null; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		& powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} { return $false } "powercfg PROCTHROTTLE 100%"
	Add-Reg "CPU04" "Tắt Spectre/Meltdown Mitigations (hiệu năng CPU tối đa)" $CPU "FeatureSettingsOverride=3 vô hiệu mitigations phần cứng — tăng IPC rõ trên CPU cũ nhưng GIẢM bảo mật. Chỉ GodMode/máy farm-game chuyên dụng." "Extreme" @() "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" 3 $null
	Add-Reg "CPU05" "DisablePagingExecutive = 1 (giữ kernel trong RAM)" $CPU "Không page-out kernel/drivers ra đĩa — giảm DPC latency, phản hồi hệ thống nhanh hơn khi RAM >=16GB." "Moderate" $ALL_PERF "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1 0
	Add-Reg "CPU06" "IRQ Priority cho CMOS/RTC Timer (TimerResolution ưu tiên)" $CPU "Tăng IRQ8Priority=1 cho realtime clock — tweak latency cổ điển, hỗ trợ timer resolution ổn định cho game/DAW." "Moderate" $GAME "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ8Priority" 1 $null
	Add-Reg "CPU07" "ForegroundLockTimeout = 0 (focus cửa sổ tức thì)" $CPU "Ứng dụng mới focus ngay không bị Windows giữ foreground lock 200s — Alt-Tab giữa các instance/game mượt hơn." "Safe" ($FARM_GAME+$STD) "HKCU:\Control Panel\Desktop" "ForegroundLockTimeout" 0 200000
	Add-Cmd "CPU08" "Energy Performance Preference = 0 (CPU thiên hiệu năng tuyệt đối)" $CPU "PERFEPP=0 qua powercfg: bộ điều tốc CPU (HWP/Intel Speed Shift, AMD CPPC) luôn chọn hiệu năng thay vì tiết kiệm điện — giảm latency tăng xung khi burst." "Moderate" $ALL_PERF {
		Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "36687f9e-e3a5-4dbf-b1dc-15eb381c6863" 0; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "36687f9e-e3a5-4dbf-b1dc-15eb381c6863" 33; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} { return $false } "powercfg PERFEPP=0"
	Add-Reg "CPU09" "LargeSystemCache = 0 (ưu tiên app/game hơn file cache)" $CPU "Đặt cache hệ thống ưu tiên tiến trình người dùng thay vì file-server cache — đúng profile desktop/gaming." "Safe" $ALL_PERF "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 0 1
	Add-Cmd "CPU10" "Tắt Page Combining (MMAgent) — đổi RAM lấy CPU cho farm lớn" $CPU "Page Combining quét tìm các trang RAM giống hệt nhau để gộp — rất tốn CPU khi chạy hàng chục instance giả lập giống nhau. Máy RAM >= 32GB tắt đi sẽ giảm CPU nền rõ rệt (tốn thêm RAM). Máy RAM ít TUYỆT ĐỐI không tick — Smart Advisor chỉ tự thêm khi RAM >= 32GB." "Moderate" @() {
		try { Disable-MMAgent -PageCombining -ErrorAction SilentlyContinue } catch {}
	} { try { Enable-MMAgent -PageCombining -ErrorAction SilentlyContinue } catch {} } { try { return (-not (Get-MMAgent -ErrorAction SilentlyContinue).PageCombining) } catch { return $false } } "Disable-MMAgent -PageCombining"

	# ═══════════════ 4. RAM & MEMORY ═══════════════
	Add-Cmd "RAM01" "Tắt Memory Compression (giải phóng CPU, farm nhiều instance)" $RAM "Memory Compression nén page trong RAM ăn CPU liên tục. Máy >=16GB tắt đi giảm CPU & latency (Enable-MMAgent -MemoryCompression off)." "Moderate" ($FARM+$WORK) {
		try { Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue } catch {}
	} { try { Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue } catch {} } { try { return (-not (Get-MMAgent -ErrorAction SilentlyContinue).MemoryCompression) } catch { return $false } } "Disable-MMAgent -MemoryCompression"
	Add-Cmd "RAM02" "Tắt SysMain (Superfetch) — chống disk/CPU spike" $RAM "SysMain preload app gây disk 100% & RAM spike ngẫu nhiên trên máy farm/game. Disable service + registry Start=4." "Moderate" ($FARM_GAME+$LOW) {
		Stop-Service SysMain -Force -ErrorAction SilentlyContinue; Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue
		Set-SophiaRegValue "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" "Start" 4 "DWord"
	} {
		Set-Service SysMain -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service SysMain -ErrorAction SilentlyContinue
		Set-SophiaRegValue "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" "Start" 2 "DWord"
	} { try { return ((Get-Service SysMain -ErrorAction SilentlyContinue).StartType -eq 'Disabled') } catch { return $false } } "SysMain Disabled"
	Add-Reg "RAM03" "Tắt NDU (Network Data Usage) — sửa leak RAM nonpaged pool" $RAM "NDU driver gây phình Nonpaged Pool theo thời gian (máy treo 24/7 hay gặp). Start=4 khắc phục leak kinh điển." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\Ndu" "Start" 4 2
	Add-Reg "RAM04" "ClearPageFileAtShutdown = 0 (shutdown/restart NHANH)" $RAM "Không xóa pagefile khi tắt máy (mặc định đã 0; ép 0 để restart farm nhanh, tránh chờ ghi đè hàng chục GB)." "Safe" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0 0
	Add-Reg "RAM05" "SessionPoolSize = 20MB (ổn định session đồ họa đa instance)" $RAM "Tăng Session Pool cho nhiều phiên đồ họa đồng thời — giảm lỗi driver/session khi mở nhiều giả lập." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "SessionPoolSize" 20 4
	Add-Reg "RAM06" "PoolUsageMaximum = 60 (cảnh báo pool sớm, chống cạn pool)" $RAM "Đặt ngưỡng trim pool ở 60% để Memory Manager chủ động thu hồi trước khi cạn Nonpaged Pool gây treo máy." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PoolUsageMaximum" 60 $null
	Add-Cmd "RAM07" "Tối ưu Prefetch = Application Launch only (PrefetchParameters=2)" $RAM "Chỉ prefetch khi launch app, tắt boot-trace thừa: giảm I/O nền mà vẫn mở giả lập/game nhanh." "Safe" ($LOW+$FARM) {
		Set-SophiaRegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 2 "DWord"
	} {
		Set-SophiaRegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3 "DWord"
	} { return ((Get-SophiaRegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher") -eq 2) } "EnablePrefetcher=2"
	Add-Cmd "RAM08" "Giảm RAM cho Windows Defender khi farm (Scan AvgCPULoadFactor=10)" $RAM "Giới hạn CPU scan định kỳ của Defender xuống 10% + tắt SampleSubmission — quét nền không giật instance/game." "Moderate" ($FARM+$LOW) {
		try { Set-MpPreference -ScanAvgCPULoadFactor 10 -ErrorAction SilentlyContinue; Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue } catch {}
	} { try { Set-MpPreference -ScanAvgCPULoadFactor 50 -ErrorAction SilentlyContinue } catch {} } { return $false } "Set-MpPreference ScanAvgCPULoadFactor"
	Add-Reg "RAM09" "PagedPoolSize = 0xFFFFFFFF (tối đa hóa paged pool)" $RAM "Cho phép Memory Manager dùng paged pool linh hoạt tối đa — ổn định khi hàng chục instance + driver đồ họa chạy dài ngày." "Extreme" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagedPoolSize" 4294967295 0
	Add-Reg "RAM10" "NonPagedPoolSize = 0 (tự động theo RAM vật lý)" $RAM "Để Windows tự tính NonPaged Pool theo RAM (tránh giới hạn cứng cũ gây cạn pool trên máy RAM lớn treo farm)." "Safe" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "NonPagedPoolSize" 0 $null

	# ═══════════════ 5. GPU & DISPLAY ═══════════════
	Add-Reg "GPU01" "Bật Hardware-Accelerated GPU Scheduling (HAGS)" $GPU "HwSchMode=2: GPU tự lập lịch VRAM — giảm latency & CPU overhead (cần restart). Chuẩn Sophia GPUScheduling." "Moderate" ($GAME+$WORK) "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 1
	Add-Reg "GPU02" "Tắt Multi-Plane Overlay (MPO) — sửa stutter/đen màn Alt-Tab" $GPU "OverlayTestMode=5 vô hiệu MPO: khắc phục giật/nhấp nháy khi stream, Alt-Tab game & đa cửa sổ giả lập." "Moderate" $ALL_PERF "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5 $null
	Add-Reg "GPU03" "TdrDelay = 10s (GPU driver không bị kill khi load nặng)" $GPU "Tăng timeout TDR để render/farm nặng không bị 'Display driver stopped responding' reset giữa chừng." "Moderate" ($FARM+$WORK) "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDelay" 10 2
	Add-Reg "GPU04" "TdrDdiDelay = 20s (ổn định encode/render dài)" $GPU "Tăng DDI timeout đồng bộ với TdrDelay cho OBS/render/GPU-compute chạy dài không timeout." "Moderate" $WORK "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDdiDelay" 20 5
	Add-Reg "GPU05" "Tắt GPU Power Saving (DisableDynamicPstate=1 cho NVIDIA)" $GPU "Ngăn GPU hạ xung khi tải nhẹ-thất thường gây FPS drop (áp dụng nếu tìm thấy class NVIDIA 3D). An toàn bỏ qua nếu không có." "Extreme" $GAME "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "DisableDynamicPstate" 1 0
	Add-Reg "GPU06" "EnableChildCompletion (giảm DWM composition latency)" $GPU "Tối ưu đường trình bày DWM cho đa cửa sổ — Alt-Tab & kéo thả instance mượt hơn." "Safe" $ALL_PERF "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "EnableChildCompletion" 1 $null
	Add-Reg "GPU07" "Tắt Transparency & Acrylic (giải phóng GPU cho game)" $GPU "EnableTransparency=0: bớt hiệu ứng kính mờ ăn GPU/compositor, nhất là máy yếu & farm nhiều cửa sổ." "Safe" ($LOW+$GAME) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 1
	Add-Reg "GPU08" "ForceEffectMode = Performance cho DWM Animation" $GPU "Giảm animation DWM ở mức hệ thống — cửa sổ mở/đóng tức thì, giảm frame compositor thừa." "Safe" $LOW "HKCU:\Software\Microsoft\Windows\Dwm" "EnableAeroPeek" 0 1
	Add-Reg "GPU09" "Ưu tiên GPU cho giả lập (GraphicsPreferences qua registry mẫu)" $GPU "Đặt GpuPreference=2 (High Performance) cho các exe giả lập phổ biến nếu tồn tại trên máy." "Moderate" $FARM "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" "C:\Program Files\BlueStacks_nxt\HD-Player.exe" "GpuPreference=2;" $null "String"
	Add-Reg "GPU10" "Tắt Windowed Game Bar Overlay trên desktop" $GPU "Không overlay Game Bar cho app cửa sổ thường — giảm hook trình bày không cần thiết khi treo farm." "Safe" $FARM "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0 1

	# ═══════════════ 6. NETWORK ═══════════════
	Add-Cmd "NET01" "Tắt Nagle Algorithm mọi NIC (TcpNoDelay + AckFrequency=1)" $NET "Nagle gom gói gây delay 40-200ms. Đặt TcpNoDelay=1, TCPackFrequency=1, TcpDelAckTicks=0 trên mọi interface có Tcpip GUID." "Moderate" $GAME {
		$base = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
		if (Test-Path $base) { Get-ChildItem $base | ForEach-Object { Set-SophiaRegValue $_.PSPath "TcpNoDelay" 1 "DWord"; Set-SophiaRegValue $_.PSPath "TCPackFrequency" 1 "DWord"; Set-SophiaRegValue $_.PSPath "TcpDelAckTicks" 0 "DWord" } }
	} {
		$base = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
		if (Test-Path $base) { Get-ChildItem $base | ForEach-Object { Remove-ItemProperty $_.PSPath -Name TcpNoDelay,TCPackFrequency,TcpDelAckTicks -Force -ErrorAction SilentlyContinue } }
	} { return $false } "Interfaces\* TcpNoDelay/TCPackFrequency"
	Add-Cmd "NET02" "netsh Tuning: autotuning=normal, RSS=on, ECN off, timestamps off" $NET "Bộ tuning cân bằng latency/throughput cho game + farm: bật RSS đa lõi, tắt heuristics cũ gây throttle." "Moderate" $ALL_PERF {
		& netsh interface tcp set global autotuninglevel=normal 2>$null | Out-Null; & netsh interface tcp set global rss=enabled 2>$null | Out-Null; & netsh interface tcp set global ecncapability=disabled 2>$null | Out-Null; & netsh interface tcp set global timestamps=disabled 2>$null | Out-Null; & netsh interface tcp set heuristics disabled 2>$null | Out-Null
	} {
		& netsh interface tcp set global autotuninglevel=normal 2>$null | Out-Null; & netsh interface tcp set heuristics enabled 2>$null | Out-Null
	} { return $false } "netsh tcp global"
	Add-Reg "NET03" "QoS: NonBestEffortLimit = 0 (mở khóa 20% băng thông dự trữ)" $NET "Lưu ý trung thực: Windows chỉ dành băng thông khi ứng dụng QoS thật sự đặt chỗ (không phải luôn mất 20%). NonBestEffortLimit=0 bỏ trần giới hạn cho các phiên QoS đó — vô hại và giúp stack nhất quán." "Safe" $GAME "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0 $null
	Add-Cmd "NET04" "DNS Cloudflare 1.1.1.1 / Google 8.8.8.8 cho mọi NIC up" $NET "DNS nhanh & ổn định giảm độ trễ phân giải khi mở game/launcher/giả lập (chỉ đặt trên adapter đang Up)." "Safe" ($GAME+$LOW) {
		try { Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -ErrorAction SilentlyContinue } } catch {}
	} { try { Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue } } catch {} } { return $false } "Set-DnsClientServerAddress 1.1.1.1"
	Add-Cmd "NET05" "Tắt Power Saving mọi Network Adapter (NetworkAdaptersSavePower)" $NET "NIC ngủ gây mất gói/delay khi treo farm & ping spike game. Tắt AllowComputerToTurnOff qua registry PnPCapabilities=24." "Moderate" $FARM_GAME {
		$class = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
		if (Test-Path $class) { Get-ChildItem $class -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { if (Get-ItemProperty $_.PSPath -Name DriverDesc -ErrorAction SilentlyContinue) { Set-SophiaRegValue $_.PSPath "PnPCapabilities" 24 "DWord" } } }
	} {
		$class = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
		if (Test-Path $class) { Get-ChildItem $class -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { Remove-ItemProperty $_.PSPath -Name PnPCapabilities -Force -ErrorAction SilentlyContinue } }
	} { return $false } "PnPCapabilities=24 all NICs"
	Add-Reg "NET06" "TcpAckFrequency mặc định hệ thống (Parameters)" $NET "Đặt tham số TCP toàn cục hỗ trợ low-latency stack (Tcp1323Opts=1 bật Window Scaling/RFC1323)." "Safe" $GAME "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "Tcp1323Opts" 1 0
	Add-Reg "NET07" "DefaultTTL = 64 (chuẩn hóa TTL gói tin)" $NET "TTL 64 giảm nguy cơ bị middlebox/ISP xử lý bất thường với gói game/voice." "Safe" $GAME "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 64 128
	Add-Reg "NET08" "MaxUserPort = 65534 (mở rộng ephemeral port cho multi-instance)" $NET "Nhiều instance + launcher dễ cạn ephemeral port gây lỗi connect. Mở MaxUserPort tối đa." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxUserPort" 65534 5000
	Add-Reg "NET09" "TcpTimedWaitDelay = 30 (giải phóng port chờ nhanh)" $NET "Giảm TIME_WAIT từ 240s xuống 30s — server/launcher mở-đóng kết nối liên tục không bị kẹt port." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" 30 240
	Add-Cmd "NET10" "Flush DNS + Clear ARP Cache (làm sạch sau khi đổi DNS)" $NET "Xóa cache DNS/ARP cũ để áp dụng DNS mới ngay, sửa lỗi vào game/launcher chập chờn." "Safe" ($GAME+$LOW+$STD) {
		& ipconfig /flushdns 2>$null | Out-Null; & arp -d * 2>$null | Out-Null
	} { return } { return $false } "ipconfig /flushdns"

	# ═══════════════ 7. SYSTEM / SERVICES / DEBLOAT ═══════════════
	Add-Cmd "SYS01" "Tắt services thừa: DiagTrack, dmwappushservice, Fax, RetailDemo..." $SYS "Bộ service telemetry/demo không cần cho farm/game — đặt Disabled giảm tiến trình nền & ghi đĩa." "Moderate" ($FARM_GAME+$LOW) {
		@("DiagTrack","dmwappushservice","Fax","RetailDemo","RemoteRegistry","MapsBroker","lfsvc","XblGameSave","XboxNetApiSvc") | ForEach-Object { Stop-Service $_ -Force -ErrorAction SilentlyContinue; Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue }
	} {
		@("DiagTrack","dmwappushservice","MapsBroker") | ForEach-Object { Set-Service $_ -StartupType Manual -ErrorAction SilentlyContinue }
	} { try { return ((Get-Service DiagTrack -ErrorAction SilentlyContinue).StartType -eq 'Disabled') } catch { return $false } } "Disable telemetry/demo services"
	Add-Cmd "SYS02" "Tắt Scheduled Tasks telemetry/quảng cáo (CEIP, Application Experience)" $SYS "Disable task thu thập dữ liệu & compatibility appraisal chạy nền định kỳ gây CPU/disk spike." "Moderate" ($FARM_GAME+$LOW+$STD) {
		@("\Microsoft\Windows\Customer Experience Improvement Program\Consolidator","\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser","\Microsoft\Windows\Application Experience\ProgramDataUpdater") | ForEach-Object { Disable-ScheduledTask -TaskName (Split-Path $_ -Leaf) -TaskPath ((Split-Path $_) + "\") -ErrorAction SilentlyContinue | Out-Null }
	} { return } { return $false } "Disable-ScheduledTask CEIP/Appraiser"
	Add-Reg "SYS03" "Tắt Background Apps toàn cục (BackgroundAccessApplications)" $SYS "Ứng dụng UWP chạy nền ăn RAM/pin/mạng. GlobalUserDisabled=1 — app foreground & giả lập không bị ảnh hưởng." "Safe" ($LOW+$FARM) "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 0
	Add-Reg "SYS04" "Fast Startup = OFF (khởi động sạch, tránh lỗi driver giả lập)" $SYS "HiberbootEnabled=0: shutdown là tắt thật — tránh driver VT-x/GPU kẹt trạng thái sau 'shutdown' lai." "Safe" $FARM_GAME "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0 1
	Add-Reg "SYS05" "Hiện đuôi file + file ẩn (chuẩn Explorer)" $SYS "HideFileExt=0, Hidden=1 — quản lý file instance/config dễ dàng, tránh nhầm file độc hại đội lốt." "Safe" $STD "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 1
	Add-Reg "SYS06" "Tắt Windows Error Reporting (WerSvc queue)" $SYS "Disabled=1 cho Error Reporting: crash app không treo chờ gửi báo cáo, restart instance nhanh hơn." "Safe" ($FARM+$LOW) "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1 0
	Add-Reg "SYS07" "Long Paths Enabled (bỏ giới hạn 260 ký tự)" $SYS "LongPathsEnabled=1 cho toolchain/giả lập có path sâu (Android SDK, cache instance) không lỗi path." "Safe" ($WORK+$FARM) "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1 0
	Add-Cmd "SYS08" "Dọn Temp & Windows Update Cache (giải phóng ổ C an toàn)" $SYS "Xóa %TEMP%, C:\Windows\Temp, SoftwareDistribution\Download — thường giải phóng 2-20GB cho ổ farm/game chật." "Safe" ($LOW+$FARM) {
		@($env:TEMP, "$env:SystemRoot\Temp", "$env:SystemRoot\SoftwareDistribution\Download") | ForEach-Object { if (Test-Path $_) { Get-ChildItem $_ -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
	} { return } { return $false } "Clean TEMP/Update cache"
	Add-Reg "SYS09" "Game Mode Policy cho máy yếu: AutoGameMode mặc định hệ thống" $SYS "Giữ cấu hình cân bằng cho LowSpec (không ép Ultimate gây nóng) — chỉ áp qua mode LowSpec bằng VisualFX & services." "Safe" $LOW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 $null
	Add-Reg "SYS10" "Tắt Storage Sense tự xóa file (bảo vệ data farm)" $SYS "Storage Sense có thể tự xóa Downloads/cache khi ổ đầy giữa lúc treo. Tắt để không mất data ngoài ý muốn." "Safe" $FARM "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 0 1
	Add-Cmd "SYS11" "Đặt Time Service đồng bộ & High-Res (tránh lệch giờ cert game)" $SYS "W32Time Automatic + resync: lệch giờ gây lỗi đăng nhập/cert HTTPS của launcher & giả lập treo lâu ngày." "Safe" $FARM {
		Set-Service w32time -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service w32time -ErrorAction SilentlyContinue; & w32tm /resync /force 2>$null | Out-Null
	} { return } { return $false } "w32time resync"
	Add-Reg "SYS12" "Verbose Status khi logon (hiện rõ bước khởi động)" $SYS "VerboseStatus=1 chuẩn MOLIK WINLIK: màn hình đăng nhập hiện chi tiết — dễ chẩn đoán treo ở bước nào khi farm restart." "Safe" $STD "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "VerboseStatus" 1 0

	# ═══════════════ 8. PRIVACY (MOLIK WINLIK NATIVE) ═══════════════
	Add-Reg "PRI01" "Telemetry = 0 (AllowTelemetry, chuẩn GPO)" $PRI "Chặn thu thập dữ liệu chẩn đoán mức cơ bản qua Policy — giảm tiến trình DiagTrack ghi đĩa nền." "Safe" ($STD+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 3
	Add-Reg "PRI02" "Tắt Advertising ID (quảng cáo cá nhân hóa)" $PRI "DisabledByGroupPolicy=1: app không dùng ID quảng cáo theo dõi hành vi." "Safe" $STD "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1 0
	Add-Cmd "PRI03" "Tắt Activity History / Timeline thu thập" $PRI "EnableActivityFeed=0 + PublishUserActivities=0 + UploadUserActivities=0: Windows không ghi/tải dòng thời gian hoạt động (Timeline) — bớt ghi đĩa và telemetry nền." "Safe" $STD {
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type "DWord"
	} {
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 1 -Type "DWord"
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 1 -Type "DWord"
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 1 -Type "DWord"
	} { return ((Get-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed") -eq 0) } "ActivityFeed/Publish/Upload = 0"
	Add-Reg "PRI04" "Tắt Location Tracking toàn cục" $PRI "SensorPermissionState=0: không app nào truy cập vị trí nền (trừ khi user bật lại)." "Safe" $STD "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "Value" "Deny" "Allow" "String"
	Add-Reg "PRI05" "Tắt Cortana (AllowCortana=0 qua Policy)" $PRI "Cortana nền ăn RAM/index — tắt qua GPO chuẩn MOLIK WINLIK cho cả farm/game/workstation." "Safe" ($STD+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0 1
	Add-Reg "PRI06" "Tắt Windows Copilot (TurnOffWindowsCopilot=1)" $PRI "Copilot sidebar/overlay không cần cho farm/game — tắt qua policy, giảm tiến trình WebView nền." "Safe" $STD "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1 0
	Add-Reg "PRI07" "Tắt Windows Recall (DisableAIDataAnalysis, Win11 AI)" $PRI "Recall chụp màn hình định kỳ ăn disk/GPU & rủi ro riêng tư — tắt trên Windows 11 nếu có." "Safe" $STD "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1 0
	Add-Cmd "PRI08" "Tắt Tailored Experiences & Content Delivery (gợi ý quảng cáo)" $PRI "TailoredExperiencesWithDiagnosticDataEnabled=0 và ContentDeliveryManager (ContentDeliveryAllowed/SilentInstalledApps/PreInstalledApps/OemPreInstalledApps = 0): Start Menu không tải/cài app quảng cáo trong nền." "Safe" ($STD+$LOW) {
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Value 0 -Type "DWord"
	} {
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 1 -Type "DWord"
		Set-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value 1 -Type "DWord"
		Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled","PreInstalledAppsEnabled","OemPreInstalledAppsEnabled" -Force -ErrorAction SilentlyContinue
	} { return ((Get-SophiaRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled") -eq 0) } "Tailored + ContentDeliveryManager off"
	Add-Reg "PRI09" "Tắt Inking/Typing personalization (gửi dữ liệu gõ phím)" $PRI "RestrictImplicitTextCollection=1: không thu thập mẫu gõ/viết tay gửi Microsoft." "Safe" $STD "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1 0
	Add-Reg "PRI10" "Tắt Delivery Optimization P2P upload (tiết kiệm băng thông farm)" $PRI "DownloadMode=0 (HTTP only, no peering): Windows Update không dùng máy bạn upload cho máy khác ngốn upstream." "Moderate" ($FARM+$STD) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0 1

	# ═══════════════ 9. EXTREME LAB ═══════════════
	Add-Cmd "EXT01" "MSI Mode cho GPU + NVMe + NIC (Message Signaled Interrupts)" $EXT "Chuyển thiết bị từ legacy IRQ dùng chung sang MSI/MSI-X riêng: giảm DPC latency & xung đột ngắt — một trong những tweak latency thật hiệu quả nhất. Cần RESTART." "Extreme" ($GAME+$WORK) {
		Enable-SophiaMsiMode | Out-Null
	} { Disable-SophiaMsiMode } { return (Test-SophiaMsiMode) } "Enum\PCI\...\MessageSignaledInterruptProperties MSISupported=1"
	Add-Cmd "EXT02" "Timer Resolution Daemon 0.5ms TOÀN HỆ THỐNG (NtSetTimerResolution)" $EXT "Tiến trình nền giữ timer Windows ở 0.5ms (5000x100ns) 24/7: mọi game/giả lập đều hưởng frame-pacing & sleep chính xác mà không cần tự request. Task tự chạy khi logon." "Extreme" $FARM_GAME {
		Start-MolikTimerDaemon
	} { Stop-MolikTimerDaemon } { return [bool](Get-ScheduledTask -TaskName "MOLIK_WINLIK_Timer" -TaskPath "\MOLIK_WINLIK\" -ErrorAction SilentlyContinue) } "ScheduledTask MOLIK_WINLIK_Timer"
	Add-Cmd "EXT03" "Process Booster Task mỗi 5 phút (Priority + Affinity TRÁNH Core 0)" $EXT "Task SYSTEM tự nâng AboveNormal + ghim affinity tránh Core 0 (nơi Windows dồn DPC/ngắt) cho mọi instance giả lập mới mở — treo farm cả tuần không cần boost tay." "Moderate" $FARM {
		Register-SophiaProcessBoosterTask
	} { Unregister-SophiaProcessBoosterTask } { return [bool](Get-ScheduledTask -TaskName "MOLIK_WINLIK_Booster" -TaskPath "\MOLIK_WINLIK\" -ErrorAction SilentlyContinue) } "ScheduledTask MOLIK_WINLIK_Booster"
	Add-Cmd "EXT04" "IFEO CpuPriorityClass = High VĨNH VIỄN cho exe giả lập" $EXT "Ghi PerfOptions vào Image File Execution Options: mỗi lần dnplayer/HD-Player/Nox/MuMu... khởi động đều tự chạy ở High priority, kể cả khi mở bằng launcher." "Moderate" $FARM_GAME {
		Set-SophiaExeCpuPriority
	} { Set-SophiaExeCpuPriority -Remove } { return (Test-SophiaExeCpuPriority) } "IFEO\<exe>\PerfOptions CpuPriorityClass=3"
	Add-Cmd "EXT05" "GPU Preference = High Performance cho exe giả lập ĐÃ PHÁT HIỆN" $EXT "Ép Windows Graphics dùng GPU mạnh (dGPU) cho từng exe giả lập tìm thấy trên máy — tránh instance chạy nhầm iGPU yếu gây FPS thảm." "Moderate" $FARM {
		Set-SophiaExeGpuPreference
	} { Set-SophiaExeGpuPreference -Remove } { return $false } "UserGpuPreferences GpuPreference=2"
	Add-Cmd "EXT06" "Tắt Fullscreen Optimizations RIÊNG cho exe giả lập/game đã phát hiện" $EXT "AppCompatFlags Layers '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' theo từng exe: fullscreen thật, giảm input lag & stutter Alt-Tab cho BlueStacks/LDPlayer..." "Moderate" $FARM_GAME {
		Set-SophiaExeDisableFSO
	} { Set-SophiaExeDisableFSO -Remove } { return $false } "AppCompatFlags\Layers DISABLEDXMAXIMIZEDWINDOWEDMODE"
	Add-Cmd "EXT07" "Power Profile CỰC HẠN (Ultimate + 10 tinh chỉnh powercfg ẩn)" $EXT "Kích hoạt Ultimate Performance rồi ép: throttle 100/100, unpark 100%, PerfBoost Aggressive, tản nhiệt Active, PERFEPP 0, disk không ngủ, PCIe ASPM off, không standby." "Moderate" $ALL_PERF {
		Import-SophiaUltimatePowerProfile
	} { & powercfg /setactive SCHEME_BALANCED 2>$null | Out-Null } { return ((& powercfg /getactivescheme 2>$null) -match 'Ultimate') } "powercfg Ultimate + GUID tuning"
	Add-Cmd "EXT08" "Vô hiệu CPU Idle States trên AC (IDLEDISABLE=1)" $EXT "Cấm C-state idle khi cắm điện: lõi CPU không bao giờ 'ngủ' — wake latency ~0 cho burst game/farm, đánh đổi điện & nhiệt cao hơn. Chỉ máy bàn/farm cắm điện 24/7." "Extreme" $GAME {
		Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "5d76a2ca-e8c0-402f-a133-2158492d58ad" 1; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "5d76a2ca-e8c0-402f-a133-2158492d58ad" 0; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} { return $false } "powercfg IDLEDISABLE=1"
	Add-Cmd "EXT09" "Tắt Power Management: USB Hubs + NIC ở mức driver (PnPCapabilities)" $EXT "Áp PnPCapabilities=24 xuống từng thiết bị USB Hub & NIC trong Device Class registry — Windows không được phép tắt thiết bị để tiết kiệm điện dù ở bất kỳ power plan nào." "Moderate" $FARM {
		Set-SophiaDeviceClassNoPowerOff
	} { Set-SophiaDeviceClassNoPowerOff -Restore } { return $false } "Control\Class\{USB,NIC}\PnPCapabilities=24"
	Add-Cmd "EXT10" "NIC Advanced CỰC HẠN (RSS đa lõi, Interrupt Moderation OFF, LSO OFF, EEE OFF)" $EXT "Đi sâu vào từng card mạng: bật RSS, tắt Interrupt Moderation (giảm delay gói), tắt Large Send Offload & Energy-Efficient Ethernet — ping ổn định, không spike khi farm tải mạng." "Extreme" $FARM_GAME {
		Set-SophiaNetAdapterExtreme
	} { Set-SophiaNetAdapterExtreme -Restore } { return $false } "Set-NetAdapterAdvancedProperty *RSS/*InterruptModeration/*LsoV2"
	Add-Cmd "EXT11" "Storage/NTFS CỰC HẠN (fsutil: LastAccess OFF, 8dot3 OFF, MemoryUsage=2, TRIM ON)" $EXT "Giảm metadata write trên SSD/NVMe khi hàng chục image giả lập I/O liên tục + tăng cache NTFS + đảm bảo TRIM bật. Máy farm chạy tháng không chậm ổ." "Moderate" ($FARM+$WORK) {
		Set-SophiaStorageExtreme
	} { Set-SophiaStorageExtreme -Restore } { return (Test-SophiaStorageExtreme) } "fsutil behavior set"
	Add-Cmd "EXT12" "Tắt AMD ULPS (GPU AMD không ngủ xung khi tải nhẹ)" $EXT "EnableUlps=0 trong driver class AMD: GPU không rơi vào Ultra Low Power State gây stutter/FPS drop thất thường. Tự bỏ qua nếu không dùng AMD." "Extreme" $GAME {
		Set-SophiaAmdUlps
	} { Set-SophiaAmdUlps -Restore } { return $false } "Class\{4d36e968}\EnableUlps=0"
	Add-Cmd "EXT14" "Tắt gói Scheduled Tasks nền mở rộng (Watson, DiskDiag, Power Efficiency...)" $EXT "Vô hiệu các task chẩn đoán/đo đạc chạy nền định kỳ ít người biết: Windows Error Reporting queue, DiskDiagnostic, Power Efficiency Diagnostics, Feedback Siuf..." "Moderate" ($FARM_GAME+$LOW) {
		$tasks = @(
			@{ P = "\Microsoft\Windows\Windows Error Reporting\"; N = "QueueReporting" },
			@{ P = "\Microsoft\Windows\DiskDiagnostic\"; N = "Microsoft-Windows-DiskDiagnosticDataCollector" },
			@{ P = "\Microsoft\Windows\Power Efficiency Diagnostics\"; N = "AnalyzeSystem" },
			@{ P = "\Microsoft\Windows\Feedback\Siuf\"; N = "DmClient" },
			@{ P = "\Microsoft\Windows\Application Experience\"; N = "StartupAppTask" }
		)
		foreach ($t in $tasks) { Disable-ScheduledTask -TaskPath $t.P -TaskName $t.N -ErrorAction SilentlyContinue | Out-Null }
	} {
		$tasks = @(
			@{ P = "\Microsoft\Windows\Windows Error Reporting\"; N = "QueueReporting" },
			@{ P = "\Microsoft\Windows\Feedback\Siuf\"; N = "DmClient" }
		)
		foreach ($t in $tasks) { Enable-ScheduledTask -TaskPath $t.P -TaskName $t.N -ErrorAction SilentlyContinue | Out-Null }
	} { return $false } "Disable-ScheduledTask bundle"
	Add-Cmd "EXT15" "Tắt gói Services ngoại vi (SmartCard, Phone, Wallet, Sensor, Insider...)" $EXT "Disabled các service ngoại vi/telemetry không liên quan farm-game: SCardSvr, PhoneSvc, WalletService, SensorService, wisvc (Insider), MapsBroker... giải phóng RAM & tiến trình nền." "Moderate" ($FARM_GAME+$LOW) {
		@("SCardSvr","ScDeviceEnum","PhoneSvc","WalletService","SensorService","SensrSvc","wisvc","MapsBroker","lfsvc","RetailDemo") | ForEach-Object { Stop-Service $_ -Force -ErrorAction SilentlyContinue; Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue }
	} {
		@("SCardSvr","PhoneSvc","MapsBroker") | ForEach-Object { Set-Service $_ -StartupType Manual -ErrorAction SilentlyContinue }
	} { try { return ((Get-Service SCardSvr -ErrorAction SilentlyContinue).StartType -eq 'Disabled') } catch { return $false } } "Disable peripheral services"
	Add-Reg "EXT16" "MMCSS 'Games': SchedulingCategory = High" $EXT "Hoàn thiện profile Games của Multimedia Scheduler: SchedulingCategory=High đi cùng GPU Priority (GAM09) — luồng game được dispatcher ưu tiên cao nhất." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SchedulingCategory" "High" "Medium" "String"
	Add-Reg "EXT17" "MMCSS NoLazyMode = 1 (scheduler không 'lười' khi có tác vụ multimedia)" $EXT "NoLazyMode ngăn MMCSS trì hoãn nâng priority cho luồng game/audio — phản hồi tức thì ngay từ frame đầu tiên." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NoLazyMode" 1 0
	Add-Reg "EXT18" "Tắt Crash Dump (không ghi memory.dmp khi crash)" $EXT "CrashDumpEnabled=0: khi app/hệ thống crash, Windows không mất thời gian ghi file dump nhiều GB — farm tự restart instance ngay. Đánh đổi: khó debug BSOD." "Extreme" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" "CrashDumpEnabled" 0 3
	Add-Reg "EXT19" "Tắt toàn bộ Animation cửa sổ (MinAnimate = 0)" $EXT "WindowMetrics MinAnimate=0: cửa sổ mở/đóng/maximize không hiệu ứng — 30 instance giả lập thao tác tức thì, giảm tải DWM rõ rệt trên máy yếu." "Safe" ($FARM_GAME+$LOW) "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "1" "String"
	Add-Reg "EXT20" "Tắt Sticky/Filter/Toggle Keys (không popup khi spam Shift)" $EXT "Accessibility Flags chuẩn game thủ: spam Shift/Ctrl khi chơi game không bao giờ bật popup Sticky Keys phá trận." "Safe" $GAME "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "510" "String"
	Add-Cmd "EXT21" "Thu gọn Svchost theo RAM (SvcHostSplitThreshold = tổng RAM KB)" $EXT "Đặt ngưỡng tách svchost bằng đúng RAM vật lý: máy RAM lớn gộp service host hợp lý, giảm hàng chục process svchost.exe tranh RAM/CPU trên farm. Cần RESTART." "Moderate" ($FARM+$WORK) {
		try {
			$totalKB = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
			Set-SophiaRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value $totalKB -Type "DWord"
		} catch {}
	} {
		Set-SophiaRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value 380000 -Type "DWord"
	} { return ((Get-SophiaRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB") -gt 380000) } "SvcHostSplitThresholdInKB = RAM"
	Add-Reg "EXT22" "Spectre/Meltdown: FeatureSettingsOverrideMask = 3 (cặp với CPU04)" $EXT "Hoàn tất vô hiệu mitigations: Override + Mask cùng =3 mới tắt triệt để (CPU04 đặt Override). Mất lớp bảo mật CPU — chỉ God Mode/máy chuyên dụng." "Extreme" @() "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" 3 $null
	Add-Reg "EXT23" "GlobalTimerResolutionRequests = 1 (Win11: timer 0.5ms áp TOÀN CỤC)" $EXT "Từ Win11 22H2, timer request bị giới hạn trong cửa sổ foreground. Registry kernel này khôi phục hành vi áp toàn hệ thống — bắt buộc để EXT02 phát huy tối đa." "Extreme" $GAME "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 1 $null
	Add-Reg "EXT24" "LanmanServer IRPStackSize = 32 (nhiều kết nối đồng thời)" $EXT "Tăng IRP stack cho Server service: farm mở hàng trăm kết nối/launcher/ADB song song không nghẽn stack mạng nội bộ." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 32 15
	Add-Reg "EXT25" "Tắt Game Presence Writer & GameInput nền" $EXT "GameInputService/Presence writer chạy nền theo dõi tay cầm & trạng thái game — tắt ghi nền thừa cho máy farm/chỉ dùng phím chuột." "Safe" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\GameInputSvc" "Start" 4 3

	Add-Reg "EXT26" "Windows Update KHÔNG tự restart khi đang đăng nhập (treo farm an toàn)" $EXT "NoAutoRebootWithLoggedOnUsers=1: update tải xong không bao giờ tự khởi động lại giữa đêm làm chết farm — bạn chủ động restart khi rảnh." "Moderate" $FARM "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1 0
	Add-Cmd "EXT27" "Tắt Scheduled Defrag/Optimize Drives nền" $EXT "Task chống phân mảnh chạy nền định kỳ giành I/O trên máy farm dùng SSD/NVMe (vốn không cần defrag). TRIM vẫn hoạt động bình thường qua EXT11." "Moderate" ($FARM+$LOW) {
		Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue | Out-Null
	} {
		Enable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue | Out-Null
	} { return $false } "Disable-ScheduledTask ScheduledDefrag"
	Add-Reg "EXT28" "Tắt kéo-thả cửa sổ hiện nội dung (DragFullWindows = 0)" $EXT "Kéo/resize 20+ cửa sổ giả lập không phải render lại toàn bộ nội dung theo thời gian thực — thao tác đa cửa sổ nhẹ hẳn trên máy yếu." "Safe" ($FARM+$LOW) "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "1" "String"
	Add-Reg "EXT29" "Tắt Bing Search trong Start Menu (tìm kiếm local thuần)" $EXT "BingSearchEnabled=0: gõ Start chỉ tìm app/file trên máy — nhanh hơn, không gọi web, không gợi ý quảng cáo." "Safe" ($STD+$LOW) "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1 0
	Add-Reg "EXT30" "Tắt Widgets / News & Interests (giảm WebView nền)" $EXT "AllowNewsAndInterests=0 qua Policy: bảng tin thời tiết/widget không tải WebView chạy nền ăn RAM/mạng." "Safe" ($STD+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0 1
	Add-Reg "EXT31" "Tắt Chat/Teams consumer trên Taskbar" $EXT "TaskbarMn=0: ẩn & không nạp Teams cá nhân nền trên Windows 11 — farm/game không cần, tiết kiệm ~100MB RAM." "Safe" ($STD+$LOW+$FARM) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0 1
	Add-Reg "EXT32" "Explorer mở 'This PC' thay Quick Access + ẩn Recent" $EXT "LaunchTo=1: mở Explorer là vào thẳng ổ đĩa quản lý file instance, không tải danh sách gần đây." "Safe" $STD "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 2
	Add-Cmd "EXT33" "Tắt Wake Timers trên AC (không tác nhân nào tự đánh thức máy)" $EXT "RTCWAKE=0 qua powercfg: hết cảnh máy tự thức dậy nửa đêm vì update/task lạ rồi chạy quạt ầm ĩ — kết hợp EXT26 cho farm ngủ yên (khi bạn cho ngủ)." "Moderate" $FARM {
		Set-SophiaPowerSetting "238c9fa8-0aad-41ed-83f4-97be242c8f20" "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" 0; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		Set-SophiaPowerSetting "238c9fa8-0aad-41ed-83f4-97be242c8f20" "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" 1; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} { return $false } "powercfg RTCWAKE=0"

	Add-Reg "EXT34" "Tắt WMI Autologger DiagLog (bớt ghi log chẩn đoán nền)" $EXT "Autologger\DiagLog Start=0: giảm I/O ghi log ETW liên tục của hệ thống chẩn đoán — ổ farm bớt bị làm phiền bởi ghi nền vô hình." "Moderate" ($FARM_GAME+$LOW) "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" "Start" 0 1
	Add-Reg "EXT35" "Tắt WMI Autologger ReadyBoot (boot trace)" $EXT "ReadyBoot trace ghi log mỗi lần khởi động phục vụ ReadyBoost/SysMain — máy SSD/farm không cần, tắt để boot sạch & ít ghi ổ." "Moderate" ($FARM+$LOW) "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" "Start" 0 1
	Add-Cmd "EXT36" "Tắt NetBIOS over TCP/IP mọi interface (giảm broadcast & delay LAN)" $EXT "TcpipNetbiosOptions=2 trên mọi NIC: ngừng broadcast NetBIOS cổ điển trong LAN — mạng farm/game sạch hơn, giảm tấn công giả mạo tên NetBIOS." "Moderate" $FARM_GAME {
		$base = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
		if (Test-Path $base) { Get-ChildItem $base | ForEach-Object { Set-SophiaRegValue $_.PSPath "TcpipNetbiosOptions" 2 "DWord" } }
	} {
		$base = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
		if (Test-Path $base) { Get-ChildItem $base | ForEach-Object { Set-SophiaRegValue $_.PSPath "TcpipNetbiosOptions" 0 "DWord" } }
	} { return $false } "NetBT TcpipNetbiosOptions=2"
	Add-Cmd "EXT37" "TCP Supplemental: CUBIC + template Internet tốc độ cao" $EXT "Ép thuật toán điều khiển tắc nghẽn CUBIC và template supplemental cho kết nối Internet — throughput ổn định hơn cho launcher/update/farm tải dữ liệu lớn." "Moderate" $GAME {
		& netsh interface tcp set supplemental template=internet congestionprovider=cubic 2>$null | Out-Null
		& netsh interface tcp set global initialRto=1000 2>$null | Out-Null
	} {
		& netsh interface tcp set supplemental template=internet congestionprovider=default 2>$null | Out-Null
	} { return $false } "netsh supplemental cubic"
	Add-Cmd "EXT38" "Interrupt Priority = HIGH cho GPU + NVMe (DevicePriority=3)" $EXT "Đi cùng EXT01 MSI Mode: nâng mức ưu tiên ngắt của GPU & controller NVMe trong Interrupt Management — GPU/NVMe được CPU phục vụ ngắt trước thiết bị phụ." "Extreme" $FARM_GAME {
		Set-SophiaInterruptPriority
	} { Set-SophiaInterruptPriority -Restore } { return $false } "Enum\PCI\...\Interrupt Management DevicePriority=3"
	Add-Cmd "EXT39" "Pagefile chuyển sang Ổ TRỐNG NHẤT (thường là NVMe phụ) — cố định lớn" $EXT "Bản cực hạn của EMU06: đặt pagefile cố định RAMx1.5 lên volume trống nhất để ổ hệ thống không bị I/O pagefile tranh với image giả lập. Cần RESTART." "Extreme" $FARM {
		Set-SophiaPagefileFastestDrive
	} { Set-SophiaPagefileFastestDrive -Restore } { return $false } "Win32_PageFileSetting fastest volume"
	Add-Reg "EXT40" "MMCSS 'Pro Audio': SchedulingCategory = High (cho Stream/OBS)" $EXT "Profile Pro Audio của Multimedia Scheduler ở mức High — thu âm/stream/encode audio-video không bị luồng nền chen ngang gây xì/xé tiếng." "Moderate" $WORK "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" "SchedulingCategory" "High" "Medium" "String"
	Add-Cmd "EXT41" "NIC Buffers = 2048/2048 (Receive/Transmit tối đa)" $EXT "Tăng bộ đệm nhận/gửi của card mạng lên tối đa phần cứng cho phép qua Advanced Properties — burst gói tin của nhiều instance/game không bị drop ở tầng driver." "Moderate" $FARM_GAME {
		Set-SophiaNetAdapterBuffers
	} { Set-SophiaNetAdapterBuffers -Restore } { return $false } "Set-NetAdapterAdvancedProperty *ReceiveBuffers/*TransmitBuffers"
	Add-Reg "EXT42" "Ưu tiên IPv4 hơn IPv6 (DisabledComponents = 0x20)" $EXT "Không tắt IPv6 (tránh vỡ kết nối mới) nhưng ưu tiên IPv4 trong prefix policy — launcher/game server IPv4 kết nối nhanh, bớt độ trễ phân giải kép." "Moderate" $GAME "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 32 0
	Add-Cmd "EXT43" "NVIDIA: Ép Power Limit = TỐI ĐA qua nvidia-smi" $EXT "Nếu có nvidia-smi: đặt power limit lên mức max_limit của card — GPU không bị giới hạn điện sớm khi boost dài. Tự bỏ qua nếu không phải NVIDIA." "Extreme" $GAME {
		Set-SophiaNvidiaPowerLimit | Out-Null
	} { Set-SophiaNvidiaPowerLimit -Restore | Out-Null } { return $false } "nvidia-smi -pl max_limit"
	Add-Cmd "EXT44" "Tắt Processor Autonomous Mode (HWP tự trị -> PERFEPP kiểm soát)" $EXT "PERFAUTONOMOUS=0: tắt chế độ CPU tự chọn xung hoàn toàn tự trị để PERFEPP=0 (EXT/CPU08) kiểm soát dứt khoát theo hướng hiệu năng. Cần hiểu rõ CPU của bạn." "Extreme" $GAME {
		Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "8baa4a8a-2c72-4c7e-8035-b6cf9943bda7" 0; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} {
		Set-SophiaPowerSetting "54533251-82be-4824-96c1-47b60b740d00" "8baa4a8a-2c72-4c7e-8035-b6cf9943bda7" 1; & powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
	} { return $false } "powercfg PERFAUTONOMOUS=0"
	Add-Cmd "EXT45" "BCD Boot Menu Policy = Legacy (vào Windows nhanh, F8 truyền thống)" $EXT "bootmenupolicy Legacy: bỏ màn hình boot đồ họa kép, khởi động thẳng & phím F8 khôi phục hoạt động kiểu cũ — farm restart nhanh và dễ cứu hộ." "Safe" $FARM {
		& bcdedit /set '{current}' bootmenupolicy Legacy 2>$null | Out-Null
	} {
		& bcdedit /set '{current}' bootmenupolicy Standard 2>$null | Out-Null
	} { return $false } "bcdedit bootmenupolicy Legacy"
	Add-Cmd "EXT47" "Hiện toàn bộ Power Settings ẩn (Unhide PERF/IDLE/EPP trong Power Options)" $EXT "Attributes=2 cho 7 thiết lập ẩn quan trọng: từ nay bạn tinh chỉnh tay IDLE/PERFBOOST/CPMINCORES... ngay trong Power Options nâng cao mà không cần lệnh." "Safe" $ALL_PERF {
		Unhide-SophiaPowerSettings
	} { Unhide-SophiaPowerSettings -Restore } { return $false } "PowerSettings Attributes=2"
	Add-Cmd "EXT48" "IFEO IoPriority=High + PagePriority=5 cho exe giả lập" $EXT "Đi cặp EXT04: ngoài CPU priority, ép cả I/O priority cao & page priority cho exe giả lập — đọc/ghi image .vdi/.vmdk được ưu tiên trên hàng đợi đĩa." "Moderate" $FARM {
		Set-SophiaExeIoPriority
	} { Set-SophiaExeIoPriority -Remove } { return $false } "IFEO PerfOptions IoPriority/PagePriority"
	Add-Reg "EXT49" "Chặn App nền bằng Policy (LetAppsRunInBackground = Deny)" $EXT "Bản Policy cứng của SYS03: AppPrivacy LetAppsRunInBackground=2 (Force Deny) — app Store không chạy ngầm ở mọi user, farm/game không bị giành tài nguyên." "Moderate" ($FARM+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2 0
	Add-Cmd "EXT50" "Tắt Print Spooler (nếu không in ấn — giảm bề mặt tấn công & process nền)" $EXT "Spooler là service hay bị khai thác (PrintNightmare) và vô dụng trên máy farm/game không máy in. Disabled hẳn; có máy in thì đừng tick." "Moderate" ($FARM_GAME+$LOW) {
		Stop-Service Spooler -Force -ErrorAction SilentlyContinue; Set-Service Spooler -StartupType Disabled -ErrorAction SilentlyContinue
	} {
		Set-Service Spooler -StartupType Manual -ErrorAction SilentlyContinue
	} { try { return ((Get-Service Spooler -ErrorAction SilentlyContinue).StartType -eq 'Disabled') } catch { return $false } } "Spooler Disabled"

	# WinUtil integration (vendored offline from ChrisTitusTech/winutil, MIT): append converted tweaks if bridge is loaded
	if (Get-Command Get-WinUtilConvertedTweaks -ErrorAction SilentlyContinue)
	{
		try { foreach ($winUtilTweak in (Get-WinUtilConvertedTweaks)) { $catalog.Add($winUtilTweak) } } catch {}
	}

	Add-Reg "EXT51" "Tắt TDR hoàn toàn (TdrLevel = 0) — GPU load nặng không bị reset driver" $EXT "Bậc cực hạn hơn GPU03: vô hiệu cơ chế Timeout Detection & Recovery — render/farm GPU 100% dài không bị Windows giết driver giữa chừng. Máy treo thì phải reset cứng." "Extreme" @() "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrLevel" 0 2
	Add-Cmd "EXT52" "Tắt Packet/DMA Coalescing trên NIC (gói tin không bị gom chờ)" $EXT "Coalescing gom gói để tiết kiệm CPU nhưng cộng thêm độ trễ từng gói. Tắt *PacketCoalescing + *DmaCoalescing cho ping/latency tối thiểu tuyệt đối." "Extreme" $GAME {
		Set-SophiaNetAdapterCoalescing
	} { Set-SophiaNetAdapterCoalescing -Restore } { return $false } "Set-NetAdapterAdvancedProperty *PacketCoalescing=0"
	Add-Cmd "EXT53" "Tắt UpdateOrchestrator Tasks (không quét update nền bất chợt)" $EXT "Disable các task Schedule Scan/UpdateModelTask của Update Orchestrator: hết cảnh CPU/disk spike vì Windows tự quét update giữa lúc treo farm/stream." "Moderate" $FARM {
		Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
	} {
		Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
	} { return $false } "Disable-ScheduledTask UpdateOrchestrator"
	Add-Reg "EXT54" "DistributeTimers = 1 (phân bổ timer interrupts ra mọi CPU)" $EXT "Kernel phân phối bộ định thời ngắt đều khắp các lõi thay vì dồn Core 0 — giảm nghẽn ngắt trên máy nhiều instance/game nặng về timer." "Extreme" $GAME "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DistributeTimers" 1 $null
	Add-Reg "EXT55" "AlwaysUnloadDLL = 1 (giải phóng DLL khỏi RAM ngay khi app đóng)" $EXT "Explorer/loader gỡ DLL khỏi bộ nhớ ngay khi tiến trình cuối cùng nhả ra — farm mở/đóng app liên tục giữ RAM sạch, ít phình theo thời gian." "Moderate" ($FARM+$LOW) "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "AlwaysUnloadDLL" 1 0
	Add-Reg "EXT56" "Tắt CEIP (SQMClient CEIPEnable = 0)" $EXT "Tắt nốt kênh Customer Experience Improvement qua registry SQMClient — đi cùng PRI01 thành bộ chặn telemetry hai lớp (Policy + Legacy)." "Safe" ($STD+$LOW) "HKLM:\SOFTWARE\Microsoft\SQMClient\Windows" "CEIPEnable" 0 1
	Add-Reg "EXT57" "Tắt Program Inventory (TurnOffProgramInventory = 1)" $EXT "AppCompat không còn quét/thống kê ứng dụng đã cài chạy nền định kỳ — bớt một nguồn I/O và telemetry tương thích thừa trên máy farm." "Safe" ($STD+$FARM) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "TurnOffProgramInventory" 1 0
	Add-Reg "EXT58" "TcpFinWait2Delay = 30s (đóng kết nối TCP dứt điểm nhanh)" $EXT "Đi cùng NET09: giảm thời gian chờ FIN_WAIT_2 từ mặc định 100s xuống 30s — launcher/ADB/giả lập đóng-mở nghìn kết nối không bị treo cổng chờ." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpFinWait2Delay" 30000 100000

	Add-Reg "EXT59" "MMCSS 'Games': Background Only = False (luồng game chạy cả khi alt-tab)" $EXT "MMCSS không hạ ưu tiên luồng game khi cửa sổ mất focus — alt-tab ra ngoài check tin nhắn mà game/stream vẫn giữ hiệu năng." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Background Only" "False" "True" "String"
	Add-Reg "EXT60" "Tắt Thumbnail Cache (không tạo thumbs.db, giảm I/O thư mục)" $EXT "Explorer không ghi file thumbs.db vào mọi thư mục chứa ảnh/video — duyệt thư mục chứa hàng nghìn file instance/screenshot nhẹ & sạch hơn." "Safe" ($FARM+$LOW) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DisableThumbnailCache" 1 0
	Add-Cmd "EXT61" "Đóng app treo NHANH (AutoEndTasks + timeout 1-2s)" $EXT "Bộ 3 giá trị Desktop: app treo tự bị đóng sau 1s, chờ kill 2s — restart máy farm/game nhanh gọn, không kẹt 'Waiting for programs to close'." "Moderate" $FARM_GAME {
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value "1" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "1000" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -Type "String"
	} {
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value "0" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "5000" -Type "String"
		Set-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "20000" -Type "String"
	} { return ((Get-SophiaRegValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks") -eq "1") } "Desktop AutoEndTasks/HungAppTimeout/WaitToKillAppTimeout"
	Add-Reg "EXT62" "Tắt Remote Assistance (fAllowToGetHelp = 0)" $EXT "Không cho phép phiên hỗ trợ từ xa không mời — đóng một bề mặt mạng thừa trên máy farm/game chuyên dụng." "Safe" ($FARM+$STD) "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" "fAllowToGetHelp" 0 1
	Add-Cmd "EXT63" "Themes Service = Manual (máy yếu không nạp theme nền)" $EXT "Service Themes chỉ chạy khi cần thay vì Automatic thường trực — hợp với máy đã tắt transparency/animation ở GAM11/EXT19. Cần hiệu ứng đẹp thì đừng tick." "Moderate" $LOW {
		Set-Service Themes -StartupType Manual -ErrorAction SilentlyContinue
	} {
		Set-Service Themes -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service Themes -ErrorAction SilentlyContinue
	} { try { return ((Get-Service Themes -ErrorAction SilentlyContinue).StartType -eq 'Manual') } catch { return $false } } "Themes Manual"
	Add-Reg "EXT64" "WaitToKillServiceTimeout = 2s (shutdown/restart dứt khoát)" $EXT "Windows chỉ chờ service tối đa 2 giây khi tắt máy thay vì 5-20s — chu kỳ restart của máy farm ngắn lại rõ rệt." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "5000" "String"

	Add-Reg "EXT65" "GraphicsDrivers DisablePreemption = 1 (DWM không cướp quyền GPU giữa chừng)" $EXT "Giảm việc Desktop Window Manager tiền chiếm (preempt) hàng đợi GPU khi game/giả lập đang render — frame pacing đều hơn trên máy đa nhiệm." "Moderate" $GAME "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisablePreemption" 1 0
	Add-Reg "EXT66" "MMCSS 'Games': Clock Rate = 10000 (timer MMCSS chuẩn 1ms)" $EXT "Đồng bộ xung nhịp scheduler multimedia Games về 10000 (đơn vị 100ns = 1ms) khớp với EXT02 Timer Daemon 0.5ms — luồng game được đánh thức đều nhịp." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Clock Rate" 10000 $null
	Add-Cmd "EXT67" "Tắt Wake-on-LAN Magic Packet & Pattern trên NIC (farm không tự thức)" $EXT "Card mạng không còn đánh thức máy vì gói magic/pattern lạ trong LAN — kết hợp EXT33 cho máy farm ngủ/thức theo đúng ý bạn." "Moderate" $FARM {
		Set-SophiaNicWakeOff
	} { Set-SophiaNicWakeOff -Restore } { return $false } "Set-NetAdapterAdvancedProperty *WakeOn* =0"
	Add-Cmd "EXT68" "BITS Service = Manual (chuyển nền chỉ chạy khi thật cần)" $EXT "Background Intelligent Transfer không còn thường trực Automatic: update/launcher vẫn gọi được khi cần nhưng không chiếm process nền 24/7 trên máy farm." "Moderate" ($FARM+$LOW) {
		Set-Service BITS -StartupType Manual -ErrorAction SilentlyContinue
	} {
		Set-Service BITS -StartupType Automatic -ErrorAction SilentlyContinue
	} { try { return ((Get-Service BITS -ErrorAction SilentlyContinue).StartType -eq 'Manual') } catch { return $false } } "BITS Manual"
	Add-Cmd "EXT69" "Office ClickToRun Service = Manual (nếu có)" $EXT "ClickToRunSvc của Office chuyển sang Manual: máy farm/game không dùng Office không phải nuôi service cập nhật nền. Tự bỏ qua nếu không cài Office." "Moderate" ($FARM+$LOW) {
		if (Get-Service ClickToRunSvc -ErrorAction SilentlyContinue) { Set-Service ClickToRunSvc -StartupType Manual -ErrorAction SilentlyContinue }
	} {
		if (Get-Service ClickToRunSvc -ErrorAction SilentlyContinue) { Set-Service ClickToRunSvc -StartupType Automatic -ErrorAction SilentlyContinue }
	} { return $false } "ClickToRunSvc Manual"
	Add-Reg "EXT70" "Tắt Miracast Wireless Display (PlatformSupportMiracast = 0)" $EXT "Máy bàn/farm không chiếu không dây: tắt hỗ trợ Miracast ở GraphicsDrivers để pipeline hiển thị gọn, bớt thành phần driver chạy nền." "Moderate" $FARM_GAME "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "PlatformSupportMiracast" 0 1
	Add-Reg "EXT71" "Tắt Online Speech Recognition (HasAccepted = 0)" $EXT "Nhận dạng giọng nói online không kích hoạt nền — giảm kết nối dịch vụ thoại thừa trên máy chuyên dụng." "Safe" $STD "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" 0 1
	Add-Reg "EXT72" "DisableWindowsConsumerFeatures = 1 (Policy cứng, chặn app quảng cáo tự cài)" $EXT "Bản Policy của Consumer Features: Windows không tự tải/cài app gợi ý (Candy Crush, TikTok...) sau mỗi lần update — ổ & Start Menu sạch lâu dài." "Safe" ($STD+$FARM+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1 0

	Add-Reg "EXT73" "LanmanWorkstation: DisableBandwidthThrottling = 1" $EXT "Workstation service không bóp băng thông chuyển file/ADB qua LAN — copy image giả lập & đẩy file giữa các máy trong farm đạt tốc độ tối đa phần cứng." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "DisableBandwidthThrottling" 1 0
	Add-Reg "EXT74" "MMCSS 'Games': Priority = 6 (cao nhất cho luồng game)" $EXT "Hoàn thiện bộ ba MMCSS Games: SchedulingCategory High (EXT16) + GPU Priority 8 (GAM09) + Priority 6 — dispatcher luôn xếp luồng game trước mọi tác vụ thường." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6 2
	Add-Reg "EXT75" "Tắt Store Apps tự cập nhật nền (WindowsStore AutoDownload = 2)" $EXT "Microsoft Store không tự tải bản cập nhật app trong nền giành mạng/disk — bạn chủ động update khi rảnh. App đã cài vẫn chạy bình thường." "Safe" ($FARM+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" "AutoDownload" 2 4

	Add-Reg "EXT76" "Tắt Startup Delay của app khởi động cùng Windows (StartupDelayInMSec = 0)" $EXT "Windows mặc định trì hoãn ~10 giây mới chạy các app Startup sau logon. Đặt 0 để launcher/giả lập/agent mở tức thì ngay khi vào desktop — vào việc nhanh hơn sau mỗi lần restart farm." "Safe" ($FARM_GAME+$LOW) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 $null
	Add-Cmd "EXT77" "Tắt Program Compatibility Assistant (PcaSvc) — bỏ hook tương thích thừa" $EXT "PcaSvc theo dõi mọi app để gợi ý chế độ tương thích (di sản từ thời Vista) và ghi log AppCompat — farm/game toàn app quen thuộc nên tắt để giảm hook/service nền." "Moderate" ($FARM_GAME+$LOW) {
		Stop-Service PcaSvc -Force -ErrorAction SilentlyContinue; Set-Service PcaSvc -StartupType Disabled -ErrorAction SilentlyContinue
	} {
		Set-Service PcaSvc -StartupType Manual -ErrorAction SilentlyContinue
	} { try { return ((Get-Service PcaSvc -ErrorAction SilentlyContinue).StartType -eq "Disabled") } catch { return $false } } "PcaSvc Disabled"
	Add-Cmd "EXT78" "Tắt Memory Diagnostic Tasks (không tự quét RAM nền)" $EXT "Hai task MemoryDiagnostic (ProcessMemoryDiagnosticEvents / RunFullMemoryDiagnostic) có thể tự chạy kiểm tra RAM gây CPU/disk spike bất chợt — trên máy farm/game ổn định là thừa. Windows Memory Diagnostic thủ công (mdsched) vẫn dùng được khi bạn chủ động chạy." "Moderate" $FARM {
		Disable-ScheduledTask -TaskPath "\Microsoft\Windows\MemoryDiagnostic\" -TaskName "ProcessMemoryDiagnosticEvents" -ErrorAction SilentlyContinue | Out-Null
		Disable-ScheduledTask -TaskPath "\Microsoft\Windows\MemoryDiagnostic\" -TaskName "RunFullMemoryDiagnostic" -ErrorAction SilentlyContinue | Out-Null
	} {
		Enable-ScheduledTask -TaskPath "\Microsoft\Windows\MemoryDiagnostic\" -TaskName "ProcessMemoryDiagnosticEvents" -ErrorAction SilentlyContinue | Out-Null
	} { return $false } "Disable-ScheduledTask MemoryDiagnostic"
	Add-Reg "EXT79" "Tắt WaaSMedicSvc (Update không tự kích hoạt lại nền)" $EXT "WaaSMedic là service chuyên tự sửa/kích hoạt lại các thành phần Windows Update bị tắt — nguyên nhân farm hay 'tự nhiên' quét update lại. Start=4 cho máy chuyên dụng đã chủ động quản lý update (đi cặp EXT53). Muốn update Windows bình thường thì Restore trước." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" "Start" 4 3
	Add-Reg "EXT80" "Tắt UsoSvc — Update Orchestrator Service (farm chủ động update)" $EXT "UsoSvc điều phối quét/tải update nền. Start=4 cùng EXT53+EXT79 tạo bộ ba khóa update nền triệt để cho máy treo 24/7: không spike CPU/disk, không tự restart (EXT26). Cập nhật thủ công qua Settings vẫn mở được sau khi Restore." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc" "Start" 4 2
	Add-Reg "EXT81" "Chặn Windows Update tự thay Driver (ExcludeWUDriversInQualityUpdate = 1)" $EXT "Update không còn tự cài đè driver GPU/NIC/VT-x qua Quality Update — nguyên nhân kinh điển làm farm mất VT-x hoặc game drop FPS sau 1 đêm. Bạn vẫn cài driver thủ công từ hãng như bình thường." "Moderate" ($FARM+$GAME) "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate" "ExcludeWUDriversInQualityUpdate" 1 0
	Add-Cmd "EXT82" "Tắt Windows Biometric Service (WbioSrvc) — máy không dùng vân tay/Face ID phụ" $EXT "Service sinh trắc học chạy nền dù máy farm/game chỉ đăng nhập bằng mật khẩu/PIN local. Disabled để giảm service nền; đăng nhập Windows Hello bằng vân tay/khuôn mặt sẽ ngừng hoạt động (PIN vẫn dùng được)." "Moderate" ($FARM+$LOW) {
		Stop-Service WbioSrvc -Force -ErrorAction SilentlyContinue; Set-Service WbioSrvc -StartupType Disabled -ErrorAction SilentlyContinue
	} {
		Set-Service WbioSrvc -StartupType Manual -ErrorAction SilentlyContinue
	} { try { return ((Get-Service WbioSrvc -ErrorAction SilentlyContinue).StartType -eq "Disabled") } catch { return $false } } "WbioSrvc Disabled"
	Add-Reg "EXT83" "Tắt Agent Activation Runtime (AarSvc) — di sản kích hoạt giọng nói Cortana" $EXT "AarSvc là runtime kích hoạt agent bằng giọng nói (thời Cortana) vẫn được nạp dạng per-user service trên Windows 11. Start=4 ở template để mọi user đều không nạp — giảm tiến trình nền vô hình." "Moderate" ($FARM+$LOW) "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\AarSvc" "Start" 4 3
	Add-Reg "EXT84" "Tắt Automatic Restart Sign-On (không tự đăng nhập sau update restart)" $EXT "DisableAutomaticRestartSignOn=1: sau khi Windows Update tự restart, máy không tự đăng nhập phiên user (ARSO) — farm an toàn hơn và bạn chủ động kiểm soát lần đăng nhập đầu tiên." "Safe" ($FARM+$STD) "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" "DisableAutomaticRestartSignOn" 1 0
	Add-Cmd "PRI11" "Tắt Clipboard History & đồng bộ clipboard đám mây" $PRI "AllowClipboardHistory=0 + AllowCrossDeviceClipboard=0: Windows không lưu lịch sử sao chép và không đồng bộ clipboard qua tài khoản Microsoft — bớt rò rỉ dữ liệu nhạy cảm (mật khẩu/token) trên máy farm dùng chung." "Safe" ($STD+$LOW) {
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Value 0 -Type "DWord"
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowCrossDeviceClipboard" -Value 0 -Type "DWord"
	} {
		Set-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Value 1 -Type "DWord"
		Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowCrossDeviceClipboard" -Force -ErrorAction SilentlyContinue
	} { return ((Get-SophiaRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory") -eq 0) } "ClipboardHistory/CrossDevice = 0"
	return $catalog.ToArray()
}

# ============================================================
# [PORTABLE-INLINE] Optimizer\UI\InteractiveCLI.ps1
# ============================================================
<#
	.SYNOPSIS
	MOLIK WINLIK - Interactive Tick-Select CLI ([✓]/[ ])

	.DESCRIPTION
	Keyboard: ↑/↓ (or K/J) move, SPACE tick/untick, A all, N none, 1-6 quick Mode,
	M cycle Mode, / search, P purge RAM now, E Emulator Booster, B backup, R restore defaults,
	ENTER apply selected, Q/Esc quit. Category headers group all catalog tweaks.
#>

function Get-SophiaModeTweakIds
{
	param([string]$ModeKey, $Catalog)
	if ($ModeKey -eq "GodMode") { return @($Catalog | ForEach-Object { $_.Id }) }
	if ([string]::IsNullOrWhiteSpace($ModeKey)) { return @() }
	return @($Catalog | Where-Object { $_.Modes -contains $ModeKey } | ForEach-Object { $_.Id })
}

function Invoke-SophiaSelectedTweaks
{
	param($Catalog, [string[]]$SelectedIds, [switch]$SkipBackup, [switch]$Force, $Snapshot = $null, [switch]$NoRestartPrompt)

	$selected = @($Catalog | Where-Object { $SelectedIds -contains $_.Id })
	if ($selected.Count -eq 0)
	{
		Write-Host "  [!] Chưa tick tweak nào. Dùng SPACE để chọn." -ForegroundColor Yellow
		return
	}

	# Plan Engine: phân tích phụ thuộc/mâu thuẫn + sắp xếp theo pha an toàn trước khi chạm vào hệ thống
	if (Get-Command Get-SophiaOptimizationPlan -ErrorAction SilentlyContinue)
	{
		try
		{
			$plan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $SelectedIds -Snapshot $Snapshot
			if (Get-Command Show-SophiaOptimizationPlan -ErrorAction SilentlyContinue) { Show-SophiaOptimizationPlan -Plan $plan }
			if ($plan.Count -ne $selected.Count)
			{
				Write-Host "  [Plan Engine] Đã điều chỉnh danh sách: $($selected.Count) -> $($plan.Count) tweak (xem ghi chú ở trên)." -ForegroundColor Cyan
			}
			$selected = @($plan.Items | ForEach-Object { $_.Tweak })
		}
		catch { Write-Host "  [!] Plan Engine lỗi ($($_.Exception.Message)) — áp dụng theo thứ tự thường." -ForegroundColor Yellow }
	}

	$extreme = @($selected | Where-Object { $_.Risk -eq "Extreme" })
	if ($extreme.Count -gt 0 -and -not $Force)
	{
		Write-Host ""
		Write-Host "  ⚠ CẢNH BÁO: Có $($extreme.Count) tweak mức EXTREME (đánh đổi bảo mật/ổn định lấy hiệu năng):" -ForegroundColor Red
		$extreme | ForEach-Object { Write-Host "      - [$($_.Id)] $($_.Name)" -ForegroundColor Yellow }
		$confirmExtreme = Read-Host "  Gõ 'EXTREME' (viết hoa) để xác nhận áp dụng, hoặc ENTER để hủy"
		if ($confirmExtreme -ne 'EXTREME')
		{
			Write-Host "  Đã hủy. Bỏ tick các tweak [Extreme] màu đỏ nếu bạn không chắc chắn." -ForegroundColor Yellow
			return
		}
	}

	$logDir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Logs"
	New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	$logFile = Join-Path $logDir ("MOLIK_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

	if (-not $SkipBackup)
	{
		if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue)
		{
			try { New-SophiaSystemBackup -Label "Before MOLIK WINLIK ($($selected.Count) tweaks)" | Out-Null } catch {}
		}
	}

	Write-Host ""
	Write-Host "  ══════════ ĐANG ÁP DỤNG $($selected.Count) TWEAK ══════════" -ForegroundColor Cyan
	"=== MOLIK WINLIK $(Get-Date) - $($selected.Count) tweaks ===" | Set-Content $logFile -Encoding UTF8

	$ok = 0; $fail = 0
	foreach ($tweak in $selected)
	{
		Write-Host ("  [{0}] {1} ... " -f $tweak.Id, $tweak.Name) -NoNewline
		try
		{
			& $tweak.ApplyScript
			Write-Host "OK" -ForegroundColor Green
			"OK   $($tweak.Id) $($tweak.Name)" | Add-Content $logFile -Encoding UTF8
			$ok++
		}
		catch
		{
			Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
			"FAIL $($tweak.Id): $($_.Exception.Message)" | Add-Content $logFile -Encoding UTF8
			$fail++
		}
	}
	Write-Host ""
	Write-Host "  ══════════ HOÀN TẤT: $ok OK / $fail FAIL — Log: $logFile ══════════" -ForegroundColor Cyan
	Write-Host "  [!] Nhiều tweak (HAGS, VBS, BCD, Pagefile) cần RESTART để có hiệu lực." -ForegroundColor Yellow
	if (-not $Force -and -not $NoRestartPrompt)
	{
		$restart = Read-Host "  Khởi động lại ngay bây giờ? (Y/N)"
		if ($restart -match '^[Yy]') { Restart-Computer -Force }
	}
	else
	{
		Write-Host "  (Che do tu dong: bo qua hoi restart - hay khoi dong lai may khi tien.)" -ForegroundColor DarkGray
	}
}

function Invoke-SophiaRestoreTweaks
{
	param($Catalog)
	Write-Host "  Đang khôi phục mặc định cho toàn bộ catalog..." -ForegroundColor Cyan
	foreach ($tweak in $Catalog)
	{
		try { & $tweak.RestoreScript } catch {}
	}
	if (Get-Command Restore-SophiaLatestBackup -ErrorAction SilentlyContinue)
	{
		try { Restore-SophiaLatestBackup | Out-Null } catch {}
	}
	Write-Host "  [✓] Đã khôi phục. Hãy RESTART máy." -ForegroundColor Green
	Read-Host "  Nhấn ENTER để quay lại menu"
}

function Invoke-EmulatorAutoBooster
{
	$found = 0
	if (Get-Command Invoke-SophiaProcessBoostNow -ErrorAction SilentlyContinue)
	{
		$found = Invoke-SophiaProcessBoostNow
	}
	else
	{
		$names = @("LdVBoxHeadless","HD-Player","Nox","NoxVMHandle","MuMuPlayer","NemuHeadless","MEmuHeadless","VBoxHeadless","Ld9BoxHeadless")
		foreach ($n in $names)
		{
			Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
				try { $_.PriorityClass = "AboveNormal"; $found++ } catch {}
			}
		}
	}
	if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge | Out-Null }
	Write-Host "  [✓] Emulator Booster: đã boost $found process giả lập (AboveNormal + affinity tránh Core 0) + purge RAM." -ForegroundColor Green
}

function Save-SophiaSelectionProfile
{
	param([string]$ModeKey, [string[]]$SelectedIds, [string]$Path)
	if (-not $Path)
	{
		$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Profiles"
		New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
		$Path = Join-Path $dir ("profile_{0}_{1}.json" -f $ModeKey, (Get-Date -Format "yyyyMMdd_HHmmss"))
	}
	$obj = [ordered]@{ Mode = $ModeKey; CreatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); TweakIds = @($SelectedIds) }
	$obj | ConvertTo-Json | Set-Content -Path $Path -Encoding UTF8 -Force
	Write-Host "  [✓] Đã lưu Profile ($($SelectedIds.Count) tweak, Mode $ModeKey): $Path" -ForegroundColor Green
	return $Path
}

function Get-SophiaSelectionProfile
{
	param([Parameter(Mandatory)][string]$Path)
	if (-not (Test-Path $Path)) { Write-Host "  [!] Không tìm thấy profile: $Path" -ForegroundColor Red; return $null }
	try
	{
		$obj = Get-Content -Path $Path -Raw | ConvertFrom-Json
		return $obj
	}
	catch
	{
		Write-Host "  [!] Profile lỗi định dạng JSON: $($_.Exception.Message)" -ForegroundColor Red
		return $null
	}
}

function Get-MolikUiVersion
{
	if ($Global:MolikWinlikVersion) { return [string]$Global:MolikWinlikVersion }
	return "3.1.0"
}

function Format-MolikTruncate
{
	param([string]$Text, [int]$Max = 80)
	if ([string]::IsNullOrEmpty($Text)) { return "" }
	if ($Max -lt 8) { $Max = 8 }
	if ($Text.Length -le $Max) { return $Text }
	return $Text.Substring(0, $Max - 3) + "..."
}

function Get-MolikRiskBadge
{
	param([string]$Risk)
	switch ($Risk)
	{
		"Extreme"  { return "[EXT ]" }
		"Moderate" { return "[MOD ]" }
		default    { return "[SAFE]" }
	}
}

function Get-MolikWrappedLines
{
	param([string]$Text, [int]$Width = 100, [int]$MaxLines = 2)
	if ([string]::IsNullOrWhiteSpace($Text)) { return @("") }
	if ($Width -lt 20) { $Width = 20 }
	$words = $Text -split '\s+'
	$lines = @()
	$current = ""
	foreach ($w in $words)
	{
		if (($current.Length + $w.Length + 1) -le $Width) { $current = if ($current) { "$current $w" } else { $w } }
		else
		{
			if ($current) { $lines += $current }
			if ($lines.Count -ge $MaxLines) { break }
			$current = $w
		}
	}
	if ($current -and $lines.Count -lt $MaxLines) { $lines += $current }
	if ($lines.Count -gt $MaxLines) { $lines = $lines[0..($MaxLines - 1)] }
	if ($lines.Count -eq $MaxLines -and ($Text.Length -gt (($lines -join " ").Length + 4))) { $lines[-1] = Format-MolikTruncate $lines[-1] ($Width) }
	return $lines
}

function Show-SophiaSimpleMenu
{
	# Menu số đơn giản: chạy được ở mọi host (ISE, VSCode, input bị redirect...) nơi ReadKey không khả dụng.
	param($Catalog, $Snapshot, [string]$LauncherPath = "")

	while ($true)
	{
		Write-Host ""
		Write-Host "  ╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
		Write-Host "  ║  👑 MOLIK WINLIK v$(Get-MolikUiVersion) by @nggkhaiz - MENU (Offline)  ║" -ForegroundColor Magenta
		Write-Host "  ╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
		if ($Snapshot)
		{
			Write-Host ("  {0} | {1} | RAM {2}GB | GPU {3} | Admin: {4}{5}" -f $Snapshot.OSName, $Snapshot.CPUName, $Snapshot.RAMTotalGB, $Snapshot.GPUName, $Snapshot.IsAdmin, $(if ($Snapshot.PendingReboot) { " | [!] DANG CHO RESTART" } else { "" })) -ForegroundColor DarkCyan
			if ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0) { Write-Host ("  Gia lap: {0}" -f ($Snapshot.InstalledEmulators -join ", ")) -ForegroundColor Green }
		}
		$modes = Get-SophiaOptimizationModes
		for ($i = 0; $i -lt $modes.Count; $i++)
		{
			$m = $modes[$i]
			$cnt = (Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog).Count
			Write-Host ("   {0}. {1} {2} ({3} tweak)" -f ($i + 1), $m.Icon, $m.Name, $cnt) -ForegroundColor Cyan
			Write-Host ("      {0}" -f $m.Description) -ForegroundColor Gray
		}
		Write-Host "   7. 🎛️  Mở giao diện TICK-CHỌN đầy đủ (phím ↑↓/SPACE)" -ForegroundColor Green
		Write-Host "   G. 🤖 SMART AUTO — tự chọn Mode + tweak theo phần cứng máy này" -ForegroundColor Green
		Write-Host "   8. 🧠 Purge RAM ngay          9. 🖥️ Boost giả lập ngay" -ForegroundColor Green
		Write-Host "   T. 📊 Benchmark (Before/After)   C. 📈 So sánh Benchmark" -ForegroundColor Green
		Write-Host "   R. ↩️  Restore mặc định        S. 💾 Tạo Shortcut Desktop" -ForegroundColor Green
		Write-Host "   A. 📦 Cài ứng dụng qua winget (kiểu winutil, 239 app)" -ForegroundColor Green
		Write-Host "   D. 🩺 SELF-TEST / DEBUG toàn diện (kiểm tra tool, không đổi hệ thống)" -ForegroundColor Green
		Write-Host "   X. 🎁 PRESETS — gói tối ưu theo kịch bản (Farm/Esports/Privacy...)" -ForegroundColor Green
		Write-Host "   H. 📄 Báo cáo HTML Dashboard      B. 💾 Tạo Backup ngay" -ForegroundColor Green
		Write-Host "   U. ↩️  HOÀN TÁC phiên áp dụng gần nhất (khôi phục các tweak vừa áp)" -ForegroundColor Green
		Write-Host "   0. Thoát" -ForegroundColor Yellow
		$choice = Read-Host "  Chọn (0-9/G/A/T/C/R/S/D/X/H/B/U)"
		if ($choice -match '^[1-6]$')
		{
			$m = $modes[[int]::Parse($choice) - 1]
			$ids = Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog
			$go = Read-Host "  Áp dụng $($ids.Count) tweak của mode $($m.Name)? (Y/N)"
			if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids -Snapshot $Snapshot }
		}
		elseif ($choice -eq '7')
		{
			try { Show-SophiaOptimizerUI -Catalog $Catalog -Snapshot $Snapshot }
			catch { Write-Host "  [!] Host này không hỗ trợ giao diện phím trực tiếp ($($_.Exception.Message)) — hãy dùng các mục số trong Menu này." -ForegroundColor Yellow }
		}
		elseif ($choice -eq 'G' -or $choice -eq 'g')
		{
			if (Get-Command Get-SophiaSmartRecommendation -ErrorAction SilentlyContinue)
			{
				$rec = Get-SophiaSmartRecommendation -Snapshot $Snapshot -Catalog $Catalog
				Write-Host "  Smart Advisor khuyên: Mode $($rec.Mode) + $($rec.ExtraIds.Count) tweak bổ sung" -ForegroundColor Green
				$rec.Reasons | ForEach-Object { Write-Host "      - $_" -ForegroundColor Cyan }
				$rec.Warnings | ForEach-Object { Write-Host "      [!] $_" -ForegroundColor Yellow }
				$ids = Get-SophiaModeTweakIds -ModeKey $rec.Mode -Catalog $Catalog
				$ids = @($ids + $rec.ExtraIds | Select-Object -Unique)
				$go = Read-Host "  Áp dụng $($ids.Count) tweak Smart Auto? (Y/N)"
				if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids -Snapshot $Snapshot }
			}
		}
		elseif ($choice -eq '8') { if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge } }
		elseif ($choice -eq 'A' -or $choice -eq 'a') { if (Get-Command Show-SophiaAppInstallerMenu -ErrorAction SilentlyContinue) { Show-SophiaAppInstallerMenu } }
		elseif ($choice -eq 'D' -or $choice -eq 'd') { if (Get-Command Test-SophiaOptimizerHealth -ErrorAction SilentlyContinue) { Test-SophiaOptimizerHealth -Catalog $Catalog | Out-Null; Read-Host '  Nhấn ENTER để quay lại menu' } }
		elseif ($choice -eq '9') { Invoke-EmulatorAutoBooster }
		elseif ($choice -eq 'T' -or $choice -eq 't') { if (Get-Command Invoke-SophiaBenchmark -ErrorAction SilentlyContinue) { Invoke-SophiaBenchmark -Label "Menu" | Out-Null } }
		elseif ($choice -eq 'C' -or $choice -eq 'c') { if (Get-Command Compare-SophiaBenchmarks -ErrorAction SilentlyContinue) { Compare-SophiaBenchmarks } }
		elseif ($choice -eq 'R' -or $choice -eq 'r')
		{
			$confirm = Read-Host "  Khôi phục MẶC ĐỊNH toàn bộ? (yes/no)"
			if ($confirm -eq 'yes') { Invoke-SophiaRestoreTweaks -Catalog $Catalog }
			$firstFrame = $true
		}
		elseif ($choice -eq 'S' -or $choice -eq 's')
		{
			try
			{
				$desktop = [Environment]::GetFolderPath("Desktop")
				$lnkPath = Join-Path $desktop "MOLIK WINLIK.lnk"
				$shell = New-Object -ComObject WScript.Shell
				$lnk = $shell.CreateShortcut($lnkPath)
				# OFFLINE: shortcut tro thang vao file local (uu tien MOLIK_WINLIK.bat canh launcher)
				$batPath = Join-Path (Get-Location).Path "MOLIK_WINLIK.bat"
				if ($LauncherPath -and (Split-Path $LauncherPath -Parent)) { $batPath = Join-Path (Split-Path $LauncherPath -Parent) "MOLIK_WINLIK.bat" }
				if (Test-Path $batPath)
				{
					$lnk.TargetPath = $batPath
					$lnk.Arguments = ""
				}
				elseif ($LauncherPath -match '\.ps1"?$')
				{
					$lnk.TargetPath = "powershell.exe"
					$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$LauncherPath`""
				}
				else
				{
					Write-Host "  [!] Không tìm thấy MOLIK_WINLIK.bat / file launcher local để tạo shortcut." -ForegroundColor Yellow
					continue
				}
				$lnk.Description = "MOLIK WINLIK - Tick-Select CLI (Portable, khong can cai)"
				$lnk.Save()
				Write-Host "  [✓] Đã tạo shortcut Desktop: $lnkPath (từ nay double-click là chạy, không cần cài)" -ForegroundColor Green
			}
			catch { Write-Host "  [!] Không tạo được shortcut: $($_.Exception.Message)" -ForegroundColor Yellow }
		}
		elseif ($choice -eq 'X' -or $choice -eq 'x')
		{
			if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue)
			{
				$presets = @(Get-MolikPresets)
				for ($i = 0; $i -lt $presets.Count; $i++)
				{
					$resolved = Resolve-MolikPreset -Preset $presets[$i] -Catalog $Catalog
					Write-Host ("   {0}. {1} {2} ({3} tweak)" -f ($i + 1), $presets[$i].Icon, $presets[$i].Title, $resolved.Count) -ForegroundColor Cyan
					Write-Host "      $($presets[$i].Description)" -ForegroundColor Gray
				}
				$pick = Read-Host "  Chọn Preset (1-$($presets.Count), ENTER = quay lại)"
				if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $presets.Count)
				{
					$chosen = $presets[[int]$pick - 1]
					$presetIds = Resolve-MolikPreset -Preset $chosen -Catalog $Catalog
					if (Get-Command Get-SophiaOptimizationPlan -ErrorAction SilentlyContinue)
					{
						$presetPlan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $presetIds -Snapshot $Snapshot
						Show-SophiaOptimizationPlan -Plan $presetPlan -Title "KE HOACH PRESET $($chosen.Name)"
					}
					$go = Read-Host "  Áp dụng $($presetIds.Count) tweak của Preset $($chosen.Title)? (Y/N)"
					if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $presetIds -Snapshot $Snapshot }
				}
			}
		}
		elseif ($choice -eq 'H' -or $choice -eq 'h')
		{
			if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue)
			{
				Write-Host "  Đang kiểm tra trạng thái tweak và xuất báo cáo HTML..." -ForegroundColor Cyan
				Export-MolikHtmlReport -Snapshot $Snapshot -Catalog $Catalog | Out-Null
				Read-Host '  Nhấn ENTER để quay lại menu'
			}
		}
		elseif ($choice -eq 'B' -or $choice -eq 'b')
		{
			if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue) { New-SophiaSystemBackup | Out-Null; Read-Host '  Nhấn ENTER để quay lại menu' }
		}
		elseif ($choice -eq 'U' -or $choice -eq 'u')
		{
			if (Get-Command Restore-MolikLastSession -ErrorAction SilentlyContinue) { Restore-MolikLastSession -Catalog $Catalog | Out-Null }
		}
		elseif ($choice -eq '0') { return }
		else { Write-Host "  Lựa chọn không hợp lệ." -ForegroundColor Yellow }
	}
}

function Show-SophiaOptimizerUI
{
	param($Catalog, $Snapshot, [string]$InitialMode = "EmulatorFarm")

	$modes = Get-SophiaOptimizationModes
	$modeKeys = @($modes | ForEach-Object { $_.Key })
	$currentMode = $InitialMode

	$selected = @{}
	foreach ($id in (Get-SophiaModeTweakIds -ModeKey $currentMode -Catalog $Catalog)) { $selected[$id] = $true }

	# Trang thai da ap dung (phim V de quet) - PHAI khoi tao truoc khi render,
	# ban cu thieu dong nay nen TUI vang loi ngay khung hinh dau tien.
	$appliedStatus = @{}
	$smartRec = $null
	try { if (Get-Command Get-SophiaSmartRecommendation -ErrorAction SilentlyContinue) { $smartRec = Get-SophiaSmartRecommendation -Snapshot $Snapshot -Catalog $Catalog } } catch {}

	$searchTerm = ""
	$filterMode = "All"
	$firstFrame = $true
	$lastFrameLines = 0
	$rebootIds = @()
	try { if (Get-Command Get-SophiaRebootTweakIds -ErrorAction SilentlyContinue) { $rebootIds = @(Get-SophiaRebootTweakIds) } } catch {}
	$cursor = 0
	$pageSize = 18

	$getFiltered = {
		$list = @($Catalog)
		if (-not [string]::IsNullOrWhiteSpace($searchTerm))
		{
			$term = $searchTerm.ToLower()
			$list = @($list | Where-Object { $_.Name.ToLower().Contains($term) -or $_.Id.ToLower().Contains($term) -or $_.Category.ToLower().Contains($term) -or $_.Description.ToLower().Contains($term) })
		}
		if ($filterMode -eq "Selected") { $list = @($list | Where-Object { $selected.ContainsKey($_.Id) -and $selected[$_.Id] }) }
		elseif ($filterMode -eq "Extreme") { $list = @($list | Where-Object { $_.Risk -eq "Extreme" }) }
		elseif ($filterMode -eq "NotApplied") { $list = @($list | Where-Object { -not ($appliedStatus.ContainsKey($_.Id) -and $appliedStatus[$_.Id]) }) }
		return $list
	}

	while ($true)
	{
		try { $pageSize = [Math]::Max(10, [Console]::WindowHeight - 18) } catch {}
		$filtered = & $getFiltered
		if ($filtered.Count -eq 0) { $filtered = @($Catalog); $searchTerm = ""; $filterMode = "All" }
		if ($cursor -ge $filtered.Count) { $cursor = $filtered.Count - 1 }
		if ($cursor -lt 0) { $cursor = 0 }
		$pageStart = [Math]::Floor($cursor / $pageSize) * $pageSize
		$pageEnd = [Math]::Min($pageStart + $pageSize - 1, $filtered.Count - 1)
		$selectedCount = @($selected.Keys | Where-Object { $selected[$_] }).Count

		try
		{
			if ($firstFrame) { [Console]::Clear(); $firstFrame = $false; $lastFrameLines = 0 }
			else { [Console]::SetCursorPosition(0, 0) }
			[Console]::CursorVisible = $false
		} catch { Clear-Host; $lastFrameLines = 0 }
		$snapLines = 0
		if ($Snapshot) { $snapLines = 1; if ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0) { $snapLines++ } }
		$frameLines = 11 + $snapLines
		if ($smartRec) { $frameLines++ }

		# Header
		Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
		Write-Host "  ║  👑 MOLIK WINLIK v$(Get-MolikUiVersion) by @nggkhaiz — OFFLINE OPTIMIZER          ║" -ForegroundColor Magenta
		Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
		if ($Snapshot)
		{
			Write-Host ("  {0} | {1} | RAM {2}GB | Admin: {3}" -f $Snapshot.OSName, $Snapshot.CPUName, $Snapshot.RAMTotalGB, $Snapshot.IsAdmin) -ForegroundColor DarkCyan
			if ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0)
			{
				Write-Host ("  🖥️ Giả lập phát hiện: {0}" -f ($Snapshot.InstalledEmulators -join ", ")) -ForegroundColor Green
			}
		}
		# Mode bar
		$modeLine = "  MODE: "
		for ($i = 0; $i -lt $modes.Count; $i++)
		{
			$m = $modes[$i]
			if ($m.Key -eq $currentMode) { $modeLine += " [$($i+1):$($m.Name)] " }
			else { $modeLine += "  $($i+1):$($m.Name)  " }
		}
		Write-Host $modeLine -ForegroundColor Yellow
		$modeObj = $modes | Where-Object Key -eq $currentMode | Select-Object -First 1
		if ($modeObj) { Write-Host "  $($modeObj.Icon) $($modeObj.Description)" -ForegroundColor DarkYellow }
		if ($smartRec) { Write-Host "  🤖 Smart Advisor (phím G): khuyên dùng Mode $($smartRec.Mode) + $($smartRec.ExtraIds.Count) tweak theo phần cứng máy này" -ForegroundColor Green }
		$appliedKnown = @($appliedStatus.Keys | Where-Object { $appliedStatus[$_] }).Count
		Write-Host ("  Đã tick: {0}/{1} tweak | Đã áp (đã quét): {2} | Hiển thị: {3} | Lọc: {4} | Tìm kiếm: '{5}'" -f $selectedCount, $Catalog.Count, $appliedKnown, $filtered.Count, $filterMode, $searchTerm) -ForegroundColor Cyan
		Write-Host "  ──────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
		Write-Host "  [↑↓/KJ] Chọn  [SPACE] Tick  [1-6] Mode  [A]ll  [N]one  [/] Tìm  [P] Purge RAM  [E] Boost Giả Lập" -ForegroundColor Gray
		Write-Host "  [G] Smart Auto (AI khuyên dùng)  [V] Check đã áp dụng (●)  [T] Benchmark  [S] Lưu Profile  [F] Đổi bộ lọc" -ForegroundColor Gray
		Write-Host "  [L] Nạp Profile  [B] Backup  [H] Báo cáo HTML  [U] Hoàn tác phiên gần nhất  [?] Trợ giúp" -ForegroundColor Gray
		Write-Host "  [R] Restore Mặc Định  [ENTER] ÁP DỤNG  [Q] Thoát" -ForegroundColor Gray
		Write-Host "  ──────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

		$lastCategory = ""
		for ($idx = $pageStart; $idx -le $pageEnd; $idx++)
		{
			$t = $filtered[$idx]
			$frameLines++
			if ($t.Category -ne $lastCategory)
			{
				$lastCategory = $t.Category
				$frameLines += 2
				Write-Host ""
				Write-Host "  $lastCategory" -ForegroundColor Magenta
			}
			$isOn = ($selected.ContainsKey($t.Id) -and $selected[$t.Id])
			$box = if ($isOn) { "[✓]" } else { "[ ]" }
			if ($appliedStatus.ContainsKey($t.Id) -and $appliedStatus[$t.Id]) { $box += "●" }
			$riskColor = "Green"
			if ($t.Risk -eq "Extreme") { $riskColor = "Red" } elseif ($t.Risk -eq "Moderate") { $riskColor = "Yellow" }
			$uiWidth = 110
			try { $uiWidth = [Console]::WindowWidth } catch {}
			$nameMax = [Math]::Max(30, $uiWidth - 32)
			$line = "{0} {1} {2} {3}" -f $box, $t.Id, (Get-MolikRiskBadge $t.Risk), (Format-MolikTruncate $t.Name $nameMax)
			if ($idx -eq $cursor)
			{
				Write-Host "  ▶ $line" -ForegroundColor White -BackgroundColor DarkBlue
				$descUiLines = @(Get-MolikWrappedLines $t.Description ([Math]::Max(40, $uiWidth - 10)) 2)
				$frameLines += $descUiLines.Count + 1
				foreach ($descLine in $descUiLines) { Write-Host "      $descLine" -ForegroundColor Cyan }
				$rebootTag = if ($rebootIds -contains $t.Id) { " | Cần RESTART" } else { "" }
				Write-Host (Format-MolikTruncate "      Chi tiết: $($t.Detail)$rebootTag" ([Math]::Max(40, $uiWidth - 2))) -ForegroundColor DarkGray
			}
			else
			{
				if ($isOn) { Write-Host "    $line" -ForegroundColor Green }
				else { Write-Host "    $line" -ForegroundColor $riskColor }
			}
		}
		$frameLines += 2
		Write-Host ""
		Write-Host ("  Trang {0}/{1} — Mục {2}/{3}" -f ([Math]::Floor($pageStart/$pageSize)+1), ([Math]::Ceiling($filtered.Count/$pageSize)), ($cursor+1), $filtered.Count) -ForegroundColor DarkGray
		# Xoa phan du cua khung hinh truoc (dai hon) de khong con "rac" phia duoi
		if ($frameLines -lt $lastFrameLines)
		{
			$padWidth = 100
			try { $padWidth = [Console]::WindowWidth } catch {}
			$padLine = " " * [Math]::Max(10, $padWidth - 1)
			for ($pad = $frameLines; $pad -lt $lastFrameLines; $pad++) { Write-Host $padLine }
			try { [Console]::SetCursorPosition(0, 0) } catch {}
		}
		$lastFrameLines = $frameLines

		$key = [Console]::ReadKey($true)
		$ch = $key.KeyChar
		switch ($key.Key)
		{
			"UpArrow"   { $cursor-- ; continue }
			"DownArrow" { $cursor++ ; continue }
			"PageUp"    { $cursor -= $pageSize; continue }
			"PageDown"  { $cursor += $pageSize; continue }
			"Home"      { $cursor = 0; continue }
			"End"       { $cursor = $filtered.Count - 1; continue }
			"Spacebar"  {
				$t = $filtered[$cursor]
				$selected[$t.Id] = -not ($selected.ContainsKey($t.Id) -and $selected[$t.Id])
				continue
			}
			"Enter" {
				try { [Console]::CursorVisible = $true } catch {}
				$ids = @($selected.Keys | Where-Object { $selected[$_] })
				Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids -Snapshot $Snapshot
				Read-Host "  Nhấn ENTER để quay lại menu"
				$firstFrame = $true
				continue
			}
			"Escape" { try { [Console]::CursorVisible = $true } catch {}; return }
		}
		if ($key.Key -eq 'Q' -or $ch -eq 'q') { try { [Console]::CursorVisible = $true } catch {}; return }
		elseif ($ch -eq 'k' -or $ch -eq 'K') { $cursor-- }
		elseif ($ch -eq 'j' -or $ch -eq 'J') { $cursor++ }
		elseif ($ch -eq 'a' -or $ch -eq 'A') { foreach ($t in $filtered) { $selected[$t.Id] = $true } }
		elseif ($ch -eq 'n' -or $ch -eq 'N') { foreach ($t in $filtered) { $selected[$t.Id] = $false } }
		elseif ($ch -eq 'm' -or $ch -eq 'M') {
			$idxMode = [array]::IndexOf($modeKeys, $currentMode)
			$currentMode = $modeKeys[($idxMode + 1) % $modeKeys.Count]
			$selected = @{}
			foreach ($id in (Get-SophiaModeTweakIds -ModeKey $currentMode -Catalog $Catalog)) { $selected[$id] = $true }
			$cursor = 0
		}
		elseif ($ch -ge '1' -and $ch -le '6') {
			$currentMode = $modeKeys[[int]::Parse([string]$ch) - 1]
			$selected = @{}
			foreach ($id in (Get-SophiaModeTweakIds -ModeKey $currentMode -Catalog $Catalog)) { $selected[$id] = $true }
			$cursor = 0
		}
		elseif ($ch -eq '/') {
			try { [Console]::CursorVisible = $true } catch {}
			$searchTerm = Read-Host "  Tìm tweak (ENTER trống = xóa lọc)"
			$cursor = 0
			$firstFrame = $true
		}
		elseif ($ch -eq 'p' -or $ch -eq 'P') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'e' -or $ch -eq 'E') {
			try { [Console]::CursorVisible = $true } catch {}
			Invoke-EmulatorAutoBooster
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'v' -or $ch -eq 'V') {
			try { [Console]::CursorVisible = $true } catch {}
			Write-Host "  Đang kiểm tra trạng thái đã áp dụng cho $($filtered.Count) tweak..." -ForegroundColor Cyan
			foreach ($t in $filtered)
			{
				try { $appliedStatus[$t.Id] = [bool](& $t.CheckScript) } catch { $appliedStatus[$t.Id] = $false }
			}
			$appliedCount = @($appliedStatus.Keys | Where-Object { $appliedStatus[$_] }).Count
			Write-Host "  [✓] Đã áp dụng: $appliedCount/$($filtered.Count) (đánh dấu ● cạnh ô tick). Nhấn phím bất kỳ..." -ForegroundColor Green
			[Console]::ReadKey($true) | Out-Null
			$firstFrame = $true
		}
		elseif ($ch -eq 't' -or $ch -eq 'T') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Invoke-SophiaBenchmark -ErrorAction SilentlyContinue) { Invoke-SophiaBenchmark -Label "Manual" | Out-Null }
			else { Write-Host "  [!] Không tìm thấy module Benchmark." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'g' -or $ch -eq 'G') {
			try { [Console]::CursorVisible = $true } catch {}
			if ($smartRec)
			{
				$currentMode = $smartRec.Mode
				$selected = @{}
				foreach ($id in (Get-SophiaModeTweakIds -ModeKey $currentMode -Catalog $Catalog)) { $selected[$id] = $true }
				foreach ($id in $smartRec.ExtraIds) { $selected[$id] = $true }
				$cursor = 0
				Write-Host "  🤖 Smart Advisor đã tự tick Mode $currentMode + tweak riêng cho máy này:" -ForegroundColor Green
				$smartRec.Reasons | ForEach-Object { Write-Host "      - $_" -ForegroundColor Cyan }
				$smartRec.Warnings | ForEach-Object { Write-Host "      [!] $_" -ForegroundColor Yellow }
			}
			else { Write-Host "  [!] Smart Advisor không khả dụng (thiếu dữ liệu phần cứng)." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để xem danh sách đã tick"
			$firstFrame = $true
		}
		elseif ($ch -eq 's' -or $ch -eq 'S') {
			try { [Console]::CursorVisible = $true } catch {}
			$ids = @($selected.Keys | Where-Object { $selected[$_] })
			Save-SophiaSelectionProfile -ModeKey $currentMode -SelectedIds $ids | Out-Null
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'l' -or $ch -eq 'L') {
			try { [Console]::CursorVisible = $true } catch {}
			$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Profiles"
			$latest = Get-ChildItem -Path $dir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
			if ($latest)
			{
				$profile = Get-SophiaSelectionProfile -Path $latest.FullName
				if ($profile)
				{
					$selected = @{}
					foreach ($id in $profile.TweakIds) { $selected[[string]$id] = $true }
					if ($profile.Mode) { $currentMode = [string]$profile.Mode }
					Write-Host "  [✓] Đã nạp Profile: $($latest.Name) ($($profile.TweakIds.Count) tweak, Mode $currentMode)" -ForegroundColor Green
				}
			}
			else { Write-Host "  [!] Chưa có Profile nào trong $dir — dùng phím S để lưu." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'b' -or $ch -eq 'B') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue) { New-SophiaSystemBackup | Out-Null }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'f' -or $ch -eq 'F') {
			$filterModes = @("All", "Selected", "Extreme", "NotApplied")
			$filterMode = $filterModes[([array]::IndexOf($filterModes, $filterMode) + 1) % $filterModes.Count]
			$cursor = 0
		}
		elseif ($ch -eq '?') {
			try { [Console]::CursorVisible = $true; [Console]::Clear() } catch {}
			Write-Host ""
			Write-Host "  ══════ MOLIK WINLIK - TRO GIUP PHIM TAT ══════" -ForegroundColor Magenta
			Write-Host "  ↑/↓ hoac K/J: di chuyen | SPACE: tick/bo tick | ENTER: AP DUNG cac tweak da tick" -ForegroundColor Gray
			Write-Host "  1-6/M: doi Mode | A: tick tat ca (dang loc) | N: bo tick tat ca | /: tim kiem" -ForegroundColor Gray
			Write-Host "  F: doi bo loc All -> Selected -> Extreme -> NotApplied (bam V truoc de quyet trang thai)" -ForegroundColor Gray
			Write-Host "  G: Smart Auto theo phan cung | V: quet tweak da ap dung (●) | T: Benchmark" -ForegroundColor Gray
			Write-Host "  P: Purge RAM | E: Boost gia lap | S/L: luu/nap Profile | B: Backup" -ForegroundColor Gray
			Write-Host "  H: xuat bao cao HTML Dashboard | U: HOAN TAC phien ap dung gan nhat | R: Restore mac dinh | Q/Esc: thoat" -ForegroundColor Gray
			Write-Host "  Badge: [SAFE] an toan - [MOD ] trung binh - [EXT ] cuc han (doc mo ta truoc khi tick)" -ForegroundColor Yellow
			Write-Host "  Bam phim bat ky de quay lai..." -ForegroundColor Cyan
			[Console]::ReadKey($true) | Out-Null
			$firstFrame = $true
		}
		elseif ($ch -eq 'h' -or $ch -eq 'H') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue) { Export-MolikHtmlReport -Snapshot $Snapshot -Catalog $Catalog | Out-Null }
			else { Write-Host "  [!] Khong tim thay Report Engine." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'u' -or $ch -eq 'U') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Restore-MolikLastSession -ErrorAction SilentlyContinue) { Restore-MolikLastSession -Catalog $Catalog | Out-Null }
			else { Write-Host "  [!] Khong tim thay module Backup/Undo." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'r' -or $ch -eq 'R') {
			try { [Console]::CursorVisible = $true } catch {}
			$confirm = Read-Host "  Khôi phục MẶC ĐỊNH toàn bộ tweak? (yes/no)"
			if ($confirm -eq 'yes') { Invoke-SophiaRestoreTweaks -Catalog $Catalog }
		}
		if ($cursor -lt 0) { $cursor = 0 }
		if ($cursor -ge $filtered.Count) { $cursor = $filtered.Count - 1 }
	}
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
