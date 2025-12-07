@echo off
echo ========================================
echo   Flutter Web Deployment Script
echo   Deploying to Firebase Hosting
echo ========================================
echo.

echo [1/4] Cleaning previous build...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b %errorlevel%
)

echo.
echo [2/4] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b %errorlevel%
)

echo.
echo [3/4] Building Flutter web app for production...
call flutter build web --release --base-href /
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b %errorlevel%
)

echo.
echo [4/4] Deploying to Firebase Hosting...
call firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ERROR: Deployment failed!
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo   Deployment completed successfully!
echo ========================================
echo.
echo Your app is now live at:
echo https://e-learning-management-79797.web.app
echo https://e-learning-management-79797.firebaseapp.com
echo.
pause
