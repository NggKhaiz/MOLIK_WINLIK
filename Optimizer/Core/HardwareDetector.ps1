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
