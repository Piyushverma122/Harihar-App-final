class ApiConfig {
  // Base URL for the backend API
  // Choose the appropriate URL based on your device:

  // For Android Emulator:
  static const String _androidEmulatorUrl = 'http://10.0.2.2:5003';

  // For Physical Device or iOS Simulator (use your computer's IP):
  static const String _physicalDeviceUrl = 'http://192.168.1.3:5003';

  // For Desktop/Web development:
  static const String _desktopUrl = 'http://127.0.0.1:5003';

  // Current active URL - Change this based on your testing device
  static const String baseUrl =
      _androidEmulatorUrl; // Switch between the above URLs

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
