<#
	.SYNOPSIS
	MOLIK WINLIK - Before/After Performance Benchmark

	.DESCRIPTION
	Lightweight repeatable benchmark (CPU single + multi via Jobs, disk 128MB sequential,
	RAM/process snapshot) saved as JSON so users can measure the real gain after optimizing.
	Results: $env:SystemDrive\MOLIK_WINLIK_Backups\Benchmarks\bench_<label>_<time>.json
#>

function Invoke-SophiaBenchmark
{
	[CmdletBinding()]
	param([string]$Label = "After")

	Write-Host ""
	Write-Host "  ══════════ MOLIK WINLIK BENCHMARK [$Label] — đang đo, vui lòng không thao tác... ══════════" -ForegroundColor Cyan

	# CPU single-thread: integer/hash loop
	$swSingle = [System.Diagnostics.Stopwatch]::StartNew()
	$acc = [Int64]0
	for ($i = 0; $i -lt 3000000; $i++) { $acc += ($i * 31) % 97 }
	$swSingle.Stop()
	$singleOps = [Math]::Round(3000000 / $swSingle.Elapsed.TotalSeconds, 0)

	# CPU multi-thread: one Job per logical core (hash workload)
	$multiOps = 0
	try
	{
		$cores = [Environment]::ProcessorCount
		$jobBlock = {
			$h = 0
			for ($i = 0; $i -lt 4000; $i++)
			{
				$bytes = [System.Text.Encoding]::UTF8.GetBytes("molikwinlik-bench-$i-$h")
				$h = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Length + $i
			}
			return 4000
		}
		$swMulti = [System.Diagnostics.Stopwatch]::StartNew()
		$jobs = @()
		for ($c = 0; $c -lt $cores; $c++) { $jobs += Start-Job -ScriptBlock $jobBlock }
		$done = $jobs | Wait-Job -Timeout 120 | Receive-Job
		$jobs | Remove-Job -Force -ErrorAction SilentlyContinue
		$swMulti.Stop()
		$totalIter = ($done | Measure-Object -Sum).Sum
		if ($totalIter -gt 0) { $multiOps = [Math]::Round($totalIter / $swMulti.Elapsed.TotalSeconds, 0) }
	}
	catch { $multiOps = 0 }

	# Disk sequential 128MB
	$diskWrite = 0; $diskRead = 0
	$tmpFile = Join-Path $env:TEMP "molikwinlik_bench_$([Guid]::NewGuid().ToString('N')).bin"
	try
	{
		$data = New-Object byte[] (1MB)
		(New-Object Random).NextBytes($data)
		$swW = [System.Diagnostics.Stopwatch]::StartNew()
		$fs = [System.IO.File]::Create($tmpFile)
		for ($i = 0; $i -lt 128; $i++) { $fs.Write($data, 0, $data.Length) }
		$fs.Flush(); $fs.Close(); $swW.Stop()
		$diskWrite = [Math]::Round(128 / $swW.Elapsed.TotalSeconds, 1)
		$swR = [System.Diagnostics.Stopwatch]::StartNew()
		$fs = [System.IO.File]::OpenRead($tmpFile)
		$buf = New-Object byte[] (1MB)
		while ($fs.Read($buf, 0, $buf.Length) -gt 0) {}
		$fs.Close(); $swR.Stop()
		$diskRead = [Math]::Round(128 / $swR.Elapsed.TotalSeconds, 1)
	} catch {}
	finally { Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue }

	# System snapshot
	$os = Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
	$freeMB = 0; $totalMB = 0; $procCount = 0
	if ($os)
	{
		$freeMB = [Math]::Round($os.FreePhysicalMemory / 1024, 0)
		$totalMB = [Math]::Round($os.TotalVisibleMemorySize / 1024, 0)
	}
	try { $procCount = (Get-Process -ErrorAction SilentlyContinue).Count } catch {}

	$result = [PSCustomObject]@{
		Label        = $Label
		Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
		CpuSingleOps = $singleOps
		CpuMultiOps  = $multiOps
		CpuScore     = [Math]::Round(($singleOps / 1000) + ($multiOps / 10), 1)
		DiskWriteMBs = $diskWrite
		DiskReadMBs  = $diskRead
		RamFreeMB    = $freeMB
		RamTotalMB   = $totalMB
		ProcessCount = $procCount
	}

	Write-Host ("  CPU Single : {0} ops/s" -f $singleOps) -ForegroundColor Green
	Write-Host ("  CPU Multi  : {0} hash/s ({1} luồng)" -f $multiOps, [Environment]::ProcessorCount) -ForegroundColor Green
	Write-Host ("  Disk Write : {0} MB/s | Read: {1} MB/s" -f $diskWrite, $diskRead) -ForegroundColor Green
	Write-Host ("  RAM trống  : {0}/{1} MB | Tiến trình đang chạy: {2}" -f $freeMB, $totalMB, $procCount) -ForegroundColor Green
	Write-Host ("  ★ ĐIỂM CPU TỔNG: {0}" -f $result.CpuScore) -ForegroundColor Yellow

	$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Benchmarks"
	New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	$file = Join-Path $dir ("bench_{0}_{1}.json" -f ($Label -replace '\W', '_'), (Get-Date -Format "yyyyMMdd_HHmmss"))
	$result | ConvertTo-Json | Set-Content -Path $file -Encoding UTF8 -Force
	Write-Host "  [✓] Đã lưu benchmark: $file" -ForegroundColor Cyan
	Write-Host "  Mẹo: chạy -Benchmark -BenchmarkLabel Before TRƯỚC khi tối ưu, rồi After để so sánh % cải thiện." -ForegroundColor Gray

	return $result
}

