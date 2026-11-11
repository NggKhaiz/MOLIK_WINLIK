@echo off
setlocal EnableExtensions DisableDelayedExpansion
title MOLIK WINLIK by @nggkhaiz - Offline Optimizer
cd /d "%~dp0"

rem =====================================================================
rem  MOLIK WINLIK - OFFLINE LAUNCHER (canonical entry point)
rem  - 100 percent offline: this file never downloads anything.
rem  - Double-click -> requests Administrator (UAC) -> runs local core.
rem  - ExecutionPolicy Bypass applies ONLY to the child PowerShell
rem    process started below. The system policy is never changed.
rem
rem  Usage:
rem    MOLIK_WINLIK.bat
rem    MOLIK_WINLIK.bat -Menu
rem    MOLIK_WINLIK.bat -SelfTest
rem    MOLIK_WINLIK.bat -Mode HardcoreGaming -Apply -Yes
rem =====================================================================

rem --- Locate the local core (prefer the single-file Portable) ---
set "CORE="
if exist "%~dp0MolikWinlik-Portable.ps1" set "CORE=%~dp0MolikWinlik-Portable.ps1"
if not defined CORE if exist "%~dp0MolikWinlik.ps1" set "CORE=%~dp0MolikWinlik.ps1"

if not defined CORE (
  echo.
  echo  [ERROR] MolikWinlik-Portable.ps1 was not found next to this .bat file.
  echo          Keep MOLIK_WINLIK.bat and MolikWinlik-Portable.ps1 in the SAME
  echo          folder, then double-click MOLIK_WINLIK.bat again.
  echo          MOLIK WINLIK is offline: nothing will be downloaded.
  echo.
  pause
  exit /b 1
)

rem --- Administrator check: fltmc succeeds only in an elevated token ---
fltmc >nul 2>&1
if errorlevel 1 (
  echo.
  echo  MOLIK WINLIK needs Administrator. Opening the UAC prompt...
  set "ARGOPT="
  if not "%*"=="" set "ARGOPT=-ArgumentList '%*'"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' %ARGOPT% -Verb RunAs -ErrorAction Stop } catch { Write-Host 'UAC was cancelled or blocked.'; exit 1 }"
  if errorlevel 1 (
    echo.
    echo  [ERROR] Could not request Administrator rights.
    echo          Right-click MOLIK_WINLIK.bat and choose "Run as administrator".
    echo.
    pause
  )
  exit /b 0
)

echo.
echo  ================================================================
echo   MOLIK WINLIK by @nggkhaiz - OFFLINE (no download, no install)
echo   Core: %CORE%
echo  ================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CORE%" %*
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" echo  [MOLIK WINLIK exited with code %EXITCODE%]
echo  Press any key to close this window...
pause >nul
exit /b %EXITCODE%
