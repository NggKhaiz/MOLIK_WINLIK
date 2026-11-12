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
	$ver = if ($Global:MolikWinlikVersion) { $Global:MolikWinlikVersion } else { "3.0.0" }
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
