class ApiConfig {
  // Base URL for the backend API
  // Choose the appropriate URL based on your device:

  // Production server URL
  // ignore: unused_field
  static const String _productionUrl = 'http://165.22.208.62:5003';

  // For Android Emulator (if needed for local testing):
  // ignore: unused_field
  static const String _androidEmulatorUrl = 'http://10.0.2.2:5003';

  // For Physical Device or iOS Simulator (use your computer's IP):
  // ignore: unused_field
  static const String _physicalDeviceUrl = 'http://192.168.1.7:5003';

  // For Desktop/Web development:
  // ignore: unused_field
  static const String _desktopUrl = 'http://127.0.0.1:5003';

  // Flexible base URL with build-time configuration
  // Default to production server for live app usage
  // Override with: flutter run --dart-define=API_BASE=<url>
  // Example URLs available:
  // - Production: flutter run --dart-define=API_BASE=$_productionUrl
  // - Emulator: flutter run --dart-define=API_BASE=$_androidEmulatorUrl
  // - Physical: flutter run --dart-define=API_BASE=$_physicalDeviceUrl
  // - Desktop: flutter run --dart-define=API_BASE=$_desktopUrl
  static const String baseUrl = String.fromEnvironment('API_BASE',
      defaultValue: 'http://165.22.208.62:5003');

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String adminLoginEndpoint = '/admin_login';
  static const String registerEndpoint = '/register';
  static const String fetchStudentEndpoint = '/fetch_student';
  static const String fetchSchoolEndpoint = '/fetch_school';
  static const String teacherDashboardEndpoint = '/teacher_dashboard';
  static const String supervisorDashboardEndpoint = '/supervisor_dashboard';
  static const String checkVerifiedStatusEndpoint = '/check_verified_status';
  static const String verifyStudentEndpoint = '/verify_student';
  static const String getPhotoEndpoint = '/get_photo';
  static const String webDashboardEndpoint = '/web_dashboard';
  static const String dataEndpoint = '/data';

  // Complete URLs for easy access
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get adminLoginUrl => '$baseUrl$adminLoginEndpoint';
  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get fetchStudentUrl => '$baseUrl$fetchStudentEndpoint';
  static String get fetchSchoolUrl => '$baseUrl$fetchSchoolEndpoint';
  static String get teacherDashboardUrl => '$baseUrl$teacherDashboardEndpoint';
  static String get supervisorDashboardUrl =>
      '$baseUrl$supervisorDashboardEndpoint';
  static String get checkVerifiedStatusUrl =>
      '$baseUrl$checkVerifiedStatusEndpoint';
  static String get verifyStudentUrl => '$baseUrl$verifyStudentEndpoint';
  static String get getPhotoUrl => '$baseUrl$getPhotoEndpoint';
  static String get webDashboardUrl => '$baseUrl$webDashboardEndpoint';
  static String get dataUrl => '$baseUrl$dataEndpoint';

  // Helper method to build full URLs
  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }

  // Standard headers for API requests
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Multipart headers for file uploads
  static Map<String, String> get multipartHeaders => {
        'Accept': 'application/json',
      };
}
