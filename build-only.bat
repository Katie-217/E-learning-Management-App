@echo off
echo ========================================
echo   Flutter Web Build Script
echo   Building for production (no deploy)
echo ========================================
echo.

echo [1/3] Cleaning previous build...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Building Flutter web app for production...
call flutter build web --release

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   Build completed successfully!
    echo ========================================
    echo.
    echo Build output is in: build\web
    echo.
    echo To test locally, run:
    echo   cd build\web
    echo   python -m http.server 8000
    echo.
) else (
    echo.
    echo ERROR: Build failed!
)

pause
