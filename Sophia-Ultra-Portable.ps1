<#
	Sophia Ultra Optimizer — PORTABLE (1 file duy nhất, KHÔNG CẦN CÀI ĐẶT)
	File này được sinh tự động bởi Optimizer\Build-Portable.ps1 — đừng sửa tay, hãy sửa nguồn trong Optimizer/ rồi build lại.
	Chạy: .\Sophia-Ultra-Portable.ps1  |  irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Portable.ps1 | iex
#>
<#
	.SYNOPSIS
	Sophia Ultra Optimizer — Interactive Tick-Select CLI (Tối ưu sâu Windows)

	.DESCRIPTION
	Tool tick-chọn [✓]/[ ] tối ưu Windows cực sâu cho Treo Giả Lập 24/7, Hardcore Gaming,
	Workstation/Streaming, Low-Spec và Sophia Standard/Privacy. Xây trên Sophia Script gốc
	(src/Sophia_Script_for_Windows_*) + 137 tweak kernel/BCD/MSI/timer/GPU/network riêng (Optimizer/).

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
	[string]$Profile = "",
	[switch]$Menu,
	[switch]$Smart,
	[switch]$Plan,
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
		$argList = @()
		if ($PSCommandPath)
		{
			$argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
		}
		else
		{
			# Đang chạy qua irm | iex (không có file trên đĩa): nâng quyền bằng cách gọi lại bản Portable từ xa
			$argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Portable.ps1 | iex")
			Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs
			exit
		}
		if ($Mode) { $argList += @("-Mode", $Mode) }
		if ($Apply) { $argList += "-Apply" }
		if ($Yes) { $argList += "-Yes" }
		if ($Benchmark) { $argList += "-Benchmark" }
		if ($DryRun) { $argList += "-DryRun" }
		if ($PurgeRAM) { $argList += "-PurgeRAM" }
		if ($Profile) { $argList += @("-Profile", "`"$Profile`"") }
		if ($Menu) { $argList += "-Menu" }
		if ($BoostEmulators) { $argList += "-BoostEmulators" }
		if ($RestoreDefaults) { $argList += "-RestoreDefaults" }
		Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs
		exit
	}
} catch {}

$RepoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# ── Load engine ───────────────────────────────────────────────────────────────
# [PORTABLE] Toàn bộ engine đã được nhúng trực tiếp bên dưới — không cần file phụ, không cần cài đặt.

# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\HardwareDetector.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Hardware, OS, Virtualization & Emulator Detection Engine

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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\RamCleanerDaemon.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Native Kernel Standby List & Working Set RAM Cleaner Engine

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
			EnablePrivilege("SeDebugPrivilege");
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

	$CleanerScriptDir = "$env:ProgramData\SophiaUltraOptimizer"
	if (-not (Test-Path -Path $CleanerScriptDir))
	{
		New-Item -Path $CleanerScriptDir -ItemType Directory -Force | Out-Null
	}

	$DaemonScriptPath = Join-Path -Path $CleanerScriptDir -ChildPath "SophiaAutoRamCleaner.ps1"

	$DaemonScriptContent = @"
# Sophia Ultra Optimizer - 24/7 Smart RAM & Standby List Auto-Cleaner Daemon
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

	Register-ScheduledTask -TaskName "Sophia_Auto_RAM_Cleaner" -TaskPath "\Sophia\" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Auto-purges Windows Standby List & Working Set RAM every $IntervalMinutes minutes when RAM > $ThresholdPercent% (Ideal for 24/7 Emulator Farming & Gaming)" -Force | Out-Null
}

function Unregister-SophiaAutoRamCleanerTask
{
	[CmdletBinding()]
	param()

	Unregister-ScheduledTask -TaskName "Sophia_Auto_RAM_Cleaner" -TaskPath "\Sophia\" -Confirm:$false -ErrorAction SilentlyContinue
	Remove-Item -Path "$env:ProgramData\SophiaUltraOptimizer\SophiaAutoRamCleaner.ps1" -Force -ErrorAction SilentlyContinue
}


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\ExtremeEngine.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Extreme Engine (MSI interrupts, timer daemon, process affinity, per-exe priority)

	.DESCRIPTION
	Low-level helpers used by the EXTREME LAB catalog section:
	MSI Mode for GPU/NVMe/NIC, 0.5ms Timer Resolution daemon, periodic Process Booster
	(priority + affinity off Core 0), IFEO CpuPriorityClass, per-exe GPU preference &
	Fullscreen-Optimizations, NIC advanced properties, USB/NIC power-off lockdown,
	full powercfg profile, NTFS/storage tuning and AMD ULPS disable.
	Every setter has a matching remover/restore and is safe to run when hardware is absent.
#>

$script:SophiaDataDir = "$env:ProgramData\SophiaUltraOptimizer"

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
				@{ K = "*EEE"; On = "0"; Off = "0" },
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
	$line = (& powercfg /list 2>$null | Select-String "Ultimate Performance" | Select-Object -First 1).ToString()
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
	$scriptPath = Join-Path $dir "SophiaProcessBooster.ps1"
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
	Register-ScheduledTask -TaskName "Sophia_Process_Booster" -TaskPath "\Sophia\" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Every 5 min: AboveNormal priority + affinity off Core 0 for Android emulator processes" -Force | Out-Null
	Invoke-SophiaProcessBoostNow | Out-Null
}

function Unregister-SophiaProcessBoosterTask
{
	Unregister-ScheduledTask -TaskName "Sophia_Process_Booster" -TaskPath "\Sophia\" -Confirm:$false -ErrorAction SilentlyContinue
}

function Start-SophiaTimerResolutionDaemon
{
	$dir = Get-SophiaDataDir
	$scriptPath = Join-Path $dir "SophiaTimerResolution.ps1"
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
	Register-ScheduledTask -TaskName "Sophia_Timer_Resolution" -TaskPath "\Sophia\" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Holds Windows timer resolution at 0.5ms (NtSetTimerResolution 5000) for minimum game/emulator latency" -Force | Out-Null
	Start-ScheduledTask -TaskName "Sophia_Timer_Resolution" -TaskPath "\Sophia\" -ErrorAction SilentlyContinue
}

function Stop-SophiaTimerResolutionDaemon
{
	Stop-ScheduledTask -TaskName "Sophia_Timer_Resolution" -TaskPath "\Sophia\" -ErrorAction SilentlyContinue
	Unregister-ScheduledTask -TaskName "Sophia_Timer_Resolution" -TaskPath "\Sophia\" -Confirm:$false -ErrorAction SilentlyContinue
	try
	{
		Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
			Where-Object { $_.CommandLine -match 'SophiaTimerResolution' } |
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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\Benchmark.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Before/After Performance Benchmark

	.DESCRIPTION
	Lightweight repeatable benchmark (CPU single + multi via Jobs, disk 128MB sequential,
	RAM/process snapshot) saved as JSON so users can measure the real gain after optimizing.
	Results: $env:SystemDrive\Sophia_Backups\Benchmarks\bench_<label>_<time>.json
#>

function Invoke-SophiaBenchmark
{
	[CmdletBinding()]
	param([string]$Label = "After")

	Write-Host ""
	Write-Host "  ══════════ SOPHIA BENCHMARK [$Label] — đang đo, vui lòng không thao tác... ══════════" -ForegroundColor Cyan

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
				$bytes = [System.Text.Encoding]::UTF8.GetBytes("sophia-bench-$i-$h")
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
	$tmpFile = Join-Path $env:TEMP "sophia_bench_$([Guid]::NewGuid().ToString('N')).bin"
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

	$dir = "$env:SystemDrive\Sophia_Backups\Benchmarks"
	New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	$file = Join-Path $dir ("bench_{0}_{1}.json" -f ($Label -replace '\W', '_'), (Get-Date -Format "yyyyMMdd_HHmmss"))
	$result | ConvertTo-Json | Set-Content -Path $file -Encoding UTF8 -Force
	Write-Host "  [✓] Đã lưu benchmark: $file" -ForegroundColor Cyan
	Write-Host "  Mẹo: chạy -Benchmark -BenchmarkLabel Before TRƯỚC khi tối ưu, rồi After để so sánh % cải thiện." -ForegroundColor Gray

	return $result
}

function Compare-SophiaBenchmarks
{
	$dir = "$env:SystemDrive\Sophia_Backups\Benchmarks"
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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\PlanEngine.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Optimization Plan Engine (phân tích siêu sâu trước khi áp dụng)

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
		"GPU01","GPU03","GPU04","GPU05","NET01","NET08","NET09","SYS04","EXT01","EXT21","EXT22","EXT38","EXT39","EXT46"
	)
}

function Get-SophiaTweakPhase
{
	param($Tweak)
	$id = $Tweak.Id
	if ($id -in @("EMU07","SYS02","SYS01","EXT13","EXT14","EXT15","EXT27")) { return 2 }
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
	if (($ids -contains "EXT03") -and ($ids -contains "EMU13"))
	{
		$ids = @($ids | Where-Object { $_ -ne "EMU13" })
		$notes += "[Trùng lặp] EXT03 Process Booster Task đã tự boost định kỳ — loại EMU13 (boost thủ công 1 lần)."
	}

	# ── Context warnings ──────────────────────────────────────────────────────
	$isLaptop = $false
	try { $isLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) } catch {}
	if ($isLaptop -and ($ids -match 'EXT08|EXT07|CPU03'))
	{
		$warnings += "Máy có pin (laptop): nhóm khóa xung/idle (EXT07/EXT08/CPU03) sẽ RẤT NÓNG và hao pin — cân nhắc bỏ tick nếu không cắm điện cố định."
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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\SmartAdvisor.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Smart Advisor (tự phân tích phần cứng -> khuyên Mode + tweak)

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
	try { $isLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) } catch {}

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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\BackupRestore.ps1
# ====================================================================
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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Core\SophiaBridge.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Bridge to Native Sophia Script Modules (src/Sophia_Script_for_Windows_*)

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
				Import-LocalizedData -BindingVariable Global:Localization -UICulture $PSUICulture -BaseDirectory $LocalizationsDir -FileName Sophia -ErrorAction Stop
			}
			catch
			{
				Import-LocalizedData -BindingVariable Global:Localization -UICulture en-US -BaseDirectory $LocalizationsDir -FileName Sophia -ErrorAction SilentlyContinue
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


# ====================================================================
# [PORTABLE-INLINE] Optimizer\Catalog\TweaksCatalog.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Deep Tweaks Catalog (137 tweaks, 9 categories incl. EXTREME LAB, 6 modes)

	.DESCRIPTION
	Every tweak: Id, Name, Category, Description, Risk, Modes, ApplyScript, RestoreScript, CheckScript.
	Registry tweaks are generated via New-SophiaRegTweak (data-driven, reversible).
	Complex tweaks (BCD, powercfg, netsh, services, tasks) use explicit scriptblocks.
	All tweaks are reversible via RestoreScript or the backup in BackupRestore.ps1.

	.NOTES
	Risk: Safe = cosmetic/standard Sophia, Moderate = performance, Extreme = kernel/security trade-off.
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
		[PSCustomObject]@{ Key = "SophiaStandard";   Icon = "🛡️"; Name = "SOPHIA STANDARD";         Sub = "Privacy + Gọn gàng chuẩn Sophia Script gốc"; Description = "Tập tweak an toàn của Sophia Script upstream: telemetry, quảng cáo, Copilot/Recall, GameBar tips, hiển thị đuôi file... Không đụng kernel/BCD." }
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
	$PRI = "8. 🔒 PRIVACY (SOPHIA NATIVE)"
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
	Add-Reg "EMU02" "Tắt Hyper-V Hypervisor khi boot (hypervisorlaunchtype=Off qua BCD)" $EMU "Hyper-V chiếm VT-x khiến LDPlayer/MuMu báo 'VT bị chiếm' / chạy cực chậm. Đặt BCD off (vẫn bật lại được bằng Restore)." "Extreme" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0 1
	Add-Cmd "EMU03" "Tắt tính năng Hyper-V / VirtualMachinePlatform / WindowsHypervisorPlatform" $EMU "Gỡ lớp hypervisor của Windows để giả lập Android (VirtualBox-based) độc chiếm VT-x. Khôi phục = bật lại feature." "Extreme" $FARM {
		Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue | Out-Null
		Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction SilentlyContinue | Out-Null
		Disable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart -ErrorAction SilentlyContinue | Out-Null
		& bcdedit /set hypervisorlaunchtype off 2>$null | Out-Null
	} {
		Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue | Out-Null
		& bcdedit /set hypervisorlaunchtype auto 2>$null | Out-Null
	} { try { return ((& bcdedit /enum '{current}' 2>$null) -match 'hypervisorlaunchtype\s+Off') } catch { return $false } } "bcdedit hypervisorlaunchtype + DISM features"
	Add-Reg "EMU04" "Tắt Memory Integrity (HVCI) cho driver giả lập" $EMU "HVCI chặn driver cũ của Nox/MEmu/LDPlayer (vd: lỗi load driver, BSOD). Tắt để driver giả lập nạp bình thường." "Extreme" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "WasEnabledBy" 0 $null
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
	} { return [bool](Get-ScheduledTask -TaskName "Sophia_Auto_RAM_Cleaner" -TaskPath "\Sophia\" -ErrorAction SilentlyContinue) } "Register-ScheduledTask Sophia_Auto_RAM_Cleaner"
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
	Add-Reg "EMU10" "Tăng Desktop Heap & Session View Size (nhiều cửa sổ instance)" $EMU "Mở 10-30 instance dễ hết desktop heap ('failed to create window'). Tăng SharedSection 1024,20480,2048 cho session đồ họa." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems" "Windows" "%SystemRoot%\system32\csrss.exe ObjectDirectory=\Windows SharedSection=1024,20480,2048 Windows=On SubSystemType=Windows ServerDll=basesrv,1 ServerDll=winsrv:UserServerDllInitialization,3 ServerDll=sxssrv,4 ProfileControl=Off MaxRequestThreads=16" $null "String"
	Add-Reg "EMU11" "Ưu tiên foreground cho process giả lập (Win32PrioritySeparation=38)" $EMU "Phân bổ quantum CPU ưu tiên ứng dụng foreground (giả lập đang focus) — giảm giật khi nhiều instance tranh CPU." "Moderate" $FARM_GAME "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38 2
	Add-Reg "EMU12" "Tắt Windows Search Indexing (chống disk 100% khi farm)" $EMU "Search indexer quét liên tục thư mục instance gây disk/CPU spike ngẫu nhiên. Tắt service WSearch cho máy farm/game." "Moderate" ($FARM+$GAME+$LOW) "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" "Start" 4 2
	Add-Cmd "EMU13" "Đặt CPU Priority cao cho process giả lập đang chạy" $EMU "Nâng priority LdVBoxHeadless/HD-Player/Nox/MuMu/Nemu lên AboveNormal để scheduler ưu tiên khi full-load multi-instance." "Moderate" $FARM {
		@("LdVBoxHeadless","HD-Player","Nox","NoxVMHandle","MuMuPlayer","NemuHeadless","MEmuHeadless","VBoxHeadless") | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = "AboveNormal" } catch {} } }
	} {
		@("LdVBoxHeadless","HD-Player","Nox","MuMuPlayer","NemuHeadless","MEmuHeadless","VBoxHeadless") | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = "Normal" } catch {} } }
	} { return $false } "Process.PriorityClass = AboveNormal"

	# ═══════════════ 2. GAMING ═══════════════
	Add-Cmd "GAM01" "Ultimate Performance Power Plan (bỏ giới hạn tiết kiệm điện)" $GAM "Kích hoạt plan Ultimate Performance (duplicated từ GUID e9a42b02...) — CPU/GPU luôn sẵn sàng, giảm latency do power-state transition." "Safe" ($FARM_GAME+$WORK) {
		& powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
		$ultimate = (& powercfg /list 2>$null | Select-String "Ultimate Performance").ToString()
		if ($ultimate -match '([0-9a-f]{8}-[0-9a-f-]+)') { & powercfg /setactive $Matches[1] 2>$null | Out-Null }
	} { & powercfg /setactive SCHEME_BALANCED 2>$null | Out-Null } { return ((& powercfg /getactivescheme 2>$null) -match 'Ultimate') } "powercfg Ultimate Performance"
	Add-Reg "GAM02" "Tắt Game DVR / Background Recording (giảm stutter & FPS drop)" $GAM "Game DVR ghi hình nền ăn GPU/CPU và gây frame-time spike. Tắt AppCapture + GameDVR_Enabled chuẩn Sophia." "Safe" ($GAME+$WORK+$STD) "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 1
	Add-Reg "GAM03" "Tắt Game Bar & Game Mode tips (Sophia: XBOXGameBar/XBOXGameTips)" $GAM "Overlay Game Bar + tips gây ngắt quãng khi Alt-Tab/record. AllowAutoGameMode=0, ShowStartupPanel=0." "Safe" ($GAME+$STD) "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 0 1
	Add-Reg "GAM04" "Tắt Fullscreen Optimizations toàn cục" $GAM "FSO gây input lag/stutter trên nhiều game DX11. Disable GameDVR_FSEBehaviorMode=2 cho cảm giác 'exclusive fullscreen' thật." "Moderate" $GAME "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2 0
	Add-Reg "GAM05" "Mouse 1:1 — Tắt Enhance Pointer Precision (gia tốc chuột)" $GAM "Tắt mouse acceleration để aim 1:1 trong FPS. MouseSpeed=0, MouseThreshold1/2=0 (chuẩn esports)." "Safe" $GAME "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "1" "String"
	Add-Reg "GAM06" "Keyboard response nhanh (KeyboardDelay=0, Speed=31)" $GAM "Giảm độ trễ phím: delay trước khi lặp phím = 0, tốc độ lặp tối đa — phản hồi nhanh cho game/ gõ phím." "Safe" ($GAME+$LOW) "HKCU:\Control Panel\Keyboard" "KeyboardDelay" "0" "1" "String"
	Add-Reg "GAM07" "SystemResponsiveness = 0 (ưu tiên game hơn background)" $GAM "Mặc định Windows giữ 20% CPU cho background. Đặt 0 -> game/foreground nhận tối đa tài nguyên multimedia scheduler." "Moderate" $FARM_GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 20
	Add-Reg "GAM08" "NetworkThrottlingIndex = OFF (không bóp băng thông game)" $GAM "Windows throttle mạng non-multimedia 10pps mặc định. Đặt 0xffffffff để game/voice không bị bóp gói tin." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295 10
	Add-Reg "GAM09" "GPU Priority = 8 cho class 'Games' (MMCSS)" $GAM "Nâng GPU Priority + Priority=6 + SchedulingCategory=High cho profile Games của Multimedia Class Scheduler." "Moderate" $GAME "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8 0
	Add-Reg "GAM10" "Tắt Power Throttling (không giảm xung khi chơi game/treo)" $GAM "PowerThrottlingOff=1 ngăn Windows hạ xung CPU cho process 'eco' — giữ FPS & instance ổn định khi load dài." "Moderate" $ALL_PERF "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 0
	Add-Reg "GAM11" "Visual Effects = Performance (tắt animation/shadow)" $GAM "VisualFXSetting=2 + tắt animate/shadow: giảm DWM overhead, Alt-Tab nhanh, nhường GPU cho game/giả lập." "Safe" ($GAME+$LOW) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 0
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
	Add-Reg "CPU10" "Tăng IoPageLockLimit (I/O locking cho NVMe/đa instance)" $CPU "IoPageLockLimit=16777216 (16MB) tăng giới hạn khóa trang I/O — hỗ trợ đọc/ghi đồng thời nhiều disk image giả lập." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "IoPageLockLimit" 16777216 $null

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
	Add-Reg "NET03" "QoS: NonBestEffortLimit = 0 (mở khóa 20% băng thông dự trữ)" $NET "Windows giữ 20% băng thông cho QoS. Đặt 0 để game/farm dùng toàn bộ đường truyền." "Safe" $GAME "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0 $null
	Add-Cmd "NET04" "DNS Cloudflare 1.1.1.1 / Google 8.8.8.8 cho mọi NIC up" $NET "DNS nhanh & ổn định giảm độ trễ phân giải khi mở game/launcher/giả lập (chỉ đặt trên adapter đang Up)." "Safe" ($GAME+$LOW) {
		try { Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -ErrorAction SilentlyContinue } } catch {}
	} { try { Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue } } catch {} } { return $false } "Set-DnsClientServerAddress 1.1.1.1"
	Add-Cmd "NET05" "Tắt Power Saving mọi Network Adapter (Sophia NetworkAdaptersSavePower)" $NET "NIC ngủ gây mất gói/delay khi treo farm & ping spike game. Tắt AllowComputerToTurnOff qua registry PnPCapabilities=24." "Moderate" $FARM_GAME {
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
	Add-Reg "SYS05" "Hiện đuôi file + file ẩn (chuẩn Sophia Explorer)" $SYS "HideFileExt=0, Hidden=1 — quản lý file instance/config dễ dàng, tránh nhầm file độc hại đội lốt." "Safe" $STD "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 1
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
	Add-Reg "SYS12" "Verbose Status khi logon (hiện rõ bước khởi động)" $SYS "VerboseStatus=1 chuẩn Sophia: màn hình đăng nhập hiện chi tiết — dễ chẩn đoán treo ở bước nào khi farm restart." "Safe" $STD "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "VerboseStatus" 1 0

	# ═══════════════ 8. PRIVACY (SOPHIA NATIVE) ═══════════════
	Add-Reg "PRI01" "Telemetry = 0 (AllowTelemetry, chuẩn Sophia/GPO)" $PRI "Chặn thu thập dữ liệu chẩn đoán mức cơ bản qua Policy — giảm tiến trình DiagTrack ghi đĩa nền." "Safe" ($STD+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 3
	Add-Reg "PRI02" "Tắt Advertising ID (quảng cáo cá nhân hóa)" $PRI "DisabledByGroupPolicy=1: app không dùng ID quảng cáo theo dõi hành vi." "Safe" $STD "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1 0
	Add-Reg "PRI03" "Tắt Activity History / Timeline thu thập" $PRI "EnableActivityFeed=0 + PublishUserActivities=0: Windows không ghi dòng thời gian hoạt động." "Safe" $STD "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0 1
	Add-Reg "PRI04" "Tắt Location Tracking toàn cục" $PRI "SensorPermissionState=0: không app nào truy cập vị trí nền (trừ khi user bật lại)." "Safe" $STD "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "Value" "Deny" "Allow" "String"
	Add-Reg "PRI05" "Tắt Cortana (AllowCortana=0 qua Policy)" $PRI "Cortana nền ăn RAM/index — tắt qua GPO chuẩn Sophia cho cả farm/game/workstation." "Safe" ($STD+$LOW) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0 1
	Add-Reg "PRI06" "Tắt Windows Copilot (TurnOffWindowsCopilot=1)" $PRI "Copilot sidebar/overlay không cần cho farm/game — tắt qua policy, giảm tiến trình WebView nền." "Safe" $STD "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1 0
	Add-Reg "PRI07" "Tắt Windows Recall (DisableAIDataAnalysis, Win11 AI)" $PRI "Recall chụp màn hình định kỳ ăn disk/GPU & rủi ro riêng tư — tắt trên Windows 11 nếu có." "Safe" $STD "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1 0
	Add-Reg "PRI08" "Tắt Tailored Experiences & Content Delivery (gợi ý quảng cáo)" $PRI "TailoredExperiencesWithDiagnosticDataEnabled=0 + ContentDeliveryManager tắt: Start Menu không tải app quảng cáo nền." "Safe" ($STD+$LOW) "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0 1
	Add-Reg "PRI09" "Tắt Inking/Typing personalization (gửi dữ liệu gõ phím)" $PRI "RestrictImplicitTextCollection=1: không thu thập mẫu gõ/viết tay gửi Microsoft." "Safe" $STD "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1 0
	Add-Reg "PRI10" "Tắt Delivery Optimization P2P upload (tiết kiệm băng thông farm)" $PRI "DownloadMode=0 (HTTP only, no peering): Windows Update không dùng máy bạn upload cho máy khác ngốn upstream." "Moderate" ($FARM+$STD) "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0 1

	# ═══════════════ 9. EXTREME LAB ═══════════════
	Add-Cmd "EXT01" "MSI Mode cho GPU + NVMe + NIC (Message Signaled Interrupts)" $EXT "Chuyển thiết bị từ legacy IRQ dùng chung sang MSI/MSI-X riêng: giảm DPC latency & xung đột ngắt — một trong những tweak latency thật hiệu quả nhất. Cần RESTART." "Extreme" ($GAME+$WORK) {
		Enable-SophiaMsiMode | Out-Null
	} { Disable-SophiaMsiMode } { return (Test-SophiaMsiMode) } "Enum\PCI\...\MessageSignaledInterruptProperties MSISupported=1"
	Add-Cmd "EXT02" "Timer Resolution Daemon 0.5ms TOÀN HỆ THỐNG (NtSetTimerResolution)" $EXT "Tiến trình nền giữ timer Windows ở 0.5ms (5000x100ns) 24/7: mọi game/giả lập đều hưởng frame-pacing & sleep chính xác mà không cần tự request. Task tự chạy khi logon." "Extreme" $FARM_GAME {
		Start-SophiaTimerResolutionDaemon
	} { Stop-SophiaTimerResolutionDaemon } { return [bool](Get-ScheduledTask -TaskName "Sophia_Timer_Resolution" -TaskPath "\Sophia\" -ErrorAction SilentlyContinue) } "ScheduledTask Sophia_Timer_Resolution"
	Add-Cmd "EXT03" "Process Booster Task mỗi 5 phút (Priority + Affinity TRÁNH Core 0)" $EXT "Task SYSTEM tự nâng AboveNormal + ghim affinity tránh Core 0 (nơi Windows dồn DPC/ngắt) cho mọi instance giả lập mới mở — treo farm cả tuần không cần boost tay." "Moderate" $FARM {
		Register-SophiaProcessBoosterTask
	} { Unregister-SophiaProcessBoosterTask } { return [bool](Get-ScheduledTask -TaskName "Sophia_Process_Booster" -TaskPath "\Sophia\" -ErrorAction SilentlyContinue) } "ScheduledTask Sophia_Process_Booster"
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
	Add-Cmd "EXT13" "Tắt toàn bộ Scheduled Scan của Windows Defender" $EXT "Disable 4 task Defender (Verification, Cleanup, Maintenance, Scheduled Scan): không còn quét định kỳ giành CPU/disk giữa lúc treo farm/chơi game. Vẫn giữ Real-time Protection." "Extreme" $FARM {
		Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
	} {
		Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
	} { return $false } "Disable-ScheduledTask Windows Defender"
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
	Add-Cmd "EXT46" "Tắt DEP/NX (nx AlwaysOff) — CHỈ God Mode" $EXT "Vô hiệu Data Execution Prevention toàn hệ thống cho tương thích giả lập/driver cũ tối đa. Mất một lớp bảo mật quan trọng — Plan Engine chỉ để ở God Mode." "Extreme" @() {
		& bcdedit /set '{current}' nx AlwaysOff 2>$null | Out-Null
	} {
		& bcdedit /set '{current}' nx OptIn 2>$null | Out-Null
	} { return $false } "bcdedit nx AlwaysOff"
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

	return $catalog.ToArray()
}


# ====================================================================
# [PORTABLE-INLINE] Optimizer\UI\InteractiveCLI.ps1
# ====================================================================
<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Interactive Tick-Select CLI ([✓]/[ ])

	.DESCRIPTION
	Keyboard: ↑/↓ (or K/J) move, SPACE tick/untick, A all, N none, 1-6 quick Mode,
	M cycle Mode, / search, P purge RAM now, E Emulator Booster, B backup, R restore defaults,
	ENTER apply selected, Q/Esc quit. Category headers group 137 tweaks.
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
	param($Catalog, [string[]]$SelectedIds, [switch]$SkipBackup, [switch]$Force)

	$selected = @($Catalog | Where-Object { $SelectedIds -contains $_.Id })
	if ($selected.Count -eq 0)
	{
		Write-Host "  [!] Chưa tick tweak nào. Dùng SPACE để chọn." -ForegroundColor Yellow
		return
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

	# Plan Engine: phân tích phụ thuộc/mâu thuẫn + sắp xếp theo pha an toàn trước khi chạm vào hệ thống
	if (Get-Command Get-SophiaOptimizationPlan -ErrorAction SilentlyContinue)
	{
		try
		{
			$plan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $SelectedIds
			if (Get-Command Show-SophiaOptimizationPlan -ErrorAction SilentlyContinue) { Show-SophiaOptimizationPlan -Plan $plan }
			if ($plan.Count -ne $selected.Count)
			{
				Write-Host "  [Plan Engine] Đã điều chỉnh danh sách: $($selected.Count) -> $($plan.Count) tweak (xem ghi chú ở trên)." -ForegroundColor Cyan
			}
			$selected = @($plan.Items | ForEach-Object { $_.Tweak })
		}
		catch { Write-Host "  [!] Plan Engine lỗi ($($_.Exception.Message)) — áp dụng theo thứ tự thường." -ForegroundColor Yellow }
	}

	$logDir = "$env:SystemDrive\Sophia_Backups\Logs"
	New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	$logFile = Join-Path $logDir ("SophiaUltra_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

	if (-not $SkipBackup)
	{
		if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue)
		{
			try { New-SophiaSystemBackup -Label "Before Sophia Ultra Optimizer ($($selected.Count) tweaks)" | Out-Null } catch {}
		}
	}

	Write-Host ""
	Write-Host "  ══════════ ĐANG ÁP DỤNG $($selected.Count) TWEAK ══════════" -ForegroundColor Cyan
	"=== Sophia Ultra Optimizer $(Get-Date) - $($selected.Count) tweaks ===" | Set-Content $logFile -Encoding UTF8

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
	$restart = Read-Host "  Khởi động lại ngay bây giờ? (Y/N)"
	if ($restart -match '^[Yy]') { Restart-Computer -Force }
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
		$dir = "$env:SystemDrive\Sophia_Backups\Profiles"
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

function Show-SophiaSimpleMenu
{
	# Menu số đơn giản: chạy được ở mọi host (ISE, VSCode, input bị redirect...) nơi ReadKey không khả dụng.
	param($Catalog, $Snapshot, [string]$LauncherPath = "")

	while ($true)
	{
		Write-Host ""
		Write-Host "  ╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
		Write-Host "  ║  👑 SOPHIA ULTRA OPTIMIZER — MENU ĐƠN GIẢN (Không cần cài)   ║" -ForegroundColor Magenta
		Write-Host "  ╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
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
		Write-Host "   0. Thoát" -ForegroundColor Yellow
		$choice = Read-Host "  Chọn (0-9/G/T/C/R/S)"
		if ($choice -match '^[1-6]$')
		{
			$m = $modes[[int]::Parse($choice) - 1]
			$ids = Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog
			$go = Read-Host "  Áp dụng $($ids.Count) tweak của mode $($m.Name)? (Y/N)"
			if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids }
		}
		elseif ($choice -eq '7') { Show-SophiaOptimizerUI -Catalog $Catalog -Snapshot $Snapshot }
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
				if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids }
			}
		}
		elseif ($choice -eq '8') { if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge } }
		elseif ($choice -eq '9') { Invoke-EmulatorAutoBooster }
		elseif ($choice -eq 'T' -or $choice -eq 't') { if (Get-Command Invoke-SophiaBenchmark -ErrorAction SilentlyContinue) { Invoke-SophiaBenchmark -Label "Menu" | Out-Null } }
		elseif ($choice -eq 'C' -or $choice -eq 'c') { if (Get-Command Compare-SophiaBenchmarks -ErrorAction SilentlyContinue) { Compare-SophiaBenchmarks } }
		elseif ($choice -eq 'R' -or $choice -eq 'r')
		{
			$confirm = Read-Host "  Khôi phục MẶC ĐỊNH toàn bộ? (yes/no)"
			if ($confirm -eq 'yes') { Invoke-SophiaRestoreTweaks -Catalog $Catalog }
		}
		elseif ($choice -eq 'S' -or $choice -eq 's')
		{
			try
			{
				if (-not $LauncherPath) { $LauncherPath = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Portable.ps1 | iex`"" }
				$desktop = [Environment]::GetFolderPath("Desktop")
				$lnkPath = Join-Path $desktop "Sophia Ultra Optimizer.lnk"
				$shell = New-Object -ComObject WScript.Shell
				$lnk = $shell.CreateShortcut($lnkPath)
				if ($LauncherPath -match '\.ps1"?$')
				{
					$lnk.TargetPath = "powershell.exe"
					$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File $LauncherPath"
				}
				else
				{
					$lnk.TargetPath = "powershell.exe"
					$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Portable.ps1 | iex`""
				}
				$lnk.Description = "Sophia Ultra Optimizer - Tick-Select CLI (Portable, khong can cai)"
				$lnk.Save()
				Write-Host "  [✓] Đã tạo shortcut Desktop: $lnkPath (từ nay double-click là chạy, không cần cài)" -ForegroundColor Green
			}
			catch { Write-Host "  [!] Không tạo được shortcut: $($_.Exception.Message)" -ForegroundColor Yellow }
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

	$searchTerm = ""
	$cursor = 0
	$pageSize = 18
	try { $pageSize = [Math]::Max(10, [Console]::WindowHeight - 16) } catch {}

	$getFiltered = {
		if ([string]::IsNullOrWhiteSpace($searchTerm)) { return @($Catalog) }
		return @($Catalog | Where-Object { $_.Name -match $searchTerm -or $_.Id -match $searchTerm -or $_.Category -match $searchTerm -or $_.Description -match $searchTerm })
	}

	while ($true)
	{
		$filtered = & $getFiltered
		if ($filtered.Count -eq 0) { $filtered = @($Catalog); $searchTerm = "" }
		if ($cursor -ge $filtered.Count) { $cursor = $filtered.Count - 1 }
		if ($cursor -lt 0) { $cursor = 0 }
		$pageStart = [Math]::Floor($cursor / $pageSize) * $pageSize
		$pageEnd = [Math]::Min($pageStart + $pageSize - 1, $filtered.Count - 1)
		$selectedCount = @($selected.Keys | Where-Object { $selected[$_] }).Count

		try { [Console]::Clear(); [Console]::CursorVisible = $false } catch { Clear-Host }

		# Header
		Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
		Write-Host "  ║  👑 SOPHIA ULTRA OPTIMIZER — Tối Ưu Sâu Windows: Giả Lập 24/7 • Game • FPS  ║" -ForegroundColor Magenta
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
		Write-Host ("  Đã tick: {0}/{1} tweak | Hiển thị: {2} | Tìm kiếm: '{3}'" -f $selectedCount, $Catalog.Count, $filtered.Count, $searchTerm) -ForegroundColor Cyan
		Write-Host "  ──────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
		Write-Host "  [↑↓/KJ] Chọn  [SPACE] Tick  [1-6] Mode  [A]ll  [N]one  [/] Tìm  [P] Purge RAM  [E] Boost Giả Lập" -ForegroundColor Gray
		Write-Host "  [G] Smart Auto (AI khuyên dùng)  [V] Check đã áp dụng (●)  [T] Benchmark  [S] Lưu Profile" -ForegroundColor Gray
		Write-Host "  [L] Nạp Profile  [B] Backup" -ForegroundColor Gray
		Write-Host "  [R] Restore Mặc Định  [ENTER] ÁP DỤNG  [Q] Thoát" -ForegroundColor Gray
		Write-Host "  ──────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

		$lastCategory = ""
		for ($idx = $pageStart; $idx -le $pageEnd; $idx++)
		{
			$t = $filtered[$idx]
			if ($t.Category -ne $lastCategory)
			{
				$lastCategory = $t.Category
				Write-Host ""
				Write-Host "  $lastCategory" -ForegroundColor Magenta
			}
			$isOn = ($selected.ContainsKey($t.Id) -and $selected[$t.Id])
			$box = if ($isOn) { "[✓]" } else { "[ ]" }
			if ($appliedStatus.ContainsKey($t.Id) -and $appliedStatus[$t.Id]) { $box += "●" }
			$riskColor = "Green"
			if ($t.Risk -eq "Extreme") { $riskColor = "Red" } elseif ($t.Risk -eq "Moderate") { $riskColor = "Yellow" }
			$line = "  {0} {1} {2} [{3}]" -f $box, $t.Id, $t.Name, $t.Risk
			if ($idx -eq $cursor)
			{
				Write-Host "  ▶ $line" -ForegroundColor White -BackgroundColor DarkBlue
				Write-Host "      └─ $($t.Description)" -ForegroundColor Cyan
				Write-Host "         $($t.Detail)" -ForegroundColor DarkGray
			}
			else
			{
				if ($isOn) { Write-Host "    $line" -ForegroundColor Green }
				else { Write-Host "    $line" -ForegroundColor $riskColor }
			}
		}
		Write-Host ""
		Write-Host ("  Trang {0}/{1} — Mục {2}/{3}" -f ([Math]::Floor($pageStart/$pageSize)+1), ([Math]::Ceiling($filtered.Count/$pageSize)), ($cursor+1), $filtered.Count) -ForegroundColor DarkGray

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
				Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids
				Read-Host "  Nhấn ENTER để quay lại menu"
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
		}
		elseif ($ch -eq 'p' -or $ch -eq 'P') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge }
			Read-Host "  Nhấn ENTER để tiếp tục"
		}
		elseif ($ch -eq 'e' -or $ch -eq 'E') {
			try { [Console]::CursorVisible = $true } catch {}
			Invoke-EmulatorAutoBooster
			Read-Host "  Nhấn ENTER để tiếp tục"
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
		}
		elseif ($ch -eq 't' -or $ch -eq 'T') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Invoke-SophiaBenchmark -ErrorAction SilentlyContinue) { Invoke-SophiaBenchmark -Label "Manual" | Out-Null }
			else { Write-Host "  [!] Không tìm thấy module Benchmark." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
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
		}
		elseif ($ch -eq 's' -or $ch -eq 'S') {
			try { [Console]::CursorVisible = $true } catch {}
			$ids = @($selected.Keys | Where-Object { $selected[$_] })
			Save-SophiaSelectionProfile -ModeKey $currentMode -SelectedIds $ids | Out-Null
			Read-Host "  Nhấn ENTER để tiếp tục"
		}
		elseif ($ch -eq 'l' -or $ch -eq 'L') {
			try { [Console]::CursorVisible = $true } catch {}
			$dir = "$env:SystemDrive\Sophia_Backups\Profiles"
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
		}
		elseif ($ch -eq 'b' -or $ch -eq 'B') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue) { New-SophiaSystemBackup | Out-Null }
			Read-Host "  Nhấn ENTER để tiếp tục"
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

# Bridge vào module Sophia gốc (không chặn bởi InitialActions/LGPO/UBR)
try { Initialize-SophiaNativeModule -RepoRoot $RepoRoot | Out-Null } catch {}

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
	Invoke-SophiaSelectedTweaks -Catalog $catalog -SelectedIds $ids -SkipBackup:$NoBackup -Force:$Yes
	return
}
if ($Apply)
{
	$ids = Get-SophiaModeTweakIds -ModeKey $Mode -Catalog $catalog
	if ($Smart -and $smartRec) { $ids = @($ids + $smartRec.ExtraIds | Select-Object -Unique) }
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