function Compare-SophiaBenchmarks
{
	$dir = "$env:SystemDrive\MOLIK_WINLIK_Backups\Benchmarks"
	if (-not (Test-Path $dir)) { Write-Host "  [!] Chưa có benchmark nào trong $dir" -ForegroundColor Yellow; return }
	$files = Get-ChildItem -Path $dir -Filter "bench_*.json" | Sort-Object LastWriteTime
	if ($files.Count -lt 2) { Write-Host "  [!] Cần ít nhất 2 benchmark (Before/After) để so sánh. Hiện có: $($files.Count)" -ForegroundColor Yellow; return }
	$first = Get-Content $files[0].FullName -Raw | ConvertFrom-Json
	$last = Get-Content $files[-1].FullName -Raw | ConvertFrom-Json
	function Show-Delta($name, $a, $b, $unit, $invert)
	{
		if ($a -and $b)
		{
			$pct = [Math]::Round((($b - $a) / $a) * 100, 1)
			$arrow = if ($pct -ge 0) { "▲" } else { "▼" }
			if ($invert) { $arrow = if ($pct -ge 0) { "▼ (nhiều hơn)" } else { "▲ (ít hơn = tốt)" } }
			Write-Host ("  {0,-12} {1} -> {2} {3}  ({4} {5}%)" -f $name, $a, $b, $unit, $arrow, $pct) -ForegroundColor Cyan
		}
	}
	Write-Host ""
	Write-Host "  ══════════ SO SÁNH BENCHMARK: [$($first.Label)] $($first.Timestamp)  vs  [$($last.Label)] $($last.Timestamp) ══════════" -ForegroundColor Cyan
	Show-Delta "CPU Score" $first.CpuScore $last.CpuScore "điểm" $false
	Show-Delta "CPU Single" $first.CpuSingleOps $last.CpuSingleOps "ops/s" $false
	Show-Delta "CPU Multi" $first.CpuMultiOps $last.CpuMultiOps "hash/s" $false
	Show-Delta "Disk Write" $first.DiskWriteMBs $last.DiskWriteMBs "MB/s" $false
	Show-Delta "Disk Read" $first.DiskReadMBs $last.DiskReadMBs "MB/s" $false
	Show-Delta "RAM trống" $first.RamFreeMB $last.RamFreeMB "MB" $false
	Show-Delta "Tiến trình" $first.ProcessCount $last.ProcessCount "process" $true
}
