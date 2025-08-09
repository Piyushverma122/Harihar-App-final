import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';

class ApiService {
  // Use configurations from ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;
  static Map<String, String> get headers => ApiConfig.headers;
  static Map<String, String> get multipartHeaders => ApiConfig.multipartHeaders;

  // Teacher login method - Uses school table since teacher table doesn't exist
  static Future<Map<String, dynamic>> teacherLogin({
    required String udiseCode,
    required String username,
    required String password,
  }) async {
    try {
      final requestBody = {
        'udise_code': udiseCode,
        'password': password,
      };

      print('Teacher Login Request: $requestBody');
      print('URL: ${ApiConfig.loginUrl}');

      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        print('Warning: Empty response body from server');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message': 'सर्वर से कोई डेटा नहीं मिला। कृपया सर्वर की जांच करें।'
          },
        };
      }

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Teacher login response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message':
                'सर्वर से गलत डेटा प्राप्त हुआ। Response: ${response.body}'
          },
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Teacher Login Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage =
            'सर्वर से गलत प्रारूप में डेटा प्राप्त हुआ। कृपया सर्वर कॉन्फ़िगरेशन की जांच करें।';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'इंटरनेट कनेक्शन की जांच करें';
      } else {
        errorMessage = 'लॉगिन में त्रुटि हुई: $e';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // School login method
  static Future<Map<String, dynamic>> schoolLogin({
    required String udiseCode,
    required String password,
  }) async {
    try {
      final requestBody = {
        'udise_code': udiseCode,
        'password': password,
      };

      print('School Login Request: $requestBody');
      print('URL: ${ApiConfig.loginUrl}');

      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        print('Warning: Empty response body from server');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message': 'सर्वर से कोई डेटा नहीं मिला। कृपया सर्वर की जांच करें।'
          },
        };
      }

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: School login response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message':
                'सर्वर से गलत डेटा प्राप्त हुआ। Response: ${response.body}'
          },
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('School Login Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage =
            'सर्वर से गलत प्रारूप में डेटा प्राप्त हुआ। कृपया सर्वर कॉन्फ़िगरेशन की जांच करें।';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'इंटरनेट कनेक्शन की जांच करें';
      } else {
        errorMessage = 'लॉगिन में त्रुटि हुई: $e';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // Supervisor/CRC login method
  static Future<Map<String, dynamic>> supervisorLogin({
    required String username,
    required String password,
  }) async {
    try {
      final requestBody = {
        'username': username,
        'password': password,
        'role': 'supervisor',
      };

      print('Supervisor Login Request: $requestBody');
      print('URL: ${ApiConfig.loginUrl}');

      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        print('Warning: Empty response body from server');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message': 'सर्वर से कोई डेटा नहीं मिला। कृपया सर्वर की जांच करें।'
          },
        };
      }

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Supervisor login response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message':
                'सर्वर से गलत डेटा प्राप्त हुआ। Response: ${response.body}'
          },
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Supervisor Login Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage =
            'सर्वर से गलत प्रारूप में डेटा प्राप्त हुआ। कृपया सर्वर कॉन्फ़िगरेशन की जांच करें।';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'इंटरनेट कनेक्शन की जांच करें';
      } else {
        errorMessage = 'लॉगिन में त्रुटि हुई: $e';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // Student registration endpoint
  static const String registrationEndpoint = '/register';

  // Complete registration URL
  static String get registrationUrl => ApiConfig.registerUrl;

  // Student registration method
  static Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String schoolName,
    required String className,
    String? mobile, // Keep mobile as optional but don't send to backend
    required String nameOfTree,
    required File plantImage,
    required File certificateImage,
    required String udiseCode,
    required String dinank, // Changed from employeeId to dinank (date)
  }) async {
    try {
      print('🔍 Pre-upload file validation...');

      // Validate files exist and are readable
      if (!await plantImage.exists()) {
        throw Exception('Plant image file does not exist: ${plantImage.path}');
      }

      if (!await certificateImage.exists()) {
        throw Exception(
            'Certificate image file does not exist: ${certificateImage.path}');
      }

      final int plantSize = await plantImage.length();
      final int certSize = await certificateImage.length();

      if (plantSize == 0) {
        throw Exception('Plant image file is empty');
      }

      if (certSize == 0) {
        throw Exception('Certificate image file is empty');
      }

      print('✅ File validation passed:');
      print('  Plant image: ${plantImage.path} (${plantSize} bytes)');
      print('  Certificate: ${certificateImage.path} (${certSize} bytes)');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(registrationUrl));

      // Add form fields - According to new backend schema
      request.fields.addAll({
        'name': name,
        'school_name': schoolName,
        'class': className,
        'name_of_tree': nameOfTree,
        'udise_code': udiseCode,
        'dinank': dinank, // Backend expects dinank (date)
      });

      print('=== STUDENT REGISTRATION DEBUG ===');
      print('Dinank (Date) being sent: $dinank');
      print('All form fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });

      // Add image files with better error handling
      try {
        request.files.add(await http.MultipartFile.fromPath(
          'plant_image',
          plantImage.path,
        ));
        print('✅ Plant image added to request');
      } catch (e) {
        throw Exception('Failed to add plant image to request: $e');
      }

      try {
        request.files.add(await http.MultipartFile.fromPath(
          'certificate',
          certificateImage.path,
        ));
        print('✅ Certificate image added to request');
      } catch (e) {
        throw Exception('Failed to add certificate image to request: $e');
      }

      print('Student Registration Request Fields: ${request.fields}');
      print(
          'Student Registration Request Files: ${request.files.map((f) => f.field)}');
      print('URL: $registrationUrl');

      // Send the request
      print('📤 Sending registration request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
          true) {
        print('Warning: Response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message': 'Server returned non-JSON response: ${response.body}'
          },
        };
      }

      final responseData = jsonDecode(response.body);

      // Debug: Check if employee_id is in response
      print('=== REGISTRATION RESPONSE DEBUG ===');
      if (responseData is Map && responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is Map) {
          print('Response employee_id: ${data['employee_id']}');
          print('Response all fields: ${data.keys}');
        }
      }

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('❌ Student Registration Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is PathNotFoundException) {
        errorMessage = 'फोटो फाइल नहीं मिली। कृपया फोटो दोबारा सेलेक्ट करें।';
      } else if (e is FormatException) {
        errorMessage = 'सर्वर रिस्पॉन्स में त्रुटि। कृपया बाद में कोशिश करें।';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'इंटरनेट कनेक्शन की जांच करें।';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'कनेक्शन टाइमआउट। कृपया दोबारा कोशिश करें।';
      } else if (e.toString().contains('Failed to add') &&
          e.toString().contains('image')) {
        errorMessage = 'फोटो अपलोड में समस्या। कृपया फोटो दोबारा सेलेक्ट करें।';
      } else {
        errorMessage = 'नेटवर्क एरर: $e';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // Update student photo method
  static Future<Map<String, dynamic>> updateStudentPhoto({
    required String studentId,
    required File photoFile,
  }) async {
    try {
      final url = ApiConfig.getUrl('update_student_photo');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add form fields
      request.fields.addAll({
        'student_id': studentId,
      });

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        photoFile.path,
      ));

      print('Update Student Photo Request Fields: ${request.fields}');
      print(
          'Update Student Photo Request Files: ${request.files.map((f) => f.field)}');
      print('URL: $url');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
          true) {
        print('Warning: Response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message': 'Server returned non-JSON response: ${response.body}'
          },
        };
      }

      // Parse JSON response
      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Update Student Photo Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage =
            'Server response format error. Please check server configuration.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage =
            'Network connection error. Please check your internet connection.';
      } else {
        errorMessage = 'Network error occurred: $e';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // Get students by UDISE code
  static Future<Map<String, dynamic>> getStudentsByUdise(
      String udiseCode) async {
    try {
      final url = ApiConfig.fetchStudentUrl;

      final requestBody = {
        'udise_code': udiseCode,
      };

      print('Get Students Request URL: $url');
      print('Get Students Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message':
                'सर्वर से गलत डेटा प्राप्त हुआ। कृपया बाद में पुनः प्रयास करें।'
          },
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Get Students Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage = 'सर्वर से डेटा प्राप्त करने में समस्या है';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'इंटरनेट कनेक्शन की जांच करें';
      } else {
        errorMessage = 'डेटा लोड करने में त्रुटि हुई';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // Get teachers by UDISE code
  static Future<Map<String, dynamic>> getTeachersByUdise(
      String udiseCode) async {
    try {
      final url = ApiConfig.getUrl('fetch_teacher');

      final requestBody = {
        'udise_code': udiseCode,
      };

      print('Get Teachers Request URL: $url');
      print('Get Teachers Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'message':
                'सर्वर से गलत डेटा प्राप्त हुआ। कृपया बाद में पुनः प्रयास करें।'
          },
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Get Teachers Error: $e');
      print('Error Type: ${e.runtimeType}');

      // Handle different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage = 'सर्वर से डेटा प्राप्त करने में समस्या है';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'इंटरनेट कनेक्शन की जांच करें';
      } else {
        errorMessage = 'डेटा लोड करने में त्रुटि हुई';
      }

      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': errorMessage},
      };
    }
  }

  // Get image from backend by filename with retry mechanism
  static Future<Map<String, dynamic>> getImageByFilename(
      String filename) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final url = ApiConfig.getPhotoUrl;

        final requestBody = {
          'file_name': filename,
        };

        print('Get Image Request URL: $url (Attempt $attempt)');
        print('Get Image Request Body: $requestBody');

        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'image/*',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(Duration(
                seconds: attempt * 15)); // Increase timeout with each attempt

        print('Image Response Status: ${response.statusCode}');
        print(
            'Image Response Content-Type: ${response.headers['content-type']}');
        print(
            'Image Response Content-Length: ${response.headers['content-length']}');

        if (response.statusCode == 200) {
          print('Image loaded successfully on attempt $attempt');
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': response.bodyBytes, // Image bytes
            'contentType': response.headers['content-type'] ?? 'image/jpeg',
          };
        } else {
          print('Image fetch failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');

          // Parse error message if it's JSON
          String errorMessage = 'फाइल नहीं मिली या सर्वर एरर';
          try {
            if (response.headers['content-type']
                    ?.contains('application/json') ==
                true) {
              final errorData = jsonDecode(response.body);
              if (errorData['message'] != null &&
                  errorData['message'].toString().contains('404 Not Found')) {
                errorMessage = 'सर्टिफिकेट फाइल सर्वर पर उपलब्ध नहीं है';
              }
            }
          } catch (e) {
            print('Could not parse error response: $e');
          }

          // Don't retry for 404 or other client errors, or when file doesn't exist
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return {
              'success': false,
              'statusCode': response.statusCode,
              'data': {'message': errorMessage},
            };
          }
        }
      } catch (e) {
        print('Get Image Error (Attempt $attempt): $e');
        print('Error Type: ${e.runtimeType}');

        // If this is the last attempt, return error
        if (attempt == 3) {
          String errorMessage;
          if (e.toString().contains('Connection closed')) {
            errorMessage = 'फाइल डाउनलोड में समस्या - फाइल खराब हो सकती है';
          } else if (e.toString().contains('TimeoutException')) {
            errorMessage = 'फाइल लोड करने में बहुत समय लग रहा है';
          } else {
            errorMessage = 'नेटवर्क एरर: ${e.toString().split('\n').first}';
          }

          return {
            'success': false,
            'statusCode': 0,
            'data': {'message': errorMessage},
          };
        }

        // Wait before retry
        await Future<void>.delayed(Duration(seconds: attempt));
        print('Retrying image fetch...');
      }
    }

    return {
      'success': false,
      'statusCode': 0,
      'data': {'message': 'फाइल लोड नहीं हो सकी'},
    };
  }

  // Download image from backend with retry mechanism
  static Future<Map<String, dynamic>> downloadImage(String filename) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final url = ApiConfig.getPhotoUrl; // Using same endpoint for download

        final requestBody = {
          'file_name': filename,
        };

        print('Download Image Request URL: $url (Attempt $attempt)');
        print('Download Image Request Body: $requestBody');

        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/octet-stream',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(Duration(
                seconds: attempt * 15)); // Increase timeout with each attempt

        print('Download Response Status: ${response.statusCode}');
        print(
            'Download Response Content-Type: ${response.headers['content-type']}');
        print(
            'Download Response Content-Length: ${response.headers['content-length']}');

        if (response.statusCode == 200) {
          print('Download completed successfully on attempt $attempt');
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': response.bodyBytes, // Image bytes for download
            'filename': filename,
            'contentType': response.headers['content-type'] ?? 'image/jpeg',
          };
        } else {
          print('Download failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');

          // Parse error message if it's JSON
          String errorMessage = 'फाइल नहीं मिली या सर्वर एरर';
          try {
            if (response.headers['content-type']
                    ?.contains('application/json') ==
                true) {
              final errorData = jsonDecode(response.body);
              if (errorData['message'] != null &&
                  errorData['message'].toString().contains('404 Not Found')) {
                errorMessage = 'सर्टिफिकेट फाइल सर्वर पर उपलब्ध नहीं है';
              }
            }
          } catch (e) {
            print('Could not parse error response: $e');
          }

          // Don't retry for 404 or other client errors, or when file doesn't exist
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return {
              'success': false,
              'statusCode': response.statusCode,
              'data': {'message': errorMessage},
            };
          }
        }
      } catch (e) {
        print('Download Image Error (Attempt $attempt): $e');
        print('Error Type: ${e.runtimeType}');

        // If this is the last attempt, return error
        if (attempt == 3) {
          String errorMessage;
          if (e.toString().contains('Connection closed')) {
            errorMessage = 'फाइल डाउनलोड में समस्या - फाइल खराब हो सकती है';
          } else if (e.toString().contains('TimeoutException')) {
            errorMessage = 'डाउनलोड में बहुत समय लग रहा है';
          } else {
            errorMessage = 'डाउनलोड एरर: ${e.toString().split('\n').first}';
          }

          return {
            'success': false,
            'statusCode': 0,
            'data': {'message': errorMessage},
          };
        }

        // Wait before retry
        await Future<void>.delayed(Duration(seconds: attempt));
        print('Retrying download...');
      }
    }

    return {
      'success': false,
      'statusCode': 0,
      'data': {'message': 'डाउनलोड नहीं हो सका'},
    };
  }

  // Get teacher dashboard data
  static Future<Map<String, dynamic>> getTeacherDashboard(
      String udiseCode) async {
    try {
      final url = ApiConfig.teacherDashboardUrl;

      final requestBody = {
        'udise_code': udiseCode,
      };

      print('Teacher Dashboard Request URL: $url');
      print('Teacher Dashboard Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Dashboard Response Status: ${response.statusCode}');
      print('Dashboard Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Dashboard response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Teacher Dashboard Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'डैशबोर्ड डेटा लोड करने में त्रुटि हुई'},
      };
    }
  }

  // Get students for verification (CRC/Supervisor use)
  static Future<Map<String, dynamic>> getStudentsForVerification(
      {String? udiseCode}) async {
    try {
      final url = ApiConfig.checkVerifiedStatusUrl;

      final requestBody = {
        if (udiseCode != null) 'udise_code': udiseCode,
      };

      print('Check Verified Status Request URL: $url');
      print('Check Verified Status Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Check Verified Status Response Status: ${response.statusCode}');
      print('Check Verified Status Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Check verified status response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Check Verified Status Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'डेटा वेरिफिकेशन लोड करने में त्रुटि हुई'},
      };
    }
  }

  // Update student verification status
  static Future<Map<String, dynamic>> updateStudentVerification({
    required int studentId,
    required bool verified,
  }) async {
    try {
      final url = ApiConfig.getUrl('update_verification');

      final requestBody = {
        'student_id': studentId,
        'verified': verified,
      };

      print('Update Verification Request URL: $url');
      print('Update Verification Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Update Verification Response Status: ${response.statusCode}');
      print('Update Verification Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Update verification response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Update Verification Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'वेरिफिकेशन अपडेट करने में त्रुटि हुई'},
      };
    }
  }

  // Verify student by name, mobile and udise code
  static Future<Map<String, dynamic>> verifyStudentByNameMobile({
    required String name,
    required String mobile,
    String? udiseCode,
  }) async {
    try {
      final url = ApiConfig.verifyStudentUrl;

      final requestBody = {
        'name': name,
        'mobile': mobile,
        if (udiseCode != null) 'udise_code': udiseCode,
      };

      print('Verify Student Request URL: $url');
      print('Verify Student Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Verify Student Response Status: ${response.statusCode}');
      print('Verify Student Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Verify student response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Verify Student Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'छात्र सत्यापन में त्रुटि हुई'},
      };
    }
  }

  // Get school dashboard data
  static Future<Map<String, dynamic>> getSchoolDashboard(
      String udiseCode) async {
    try {
      final url = ApiConfig.getUrl('school_dashboard');

      final requestBody = {
        'udise_code': udiseCode,
      };

      print('School Dashboard Request URL: $url');
      print('School Dashboard Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('School Dashboard Response Status: ${response.statusCode}');
      print('School Dashboard Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: School dashboard response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('School Dashboard Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'स्कूल डैशबोर्ड डेटा लोड करने में त्रुटि हुई'},
      };
    }
  }

  // Get supervisor dashboard data
  static Future<Map<String, dynamic>> getSupervisorDashboard({
    String? udiseCode,
  }) async {
    try {
      final url = ApiConfig.supervisorDashboardUrl;

      final requestBody = {
        if (udiseCode != null) 'udise_code': udiseCode,
      };

      print('Supervisor Dashboard Request URL: $url');
      print('Supervisor Dashboard Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Supervisor Dashboard Response Status: ${response.statusCode}');
      print('Supervisor Dashboard Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print('Warning: Supervisor dashboard response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Supervisor Dashboard Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'डैशबोर्ड डेटा लोड करने में त्रुटि हुई'},
      };
    }
  }

  // Get teacher dashboard data by username
  static Future<Map<String, dynamic>> getTeacherDashboardByUsername(
      String username,
      {String? udiseCode}) async {
    try {
      final url = ApiConfig.teacherDashboardUrl;

      final requestBody = <String, dynamic>{
        'username': username,
      };

      // Add UDISE code if provided
      if (udiseCode != null && udiseCode.isNotEmpty) {
        requestBody['udise_code'] = udiseCode;
      }

      print('Teacher Dashboard by Username Request URL: $url');
      print('Teacher Dashboard by Username Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print(
          'Teacher Dashboard by Username Response Status: ${response.statusCode}');
      print('Teacher Dashboard by Username Response Body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') !=
              true &&
          !response.body.trim().startsWith('{')) {
        print(
            'Warning: Teacher dashboard by username response is not JSON format');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'सर्वर से गलत डेटा प्राप्त हुआ।'},
        };
      }

      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Teacher Dashboard by Username Error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {'message': 'शिक्षक डैशबोर्ड डेटा लोड करने में त्रुटि हुई'},
      };
    }
  }

  // Calculate next upload date (7 days after last upload)
  static String getNextUploadDate(String lastUploadDate) {
    try {
      print('=== NEXT UPLOAD DATE DEBUG ===');
      print('Input date string: "$lastUploadDate"');

      final DateTime lastUpload = DateTime.parse(lastUploadDate);
      print('Parsed last upload: $lastUpload');

      final DateTime nextUploadDate = lastUpload.add(const Duration(days: 7));
      print('Calculated next upload: $nextUploadDate');

      final DateTime now = DateTime.now();
      print('Current date: $now');
      print('Days since last upload: ${now.difference(lastUpload).inDays}');

      if (now.isAfter(nextUploadDate)) {
        print('Can upload now - returning "अब अपलोड करें!"');
        return 'अब अपलोड करें!';
      } else {
        // Format as DD/MM/YY
        final String year = nextUploadDate.year.toString().substring(2);
        final String formatted =
            "${nextUploadDate.day.toString().padLeft(2, '0')}/${nextUploadDate.month.toString().padLeft(2, '0')}/$year";
        print('Cannot upload yet - returning: $formatted');
        return formatted;
      }
    } catch (e) {
      print('Error calculating next upload date: $e');
      return ''; // Return empty string instead of "N/A"
    }
  }

  // Get remaining days for next upload
  static int getRemainingDaysForUpload(String lastUploadDate) {
    try {
      print('=== REMAINING DAYS DEBUG ===');
      print('Input date string: "$lastUploadDate"');

      final DateTime lastUpload = DateTime.parse(lastUploadDate);
      print('Parsed last upload: $lastUpload');

      final DateTime nextUploadDate = lastUpload.add(const Duration(days: 7));
      print('Next upload date: $nextUploadDate');

      final DateTime now = DateTime.now();
      print('Current date: $now');

      final int remainingDays = nextUploadDate.difference(now).inDays;
      print('Raw remaining days: $remainingDays');

      final int result = remainingDays > 0 ? remainingDays : 0;
      print('Final remaining days: $result');

      return result;
    } catch (e) {
      print('Error calculating remaining days: $e');
      return 0; // Return 0 instead of -1 for error case
    }
  }

  // Check if student can upload now
  static bool canUploadNow(String lastUploadDate) {
    try {
      print('=== CAN UPLOAD NOW DEBUG ===');
      print('Input date string: "$lastUploadDate"');

      final DateTime lastUpload = DateTime.parse(lastUploadDate);
      print('Parsed last upload: $lastUpload');

      final DateTime nextUploadDate = lastUpload.add(const Duration(days: 7));
      print('Next upload date: $nextUploadDate');

      final DateTime now = DateTime.now();
      print('Current date: $now');
      print('Days since last upload: ${now.difference(lastUpload).inDays}');

      final bool canUpload =
          now.isAfter(nextUploadDate) || now.isAtSameMomentAs(nextUploadDate);
      print('Can upload result: $canUpload');

      return canUpload;
    } catch (e) {
      print('Error checking upload eligibility: $e');
      return false;
    }
  }
}
