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
	$ver = if ($Global:MolikWinlikVersion) { $Global:MolikWinlikVersion } else { "4.0.0" }
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
