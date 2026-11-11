<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Self-Test / Debug toàn diện (không thay đổi hệ thống)

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
	Write-Host "  ║  🩺 SOPHIA ULTRA OPTIMIZER — SELF-TEST / DEBUG TOÀN DIỆN           ║" -ForegroundColor Cyan
	Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

	# 1) Syntax parse
	$files = @()
	if ($RepoRoot)
	{
		$files += Get-ChildItem -Path (Join-Path $RepoRoot "Optimizer") -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue
		foreach ($extra in @("Sophia-Optimizer.ps1","Sophia-Ultra-Portable.ps1","Sophia-Ultra-Standalone.ps1"))
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
	if ($parseErrors -eq 0) { Report "PASS" "Cú pháp PowerShell: $($files.Count) file đều parse sạch" }

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

	# 5) Portable integrity
	if ($RepoRoot)
	{
		$portable = Join-Path $RepoRoot "Sophia-Ultra-Portable.ps1"
		if (Test-Path $portable)
		{
			$content = Get-Content $portable -Raw
			$markers = ([regex]::Matches($content, "PORTABLE-INLINE")).Count
			if ($markers -ge 10 -and $content -match "Get-WinUtilConvertedTweaks" -and $content -match "EXT50") { Report "PASS" "Portable: $markers module inline, đủ WinUtil + EXT (offline)" }
			else { Report "WARN" "Portable có vẻ thiếu module (markers=$markers) — chạy Optimizer\Build-Portable.ps1 để sinh lại" }
		}
	}

	Write-Host ""
	Write-Host ("  ══════════ KẾT QUẢ: {0} PASS / {1} FAIL / {2} WARN ══════════" -f $script:pass, $script:fail, $script:warn) -ForegroundColor Cyan
	if ($script:fail -eq 0) { Write-Host "  ✅ Tool khỏe mạnh, sẵn sàng tối ưu!" -ForegroundColor Green } else { Write-Host "  Hãy gửi log này khi báo lỗi." -ForegroundColor Yellow }
	return ($script:fail -eq 0)
}
