# API Configuration Guide

This guide explains how to configure the API base URL for different environments and devices.

## Configuration File Location
`lib/src/config/api_config.dart`

## Available URLs

### 1. Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:5003';
```
- Use this when testing on Android emulator
- `10.0.2.2` is the special IP that maps to the host machine's localhost

### 2. Physical Device
```dart
static const String baseUrl = 'http://192.168.1.3:5003';
```
- Use this when testing on a physical Android/iOS device
- Replace `192.168.1.3` with your computer's actual IP address
- Find your IP with: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)

### 3. Desktop/Web Development
```dart
static const String baseUrl = 'http://127.0.0.1:5003';
```
- Use this for Flutter desktop apps or web development
- Also used for testing API scripts from development machine

## How to Switch URLs

### Method 1: Edit api_config.dart
1. Open `lib/src/config/api_config.dart`
2. Change the `baseUrl` constant to the appropriate URL
3. Hot restart your Flutter app

### Method 2: Use Environment-Based Configuration (Recommended)
Create different configurations for different environments:

```dart
class ApiConfig {
  static const String baseUrl = kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux
      ? 'http://127.0.0.1:5003'          // Desktop/Web
      : 'http://10.0.2.2:5003';          // Mobile (emulator)
}
```

## Backend Server
Make sure your backend server is running:
```bash
cd pathshala_backend
python app.py
```

Server should show:
```
* Running on http://127.0.0.1:5003
* Running on http://192.168.1.3:5003
```

## Testing API Connection

### From Development Machine
```bash
cd pustakaalay-final
dart test_api_connection.dart
```

### Common Issues

1. **Connection Refused**: Backend server not running
2. **Timeout**: Wrong IP address for your device type
3. **CORS Error**: Backend CORS configuration issue

### Troubleshooting

1. **Check if backend is running**:
   ```bash
   curl http://127.0.0.1:5003/
   ```

2. **Find your computer's IP** (for physical device):
   ```bash
   # Windows
   ipconfig | findstr IPv4
   
   # Mac/Linux  
   ifconfig | grep inet
   ```

3. **Test from Flutter**:
   - Android Emulator: Use `10.0.2.2:5003`
   - Physical Device: Use your computer's IP
   - Desktop: Use `127.0.0.1:5003`

## Current Configuration
The app is currently configured for **Android Emulator** with URL: `http://10.0.2.2:5003`

Switch the `baseUrl` in `api_config.dart` based on your testing device.
