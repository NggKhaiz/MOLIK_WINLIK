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
