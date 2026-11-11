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
