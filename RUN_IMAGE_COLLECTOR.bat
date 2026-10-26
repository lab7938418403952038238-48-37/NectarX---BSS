@echo off
setlocal
title NectarX Image Collector
cd /d "%~dp0"

echo ==========================================
echo       NectarX Image Collector
echo ==========================================
echo.

where py >nul 2>nul
if errorlevel 1 (
    echo ERROR: Python was not found.
    echo Install Python 3 from https://www.python.org/downloads/windows/
    echo During installation, enable "Add Python to PATH".
    echo Then double-click this file again.
    echo.
    pause
    exit /b 1
)

echo Checking required image library...
py -m pip --version >nul 2>nul
if errorlevel 1 (
    echo ERROR: pip is not available in this Python installation.
    echo Repair or reinstall Python with pip enabled.
    echo.
    pause
    exit /b 1
)

py -c "import PIL" >nul 2>nul
if errorlevel 1 (
    echo Pillow is missing. Installing it now...
    py -m pip install --user pillow
    if errorlevel 1 (
        echo.
        echo ERROR: Pillow installation failed.
        echo Check your internet connection and try again.
        pause
        exit /b 1
    )
)

echo Starting collector...
echo Keep this window open while using the collector.
echo.
py image_collector.py
if errorlevel 1 (
    echo.
    echo The collector closed with an error. Read the message above.
    pause
)
endlocal
