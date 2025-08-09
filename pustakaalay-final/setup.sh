#!/bin/bash

# HariHar Pathshala Flutter Setup Script
echo "🌳 HariHar Pathshala Flutter Setup 🌳"
echo "======================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter is installed"

# Check Flutter doctor
echo "🔍 Checking Flutter setup..."
flutter doctor

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate missing files if needed
echo "🔧 Analyzing project..."
flutter analyze

# Check for any issues
echo "🧪 Running basic checks..."

# Create missing asset files if they don't exist
echo "📁 Checking asset directories..."
mkdir -p assets/images
mkdir -p assets/fonts

# Download a basic Hindi font (optional)
echo "📝 To add Hindi font support:"
echo "1. Download Noto Sans Devanagari font from Google Fonts"
echo "2. Place font files in assets/fonts/ directory"
echo "3. Run 'flutter pub get' again"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📱 To run the app:"
echo "   flutter run"
echo ""
echo "🔧 To build for release:"
echo "   flutter build apk --release"
echo ""
echo "📚 Key features implemented:"
echo "   ✅ User type selection"
echo "   ✅ Teacher & CRC login"
echo "   ✅ Home dashboards"
echo "   ✅ Photo upload (with image picker)"
echo "   ✅ Navigation system"
echo "   ✅ State management (Provider)"
echo "   ✅ Hindi language support"
echo ""
echo "🚧 Features to be completed:"
echo "   🔄 Student registration form"
echo "   🔄 Certificate generation"
echo "   🔄 Data verification"
echo "   🔄 Progress tracking"
echo "   🔄 School monitoring"
echo "   🔄 Reports generation"
echo ""
echo "Happy coding! 🚀"
