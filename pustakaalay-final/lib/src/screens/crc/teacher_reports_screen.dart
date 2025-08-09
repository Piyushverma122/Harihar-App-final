import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> teacherReports = [];
  List<Map<String, dynamic>> filteredTeacherReports = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode ?? '1234'; // Default UDISE code
      
      final response = await ApiService.getTeachersByUdise(udiseCode);
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data != null && data['data'] != null) {
          final teachersData = data['data'] as List<dynamic>?;
          if (teachersData != null) {
            final teachers = teachersData.map((e) => e as Map<String, dynamic>).toList();
            
            // Fetch dashboard data for each teacher
            final processedTeachers = <Map<String, dynamic>>[];
            for (final teacher in teachers) {
              final username = teacher['username'] as String? ?? '';
              if (username.isNotEmpty) {
                // Call teacher dashboard API for each teacher with UDISE code
                final dashboardResponse = await ApiService.getTeacherDashboardByUsername(username, udiseCode: udiseCode);
                if (dashboardResponse['success'] == true) {
                  final dashboardData = dashboardResponse['data'];
                  // Merge dashboard data with teacher data
                  final mergedTeacher = Map<String, dynamic>.from(teacher);
                  mergedTeacher['dashboard_data'] = dashboardData;
                  processedTeachers.add(mergedTeacher);
                } else {
                  // Add teacher without dashboard data
                  processedTeachers.add(teacher);
                }
              } else {
                // Add teacher without dashboard data
                processedTeachers.add(teacher);
              }
            }
            
            setState(() {
              teacherReports = _processTeacherData(processedTeachers);
              _applyFilters();
              _isLoading = false;
            });
          } else {
            setState(() {
              teacherReports = [];
              filteredTeacherReports = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            teacherReports = [];
            filteredTeacherReports = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = (response['data']?['message'] as String?) ?? 'शिक्षक डेटा लोड करने में त्रुटि हुई';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'नेटवर्क कनेक्शन की जांच करें';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _processTeacherData(List<Map<String, dynamic>> teachers) {
    return teachers.map((teacher) {
      // Get dashboard data if available
      final dashboardData = teacher['dashboard_data'] as Map<String, dynamic>?;
      
      // Debug: Print the dashboard data to see what fields are available
      print('Teacher: ${teacher['name']}');
      print('Dashboard Data: $dashboardData');
      print('Teacher Data Keys: ${teacher.keys.toList()}');
      
      // Extract data from dashboard if available, trying multiple possible field names
      final totalStudents = (dashboardData?['COUNT'] as num?)?.toInt() ?? 
                           (dashboardData?['total_students'] as num?)?.toInt() ?? 
                           (dashboardData?['student_count'] as num?)?.toInt() ?? 
                           (dashboardData?['total_student'] as num?)?.toInt() ?? 
                           (teacher['total_students'] as num?)?.toInt() ?? 
                           (teacher['student_count'] as num?)?.toInt() ?? 
                           0; // Default to 0 if not available
      
      // Use registered students count from teacher dashboard API, trying multiple field names
      // Since API returns COUNT, use it for both total and registered
      final studentsRegistered = (dashboardData?['COUNT'] as num?)?.toInt() ?? 
                                (dashboardData?['students_registered'] as num?)?.toInt() ?? 
                                (dashboardData?['registered_students'] as num?)?.toInt() ?? 
                                (dashboardData?['student_registered'] as num?)?.toInt() ?? 
                                (dashboardData?['registered_count'] as num?)?.toInt() ?? 
                                (teacher['students_registered'] as num?)?.toInt() ?? 
                                (teacher['registered_count'] as num?)?.toInt() ?? 
                                0; // Default to 0 if not available
      
      // Calculate photos as double the registered students count
      final photosUploaded = studentsRegistered * 2;
      
      print('Processed - Total: $totalStudents, Registered: $studentsRegistered, Photos: $photosUploaded');
      print('---');
      
      // Get phone number from teacher data (already available in /fetch_teacher response)
      final phoneNumber = teacher['mobile'] as String? ?? 
                         dashboardData?['phone'] as String? ?? 
                         dashboardData?['mobile'] as String? ?? '';
      
      // Generate a simple ID from name hash if no ID provided
      final teacherId = (teacher['id'] as num?)?.toInt() ?? 
                       (teacher['name'] as String? ?? '').hashCode.abs() % 10000;
      
      return {
        'id': teacherId,
        'teacherName': teacher['name'] as String? ?? 'अज्ञात शिक्षक',
        'schoolName': teacher['school_name'] as String? ?? 'अज्ञात स्कूल',
        'totalStudents': totalStudents,
        'photosUploaded': photosUploaded,
        'studentsRegistered': studentsRegistered,
        'mobile': phoneNumber,
        'username': teacher['username'] as String? ?? '',
      };
    }).toList();
  }

  void _applyFilters() {
    filteredTeacherReports = teacherReports.where((teacher) {
      final teacherName = (teacher['teacherName'] as String).toLowerCase();
      final schoolName = (teacher['schoolName'] as String).toLowerCase();
      final mobile = (teacher['mobile'] as String).toLowerCase();
      
      // Search filter only
      final matchesSearch = _searchQuery.isEmpty ||
          teacherName.contains(_searchQuery) ||
          schoolName.contains(_searchQuery) ||
          mobile.contains(_searchQuery);
      
      return matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredReports => filteredTeacherReports;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          appState.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('शिक्षक रिपोर्ट'),
          backgroundColor: AppTheme.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => appState.goBack(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTeacherData,
            ),
          ],
        ),
        body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.green),
                  SizedBox(height: 16),
                  Text(
                    'शिक्षक डेटा लोड हो रहा है...',
                    style: TextStyle(color: AppTheme.darkGray),
                  ),
                ],
              ),
            )
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.darkGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadTeacherData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('पुनः प्रयास करें'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.lightGray,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'शिक्षक का नाम, स्कूल या मोबाइल नंबर खोजें...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.darkGray),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.darkGray),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            
            // Summary Card - Compact Total Teachers
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, color: AppTheme.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      filteredReports.length.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'कुल शिक्षक',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Teacher Reports List
            Expanded(
              child: filteredReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                            size: 48,
                            color: AppTheme.gray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'कोई शिक्षक नहीं मिला'
                                : 'कोई शिक्षक डेटा उपलब्ध नहीं है',
                            style: const TextStyle(fontSize: 16, color: AppTheme.darkGray),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.green.withOpacity(0.2),
                    child: const Icon(Icons.person, color: AppTheme.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['teacherName'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report['schoolName'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkGray.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 12, color: AppTheme.green),
                            const SizedBox(width: 4),
                            Text(
                              report['mobile'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Statistics Row - Commented out counts
              /*
              Row(
                children: [
                  _buildStatItem(Icons.people, '${report['totalStudents']} छात्र'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.photo_library, '${report['photosUploaded']} फोटो'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.how_to_reg, '${report['studentsRegistered']} रजिस्टर्ड'),
                ],
              ),
              */
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.gray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Teacher Header
                  Text(
                    report['teacherName'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report['schoolName'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGray.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Performance Card
                        _buildDetailCard(
                          'प्रदर्शन विवरण',
                          [
                            _buildDetailRow('शिक्षक का नाम', report['teacherName'] as String),
                            _buildDetailRow('स्कूल का नाम', report['schoolName'] as String),
                            _buildDetailRow('कुल छात्र', '${report['totalStudents']}'),
                            _buildDetailRow('रजिस्टर्ड छात्र', '${report['studentsRegistered']}'),
                            _buildDetailRow('अपलोडेड फोटो', '${report['photosUploaded']}'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Contact Card
                        _buildDetailCard(
                          'संपर्क विवरण',
                          [
                            _buildDetailRow('मोबाइल नंबर', report['mobile'] as String),
                            _buildDetailRow('यूजरनेम', report['username'] as String),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final phoneNumber = report['mobile'] as String;
                                  if (phoneNumber.isNotEmpty) {
                                    final Uri smsUri = Uri(
                                      scheme: 'sms',
                                      path: phoneNumber,
                                      queryParameters: {'body': 'नमस्ते ${report['teacherName'] as String} जी, '},
                                    );
                                    
                                    try {
                                      if (await canLaunchUrl(smsUri)) {
                                        await launchUrl(smsUri);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('SMS ऐप नहीं खुल सका')),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('SMS भेजने में त्रुटि')),
                                        );
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('मोबाइल नंबर उपलब्ध नहीं है')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('संदेश भेजें'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final phoneNumber = report['mobile'] as String;
                                  if (phoneNumber.isNotEmpty) {
                                    final Uri telUri = Uri(
                                      scheme: 'tel',
                                      path: phoneNumber,
                                    );
                                    
                                    try {
                                      if (await canLaunchUrl(telUri)) {
                                        await launchUrl(telUri);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('डायलर नहीं खुल सका')),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('कॉल करने में त्रुटि')),
                                        );
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('मोबाइल नंबर उपलब्ध नहीं है')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('कॉल करें'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray.withOpacity(0.7),
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
