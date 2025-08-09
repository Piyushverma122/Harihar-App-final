# हरिहर पाठशाला App Icon Setup Guide

## Required Icon Sizes

Place your app icon images in the following directories with the name `harihar_pathshala_icon.png`:

### Android Icon Sizes:
- `android/app/src/main/res/mipmap-mdpi/harihar_pathshala_icon.png` (48x48 px)
- `android/app/src/main/res/mipmap-hdpi/harihar_pathshala_icon.png` (72x72 px)
- `android/app/src/main/res/mipmap-xhdpi/harihar_pathshala_icon.png` (96x96 px)
- `android/app/src/main/res/mipmap-xxhdpi/harihar_pathshala_icon.png` (144x144 px)
- `android/app/src/main/res/mipmap-xxxhdpi/harihar_pathshala_icon.png` (192x192 px)

### iOS Icon Sizes (if needed):
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  - Multiple sizes from 20x20 to 1024x1024

## Icon Design Guidelines:

Based on the provided green icon design with school building and leaves:

1. **Background**: Green gradient (#4CAF50 to #388E3C)
2. **Main Element**: White school building with flag
3. **Bottom Element**: Two green leaves
4. **Text**: "हरिहर पाठशाला" in white Devanagari script
5. **Style**: Rounded square with subtle shadow

## Recommended Tools:

1. **Flutter Launcher Icons Package**: 
   Add to pubspec.yaml:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   
   flutter_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
     adaptive_icon_background: "#4CAF50"
     adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
   ```

2. **Online Icon Generator**:
   - Use https://appicon.co/ 
   - Upload a 1024x1024 px version of your icon
   - Download all sizes automatically

## Manual Setup:

If you have the icon file ready:

1. Create a 1024x1024 px PNG with transparent background
2. Use online tools to generate all required sizes
3. Place files in the directories listed above
4. Run `flutter clean && flutter build apk` to rebuild

## Current Configuration:

The app is already configured to use `harihar_pathshala_icon` as the icon name in:
- AndroidManifest.xml
- App label is set to "हरिहर पाठशाला"

Just add the actual icon files to complete the setup!
