@echo off
chcp 65001 >nul
title Sophia Ultra Optimizer - Tick-Select CLI
cd /d "%~dp0"
echo.
echo  ============================================================
echo   SOPHIA ULTRA OPTIMIZER - Toi Uu Sau Windows
echo   Treo Gia Lap 24/7 - Hardcore Gaming - Workstation - Low-Spec
echo  ============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Sophia-Optimizer.ps1" %*
echo.
pause
