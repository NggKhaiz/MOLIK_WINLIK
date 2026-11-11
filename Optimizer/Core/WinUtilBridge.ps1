<#
	.SYNOPSIS
	Sophia Ultra Optimizer - WinUtil Bridge (ChrisTitusTech/winutil integration, 100% OFFLINE)

	.DESCRIPTION
	Converts vendored winutil tweaks data (Optimizer/Data/WinUtilTweaks.ps1, converted from
	ChrisTitusTech/winutil config/tweaks.json, MIT License) into native Sophia tweak objects
	(ApplyScript/RestoreScript/CheckScript) in category "10. WINUTIL (Chris Titus Tech)".
	No download at runtime: all data is bundled in this repository / the Portable file.

	.NOTES
	Attribution: Chris Titus Tech Windows Utility - https://github.com/ChrisTitusTech/winutil (MIT)
#>

function Convert-WinUtilEntryValue
{
	param($Entry)
	if ($Entry.Type -eq "DWord") { try { return [int]$Entry.Value } catch { return 0 } }
	if ($Entry.Type -eq "QWord") { try { return [long]$Entry.Value } catch { return 0 } }
	return [string]$Entry.Value
}

function New-WinUtilConvertedTweak
{
	param($Raw)

	$entries = @($Raw.Entries)
	$apply = {
		foreach ($e in $entries)
		{
			$val = $e.Value
			if ($e.Type -eq "DWord") { try { $val = [int]$e.Value } catch { $val = 0 } }
			elseif ($e.Type -eq "QWord") { try { $val = [long]$e.Value } catch { $val = 0 } }
			Set-SophiaRegValue -Path $e.Path -Name $e.Name -Value $val -Type $e.Type
		}
	}.GetNewClosure()

	$restore = {
		foreach ($e in $entries)
		{
			if ($null -eq $e.Original)
			{
				Remove-ItemProperty -Path $e.Path -Name $e.Name -Force -ErrorAction SilentlyContinue
			}
			else
			{
				$val = $e.Original
				if ($e.Type -eq "DWord") { try { $val = [int]$e.Original } catch { $val = 0 } }
				elseif ($e.Type -eq "QWord") { try { $val = [long]$e.Original } catch { $val = 0 } }
				Set-SophiaRegValue -Path $e.Path -Name $e.Name -Value $val -Type $e.Type
			}
		}
	}.GetNewClosure()

	$check = {
		foreach ($e in $entries)
		{
			$current = Get-SophiaRegValue -Path $e.Path -Name $e.Name
			if ($null -eq $current -or "$current" -ne "$($e.Value)") { return $false }
		}
		return $true
	}.GetNewClosure()

	return [PSCustomObject]@{
		Id = $Raw.Id; Name = "[WinUtil] $($Raw.Name)"; Category = "10. 🧩 WINUTIL (Chris Titus Tech)"
		Description = "$($Raw.Description) (Nguồn: winutil/$($Raw.SourceKey), đã vendor offline)"
		Risk = $Raw.Risk; Modes = @($Raw.Modes)
		ApplyScript = $apply; RestoreScript = $restore; CheckScript = $check
		Kind = "WinUtilRegistry"; Detail = "$($entries.Count) registry entries (winutil $($Raw.SourceKey))"
	}
}

function Get-WinUtilConvertedTweaks
{
	if (-not (Get-Command Get-WinUtilRawTweaks -ErrorAction SilentlyContinue)) { return @() }
	$result = @()
	foreach ($raw in (Get-WinUtilRawTweaks))
	{
		try { $result += New-WinUtilConvertedTweak -Raw $raw } catch {}
	}
	return $result
}
