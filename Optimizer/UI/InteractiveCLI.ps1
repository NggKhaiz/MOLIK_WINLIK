<#
	.SYNOPSIS
	MOLIK WINLIK - Interactive Tick-Select CLI ([✓]/[ ])

	.DESCRIPTION
	Keyboard: ↑/↓ (or K/J) move, SPACE tick/untick, A all, N none, 1-6 quick Mode,
	M cycle Mode, / search, P purge RAM now, E Emulator Booster, B backup, R restore defaults,
	ENTER apply selected, Q/Esc quit. Category headers group all catalog tweaks.
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
	param($Catalog, [string[]]$SelectedIds, [switch]$SkipBackup, [switch]$Force, $Snapshot = $null, [switch]$NoRestartPrompt)

	$selected = @($Catalog | Where-Object { $SelectedIds -contains $_.Id })
	if ($selected.Count -eq 0)
	{
		Write-Host "  [!] Chưa tick tweak nào. Dùng SPACE để chọn." -ForegroundColor Yellow
		return
	}

	# Plan Engine: phân tích phụ thuộc/mâu thuẫn + sắp xếp theo pha an toàn trước khi chạm vào hệ thống
	if (Get-Command Get-SophiaOptimizationPlan -ErrorAction SilentlyContinue)
	{
		try
		{
			$plan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $SelectedIds -Snapshot $Snapshot
			if (Get-Command Show-SophiaOptimizationPlan -ErrorAction SilentlyContinue) { Show-SophiaOptimizationPlan -Plan $plan }
			if ($plan.Count -ne $selected.Count)
			{
				Write-Host "  [Plan Engine] Đã điều chỉnh danh sách: $($selected.Count) -> $($plan.Count) tweak (xem ghi chú ở trên)." -ForegroundColor Cyan
			}
			$selected = @($plan.Items | ForEach-Object { $_.Tweak })
		}
		catch { Write-Host "  [!] Plan Engine lỗi ($($_.Exception.Message)) — áp dụng theo thứ tự thường." -ForegroundColor Yellow }
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

	$logDir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Logs"
	New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	$logFile = Join-Path $logDir ("MOLIK_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

	if (-not $SkipBackup)
	{
		if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue)
		{
			try { New-SophiaSystemBackup -Label "Before MOLIK WINLIK ($($selected.Count) tweaks)" | Out-Null } catch {}
		}
	}

	Write-Host ""
	Write-Host "  Áp dụng $($selected.Count) tweak" -ForegroundColor White
	"=== MOLIK WINLIK $(Get-Date) - $($selected.Count) tweaks ===" | Set-Content $logFile -Encoding UTF8

	# Danh dau "phien dang chay": neu tien trinh bi tat giua chung (mat dien,
	# treo may), marker con lai de Doctor canh bao + huong dan Undo o lan mo sau.
	$sessionMarker = Join-Path $logDir "session_in_progress.json"
	try { (@{ StartedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); TweakCount = $selected.Count; LogFile = $logFile } | ConvertTo-Json) | Set-Content $sessionMarker -Encoding UTF8 -Force } catch {}

	# Pre-scan (chi doc): bao nhieu tweak da o trang thai dich tu truoc
	$alreadyApplied = 0
	foreach ($tweak in $selected) { try { if (& $tweak.CheckScript) { $alreadyApplied++ } } catch {} }
	if ($alreadyApplied -gt 0) { Write-Host "  $alreadyApplied/$($selected.Count) tweak đã ở trạng thái đích từ trước (vẫn áp lại để đồng bộ)." -ForegroundColor DarkGray }

	$ok = 0; $fail = 0; $verifiedCount = 0; $unverifiedCount = 0
	foreach ($tweak in $selected)
	{
		Write-Host ("  [{0}] {1} ... " -f $tweak.Id, $tweak.Name) -NoNewline
		try
		{
			& $tweak.ApplyScript
			# Post-verify: chay lai CheckScript de xac nhan trang thai that,
			# khong chi dua vao viec Apply khong nem loi (registry ghi that bai
			# thuong bi nuot am tham boi SilentlyContinue).
			$isVerified = $false
			try { $isVerified = [bool](& $tweak.CheckScript) } catch {}
			if ($isVerified)
			{
				Write-Host "OK" -ForegroundColor Green
				"OK   $($tweak.Id) $($tweak.Name) [verified]" | Add-Content $logFile -Encoding UTF8
				$verifiedCount++
			}
			else
			{
				Write-Host "OK (unverified)" -ForegroundColor Yellow
				"OK   $($tweak.Id) $($tweak.Name) [unverified]" | Add-Content $logFile -Encoding UTF8
				$unverifiedCount++
			}
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
	Write-Host "  Hoàn tất: $ok OK ($verifiedCount verified, $unverifiedCount unverified) / $fail FAIL — Log: $logFile" -ForegroundColor Cyan
	try { Remove-Item $sessionMarker -Force -ErrorAction SilentlyContinue } catch {}
	Write-Host "  [!] Nhiều tweak (HAGS, VBS, BCD, Pagefile) cần RESTART để có hiệu lực." -ForegroundColor Yellow
	if (-not $Force -and -not $NoRestartPrompt)
	{
		$restart = Read-Host "  Khởi động lại ngay bây giờ? (Y/N)"
		if ($restart -match '^[Yy]') { Restart-Computer -Force }
	}
	else
	{
		Write-Host "  (Che do tu dong: bo qua hoi restart - hay khoi dong lai may khi tien.)" -ForegroundColor DarkGray
	}
}

function Invoke-SophiaRestoreTweaks
{
	param($Catalog, [switch]$NoPause)
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
	if (-not $NoPause) { Read-Host "  Nhấn ENTER để quay lại menu" }
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
		$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Profiles"
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

function Get-MolikUiVersion
{
	if ($Global:MolikWinlikVersion) { return [string]$Global:MolikWinlikVersion }
	return "4.1.0"
}

function Format-MolikTruncate
{
	param([string]$Text, [int]$Max = 80)
	if ([string]::IsNullOrEmpty($Text)) { return "" }
	if ($Max -lt 8) { $Max = 8 }
	if ($Text.Length -le $Max) { return $Text }
	return $Text.Substring(0, $Max - 3) + "..."
}

function Get-MolikRiskBadge
{
	param([string]$Risk)
	switch ($Risk)
	{
		"Extreme"  { return "EXT" }
		"Moderate" { return "MOD" }
		default    { return "" }
	}
}

function Format-MolikCategoryName
{
	param([string]$Category)
	if ([string]::IsNullOrWhiteSpace($Category)) { return "" }
	$name = $Category -replace '^\s*\d+\.\s*', ''
	$name = $name -replace '[\uD800-\uDBFF][\uDC00-\uDFFF]', ''
	$name = $name -replace '\uFE0F', ''
	return ($name -replace '\s+', ' ').Trim()
}

function Show-SophiaSimpleMenu
{
	# Menu số đơn giản: chạy được ở mọi host (ISE, VSCode, input bị redirect...) nơi ReadKey không khả dụng.
	param($Catalog, $Snapshot, [string]$LauncherPath = "")

	while ($true)
	{
		Write-Host ""
		Write-Host " MOLIK WINLIK v$(Get-MolikUiVersion)" -ForegroundColor White
		if ($Snapshot)
		{
			Write-Host (" {0} · RAM {1} GB · Admin: {2}{3}" -f $Snapshot.OSName, $Snapshot.RAMTotalGB, $Snapshot.IsAdmin, $(if ($Snapshot.PendingReboot) { " · restart pending" } else { "" })) -ForegroundColor DarkGray
			if ($Snapshot.InstalledEmulators -and $Snapshot.InstalledEmulators.Count -gt 0) { Write-Host (" Emulators: {0}" -f ($Snapshot.InstalledEmulators -join ", ")) -ForegroundColor DarkGray }
		}
		Write-Host ""
		$modes = Get-SophiaOptimizationModes
		for ($i = 0; $i -lt $modes.Count; $i++)
		{
			$m = $modes[$i]
			$cnt = (Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog).Count
			Write-Host ("  {0}  {1} ({2}) — {3}" -f ($i + 1), $m.Name, $cnt, (Format-MolikTruncate $m.Sub 60)) -ForegroundColor Gray
		}
		Write-Host ""
		Write-Host "  7  Tick-select UI     G  Smart Auto       8  Purge RAM" -ForegroundColor Gray
		Write-Host "  9  Boost emulators  T  Benchmark        C  Compare benchmarks" -ForegroundColor Gray
		Write-Host "  A  Install apps     X  Presets          H  HTML report" -ForegroundColor Gray
		Write-Host "  B  Backup           U  Undo session     R  Restore defaults" -ForegroundColor Gray
		Write-Host "  S  Desktop shortcut D  Self-test        K  Doctor           0  Exit" -ForegroundColor Gray
		$choice = Read-Host "  Chọn (0-9/G/A/T/C/R/S/D/X/H/B/U/K)"
		if ($choice -match '^[1-6]$')
		{
			$m = $modes[[int]::Parse($choice) - 1]
			$ids = Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog
			$go = Read-Host "  Áp dụng $($ids.Count) tweak của mode $($m.Name)? (Y/N)"
			if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids -Snapshot $Snapshot }
		}
		elseif ($choice -eq '7')
		{
			try { Show-SophiaOptimizerUI -Catalog $Catalog -Snapshot $Snapshot }
			catch { Write-Host "  [!] Host này không hỗ trợ giao diện phím trực tiếp ($($_.Exception.Message)) — hãy dùng các mục số trong Menu này." -ForegroundColor Yellow }
		}
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
				if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids -Snapshot $Snapshot }
			}
		}
		elseif ($choice -eq '8') { if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge } }
		elseif ($choice -eq 'A' -or $choice -eq 'a') { if (Get-Command Show-SophiaAppInstallerMenu -ErrorAction SilentlyContinue) { Show-SophiaAppInstallerMenu } }
		elseif ($choice -eq 'D' -or $choice -eq 'd') { if (Get-Command Test-SophiaOptimizerHealth -ErrorAction SilentlyContinue) { Test-SophiaOptimizerHealth -Catalog $Catalog | Out-Null; Read-Host '  Nhấn ENTER để quay lại menu' } }
		elseif ($choice -eq '9') { Invoke-EmulatorAutoBooster }
		elseif ($choice -eq 'T' -or $choice -eq 't') { if (Get-Command Invoke-SophiaBenchmark -ErrorAction SilentlyContinue) { Invoke-SophiaBenchmark -Label "Menu" | Out-Null } }
		elseif ($choice -eq 'C' -or $choice -eq 'c') { if (Get-Command Compare-SophiaBenchmarks -ErrorAction SilentlyContinue) { Compare-SophiaBenchmarks } }
		elseif ($choice -eq 'R' -or $choice -eq 'r')
		{
			$confirm = Read-Host "  Khôi phục MẶC ĐỊNH toàn bộ? (yes/no)"
			if ($confirm -eq 'yes') { Invoke-SophiaRestoreTweaks -Catalog $Catalog }
			$firstFrame = $true
		}
		elseif ($choice -eq 'S' -or $choice -eq 's')
		{
			try
			{
				$desktop = [Environment]::GetFolderPath("Desktop")
				$lnkPath = Join-Path $desktop "MOLIK WINLIK.lnk"
				$shell = New-Object -ComObject WScript.Shell
				$lnk = $shell.CreateShortcut($lnkPath)
				# OFFLINE: shortcut tro thang vao file local (uu tien MOLIK_WINLIK.bat canh launcher)
				$batPath = Join-Path (Get-Location).Path "MOLIK_WINLIK.bat"
				if ($LauncherPath -and (Split-Path $LauncherPath -Parent)) { $batPath = Join-Path (Split-Path $LauncherPath -Parent) "MOLIK_WINLIK.bat" }
				if (Test-Path $batPath)
				{
					$lnk.TargetPath = $batPath
					$lnk.Arguments = ""
				}
				elseif ($LauncherPath -match '\.ps1"?$')
				{
					$lnk.TargetPath = "powershell.exe"
					$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$LauncherPath`""
				}
				else
				{
					Write-Host "  [!] Không tìm thấy MOLIK_WINLIK.bat / file launcher local để tạo shortcut." -ForegroundColor Yellow
					continue
				}
				$lnk.Description = "MOLIK WINLIK - Tick-Select CLI (Portable, khong can cai)"
				$lnk.Save()
				Write-Host "  [✓] Đã tạo shortcut Desktop: $lnkPath (từ nay double-click là chạy, không cần cài)" -ForegroundColor Green
			}
			catch { Write-Host "  [!] Không tạo được shortcut: $($_.Exception.Message)" -ForegroundColor Yellow }
		}
		elseif ($choice -eq 'X' -or $choice -eq 'x')
		{
			if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue)
			{
				$presets = @(Get-MolikPresets)
				for ($i = 0; $i -lt $presets.Count; $i++)
				{
					$resolved = Resolve-MolikPreset -Preset $presets[$i] -Catalog $Catalog
					Write-Host ("   {0}. {1} {2} ({3} tweak)" -f ($i + 1), $presets[$i].Icon, $presets[$i].Title, $resolved.Count) -ForegroundColor Cyan
					Write-Host "      $($presets[$i].Description)" -ForegroundColor Gray
				}
				$pick = Read-Host "  Chọn Preset (1-$($presets.Count), ENTER = quay lại)"
				if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $presets.Count)
				{
					$chosen = $presets[[int]$pick - 1]
					$presetIds = Resolve-MolikPreset -Preset $chosen -Catalog $Catalog
					if (Get-Command Get-SophiaOptimizationPlan -ErrorAction SilentlyContinue)
					{
						$presetPlan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $presetIds -Snapshot $Snapshot
						Show-SophiaOptimizationPlan -Plan $presetPlan -Title "KE HOACH PRESET $($chosen.Name)"
					}
					$go = Read-Host "  Áp dụng $($presetIds.Count) tweak của Preset $($chosen.Title)? (Y/N)"
					if ($go -match '^[Yy]') { Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $presetIds -Snapshot $Snapshot }
				}
			}
		}
		elseif ($choice -eq 'H' -or $choice -eq 'h')
		{
			if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue)
			{
				Write-Host "  Đang kiểm tra trạng thái tweak và xuất báo cáo HTML..." -ForegroundColor Cyan
				Export-MolikHtmlReport -Snapshot $Snapshot -Catalog $Catalog | Out-Null
				Read-Host '  Nhấn ENTER để quay lại menu'
			}
		}
		elseif ($choice -eq 'B' -or $choice -eq 'b')
		{
			if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue) { New-SophiaSystemBackup | Out-Null; Read-Host '  Nhấn ENTER để quay lại menu' }
		}
		elseif ($choice -eq 'K' -or $choice -eq 'k')
		{
			if (Get-Command Show-MolikSystemDoctor -ErrorAction SilentlyContinue) { Show-MolikSystemDoctor -Snapshot $Snapshot -Catalog $Catalog; Read-Host '  Nhấn ENTER để quay lại menu' }
		}
		elseif ($choice -eq 'U' -or $choice -eq 'u')
		{
			if (Get-Command Restore-MolikLastSession -ErrorAction SilentlyContinue) { Restore-MolikLastSession -Catalog $Catalog | Out-Null }
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
	$tabLabels = @{ EmulatorFarm = "Farm"; HardcoreGaming = "Gaming"; Workstation = "Workstation"; LowSpec = "LowSpec"; SophiaStandard = "Standard"; GodMode = "GodMode" }
	$currentMode = $InitialMode

	$selected = @{}
	foreach ($id in (Get-SophiaModeTweakIds -ModeKey $currentMode -Catalog $Catalog)) { $selected[$id] = $true }

	# Trang thai da ap dung (phim V de quet)
	$appliedStatus = @{}
	$smartRec = $null
	try { if (Get-Command Get-SophiaSmartRecommendation -ErrorAction SilentlyContinue) { $smartRec = Get-SophiaSmartRecommendation -Snapshot $Snapshot -Catalog $Catalog } } catch {}

	$searchTerm = ""
	$filterMode = "All"
	$firstFrame = $true
	$lastFrameLines = 0
	$rebootIds = @()
	try { if (Get-Command Get-SophiaRebootTweakIds -ErrorAction SilentlyContinue) { $rebootIds = @(Get-SophiaRebootTweakIds) } } catch {}
	$cursor = 0
	$pageSize = 18

	$getFiltered = {
		$list = @($Catalog)
		if (-not [string]::IsNullOrWhiteSpace($searchTerm))
		{
			$term = $searchTerm.ToLower()
			$list = @($list | Where-Object { $_.Name.ToLower().Contains($term) -or $_.Id.ToLower().Contains($term) -or $_.Category.ToLower().Contains($term) -or $_.Description.ToLower().Contains($term) })
		}
		if ($filterMode -eq "Selected") { $list = @($list | Where-Object { $selected.ContainsKey($_.Id) -and $selected[$_.Id] }) }
		elseif ($filterMode -eq "Extreme") { $list = @($list | Where-Object { $_.Risk -eq "Extreme" }) }
		elseif ($filterMode -eq "NotApplied") { $list = @($list | Where-Object { -not ($appliedStatus.ContainsKey($_.Id) -and $appliedStatus[$_.Id]) }) }
		return $list
	}

	while ($true)
	{
		$width = 100
		try { $width = [Console]::WindowWidth } catch {}
		if ($width -lt 60) { $width = 60 }
		try { $pageSize = [Math]::Max(8, [Console]::WindowHeight - 9) } catch {}
		$filtered = & $getFiltered
		if ($filtered.Count -eq 0) { $filtered = @($Catalog); $searchTerm = ""; $filterMode = "All" }
		if ($cursor -ge $filtered.Count) { $cursor = $filtered.Count - 1 }
		if ($cursor -lt 0) { $cursor = 0 }
		$pageStart = [Math]::Floor($cursor / $pageSize) * $pageSize
		$pageEnd = [Math]::Min($pageStart + $pageSize - 1, $filtered.Count - 1)
		$selectedCount = @($selected.Keys | Where-Object { $selected[$_] }).Count
		$appliedKnown = @($appliedStatus.Keys | Where-Object { $appliedStatus[$_] }).Count

		try
		{
			if ($firstFrame) { [Console]::Clear(); $firstFrame = $false; $lastFrameLines = 0 }
			else { [Console]::SetCursorPosition(0, 0) }
			[Console]::CursorVisible = $false
		} catch { Clear-Host; $lastFrameLines = 0 }

		# ── Header (3 dong): tieu de / tab Mode + trang thai / gach ngang ──
		$titleLeft = " MOLIK WINLIK"
		$titleVer = " v$(Get-MolikUiVersion)"
		$titleRight = ""
		if ($Snapshot)
		{
			$titleRight = "{0} · RAM {1} GB" -f $Snapshot.OSName, $Snapshot.RAMTotalGB
			if ($Snapshot.PendingReboot) { $titleRight += " · restart pending" }
			$titleRight = Format-MolikTruncate $titleRight 44
		}
		Write-Host $titleLeft -ForegroundColor White -NoNewline
		Write-Host $titleVer -ForegroundColor DarkGray -NoNewline
		if ($titleRight)
		{
			$usedWidth = $titleLeft.Length + $titleVer.Length + $titleRight.Length
			if ($usedWidth -lt ($width - 2)) { Write-Host (" " * ($width - 2 - $usedWidth)) -NoNewline }
			Write-Host $titleRight -ForegroundColor DarkGray -NoNewline
		}
		Write-Host ""

		$tabsLen = 1
		for ($i = 0; $i -lt $modes.Count; $i++)
		{
			$m = $modes[$i]
			$label = $tabLabels[$m.Key]
			if (-not $label) { $label = $m.Key }
			$tabText = " $($i + 1) $label "
			$tabsLen += $tabText.Length + 1
			if ($m.Key -eq $currentMode) { Write-Host $tabText -ForegroundColor White -BackgroundColor DarkCyan -NoNewline }
			else { Write-Host $tabText -ForegroundColor DarkGray -NoNewline }
			Write-Host " " -NoNewline
		}
		$status = " {0}/{1} selected" -f $selectedCount, $Catalog.Count
		if ($appliedKnown -gt 0) { $status += " · $appliedKnown applied" }
		if ($smartRec) { $status += " · G Smart: $($tabLabels[$smartRec.Mode])" }
		if ($filterMode -ne "All") { $status += " · filter: $filterMode" }
		if ($searchTerm) { $status += " · search: '$searchTerm'" }
		Write-Host (Format-MolikTruncate $status ([Math]::Max(10, $width - $tabsLen - 1))) -ForegroundColor DarkGray

		$rule = " " + ("─" * ($width - 2))
		Write-Host $rule -ForegroundColor DarkGray

		# ── Danh sach (1 dong/tweak, cot thang hang) ──
		$listLines = 0
		$lastCategory = ""
		for ($idx = $pageStart; $idx -le $pageEnd; $idx++)
		{
			$t = $filtered[$idx]
			if ($t.Category -ne $lastCategory)
			{
				$lastCategory = $t.Category
				Write-Host (" " + (Format-MolikCategoryName $t.Category)) -ForegroundColor DarkCyan
				$listLines++
			}
			$isOn = ($selected.ContainsKey($t.Id) -and $selected[$t.Id])
			$box = if ($isOn) { "[x]" } else { "[ ]" }
			if ($appliedStatus.ContainsKey($t.Id) -and $appliedStatus[$t.Id]) { $box += "●" }
			$mark = if ($idx -eq $cursor) { ">" } else { " " }
			$badge = Get-MolikRiskBadge $t.Risk
			$badgeCol = if ($badge) { " " + $badge } else { "" }
			$prefix = " $mark $box $($t.Id.PadRight(6)) "
			$nameMax = [Math]::Max(16, $width - $prefix.Length - $badgeCol.Length - 1)
			$row = $prefix + (Format-MolikTruncate $t.Name $nameMax).PadRight($nameMax) + $badgeCol
			if ($idx -eq $cursor)
			{
				Write-Host $row.PadRight($width - 1) -ForegroundColor White -BackgroundColor DarkBlue
			}
			elseif ($isOn) { Write-Host $row -ForegroundColor White }
			else { Write-Host $row -ForegroundColor Gray }
			$listLines++
		}
		if ($filtered.Count -eq 0)
		{
			Write-Host " (no tweaks)" -ForegroundColor DarkGray
			$listLines++
		}

		# ── Panel chi tiet co dinh (2 dong) + thanh phim tat (1 dong) ──
		Write-Host $rule -ForegroundColor DarkGray
		$cur = $null
		if ($filtered.Count -gt 0) { $cur = $filtered[$cursor] }
		if ($cur)
		{
			Write-Host (" " + (Format-MolikTruncate $cur.Description ($width - 3))) -ForegroundColor Gray
			$detailLine = $cur.Detail
			if ($rebootIds -contains $cur.Id) { $detailLine += " · Restart required" }
			Write-Host (" " + (Format-MolikTruncate $detailLine ($width - 3))) -ForegroundColor DarkGray
		}
		else
		{
			Write-Host " " -ForegroundColor Gray
			Write-Host " " -ForegroundColor DarkGray
		}
		$keys = " Enter apply · Space toggle · ↑↓ move · 1-6 mode · / search · F filter · ? help · Q quit"
		$pageInfo = "{0}/{1} · page {2}/{3} " -f ($cursor + 1), $filtered.Count, ([Math]::Floor($pageStart / $pageSize) + 1), ([Math]::Ceiling($filtered.Count / $pageSize))
		$footer = $keys
		$padFooter = $width - 1 - $keys.Length - $pageInfo.Length
		if ($padFooter -ge 2) { $footer = $keys + (" " * $padFooter) + $pageInfo }
		else { $footer = (Format-MolikTruncate $keys ([Math]::Max(20, $width - 1 - $pageInfo.Length))) + $pageInfo }
		Write-Host (Format-MolikTruncate $footer ($width - 1)) -ForegroundColor DarkGray

		# Xoa phan du cua khung hinh truoc (dai hon) de khong con "rac" phia duoi
		$frameLines = 7 + $listLines
		if ($frameLines -lt $lastFrameLines)
		{
			$padLine = " " * [Math]::Max(10, $width - 1)
			for ($pad = $frameLines; $pad -lt $lastFrameLines; $pad++) { Write-Host $padLine }
			try { [Console]::SetCursorPosition(0, 0) } catch {}
		}
		$lastFrameLines = $frameLines

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
				Invoke-SophiaSelectedTweaks -Catalog $Catalog -SelectedIds $ids -Snapshot $Snapshot
				Read-Host "  Nhấn ENTER để quay lại menu"
				$firstFrame = $true
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
			$firstFrame = $true
		}
		elseif ($ch -eq 'p' -or $ch -eq 'P') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Invoke-SophiaRamPurge -ErrorAction SilentlyContinue) { Invoke-SophiaRamPurge }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'e' -or $ch -eq 'E') {
			try { [Console]::CursorVisible = $true } catch {}
			Invoke-EmulatorAutoBooster
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
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
			$firstFrame = $true
		}
		elseif ($ch -eq 't' -or $ch -eq 'T') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Invoke-SophiaBenchmark -ErrorAction SilentlyContinue) { Invoke-SophiaBenchmark -Label "Manual" | Out-Null }
			else { Write-Host "  [!] Không tìm thấy module Benchmark." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
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
				Write-Host "  Smart Advisor đã tự tick Mode $currentMode + tweak riêng cho máy này:" -ForegroundColor Green
				$smartRec.Reasons | ForEach-Object { Write-Host "      - $_" -ForegroundColor Cyan }
				$smartRec.Warnings | ForEach-Object { Write-Host "      [!] $_" -ForegroundColor Yellow }
			}
			else { Write-Host "  [!] Smart Advisor không khả dụng (thiếu dữ liệu phần cứng)." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để xem danh sách đã tick"
			$firstFrame = $true
		}
		elseif ($ch -eq 's' -or $ch -eq 'S') {
			try { [Console]::CursorVisible = $true } catch {}
			$ids = @($selected.Keys | Where-Object { $selected[$_] })
			Save-SophiaSelectionProfile -ModeKey $currentMode -SelectedIds $ids | Out-Null
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'l' -or $ch -eq 'L') {
			try { [Console]::CursorVisible = $true } catch {}
			$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Profiles"
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
			$firstFrame = $true
		}
		elseif ($ch -eq 'b' -or $ch -eq 'B') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command New-SophiaSystemBackup -ErrorAction SilentlyContinue) { New-SophiaSystemBackup | Out-Null }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'f' -or $ch -eq 'F') {
			$filterModes = @("All", "Selected", "Extreme", "NotApplied")
			$filterMode = $filterModes[([array]::IndexOf($filterModes, $filterMode) + 1) % $filterModes.Count]
			$cursor = 0
		}
		elseif ($ch -eq '?') {
			try { [Console]::CursorVisible = $true; [Console]::Clear() } catch {}
			Write-Host ""
			Write-Host "  Keyboard" -ForegroundColor White
			Write-Host "  ↑/↓, K/J    Move              Space       Toggle tweak" -ForegroundColor Gray
			Write-Host "  Enter       Apply selected    1-6, M      Switch mode" -ForegroundColor Gray
			Write-Host "  A / N       Select all/none   /           Search" -ForegroundColor Gray
			Write-Host "  F           Cycle filter      V           Scan applied (●)" -ForegroundColor Gray
			Write-Host "  G           Smart Advisor     P / E       Purge RAM / Boost emulators" -ForegroundColor Gray
			Write-Host "  T           Benchmark         S / L       Save / Load profile" -ForegroundColor Gray
			Write-Host "  B           Backup            H           HTML report" -ForegroundColor Gray
			Write-Host "  U           Undo last session R           Restore defaults" -ForegroundColor Gray
			Write-Host "  Q, Esc      Quit" -ForegroundColor Gray
			Write-Host ""
			Write-Host "  EXT = Extreme risk (read the description first). Press any key to return." -ForegroundColor DarkGray
			[Console]::ReadKey($true) | Out-Null
			$firstFrame = $true
		}
		elseif ($ch -eq 'h' -or $ch -eq 'H') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue) { Export-MolikHtmlReport -Snapshot $Snapshot -Catalog $Catalog | Out-Null }
			else { Write-Host "  [!] Khong tim thay Report Engine." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'u' -or $ch -eq 'U') {
			try { [Console]::CursorVisible = $true } catch {}
			if (Get-Command Restore-MolikLastSession -ErrorAction SilentlyContinue) { Restore-MolikLastSession -Catalog $Catalog | Out-Null }
			else { Write-Host "  [!] Khong tim thay module Backup/Undo." -ForegroundColor Yellow }
			Read-Host "  Nhấn ENTER để tiếp tục"
			$firstFrame = $true
		}
		elseif ($ch -eq 'r' -or $ch -eq 'R') {
			try { [Console]::CursorVisible = $true } catch {}
			$confirm = Read-Host "  Khôi phục MẶC ĐỊNH toàn bộ tweak? (yes/no)"
			if ($confirm -eq 'yes') { Invoke-SophiaRestoreTweaks -Catalog $Catalog }
			$firstFrame = $true
		}
		if ($cursor -lt 0) { $cursor = 0 }
		if ($cursor -ge $filtered.Count) { $cursor = $filtered.Count - 1 }
	}
}
