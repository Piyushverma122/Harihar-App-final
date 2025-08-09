@echo off
echo ========================================
echo    SSIPMT App Icon Setup Script
echo ========================================
echo.

echo Step 1: Creating icon directories...
if not exist "assets\icons" mkdir "assets\icons"
if not exist "android\app\src\main\res\mipmap-mdpi" mkdir "android\app\src\main\res\mipmap-mdpi"
if not exist "android\app\src\main\res\mipmap-hdpi" mkdir "android\app\src\main\res\mipmap-hdpi"
if not exist "android\app\src\main\res\mipmap-xhdpi" mkdir "android\app\src\main\res\mipmap-xhdpi"
if not exist "android\app\src\main\res\mipmap-xxhdpi" mkdir "android\app\src\main\res\mipmap-xxhdpi"
if not exist "android\app\src\main\res\mipmap-xxxhdpi" mkdir "android\app\src\main\res\mipmap-xxxhdpi"

echo Step 2: Required SSIPMT Logo Sizes:
echo.
echo Place the SSIPMT logo in these sizes:
echo   assets/icons/app_icon_512.png  (512x512 - Master Icon)
echo   assets/icons/app_icon_192.png  (192x192 - High Res)
echo   assets/icons/app_icon_144.png  (144x144 - XXHdpi)
echo   assets/icons/app_icon_96.png   (96x96   - XHdpi)
echo   assets/icons/app_icon_72.png   (72x72   - Hdpi)
echo   assets/icons/app_icon_48.png   (48x48   - Mdpi)
echo.

echo Step 3: Run flutter_launcher_icons:
echo   flutter pub get
echo   flutter pub run flutter_launcher_icons:main
echo.

echo Step 4: Build and test:
echo   flutter build apk
echo.

echo ========================================
echo Icon setup directories created!
echo Now add your SSIPMT logo files.
echo ========================================
pause
