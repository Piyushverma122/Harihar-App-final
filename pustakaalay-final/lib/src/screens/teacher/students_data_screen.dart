import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';

class StudentsDataScreen extends StatefulWidget {
  const StudentsDataScreen({super.key});

  @override
  State<StudentsDataScreen> createState() => _StudentsDataScreenState();
}

class _StudentsDataScreenState extends State<StudentsDataScreen> {
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  // Guard to prevent duplicate navigator pops / multiple parallel uploads causing black screen
  bool _isUploadingRePhoto = false;
  String _errorMessage = '';
  final Set<int> _expandedIndices = {}; // Track which cards are expanded
  int _studentsNeedingPhotoUpdate = 0;

  // Filter variables
  String? _selectedClass;
  List<String> _availableClasses = [];

  // Status update controllers - one for each student
  final Map<String, TextEditingController> _statusControllers = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchStudentsData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // Dispose all status controllers
    for (final controller in _statusControllers.values) {
      controller.dispose();
    }
    _statusControllers.clear();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStudents(_searchController.text);
  }

  // Helper method to safely parse HTTP date format
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return null;
    }

    try {
      print('🔄 [DATE] Attempting to parse: "$dateString"');

      // Handle RFC-7231 HTTP date format: "Thu, 07 Aug 2025 01:01:08 GMT"
      if (dateString.contains(',') && dateString.endsWith('GMT')) {
        try {
          // Split and parse the format: "Thu, 07 Aug 2025 01:01:08 GMT"
          final parts = dateString.trim().split(' ');
          if (parts.length >= 5) {
            final day = int.parse(parts[1]);
            final monthName = parts[2];
            final year = int.parse(parts[3]);

            // Parse time if available
            final timePart = parts.length > 4 ? parts[4] : '00:00:00';
            final timeParts = timePart.split(':');
            final hour = timeParts.length > 0 ? int.parse(timeParts[0]) : 0;
            final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
            final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

            final month = _getMonthNumber(monthName);

            final parsedDate =
                DateTime.utc(year, month, day, hour, minute, second);
            print('✅ [DATE] Successfully parsed GMT date: $parsedDate');
            return parsedDate;
          }
        } catch (e) {
          print('❌ [DATE] Error parsing RFC format: $e');
        }
      }

      // Handle simple date format: "2025-08-07"
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString)) {
        final parsedDate = DateTime.parse(dateString);
        print('✅ [DATE] Successfully parsed simple date: $parsedDate');
        return parsedDate;
      }

      // Handle ISO format with milliseconds
      if (dateString.contains('T') || dateString.contains('Z')) {
        final parsedDate = DateTime.parse(dateString);
        print('✅ [DATE] Successfully parsed ISO date: $parsedDate');
        return parsedDate;
      }

      // Handle "YYYY-MM-DD HH:MM:SS" format
      if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')
          .hasMatch(dateString)) {
        final parsedDate = DateTime.parse(dateString);
        print('✅ [DATE] Successfully parsed datetime: $parsedDate');
        return parsedDate;
      }

      print('❌ [DATE] No matching format for: "$dateString"');
      return null;
    } catch (e) {
      print('❌ [DATE] Error parsing date "$dateString": $e');
      return null;
    }
  }

  // Helper to convert month name to number
  int _getMonthNumber(String monthName) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12
    };
    return months[monthName] ?? 1;
  }

  // Method to format date for display
  String _formatDate(String dateString) {
    try {
      print('🔄 [FORMAT] Attempting to format: "$dateString"');

      // Use the improved _parseDate method
      final dateTime = _parseDate(dateString);

      if (dateTime != null) {
        final formatted = DateFormat('dd/MM/yyyy').format(dateTime);
        print('✅ [FORMAT] Successfully formatted: $formatted');
        return formatted;
      } else {
        print('❌ [FORMAT] Failed to parse date, returning raw string');
        return dateString;
      }
    } catch (e) {
      print('❌ [FORMAT] Error formatting date "$dateString": $e');
      return dateString;
    }
  }

  // Helper method to normalize class names (extract numeric part from "1st", "1th", "2nd", etc.)
  String _normalizeClassName(String className) {
    final normalized = className.trim().toLowerCase();
    // Use regex to extract just the number part
    final match = RegExp(r'^(\d+)').firstMatch(normalized);
    return match != null ? match.group(1)! : className.trim();
  }

  // Photo update methods
  bool _isPhotoUpdateRequired(Map<String, dynamic> student) {
    try {
      // Check if there's a last photo update date, otherwise use registration date
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      final dateTimeString =
          lastPhotoUpdateString ?? student['date_time']?.toString();

      final lastUpdateDate = _parseDate(dateTimeString);
      if (lastUpdateDate == null) return false;

      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(lastUpdateDate).inDays;

      // Show red icon only after 7+ days since last photo update
      return daysDifference >= 7;
    } catch (e) {
      print('Error calculating photo update requirement: $e');
      return false;
    }
  }

  bool _isPhotoUpdateLocked(Map<String, dynamic> student) {
    try {
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      final lastUpdateDate = _parseDate(lastPhotoUpdateString);
      if (lastUpdateDate == null) return false;

      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(lastUpdateDate).inDays;

      // Lock photo update for 7 days after last update
      return daysDifference < 7;
    } catch (e) {
      print('Error calculating photo update lock: $e');
      return false;
    }
  }

  int _getDaysSinceLastPhotoUpdate(Map<String, dynamic> student) {
    try {
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      final dateTimeString =
          lastPhotoUpdateString ?? student['date_time']?.toString();

      final lastUpdateDate = _parseDate(dateTimeString);
      if (lastUpdateDate == null) return 0;

      final currentDate = DateTime.now();
      return currentDate.difference(lastUpdateDate).inDays;
    } catch (e) {
      print('Error calculating days since last photo update: $e');
      return 0;
    }
  }

  int _getDaysSinceRegistration(Map<String, dynamic> student) {
    try {
      final dateTimeString = student['date_time']?.toString();
      final registrationDate = _parseDate(dateTimeString);
      if (registrationDate == null) return 0;

      final currentDate = DateTime.now();
      return currentDate.difference(registrationDate).inDays;
    } catch (e) {
      print('Error calculating days since registration: $e');
      return 0;
    }
  }

  // Check if student is newly registered (within last 7 days)
  bool _isNewlyRegistered(Map<String, dynamic> student) {
    try {
      final dateTimeString = student['date_time']?.toString();
      final registrationDate = _parseDate(dateTimeString);
      if (registrationDate == null) return false;

      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(registrationDate).inDays;

      return daysDifference <= 7; // Show as "new" for 7 days
    } catch (e) {
      print('Error checking if newly registered: $e');
      return false;
    }
  }

  void _showPhotoUpdateDialog(Map<String, dynamic> student) {
    final isLocked = _isPhotoUpdateLocked(student);
    final daysSinceLastUpdate = _getDaysSinceLastPhotoUpdate(student);
    final daysUntilUnlock = isLocked ? (7 - daysSinceLastUpdate) : 0;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('फोटो अपडेट करें - ${student['student_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'फोटो अपडेट $daysUntilUnlock दिन बाद उपलब्ध होगा',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('अंतिम फोटो अपडेट के बाद से दिन: $daysSinceLastUpdate'),
                const SizedBox(height: 16),
                const Text('फोटो अपडेट करना आवश्यक है'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('रद्द करें'),
            ),
            if (!isLocked) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('कैमरा'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndUploadPhoto(student, ImageSource.camera);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('गैलरी'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndUploadPhoto(student, ImageSource.gallery);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(
      Map<String, dynamic> student, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadStudentPhoto(student, File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('फोटो सेलेक्ट करने में त्रुटि: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadStudentPhoto(
      Map<String, dynamic> student, File imageFile) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('फोटो अपलोड हो रही है...'),
            ],
          ),
        );
      },
    );

    try {
      // Call API to update student photo
      final result = await ApiService.updateStudentPhoto(
        studentId: student['student_id'].toString(),
        photoFile: imageFile,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (result['success'] == true) {
        // Update the student data locally
        final studentIndex = _allStudents.indexWhere(
          (s) => s['student_id'] == student['student_id'],
        );

        if (studentIndex != -1) {
          setState(() {
            _allStudents[studentIndex]['last_photo_update'] =
                DateTime.now().toIso8601String();
            _studentsNeedingPhotoUpdate =
                _allStudents.where(_isPhotoUpdateRequired).length;
          });
          _filterStudents(_searchController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('फोटो सफलतापूर्वक अपडेट हो गई!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'फोटो अपडेट असफल';
        final data = result['data'];
        if (data != null && data['message'] != null) {
          errorMessage = data['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('नेटवर्क एरर: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhotoUpdateSummary() {
    final studentsNeedingUpdate =
        _allStudents.where(_isPhotoUpdateRequired).toList();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('फोटो अपडेट की आवश्यकता वाले छात्र'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '${studentsNeedingUpdate.length} छात्रों को फोटो अपडेट की आवश्यकता है'),
                const SizedBox(height: 16),
                if (studentsNeedingUpdate.isNotEmpty) ...[
                  const Text('छात्र:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: studentsNeedingUpdate.length,
                      itemBuilder: (context, index) {
                        final student = studentsNeedingUpdate[index];
                        final days = _getDaysSinceRegistration(student);
                        return ListTile(
                          leading:
                              const Icon(Icons.camera_alt, color: Colors.red),
                          title: Text(
                              student['student_name']?.toString() ?? 'N/A'),
                          subtitle: Text('$days दिन पहले रजिस्टर हुआ'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showPhotoUpdateDialog(student);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('बंद करें'),
            ),
          ],
        );
      },
    );
  }

  // Check if re-photo upload is available with 6-upload limit and 30-day cooldown
  bool _isRePhotoUploadAvailable(Map<String, dynamic> student) {
    try {
      // Check re-upload count limit (maximum 6)
      final reuploadCount = (student['reupload_count'] ?? 0) as int;
      if (reuploadCount >= 6) {
        print('🔄 [RE-PHOTO] Maximum limit reached: $reuploadCount/6');
        return false;
      }

      // Get dates
      String? submissionDateString = student['date']?.toString();
      String? lastReuploadDateString =
          student['last_reupload_date']?.toString();

      print('🔄 [RE-PHOTO] Student: ${student['student_name']}');
      print('🔄 [RE-PHOTO] Re-upload count: $reuploadCount/6');
      print('🔄 [RE-PHOTO] Raw date value: "${student['date']}"');
      print('🔄 [RE-PHOTO] Raw last_reupload_date: "$lastReuploadDateString"');

      // If date column is empty or invalid, use date_time as fallback
      if (submissionDateString == null ||
          submissionDateString.isEmpty ||
          submissionDateString == 'N/A' ||
          submissionDateString == 'null') {
        submissionDateString = student['date_time']?.toString();
        print(
            '🔄 [RE-PHOTO] Using date_time as fallback: "$submissionDateString"');

        if (submissionDateString == null ||
            submissionDateString.isEmpty ||
            submissionDateString == 'N/A' ||
            submissionDateString == 'null') {
          print('🔄 [RE-PHOTO] No valid date found, returning false');
          return false;
        }
      }

      print('🔄 [RE-PHOTO] Attempting to parse: "$submissionDateString"');

      // Determine reference date based on re-upload count
      DateTime? referenceDate;

      if (reuploadCount == 0) {
        // First re-upload: check against initial submission date
        referenceDate = _parseDate(submissionDateString);
        print(
            '🔄 [RE-PHOTO] First re-upload - checking against submission date');
      } else {
        // Subsequent re-uploads: check against last re-upload date
        if (lastReuploadDateString == null ||
            lastReuploadDateString.isEmpty ||
            lastReuploadDateString == 'N/A' ||
            lastReuploadDateString == 'null') {
          print('🔄 [RE-PHOTO] No last re-upload date found, returning false');
          return false;
        }

        referenceDate = _parseDate(lastReuploadDateString);
        print(
            '🔄 [RE-PHOTO] Subsequent re-upload - checking against last re-upload date');
      }

      if (referenceDate == null) {
        print('🔄 [RE-PHOTO] Failed to parse reference date, returning false');
        return false;
      }

      // Use device's current date (not server date)
      final currentDate = DateTime.now();
      final daysSinceReference = currentDate.difference(referenceDate).inDays;

      print('🔄 [RE-PHOTO] Reference Date: $referenceDate');
      print('🔄 [RE-PHOTO] Current Date (Device): $currentDate');
      print('🔄 [RE-PHOTO] Days Since Reference: $daysSinceReference');
      print(
          '🔄 [RE-PHOTO] Is Available (>=30 days): ${daysSinceReference >= 30}');

      // Return true if 30+ days have passed and under the limit
      return daysSinceReference >= 30;
    } catch (e) {
      print('🔄 [RE-PHOTO] Error calculating re-photo availability: $e');
      print('🔄 [RE-PHOTO] Student data keys: ${student.keys.toList()}');
      return false;
    }
  }

  // Get days since relevant date for display (submission or last reupload)
  int _getDaysSinceSubmission(Map<String, dynamic> student) {
    try {
      // Check re-upload count to determine reference date
      final reuploadCount = (student['reupload_count'] ?? 0) as int;

      String? referenceDateString;
      String referenceType;

      if (reuploadCount == 0) {
        // Use initial submission date
        referenceDateString = student['date']?.toString();
        if (referenceDateString == null ||
            referenceDateString.isEmpty ||
            referenceDateString == 'N/A' ||
            referenceDateString == 'null') {
          referenceDateString = student['date_time']?.toString();
        }
        referenceType = "submission";
      } else {
        // Use last re-upload date
        referenceDateString = student['last_reupload_date']?.toString();
        referenceType = "last re-upload";
      }

      // Debug: Check what we're getting
      print('🔍 [DATE DEBUG] Reference type: $referenceType');
      print('🔍 [DATE DEBUG] Re-upload count: $reuploadCount');
      print('🔍 [DATE DEBUG] Reference date string: "$referenceDateString"');

      if (referenceDateString == null ||
          referenceDateString.isEmpty ||
          referenceDateString == 'N/A' ||
          referenceDateString == 'null') {
        print('🔍 [DATE DEBUG] No valid reference date found, returning 0');
        return 0;
      }

      print('🔍 [DATE DEBUG] Attempting to parse: "$referenceDateString"');

      // Use the improved _parseDate method for all formats
      DateTime? referenceDate = _parseDate(referenceDateString);

      if (referenceDate == null) {
        print('🔍 [DATE DEBUG] Failed to parse reference date, returning 0');
        return 0;
      }

      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(referenceDate).inDays;

      print('🔍 [DATE DEBUG] Parsed reference date: $referenceDate');
      print('🔍 [DATE DEBUG] Current date: $currentDate');
      print('🔍 [DATE DEBUG] Days difference: $daysDifference');

      return daysDifference;
    } catch (e) {
      print('🔄 [RE-PHOTO] Error calculating days since reference: $e');
      print('🔄 [RE-PHOTO] Student data keys: ${student.keys.toList()}');
      return 0;
    }
  }

  // Check if student has already uploaded re-photo
  bool _hasRePhoto(Map<String, dynamic> student) {
    final certificate = student['certificate']?.toString();
    return certificate != null &&
        certificate.isNotEmpty &&
        certificate != 'N/A';
  }

  // Show re-photo upload dialog
  void _showRePhotoUploadDialog(Map<String, dynamic> student) {
    final daysSinceSubmission = _getDaysSinceSubmission(student);
    final hasRePhoto = _hasRePhoto(student);
    final isAvailable = _isRePhotoUploadAvailable(student);
    final reuploadCount = (student['reupload_count'] ?? 0) as int;
    final remainingUploads = 6 - reuploadCount;

    // Use showModalBottomSheet for better image picker compatibility
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'पौधे की दोबारा तस्वीर',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('छात्र: ${student['student_name']}'),
              const SizedBox(height: 8),
              Text('दोबारा अपलोड: $reuploadCount/6 बार'),
              const SizedBox(height: 4),
              if (remainingUploads > 0)
                Text('बाकी अपलोड: $remainingUploads बार',
                    style: const TextStyle(color: Colors.blue)),
              const SizedBox(height: 16),

              if (reuploadCount >= 6) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'अधिकतम सीमा पूरी हो गई (6/6)',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!isAvailable) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'दोबारा तस्वीर ${30 - daysSinceSubmission} दिन बाद उपलब्ध होगी',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (hasRePhoto) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'दोबारा तस्वीर पहले से अपलोड की गई है',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                    'नई तस्वीर अपलोड करने के लिए नीचे के विकल्प का उपयोग करें:'),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'अब आप पौधे की दोबारा तस्वीर अपलोड कर सकते हैं',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ], // Fixed missing comma before closing
              if (hasRePhoto) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'दोबारा तस्वीर पहले से अपलोड की गई है',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              if (isAvailable) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('कैमरा'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();

                          // Add delay to avoid dialog context issues
                          await Future<void>.delayed(
                              const Duration(milliseconds: 100));

                          try {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 85,
                            );

                            if (image != null) {
                              await _uploadRePhoto(student, File(image.path));
                            }
                          } catch (e) {
                            print('📷 Camera error: $e');
                            if (!e.toString().contains('cancelled')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('कैमरा खोलने में त्रुटि: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('गैलरी'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();

                          // Add delay to avoid dialog context issues
                          await Future<void>.delayed(
                              const Duration(milliseconds: 100));

                          try {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 85,
                            );

                            if (image != null) {
                              await _uploadRePhoto(student, File(image.path));
                            }
                          } catch (e) {
                            print('📷 Gallery error: $e');
                            if (!e.toString().contains('cancelled')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('गैलरी खोलने में त्रुटि: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('बंद करें'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Upload re-photo to server
  Future<void> _uploadRePhoto(
      Map<String, dynamic> student, File imageFile) async {
    if (_isUploadingRePhoto) {
      // Prevent duplicate submissions which can corrupt navigator stack
      return;
    }
    _isUploadingRePhoto = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('दोबारा तस्वीर अपलोड हो रही है...'),
            ],
          ),
        );
      },
    );

    try {
      // Call API to upload re-photo
      final result = await ApiService.uploadRePhoto(
        studentName: student['student_name'].toString(),
        udiseCode: student['udise_code'].toString(),
        photoFile: imageFile,
      );

      // Close loading dialog only if widget is still mounted
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      if (!mounted) {
        _isUploadingRePhoto = false;
        return; // Widget is no longer mounted, exit early
      }

      if (result['success'] == true) {
        // Get response data
        final responseData = result['data'];

        // Update the student data locally
        final studentIndex = _allStudents.indexWhere(
          (s) =>
              s['student_name'] == student['student_name'] &&
              s['udise_code'] == student['udise_code'],
        );

        if (studentIndex != -1) {
          setState(() {
            // Update certificate field with new re-photo path
            if (responseData != null && responseData['re_photo_path'] != null) {
              _allStudents[studentIndex]['certificate'] =
                  responseData['re_photo_path'];
            }
            // Update re-upload count and last reupload date
            if (responseData != null) {
              _allStudents[studentIndex]['reupload_count'] =
                  responseData['reupload_count'] ?? 0;
              _allStudents[studentIndex]['last_reupload_date'] =
                  responseData['upload_date'];
            }
          });
          _filterStudents(_searchController.text);
        }

        // Show success message with remaining uploads info
        final reuploadCount = responseData?['reupload_count'] ?? 0;
        final remainingUploads = responseData?['remaining_uploads'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'दोबारा तस्वीर सफलतापूर्वक अपलोड हो गई! ($reuploadCount/6) - $remainingUploads बार और अपलोड कर सकते हैं'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'दोबारा तस्वीर अपलोड असफल';
        final data = result['data'];
        if (data != null) {
          if (data['message'] != null) {
            errorMessage = data['message'].toString();
          } else if (data['data'] != null && data['data']['message'] != null) {
            errorMessage = data['data']['message'].toString();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog only if widget is still mounted
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('नेटवर्क त्रुटि: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isUploadingRePhoto = false;
    }
  }

  // Update student status
  Future<void> _updateStudentStatus(
      Map<String, dynamic> student, String statusText) async {
    try {
      // Get app state for UDISE code
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final String udiseCode = appState.udiseCode ?? '';

      // Use the original name from backend (student_name is mapped from 'name' in database)
      final String studentName = student['student_name']?.toString() ?? '';

      print('📝 Updating status for: $studentName');
      print('📝 Status text: $statusText');
      print('📝 UDISE code: $udiseCode');

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('स्थिति अपडेट हो रही है...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Call API to update student status
      final result = await ApiService.updateStudentStatus(
        studentName: studentName,
        udiseCode: udiseCode,
        status: statusText,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Update the student data locally
        final studentIndex = _allStudents.indexWhere(
          (s) => s['student_name'] == studentName,
        );

        if (studentIndex != -1) {
          setState(() {
            _allStudents[studentIndex]['status'] = statusText;
          });
          _filterStudents(_searchController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('पौधे की स्थिति सफलतापूर्वक अपडेट हो गई! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'स्थिति अपडेट असफल';
        final data = result['data'];
        if (data != null && data['message'] != null) {
          errorMessage = data['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('नेटवर्क एरर: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get or create status controller for a student
  TextEditingController _getStatusController(Map<String, dynamic> student) {
    final studentKey = '${student['student_name']}_${student['udise_code']}';

    if (!_statusControllers.containsKey(studentKey)) {
      final controller = TextEditingController();
      // Set initial value from student data
      controller.text = student['status']?.toString() ?? '';
      _statusControllers[studentKey] = controller;
    }

    return _statusControllers[studentKey]!;
  }

  Future<void> _fetchStudentsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<Map<String, dynamic>> students;

      // Use API data
      final appStateProvider =
          Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appStateProvider.udiseCode;

      if (udiseCode == null || udiseCode.isEmpty) {
        throw Exception('UDISE code not found. Please login again.');
      }

      final result = await ApiService.getStudentsByUdise(udiseCode);
      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];

        // Handle different response structures
        List<dynamic> studentsData = [];
        if (responseData is Map<String, dynamic>) {
          // If response has nested data structure
          if (responseData.containsKey('data')) {
            final nestedData = responseData['data'];
            if (nestedData is List) {
              studentsData = nestedData;
            }
          }
        } else if (responseData is List) {
          // If response is directly a list
          studentsData = responseData;
        }

        print('Students data count: ${studentsData.length}');
        print(
            'Sample student data: ${studentsData.isNotEmpty ? studentsData.first : 'No data'}');

        // Debug: Check date fields
        if (studentsData.isNotEmpty) {
          final sampleStudent = studentsData.first;
          print('Available fields in student data: ${sampleStudent.keys}');
          print('Date field value: ${sampleStudent['date']}');
          print('Date_time field value: ${sampleStudent['date_time']}');
        }

        // Map API field names to expected field names
        students = studentsData
            .map((studentData) {
              if (studentData is Map<String, dynamic>) {
                return {
                  'student_id': studentData['mobile']?.toString() ??
                      studentData['student_id']?.toString() ??
                      'N/A',
                  'student_name': studentData['name']?.toString() ??
                      studentData['student_name']?.toString() ??
                      'N/A',
                  'class_name': studentData['class']?.toString() ??
                      studentData['class_name']?.toString() ??
                      'N/A',
                  'phone_number': studentData['mobile']?.toString() ??
                      studentData['phone_number']?.toString() ??
                      'N/A',
                  'date_time': studentData['date_time']?.toString() ?? 'N/A',
                  'date': studentData['date']?.toString() ??
                      'N/A', // For re-photo eligibility check
                  'certificate': studentData['certificate']?.toString() ??
                      '', // For re-photo storage
                  'udise_code':
                      studentData['udise_code']?.toString() ?? udiseCode,
                  'school_name':
                      studentData['school_name']?.toString() ?? 'N/A',
                  'name_of_tree':
                      studentData['name_of_tree']?.toString() ?? 'N/A',
                  'plant_image': studentData['plant_image']?.toString() ?? '',
                  'last_photo_update':
                      studentData['last_photo_update']?.toString() ??
                          studentData['date_time']?.toString(),
                  'status': studentData['status']?.toString() ?? '',
                };
              }
              return <String, dynamic>{};
            })
            .where((student) => student.isNotEmpty)
            .toList();
      } else {
        throw Exception(
            result['data']?['message'] ?? 'Failed to fetch students data');
      }
      print('API Response - Students count: ${students.length}');

      // Sort students by registration date - newest first
      students.sort((a, b) {
        try {
          final dateA = _parseDate(a['date_time']?.toString());
          final dateB = _parseDate(b['date_time']?.toString());
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // Newest first (descending order)
        } catch (e) {
          return 0; // Keep original order if date parsing fails
        }
      });

      setState(() {
        _allStudents = students;
        _filteredStudents = List.from(students);
        _studentsNeedingPhotoUpdate =
            _allStudents.where(_isPhotoUpdateRequired).length;
        _isLoading = false;

        // Extract unique classes for filter dropdown
        _availableClasses = students
            .map((student) => student['class_name']?.toString() ?? '')
            .where((className) => className.isNotEmpty)
            .map((className) => _normalizeClassName(className))
            .toSet() // Remove duplicates after normalization
            .toList()
          ..sort((a, b) {
            // Sort classes numerically in ascending order (1, 2, 3... rather than 1, 10, 11, 2...)
            final numA = int.tryParse(a.trim());
            final numB = int.tryParse(b.trim());

            // If both are valid numbers, sort numerically
            if (numA != null && numB != null) {
              return numA.compareTo(numB); // Ascending order
            }

            // If one is a number and other is not, number comes first
            if (numA != null && numB == null) return -1;
            if (numA == null && numB != null) return 1;

            // If both are non-numeric, sort alphabetically
            return a.compareTo(b);
          });
      });

      _filterStudents(_searchController.text);
    } catch (e) {
      print('Error fetching students data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _allStudents = [];
        _filteredStudents = [];
        _studentsNeedingPhotoUpdate = 0;
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      List<Map<String, dynamic>> filtered = _allStudents;

      // Apply class filter
      if (_selectedClass != null && _selectedClass!.isNotEmpty) {
        filtered = filtered.where((student) {
          final className = student['class_name']?.toString() ?? '';
          // Normalize both the student's class and the selected filter
          final normalizedStudentClass = _normalizeClassName(className);
          final normalizedSelectedClass = _normalizeClassName(_selectedClass!);
          return normalizedStudentClass == normalizedSelectedClass;
        }).toList();
      }

      // Apply search query filter
      if (query.isNotEmpty) {
        filtered = filtered.where((student) {
          final studentName =
              student['student_name']?.toString().toLowerCase() ?? '';
          // final phoneNumber =
          //     student['phone_number']?.toString().toLowerCase() ?? '';  // Hidden
          final className =
              student['class_name']?.toString().toLowerCase() ?? '';
          final schoolName =
              student['school_name']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return studentName.contains(searchQuery) ||
              // phoneNumber.contains(searchQuery) ||  // Hidden
              className.contains(searchQuery) ||
              schoolName.contains(searchQuery);
        }).toList();
      }

      _filteredStudents = filtered;

      // Always sort filtered results by registration date - newest first
      _filteredStudents.sort((a, b) {
        try {
          final dateA = _parseDate(a['date_time']?.toString());
          final dateB = _parseDate(b['date_time']?.toString());
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // Newest first (descending order)
        } catch (e) {
          return 0; // Keep original order if date parsing fails
        }
      });
    });
  }

  void _onClassFilterChanged(String? className) {
    setState(() {
      _selectedClass = className;
    });
    _filterStudents(_searchController.text);
  }

  void _clearFilters() {
    setState(() {
      _selectedClass = null;
    });
    _filterStudents(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final udiseCode = appState.udiseCode ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('छात्र डेटा'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'नवीनतम पहले',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'UDISE: $udiseCode',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
        actions: [
          if (_studentsNeedingPhotoUpdate > 0) ...[
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.camera_alt),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_studentsNeedingPhotoUpdate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                _showPhotoUpdateSummary();
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentsData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'छात्रों को खोजें...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    // Class Filter
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'कक्षा फिल्टर',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.class_, size: 20),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('सभी कक्षा'),
                            ),
                            ..._availableClasses
                                .map((className) => DropdownMenuItem<String>(
                                      value: className,
                                      child: Text('कक्षा $className'),
                                    )),
                          ],
                          onChanged: _onClassFilterChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear Filters Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearFilters,
                        tooltip: 'फिल्टर साफ़ करें',
                      ),
                    ),
                  ],
                ),
                // Filter Status
                if (_selectedClass != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'फ़िल्टर सक्रिय: ${_filteredStudents.length} छात्र',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('छात्र डेटा लोड हो रहा है...'),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'डेटा लोड करने में त्रुटि',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('पुनः प्रयास'),
                              onPressed: _fetchStudentsData,
                            ),
                          ],
                        ),
                      )
                    : _filteredStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _allStudents.isEmpty
                                      ? 'कोई छात्र नहीं मिला'
                                      : 'आपकी खोज से कोई छात्र मेल नहीं खाता',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                if (_allStudents.isEmpty) ...[
                                  const Text(
                                      'डेटा रिफ्रेश करने का प्रयास करें'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('रिफ्रेश करें'),
                                    onPressed: _fetchStudentsData,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Results Summary
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_filteredStudents.length} छात्र मिले',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    if (_allStudents.length !=
                                        _filteredStudents.length)
                                      Text(
                                        'कुल ${_allStudents.length} में से',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Students List
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = _filteredStudents[index];
                                    final isExpanded =
                                        _expandedIndices.contains(index);
                                    final needsPhotoUpdate =
                                        _isPhotoUpdateRequired(student);
                                    final isPhotoLocked =
                                        _isPhotoUpdateLocked(student);
                                    final daysSinceLastUpdate =
                                        _getDaysSinceLastPhotoUpdate(student);
                                    final isNewlyRegistered =
                                        _isNewlyRegistered(student);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 4,
                                      shadowColor:
                                          Colors.black.withOpacity(0.1),
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: needsPhotoUpdate
                                            ? BorderSide(
                                                color: Colors.red.shade400,
                                                width: 2)
                                            : isNewlyRegistered
                                                ? BorderSide(
                                                    color:
                                                        Colors.green.shade400,
                                                    width: 2)
                                                : BorderSide.none,
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12),
                                            leading: Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 26,
                                                  backgroundColor: theme
                                                      .primaryColor
                                                      .withOpacity(0.15),
                                                  child: Text(
                                                    (student['student_name']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true)
                                                        ? student[
                                                                'student_name']!
                                                            .toString()[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: TextStyle(
                                                      color: theme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                if (needsPhotoUpdate)
                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    child: Container(
                                                      width: 14,
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.red.shade500,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            title: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Student name with NEW badge
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        student['student_name']
                                                                ?.toString() ??
                                                            'N/A',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 17,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isNewlyRegistered) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Colors.green
                                                                  .shade400,
                                                              Colors.green
                                                                  .shade600,
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .green
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Text(
                                                          'NEW',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                            subtitle: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                        color: Colors
                                                            .blue.shade200,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'कक्षा: ${student['class_name']?.toString() ?? 'N/A'}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors
                                                            .blue.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Upload Photo Button - only show when needed
                                                  if (_isPhotoUpdateRequired(
                                                          student) &&
                                                      !_isPhotoUpdateLocked(
                                                          student))
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child:
                                                          ElevatedButton.icon(
                                                        onPressed: () {
                                                          _showPhotoUpdateDialog(
                                                              student);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red[600],
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 10),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          elevation: 2,
                                                        ),
                                                        icon: const Icon(
                                                          Icons.camera_alt,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          'फोटो अपडेट करें',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                  // Re-photo Upload Button (30+ days after submission)
                                                  Builder(
                                                    builder: (context) {
                                                      final isRePhotoAvailable =
                                                          _isRePhotoUploadAvailable(
                                                              student);
                                                      final daysSinceSubmission =
                                                          _getDaysSinceSubmission(
                                                              student);
                                                      final hasRePhoto =
                                                          _hasRePhoto(student);

                                                      // Always show button, but with different styles based on availability
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () {
                                                              _showRePhotoUploadDialog(
                                                                  student);
                                                            },
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor: isRePhotoAvailable
                                                                  ? (hasRePhoto
                                                                      ? Colors.green[
                                                                          600]
                                                                      : Colors.blue[
                                                                          600])
                                                                  : Colors.grey[
                                                                      400],
                                                              foregroundColor:
                                                                  Colors.white,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          10),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              elevation:
                                                                  isRePhotoAvailable
                                                                      ? 2
                                                                      : 1,
                                                            ),
                                                            icon: Icon(
                                                              hasRePhoto
                                                                  ? Icons
                                                                      .check_circle
                                                                  : (isRePhotoAvailable
                                                                      ? Icons
                                                                          .add_a_photo
                                                                      : Icons
                                                                          .access_time),
                                                              size: 18,
                                                            ),
                                                            label: Text(
                                                              hasRePhoto
                                                                  ? 'दोबारा तस्वीर अपलोड की गई'
                                                                  : (isRePhotoAvailable
                                                                      ? 'दोबारा तस्वीर अपलोड करें'
                                                                      : 'दोबारा तस्वीर (${30 - daysSinceSubmission} दिन बाद)'),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),

                                                  // Last upload info
                                                  if (student['date_time']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Text(
                                                        'पिछला अपलोड: ${_formatDate(student['date_time']?.toString() ?? '')}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  if (needsPhotoUpdate)
                                                    Text(
                                                      isPhotoLocked
                                                          ? 'फोटो अपडेट लॉक है (${7 - daysSinceLastUpdate} दिन बाकी)'
                                                          : 'फोटो अपडेट आवश्यक ($daysSinceLastUpdate दिन)',
                                                      style: TextStyle(
                                                        color: isPhotoLocked
                                                            ? Colors.orange
                                                            : Colors.red,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Upload status indicator
                                                if (ApiService.canUploadNow(
                                                    student['date_time']
                                                            ?.toString() ??
                                                        ''))
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[600],
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.green
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.camera_alt,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                else
                                                  Builder(
                                                    builder: (context) {
                                                      final remainingDays = ApiService
                                                          .getRemainingDaysForUpload(student[
                                                                      'last_photo_update']
                                                                  ?.toString() ??
                                                              student['date_time']
                                                                  ?.toString() ??
                                                              '');
                                                      if (remainingDays > 0) {
                                                        return Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .blue[600],
                                                            shape:
                                                                BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
                                                                        0.3),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            '$remainingDays',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox
                                                          .shrink();
                                                    },
                                                  ),
                                                const SizedBox(width: 8),
                                                if (needsPhotoUpdate)
                                                  IconButton(
                                                    icon: Icon(
                                                      isPhotoLocked
                                                          ? Icons.lock
                                                          : Icons.camera_alt,
                                                      color: isPhotoLocked
                                                          ? Colors.orange
                                                          : Colors.red,
                                                    ),
                                                    onPressed: isPhotoLocked
                                                        ? null
                                                        : () =>
                                                            _showPhotoUpdateDialog(
                                                                student),
                                                    tooltip: isPhotoLocked
                                                        ? 'फोटो अपडेट लॉक है'
                                                        : 'फोटो अपडेट करें',
                                                  ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    isExpanded
                                                        ? Icons.expand_less
                                                        : Icons.expand_more,
                                                    color: Colors.grey[700],
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onTap: () {
                                              setState(() {
                                                if (isExpanded) {
                                                  _expandedIndices
                                                      .remove(index);
                                                } else {
                                                  _expandedIndices.add(index);
                                                }
                                              });
                                            },
                                          ),
                                          if (isExpanded) ...[
                                            Container(
                                              height: 1,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.grey.shade300,
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // _buildDetailRow(
                                                  //     'जमा करने की तिथि',
                                                  //     (student['date'] !=
                                                  //                 null &&
                                                  //             student['date'] !=
                                                  //                 'N/A')
                                                  //         ? _formatDate(
                                                  //             student['date']
                                                  //                 .toString())
                                                  //         : (student['date_time'] !=
                                                  //                     null &&
                                                  //                 student['date_time'] !=
                                                  //                     'N/A')
                                                  //             ? _formatDate(student[
                                                  //                     'date_time']
                                                  //                 .toString())
                                                  //             : 'तारीख उपलब्ध नहीं'),
                                                  // _buildDetailRow('मोबाइल नंबर',
                                                  //     student['phone_number']),  // Hidden
                                                  _buildDetailRow(
                                                      'Submitted Date',
                                                      (student['date_time'] !=
                                                                  null &&
                                                              student['date_time'] !=
                                                                  'N/A')
                                                          ? student['date_time']
                                                              .toString()
                                                          : 'Date not available'),
                                                  _buildDetailRow(
                                                      'स्कूल का नाम',
                                                      student['school_name']),
                                                  _buildDetailRow('UDISE कोड',
                                                      student['udise_code']),
                                                  _buildDetailRow('पेड़ का नाम',
                                                      student['name_of_tree']),

                                                  // Status text box
                                                  const SizedBox(height: 12),
                                                  _buildStatusTextBox(student),

                                                  // _buildDetailRow(
                                                  //     'पंजीकरण तिथि',
                                                  //     student['date'] != null
                                                  //         ? _formatDate(
                                                  //             student['date']
                                                  //                 .toString())
                                                  //         : 'तारीख उपलब्ध नहीं'),
                                                  if (student['plant_image']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                    _buildPhotoRow(
                                                        'पौधे की फोटो',
                                                        student['plant_image']),
                                                  if (needsPhotoUpdate) ...[
                                                    const SizedBox(height: 12),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                            color: Colors.red
                                                                .withOpacity(
                                                                    0.3)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.warning,
                                                              color: Colors.red,
                                                              size: 20),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              isPhotoLocked
                                                                  ? 'फोटो अपडेट लॉक है - ${7 - daysSinceLastUpdate} दिन बाकी'
                                                                  : 'फोटो अपडेट आवश्यक - अंतिम अपडेट के $daysSinceLastUpdate दिन बाद',
                                                              style: TextStyle(
                                                                color: isPhotoLocked
                                                                    ? Colors
                                                                        .orange
                                                                    : Colors
                                                                        .red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: isPhotoLocked
                                                                ? null
                                                                : () =>
                                                                    _showPhotoUpdateDialog(
                                                                        student),
                                                            child: Text(
                                                              isPhotoLocked
                                                                  ? 'लॉक है'
                                                                  : 'अपडेट करें',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTextBox(Map<String, dynamic> student) {
    final statusController = _getStatusController(student);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'पौधे की स्थिति:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: statusController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'पौधे की स्थिति या नोट्स यहाँ लिखें...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (student['status']?.toString().isNotEmpty == true) ...[
                TextButton.icon(
                  onPressed: () {
                    statusController.clear();
                    _updateStudentStatus(student, '');
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('साफ करें'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  final statusText = statusController.text.trim();
                  if (statusText.isNotEmpty) {
                    _updateStudentStatus(student, statusText);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('कृपया स्थिति टेक्स्ट दर्ज करें'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('सेव करें'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(String label, dynamic imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'उपलब्ध',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewPhoto(imageUrl?.toString() ?? ''),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('देखें'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(String imageUrl) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('फोटो उपलब्ध नहीं है'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add base URL if relative path
    String fullImageUrl = imageUrl;
    if (!imageUrl.startsWith('http')) {
      fullImageUrl = '${ApiService.baseUrl}/$imageUrl';
    }

    // Determine title based on image type
    String title = 'फोटो देखें';
    if (imageUrl.contains('plant')) {
      title = '🌱 पौधे की फोटो';
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with title and close button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        imageUrl.contains('plant')
                            ? Icons.local_florist
                            : Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Image container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          fullImageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 3,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'फोटो लोड हो रही है...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (loadingProgress.expectedTotalBytes !=
                                      null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 60,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'फोटो लोड नहीं हो सकी',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'नेटवर्क कनेक्शन या फाइल की जांच करें',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('बंद करें'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Zoom instruction
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.touch_app,
                                color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ज़ूम करने के लिए पिंच करें',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Full screen button
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('फुल स्क्रीन के लिए ज़ूम करें'),
                              backgroundColor: Colors.green[600],
                            ),
                          );
                        },
                        icon: const Icon(Icons.fullscreen, size: 18),
                        label: const Text('फुल स्क्रीन'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
