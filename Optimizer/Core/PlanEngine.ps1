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
	if ($id -in @("EMU07","SYS02","SYS01","EXT14","EXT15","EXT27")) { return 2 }
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
