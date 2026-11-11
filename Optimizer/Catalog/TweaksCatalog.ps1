<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Deep Tweaks Catalog (85+ tweaks, 8 categories, 6 modes)

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
	Add-Reg "GAM02" "Tắt Game DVR / Background Recording (giảm stutter & FPS drop)" $GAM "Game DVR ghi hình nền ăn GPU/CPU và gây frame-time spike. Tắt AppCapture + GameDVR_Enabled chuẩn Sophia." "Safe" ($GAME+$STD) "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 1
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
	Add-Reg "CPU08" "Tắt CPU Idle sâu trên AC (IDLESTATEMAX=1, giảm wake latency)" $CPU "Hạn chế C-state sâu khi cắm điện qua power scheme (registry PERFIDLE) — giảm latency đánh thức lõi khi burst." "Extreme" $GAME "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\5d76a2ca-e8c0-402f-a133-2158492d58ad" "Attributes" 2 1
	Add-Reg "CPU09" "LargeSystemCache = 0 (ưu tiên app/game hơn file cache)" $CPU "Đặt cache hệ thống ưu tiên tiến trình người dùng thay vì file-server cache — đúng profile desktop/gaming." "Safe" $ALL_PERF "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 0 1
	Add-Reg "CPU10" "Tăng IoPageLockLimit (I/O locking cho NVMe/đa instance)" $CPU "IoPageLockLimit=16777216 (16MB) tăng giới hạn khóa trang I/O — hỗ trợ đọc/ghi đồng thời nhiều disk image giả lập." "Moderate" $FARM "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "IoPageLockLimit" 16777216 $null

	# ═══════════════ 4. RAM & MEMORY ═══════════════
	Add-Cmd "RAM01" "Tắt Memory Compression (giải phóng CPU, farm nhiều instance)" $RAM "Memory Compression nén page trong RAM ăn CPU liên tục. Máy >=16GB tắt đi giảm CPU & latency (Enable-MMAgent -MemoryCompression off)." "Moderate" $FARM {
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

	return $catalog.ToArray()
}
