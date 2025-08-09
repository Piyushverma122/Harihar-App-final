# HariHar Pathshala Flutter App

A Flutter version of the HariHar Pathshala educational portal for Raipur district.

## Overview

**एक पेड़ माँ के नाम 2.0** is an educational portal designed for teachers and supervisors in the Raipur district to manage tree planting activities, student registrations, photo uploads, and progress tracking.

## Features

### For Teachers (शिक्षक)
- **Photo Upload**: Upload photos of students with trees and teachers
- **Student Registration**: Register student information
- **Certificate Download**: Generate and download certificates for students
- **Previous Photos**: View previously uploaded photos
- **Progress Tracking**: Track personal progress and activities

### For Supervisors/CRC (सुपरवाइजर)
- **School Monitoring**: Monitor school activities and progress
- **Teacher Reports**: View and manage teacher activity reports
- **Data Verification**: Verify uploaded data and information
- **Progress Tracking**: Track district-wide progress
- **Statistics Dashboard**: View comprehensive statistics

## Technical Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Language Support**: Hindi with Devanagari script
- **Image Handling**: image_picker, file_picker
- **PDF Generation**: pdf, printing packages
- **Local Storage**: shared_preferences, path_provider

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── src/
    ├── providers/                      # State management
    │   ├── app_state_provider.dart     # App navigation & state
    │   └── theme_provider.dart         # Theme management
    ├── navigation/
    │   └── app_navigator.dart          # Navigation logic
    └── screens/                        # All app screens
        ├── user_type_selection_screen.dart
        ├── teacher_login_screen.dart
        ├── crc_login_screen.dart
        ├── teacher_home_screen.dart
        ├── crc_home_screen.dart
        ├── photo_upload_screen.dart
        ├── students_data_screen.dart
        ├── certificate_screen.dart
        └── ...
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 2.17.0 or higher
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd HariHar-Pathshala-Flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Key Features Implementation

### Multi-language Support
- Primary language: Hindi (हिंदी)
- Devanagari script support
- Custom fonts for proper Hindi text rendering

### User Roles
- **Teacher Role**: Focus on photo uploads, student data, and certificates
- **Supervisor Role**: Monitoring, reports, and verification tools

### Navigation
- Custom navigation system using Provider state management
- Screen-based navigation without traditional routes
- Back navigation handling for different user roles

### Responsive Design
- Adaptive layouts for different screen sizes
- Material Design 3 components
- Custom color scheme reflecting the green theme

## App Flow

1. **User Type Selection**: Choose between Teacher or Supervisor login
2. **Authentication**: Role-specific login screens
3. **Dashboard**: Customized home screens based on user role
4. **Feature Access**: Navigate to specific features based on permissions
5. **Data Management**: Upload, view, and manage educational data

## Color Scheme

- **Primary Green**: #2E7D32 (Dark Green)
- **Light Green**: #E8F5E8 (Background)
- **Blue**: #2196F3 (Supervisor theme)
- **Purple**: #9C27B0 (Certificate features)
- **Orange**: #FF5722 (Photo features)

## Dependencies

### Core Dependencies
```yaml
flutter: SDK
provider: ^6.1.1          # State management
image_picker: ^1.0.4      # Image selection
file_picker: ^6.1.1       # File selection
shared_preferences: ^2.2.2 # Local storage
path_provider: ^2.1.1     # File paths
pdf: ^3.10.7              # PDF generation
printing: ^5.11.0         # PDF printing
permission_handler: ^11.1.0 # Permissions
gallery_saver: ^2.3.2     # Save to gallery
```

## Development Notes

### State Management
- Uses Provider pattern for clean separation of concerns
- AppStateProvider manages navigation and user state
- ThemeProvider handles app theming

### Localization
- All UI text in Hindi
- English subtitles for clarity
- Future support for multiple languages possible

### Performance
- Optimized image handling
- Lazy loading for screens
- Efficient state updates

## Future Enhancements

- [ ] Complete implementation of all feature screens
- [ ] Database integration for data persistence
- [ ] Offline support with local caching
- [ ] Push notifications for updates
- [ ] Advanced analytics and reporting
- [ ] Multi-language support expansion
- [ ] Dark mode theme support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is developed for educational purposes for the Raipur district education portal.

## Support

For technical support or feature requests, please contact the development team.

---

**एक पेड़ माँ के नाम 2.0** - A Digital Initiative for Environmental Education
