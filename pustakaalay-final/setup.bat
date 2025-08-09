@echo off
echo 🌳 HariHar Pathshala Flutter Setup 🌳
echo ======================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    echo Visit: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter is installed

REM Check Flutter doctor
echo 🔍 Checking Flutter setup...
flutter doctor

REM Get dependencies
echo 📦 Getting Flutter dependencies...
flutter pub get

REM Generate missing files if needed
echo 🔧 Analyzing project...
flutter analyze

REM Check for any issues
echo 🧪 Running basic checks...

REM Create missing asset directories
echo 📁 Checking asset directories...
if not exist "assets\images" mkdir "assets\images"
if not exist "assets\fonts" mkdir "assets\fonts"

echo.
echo 🎉 Setup complete!
echo.
echo 📱 To run the app:
echo    flutter run
echo.
echo 🔧 To build for release:
echo    flutter build apk --release
echo.
echo 📚 Key features implemented:
echo    ✅ User type selection
echo    ✅ Teacher ^& CRC login
echo    ✅ Home dashboards
echo    ✅ Photo upload (with image picker)
echo    ✅ Navigation system
echo    ✅ State management (Provider)
echo    ✅ Hindi language support
echo.
echo 🚧 Features to be completed:
echo    🔄 Student registration form
echo    🔄 Certificate generation
echo    🔄 Data verification
echo    🔄 Progress tracking
echo    🔄 School monitoring
echo    🔄 Reports generation
echo.
echo Happy coding! 🚀
pause
