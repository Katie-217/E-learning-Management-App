#!/bin/bash

echo "========================================"
echo "  Flutter Web Deployment Script"
echo "  Deploying to Firebase Hosting"
echo "========================================"
echo ""

echo "[1/4] Cleaning previous build..."
flutter clean
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter clean failed!"
    exit 1
fi

echo ""
echo "[2/4] Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter pub get failed!"
    exit 1
fi

echo ""
echo "[3/4] Building Flutter web app for production..."
flutter build web --release
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed!"
    exit 1
fi

echo ""
echo "[4/4] Deploying to Firebase Hosting..."
firebase deploy --only hosting
if [ $? -ne 0 ]; then
    echo "ERROR: Deployment failed!"
    exit 1
fi

echo ""
echo "========================================"
echo "  Deployment completed successfully!"
echo "========================================"
echo ""
echo "Your app is now live at:"
echo "https://e-learning-management-79797.web.app"
echo "https://e-learning-management-79797.firebaseapp.com"
echo ""
