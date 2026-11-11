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
