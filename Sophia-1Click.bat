@echo off
chcp 65001 >nul
title Sophia Ultra Optimizer - 1 Click (Khong Can Cai Dat)
echo.
echo  ================================================================
echo   MOLIK_WINLIK by @nggkhaiz - SOPHIA ULTRA OPTIMIZER - 1 CLICK
echo   Chi tai 1 file Portable vao TEMP roi chay ngay. Bam phim bat ky
echo  ================================================================
echo.
set "PORTABLE=%TEMP%\Sophia-Ultra-Portable.ps1"
if exist "%~dp0Sophia-Ultra-Portable.ps1" set "PORTABLE=%~dp0Sophia-Ultra-Portable.ps1"
if exist "%PORTABLE%" goto run
echo  Dang tai ban Portable (141KB)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Portable.ps1' -OutFile '%PORTABLE%' -UseBasicParsing"
if not exist "%PORTABLE%" (
  echo  [X] Tai that bai. Kiem tra mang roi thu lai, hoac tai thu cong file Sophia-Ultra-Portable.ps1 tu GitHub NggKhaiz/MOLIK_WINLIK
  pause
  exit /b 1
)
:run
powershell -NoProfile -ExecutionPolicy Bypass -File "%PORTABLE%" %*
echo.
pause
