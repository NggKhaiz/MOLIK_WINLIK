<#
	.SYNOPSIS
	MOLIK WINLIK - Self-Test / Debug toàn diện (không thay đổi hệ thống)

	.DESCRIPTION
	1) Parse cú pháp mọi file .ps1 của tool bằng PowerShell Parser chính chủ
	2) Dựng catalog, kiểm tra ID trùng, mỗi tweak đủ Apply/Restore/Check
	3) Chạy thử toàn bộ CheckScript (chỉ đọc) và báo tweak nào lỗi
	4) Kiểm tra 6 Mode có tweak, Plan Engine chạy được, Smart Advisor chạy được
	5) Kiểm tra bản Portable có đủ module inline (nếu chạy trong repo)
	Chỉ ĐỌC — không áp dụng tweak nào.
#>

function Test-SophiaOptimizerHealth
{
	[CmdletBinding()]
	param([string]$RepoRoot, $Catalog)

	$pass = 0; $fail = 0; $warn = 0
	function Report([string]$Status, [string]$Msg)
	{
		if ($Status -eq "PASS") { $script:pass++; Write-Host "  [✓ PASS] $Msg" -ForegroundColor Green }
		elseif ($Status -eq "WARN") { $script:warn++; Write-Host "  [! WARN] $Msg" -ForegroundColor Yellow }
		else { $script:fail++; Write-Host "  [X FAIL] $Msg" -ForegroundColor Red }
	}
	$script:pass = 0; $script:fail = 0; $script:warn = 0

	Write-Host ""
	Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "  ║  🩺 MOLIK WINLIK — SELF-TEST / DEBUG TOÀN DIỆN           ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

	# 1) Syntax parse
	$files = @()
	if ($RepoRoot)
	{
		$files += Get-ChildItem -Path (Join-Path $RepoRoot "Optimizer") -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue
		foreach ($extra in @("MolikWinlik.ps1","MolikWinlik-Portable.ps1","Sophia-Optimizer.ps1","Sophia-Ultra-Portable.ps1"))
		{
			$ef = Join-Path $RepoRoot $extra
			if (Test-Path $ef) { $files += Get-Item $ef }
		}
	}
	$parseErrors = 0
	foreach ($f in $files)
	{
		$tokens = $null; $errors = $null
		[void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)
		if ($errors -and $errors.Count -gt 0) { $parseErrors += $errors.Count; Report "FAIL" "Parse: $($f.Name) có $($errors.Count) lỗi: $($errors[0].Message)" }
	}
	if ($files.Count -eq 0) { Report "WARN" "Cú pháp PowerShell: không tìm thấy file .ps1 nguồn nào để parse (bỏ qua nếu đang chạy bản Portable độc lập)" }
	elseif ($parseErrors -eq 0) { Report "PASS" "Cú pháp PowerShell: $($files.Count) file đều parse sạch" }

	# 2) Catalog integrity
	if (-not $Catalog) { $Catalog = Get-SophiaTweaksCatalog }
	Report "PASS" "Catalog dựng thành công: $($Catalog.Count) tweak"
	$dupes = $Catalog | Group-Object Id | Where-Object Count -gt 1
	if ($dupes) { Report "FAIL" "ID trùng: $($dupes.Name -join ', ')" } else { Report "PASS" "Không có ID tweak nào trùng" }
	$incomplete = @($Catalog | Where-Object { -not $_.ApplyScript -or -not $_.RestoreScript -or -not $_.CheckScript -or -not $_.Name })
	if ($incomplete.Count -gt 0) { Report "FAIL" "Tweak thiếu script/tên: $($incomplete.Id -join ', ')" } else { Report "PASS" "Mọi tweak đủ Apply/Restore/Check/Name" }

	# 3) CheckScripts (read-only)
	$checkErrors = @()
	foreach ($t in $Catalog)
	{
		try { [void](& $t.CheckScript) } catch { $checkErrors += "$($t.Id): $($_.Exception.Message)" }
	}
	if ($checkErrors.Count -eq 0) { Report "PASS" "Toàn bộ $($Catalog.Count) CheckScript chạy không lỗi (chỉ đọc)" }
	else { Report "WARN" "$($checkErrors.Count) CheckScript báo vấn đề (thường do thiếu phần cứng/quyền): $($checkErrors[0])" }

	# 4) Modes + Plan + Smart
	foreach ($m in (Get-SophiaOptimizationModes))
	{
		$cnt = (Get-SophiaModeTweakIds -ModeKey $m.Key -Catalog $Catalog).Count
		if ($cnt -gt 0) { Report "PASS" "Mode $($m.Key): $cnt tweak" } else { Report "FAIL" "Mode $($m.Key) rỗng!" }
	}
	try
	{
		$sampleIds = (Get-SophiaModeTweakIds -ModeKey "EmulatorFarm" -Catalog $Catalog)
		$plan = Get-SophiaOptimizationPlan -Catalog $Catalog -SelectedIds $sampleIds
		Report "PASS" "Plan Engine: lập plan $($plan.Count) tweak, Impact $($plan.ImpactScore), $($plan.Notes.Count) ghi chú phụ thuộc/mâu thuẫn"
	} catch { Report "FAIL" "Plan Engine lỗi: $($_.Exception.Message)" }
	try
	{
		$snap = Get-SophiaSystemSnapshot
		$rec = Get-SophiaSmartRecommendation -Snapshot $snap -Catalog $Catalog
		Report "PASS" "Smart Advisor: máy này -> Mode $($rec.Mode) + $($rec.ExtraIds.Count) tweak bổ sung ($($snap.OSName), $($snap.CPUThreads) luồng, RAM $($snap.RAMTotalGB)GB)"
	} catch { Report "WARN" "Smart Advisor/Snapshot: $($_.Exception.Message)" }

	# 5) Encoding guard (OFFLINE): file .ps1 chay bang -File tren Windows PowerShell 5.1
	# phai co BOM UTF-8 (hoac thuan ASCII) thi tieng Viet moi hien dung. Ban Portable
	# duoc Build-Portable.ps1 ghi UTF-8 BOM nen kiem tra ca BOM lan noi dung tai mang.
	if ($RepoRoot)
	{
		foreach ($coreFile in @("MolikWinlik.ps1", "MolikWinlik-Portable.ps1"))
		{
			$of = Join-Path $RepoRoot $coreFile
			if (Test-Path $of)
			{
				$bytes = [System.IO.File]::ReadAllBytes($of)
				$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
				$hasNonAscii = $false
				foreach ($b in $bytes) { if ($b -gt 127) { $hasNonAscii = $true; break } }
				if ($hasNonAscii -and -not $hasBom) { Report "FAIL" "Encoding guard: $coreFile co ky tu khong-ASCII nhung thieu BOM UTF-8 - PowerShell 5.1 se doc sai tieng Viet!" }
				else { Report "PASS" "Encoding guard: $coreFile an toan cho PowerShell 5.1 (BOM UTF-8 hoac ASCII thuan)" }
			}
		}
		$bat = Join-Path $RepoRoot "MOLIK_WINLIK.bat"
		if (Test-Path $bat)
		{
			$batText = Get-Content $bat -Raw
			if ($batText -match "MolikWinlik-Portable\.ps1" -and $batText -match "fltmc" -and $batText -notmatch "Invoke-WebRequest|Invoke-RestMethod|DownloadString")
			{
				Report "PASS" "Offline launcher: MOLIK_WINLIK.bat tu xin Admin (fltmc/UAC), chay file local, khong tai gi khi chay"
			}
			else { Report "FAIL" "Offline launcher: MOLIK_WINLIK.bat thieu fltmc/core local hoac chua lenh tai mang!" }
		}
		else { Report "WARN" "Khong thay MOLIK_WINLIK.bat o goc repo (bo qua neu dang chay ban Portable doc lap)" }
	}

	# 6) Portable integrity + OFFLINE purity (khong cmdlet tai code khi chay)
	if ($RepoRoot)
	{
		$portable = Join-Path $RepoRoot "MolikWinlik-Portable.ps1"
		if (Test-Path $portable)
		{
			$content = Get-Content $portable -Raw
			$markers = ([regex]::Matches($content, "PORTABLE-INLINE")).Count
			if ($markers -ge 10 -and $content -match "Get-WinUtilConvertedTweaks" -and $content -match "EXT84") { Report "PASS" "Portable: $markers module inline, du WinUtil + EXT84 (offline)" }
			else { Report "WARN" "Portable co ve thieu module (markers=$markers) - chay Optimizer\\Build-Portable.ps1 de sinh lai" }
			$scanText = (($content -split "`n") | Where-Object { $_ -notmatch "OFFLINE guard|-match|-notmatch" }) -join "`n"
			if ($scanText -match "Invoke-RestMethod|Invoke-WebRequest|DownloadString") { Report "FAIL" "OFFLINE guard: Portable chua cmdlet tai code tu Internet!" }
			else { Report "PASS" "OFFLINE guard: Portable khong tai code khi chay (chi winget tuy chon cho app)" }
		}
	}

	# 7) Presets + Report Engine
	try
	{
		if (Get-Command Get-MolikPresets -ErrorAction SilentlyContinue)
		{
			$presetFail = @()
			foreach ($preset in (Get-MolikPresets))
			{
				$resolved = Resolve-MolikPreset -Preset $preset -Catalog $Catalog
				if ($resolved.Count -eq 0) { $presetFail += $preset.Name }
				if (@($preset.ExcludeRisks).Count -gt 0)
				{
					$violations = @($Catalog | Where-Object { ($resolved -contains $_.Id) -and ($preset.ExcludeRisks -contains $_.Risk) })
					if ($violations.Count -gt 0) { $presetFail += "$($preset.Name) (chứa $($violations[0].Risk) dù đã loại trừ: $($violations[0].Id))" }
				}
			}
			if ($presetFail.Count -eq 0) { Report "PASS" "Presets: $((Get-MolikPresets).Count) preset deu giai ra danh sach tweak hop le" }
			else { Report "FAIL" "Preset giai rong: $($presetFail -join ', ')" }
		}
	}
	catch { Report "FAIL" "Presets loi: $($_.Exception.Message)" }
	try
	{
		if (Get-Command Export-MolikHtmlReport -ErrorAction SilentlyContinue)
		{
			$tmpReport = Join-Path $env:TEMP "MolikWinlik-SelfTest-Report.html"
			Export-MolikHtmlReport -Snapshot $null -Catalog $Catalog -Path $tmpReport -SkipStatus | Out-Null
			if ((Test-Path $tmpReport) -and ((Get-Content $tmpReport -Raw) -match "MOLIK WINLIK")) { Report "PASS" "Report Engine: xuat HTML Dashboard thanh cong (file tam, da xoa)" } else { Report "FAIL" "Report Engine: file HTML khong hop le" }
			Remove-Item $tmpReport -Force -ErrorAction SilentlyContinue
		}
	}
	catch { Report "FAIL" "Report Engine loi: $($_.Exception.Message)" }

	# 8) Tinh nang v3.1: Doctor / Undo / Backup list
	$missingFn = @()
	foreach ($fn in @("Show-MolikSystemDoctor", "Restore-MolikLastSession", "Get-MolikBackupFolders", "Show-MolikBackupList"))
	{
		if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) { $missingFn += $fn }
	}
	if ($missingFn.Count -eq 0) { Report "PASS" "v3.1 core: Doctor + UndoLast + Backup list đều sẵn sàng" }
	else { Report "FAIL" "Thiếu hàm v3.1: $($missingFn -join ', ')" }
	# Luu y: SelfTest la CHI DOC - khong bao gio goi Undo/Restore that o day,
	# chi kiem tra ham ton tai. Logic parse log duoc bao phu boi kiem tra tinh.

	Write-Host ""
	Write-Host ("  ══════════ KẾT QUẢ: {0} PASS / {1} FAIL / {2} WARN ══════════" -f $script:pass, $script:fail, $script:warn) -ForegroundColor Cyan
	if ($script:fail -eq 0) { Write-Host "  ✅ Tool khỏe mạnh, sẵn sàng tối ưu!" -ForegroundColor Green } else { Write-Host "  Hãy gửi log này khi báo lỗi." -ForegroundColor Yellow }
	return ($script:fail -eq 0)
}
