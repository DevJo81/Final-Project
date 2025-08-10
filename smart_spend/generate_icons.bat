@echo off
echo Generating Smart Spend App Icons...
echo.

echo Step 1: Getting Flutter dependencies...
flutter pub get

echo.
echo Step 2: Generating app icons...
flutter pub run flutter_launcher_icons:main

echo.
echo Step 3: Icons generated successfully!
echo.
echo The app now has the wallet icon on all platforms:
echo - Android: launcher_icon
echo - iOS: App icon
echo - Web: Favicon and PWA icons
echo - Windows: Desktop icon
echo - macOS: App icon
echo.
echo You can now build and run the app to see the new icon!
pause 