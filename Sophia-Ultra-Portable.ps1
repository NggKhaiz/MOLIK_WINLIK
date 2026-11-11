<#
	.SYNOPSIS
	DEPRECATED legacy filename for MOLIK WINLIK Portable.

	.DESCRIPTION
	The canonical single-file build is MolikWinlik-Portable.ps1 in this same
	folder (or just double-click MOLIK_WINLIK.bat). This shim forwards to it
	so old local commands keep working. MOLIK WINLIK is fully offline:
	nothing is downloaded at runtime.
#>
$target = Join-Path $PSScriptRoot "MolikWinlik-Portable.ps1"
if (-not (Test-Path $target))
{
	Write-Host "  [X] Khong tim thay MolikWinlik-Portable.ps1 canh file nay. Hay chay MOLIK_WINLIK.bat trong cung thu muc." -ForegroundColor Red
	return
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $target @args
