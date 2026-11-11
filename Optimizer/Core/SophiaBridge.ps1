<#
	.SYNOPSIS
	Sophia Ultra Optimizer - Bridge to Native Sophia Script Modules (src/Sophia_Script_for_Windows_*)

	.DESCRIPTION
	Automatically resolves the correct Sophia Script edition for the host OS (Windows 10 / 11 / LTSC / ARM / PS5.1 / PS7),
	imports localizations, WinAPI P/Invoke types, Private helpers, and Sophia.psm1 functions without being blocked
	by offline LGPO or minor Windows UBR version checks.
#>

function Resolve-SophiaEditionFolder
{
	[CmdletBinding()]
	param
	(
		[string]$RepoRoot
	)

	$SrcRoot = Join-Path -Path $RepoRoot -ChildPath "src"
	if (-not (Test-Path -Path $SrcRoot))
	{
		return $null
	}

	$BuildNumber = 19045
	$ProductName = "Windows 10 Pro"
	$Arch        = 9

	try
	{
		$BuildNumber = [int](Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild -ErrorAction SilentlyContinue)
		$ProductName = [string](Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName -ErrorAction SilentlyContinue)
		$Arch        = [int]((Get-CimInstance -Namespace root/CIMV2 -ClassName CIM_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Architecture)
	}
	catch {}

	$IsPS7 = ($PSVersionTable.PSVersion.Major -ge 7)
	$EditionName = "Sophia_Script_for_Windows_11"

	if ($BuildNumber -eq 17763 -and $ProductName -match "LTSC")
	{
		$EditionName = "Sophia_Script_for_Windows_10_LTSC_2019"
	}
	elseif ($BuildNumber -eq 19044 -and $ProductName -match "LTSC")
	{
		$EditionName = "Sophia_Script_for_Windows_10_LTSC_2021"
	}
	elseif ($BuildNumber -le 19045)
	{
		$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_10_PowerShell_7" } else { "Sophia_Script_for_Windows_10" }
	}
	else
	{
		if ($ProductName -match "LTSC")
		{
			$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_11_LTSC_2024_PowerShell_7" } else { "Sophia_Script_for_Windows_11_LTSC_2024" }
		}
		elseif ($Arch -eq 12)
		{
			$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_11_Arm_PowerShell_7" } else { "Sophia_Script_for_Windows_11_Arm" }
		}
		else
		{
			$EditionName = if ($IsPS7) { "Sophia_Script_for_Windows_11_PowerShell_7" } else { "Sophia_Script_for_Windows_11" }
		}
	}

	$EditionPath = Join-Path -Path $SrcRoot -ChildPath $EditionName
	if (Test-Path -Path $EditionPath)
	{
		return $EditionPath
	}

	# Fallback to Windows 11 or 10 folder
	$Fallback = Get-ChildItem -Path $SrcRoot -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($Fallback) { return $Fallback.FullName }
	return $null
}

function Initialize-SophiaNativeModule
{
	[CmdletBinding()]
	param
	(
		[string]$RepoRoot
	)

	if ($Global:SophiaNativeLoaded)
	{
		return $true
	}

	$EditionPath = Resolve-SophiaEditionFolder -RepoRoot $RepoRoot
	if (-not $EditionPath)
	{
		return $false
	}

	try
	{
		$LocalizationsDir = Join-Path -Path $EditionPath -ChildPath "Module\Localizations"
		if (Test-Path -Path $LocalizationsDir)
		{
			try
			{
				Import-LocalizedData -BindingVariable Global:Localization -UICulture $PSUICulture -BaseDirectory $LocalizationsDir -FileName Sophia -ErrorAction Stop
			}
			catch
			{
				Import-LocalizedData -BindingVariable Global:Localization -UICulture en-US -BaseDirectory $LocalizationsDir -FileName Sophia -ErrorAction SilentlyContinue
			}
		}

		$PrivateDir = Join-Path -Path $EditionPath -ChildPath "Module\Private"
		if (Test-Path -Path $PrivateDir)
		{
			Get-ChildItem -Path $PrivateDir -Filter "*.ps1" -File | Where-Object { $_.Name -notin @("InitialActions.ps1", "PostActions.ps1") } | ForEach-Object {
				. $_.FullName
			}
		}

		if (Get-Command -Name Import-WinAPI -ErrorAction SilentlyContinue)
		{
			Import-WinAPI -ErrorAction SilentlyContinue
		}

		$ModulePsm1 = Join-Path -Path $EditionPath -ChildPath "Module\Sophia.psm1"
		if (Test-Path -Path $ModulePsm1)
		{
			Import-Module -Name $ModulePsm1 -Global -Force -ErrorAction SilentlyContinue | Out-Null
			$Global:SophiaNativeLoaded = $true
			$Global:SophiaEditionLoaded = (Split-Path -Path $EditionPath -Leaf)
			return $true
		}
	}
	catch
	{
		return $false
	}

	return $false
}

function Invoke-SophiaNativeSafe
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$CommandName,

		[Parameter(Mandatory = $false)]
		[hashtable]$Parameters = @{}
	)

	$Cmd = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
	if ($Cmd)
	{
		try
		{
			& $Cmd @Parameters
			return $true
		}
		catch
		{
			return $false
		}
	}
	return $false
}
