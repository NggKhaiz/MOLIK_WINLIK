<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Interactive Tick-Select CLI ([✓]/[ ])

	.DESCRIPTION
	Keyboard: ↑/↓ (or K/J) move, SPACE tick/untick, A all, N none, 1-6 quick Mode,
	M cycle Mode, / search, P purge RAM now, E Emulator Booster, B backup, R restore defaults,
	ENTER apply selected, Q/Esc quit. Category headers group 162 tweaks.
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
		Write-Host "   A. 📦 Cài ứng dụng qua winget (kiểu winutil, 239 app)" -ForegroundColor Green
		Write-Host "   0. Thoát" -ForegroundColor Yellow
		$choice = Read-Host "  Chọn (0-9/G/A/T/C/R/S)"
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
		elseif ($choice -eq 'A' -or $choice -eq 'a') { if (Get-Command Show-SophiaAppInstallerMenu -ErrorAction SilentlyContinue) { Show-SophiaAppInstallerMenu } }
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
