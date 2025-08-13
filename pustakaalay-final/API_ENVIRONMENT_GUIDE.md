# API Environment Configuration Guide

## Current Setup
Your app now uses flexible base URL configuration that can be set at build/run time.

**Default**: Android Emulator (`http://10.0.2.2:5003`)

## Running on Different Devices

### Android Emulator
```bash
# Uses default (10.0.2.2:5003)
flutter run

# Or explicitly set
flutter run --dart-define=API_BASE=http://10.0.2.2:5003
```

### Physical Android Device
```bash
# Replace 192.168.1.3 with your PC's actual IP address
flutter run --dart-define=API_BASE=http://192.168.1.3:5003
```

### Remote Server (Production)
```bash
flutter run --dart-define=API_BASE=http://165.22.208.62:5003
```

### Desktop/Web Development
```bash
flutter run --dart-define=API_BASE=http://127.0.0.1:5003
```

## Building APK

### For Android Emulator Testing
```bash
flutter build apk --dart-define=API_BASE=http://10.0.2.2:5003
```

### For Physical Device Distribution
```bash
# First, find your PC's IP address:
ipconfig | findstr IPv4

# Then build with your PC's IP:
flutter build apk --dart-define=API_BASE=http://192.168.1.3:5003
```

### For Production Release
```bash
flutter build apk --release --dart-define=API_BASE=http://165.22.208.62:5003
```

## Troubleshooting Network Issues

### Check Backend Server
```bash
# Verify server is running on all interfaces
netstat -an | findstr :5003

# Test from browser
# Emulator: http://10.0.2.2:5003/
# Phone: http://192.168.1.3:5003/ (use your PC IP)
```

### Windows Firewall
```bash
# Allow inbound connections on port 5003
netsh advfirewall firewall add rule name="Flutter Backend" dir=in action=allow protocol=TCP localport=5003
```

### Find Your PC's IP Address
```bash
ipconfig | findstr IPv4
```

## Status Code: 0 Fixes Applied
- ✅ Added `android:usesCleartextTraffic="true"` to AndroidManifest.xml
- ✅ Configured flexible base URL with build-time environment variables
- ✅ Default to emulator-compatible URL (10.0.2.2:5003)

## Quick Device Type Detection
- **Android Emulator**: Use `http://10.0.2.2:5003`
- **Physical Phone**: Use `http://[YOUR_PC_IP]:5003`
- **iPhone Simulator**: Use `http://[YOUR_PC_IP]:5003`
- **Desktop/Web**: Use `http://127.0.0.1:5003`
