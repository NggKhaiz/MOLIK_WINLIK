<#
	.SYNOPSIS
	DEPRECATED legacy filename for MOLIK WINLIK.

	.DESCRIPTION
	The canonical offline entry points are MOLIK_WINLIK.bat (double-click,
	auto-Administrator) and MolikWinlik.ps1 in this same folder. This shim only
	forwards to MolikWinlik.ps1 so old local commands keep working. MOLIK
	WINLIK is fully offline: nothing is downloaded at runtime.
#>
$target = Join-Path $PSScriptRoot "MolikWinlik.ps1"
if (-not (Test-Path $target))
{
	Write-Host "  [X] Khong tim thay MolikWinlik.ps1 canh file nay. Hay chay MOLIK_WINLIK.bat trong cung thu muc." -ForegroundColor Red
	return
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $target @args
