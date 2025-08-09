import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class DataVerificationScreen extends StatefulWidget {
  const DataVerificationScreen({super.key});

  @override
  State<DataVerificationScreen> createState() => _DataVerificationScreenState();
}

class _DataVerificationScreenState extends State<DataVerificationScreen> {
  String selectedStatus = 'all';
  List<Map<String, dynamic>> verificationData = [];
  bool isLoading = true;
  String? errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadVerificationData();
  }
  
  Future<void> _loadVerificationData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      // Get app state to get UDISE code
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode;
      
      print('Data Verification - App State UDISE code: $udiseCode');
      print('Data Verification - User type: ${appState.userType}');
      print('Data Verification - Logged in user: ${appState.loggedInUser}');
      
      if (udiseCode != null) {
        print('Calling /check_verified_status with UDISE code: $udiseCode');
      } else {
        print('WARNING: No UDISE code available for data verification');
      }
      
      final result = await ApiService.getStudentsForVerification(udiseCode: udiseCode);
      
      if (result['success'] == true) {
        final responseData = result['data'];
        print('Verification API Response: $responseData');
        
        // Parse the response data
        List<Map<String, dynamic>> parsedData = [];
        
        if (responseData is Map && responseData['data'] != null) {
          // If response has data array (current backend format)
          final students = responseData['data'] as List;
          parsedData = students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return {
              'id': student['id'] ?? index, // Use index if no ID provided
              'studentName': student['name'] ?? 'अज्ञात छात्र',
              'schoolName': student['school_name'] ?? 'अज्ञात स्कूल',
              'className': student['class'] ?? 'अज्ञात कक्षा',
              'mobile': student['mobile'] ?? '',
              'nameOfTree': student['name_of_tree'] ?? '',
              'plantImage': student['plant_image'] ?? '',
              'certificate': student['certificate'] ?? '',
              'udiseCode': student['udise_code'] ?? '',
              'submissionDate': student['date_time'] ?? 'अज्ञात दिनांक',
              'status': (student['verified'] == true || student['verified'] == 1) ? 'verified' : 'pending',
              'dataType': 'छात्र रजिस्ट्रेशन',
            };
          }).cast<Map<String, dynamic>>().toList();
        } else if (responseData is Map && responseData['students'] != null) {
          // If response has students array (alternative format)
          final students = responseData['students'] as List;
          parsedData = students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return {
              'id': student['id'] ?? index, // Use index if no ID provided
              'studentName': student['name'] ?? 'अज्ञात छात्र',
              'schoolName': student['school_name'] ?? 'अज्ञात स्कूल',
              'className': student['class'] ?? 'अज्ञात कक्षा',
              'mobile': student['mobile'] ?? '',
              'nameOfTree': student['name_of_tree'] ?? '',
              'plantImage': student['plant_image'] ?? '',
              'certificate': student['certificate'] ?? '',
              'udiseCode': student['udise_code'] ?? '',
              'submissionDate': student['date_time'] ?? student['created_at'] ?? 'अज्ञात दिनांक',
              'status': (student['verified'] == true || student['verified'] == 1) ? 'verified' : 'pending',
              'dataType': 'छात्र रजिस्ट्रेशन',
            };
          }).cast<Map<String, dynamic>>().toList();
        } else if (responseData is List) {
          // If response is directly a list
          parsedData = responseData.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return {
              'id': student['id'] ?? index, // Use index if no ID provided
              'studentName': student['name'] ?? 'अज्ञात छात्र',
              'schoolName': student['school_name'] ?? 'अज्ञात स्कूल',
              'className': student['class'] ?? 'अज्ञात कक्षा',
              'mobile': student['mobile'] ?? '',
              'nameOfTree': student['name_of_tree'] ?? '',
              'plantImage': student['plant_image'] ?? '',
              'certificate': student['certificate'] ?? '',
              'udiseCode': student['udise_code'] ?? '',
              'submissionDate': student['date_time'] ?? student['created_at'] ?? 'अज्ञात दिनांक',
              'status': (student['verified'] == true || student['verified'] == 1) ? 'verified' : 'pending',
              'dataType': 'छात्र रजिस्ट्रेशन',
            };
          }).cast<Map<String, dynamic>>().toList();
        }
        
        print('Parsed ${parsedData.length} students from API response');
        for (var student in parsedData) {
          print('Student ID: ${student['id']} - Name: ${student['studentName']} - Status: ${student['status']}');
        }
        
        setState(() {
          verificationData = parsedData;
          isLoading = false;
        });
        
        print('Loaded ${parsedData.length} students for verification');
      } else {
        setState(() {
          errorMessage = (result['data']['message'] as String?) ?? 'डेटा लोड करने में त्रुटि हुई';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Load verification data error: $e');
      setState(() {
        errorMessage = 'डेटा लोड करने में त्रुटि हुई';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredData {
    return verificationData.where((data) {
      return selectedStatus == 'all' || data['status'] == selectedStatus;
    }).toList();
  }

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
          title: const Text('डेटा वेरिफिकेशन'),
          backgroundColor: AppTheme.purple,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => appState.goBack(),
          ),
        ),
        body: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.lightGray,
              child: Row(
                children: [
                  _buildFilterChip('सभी', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('लंबित', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('सत्यापित', 'verified'),
                  const SizedBox(width: 8),
                  _buildFilterChip('अस्वीकृत', 'rejected'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadVerificationData,
                    tooltip: 'रीफ्रेश करें',
                  ),
                ],
              ),
            ),
            
            // Data List
            Expanded(
              child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.purple),
                        SizedBox(height: 16),
                        Text('डेटा लोड हो रहा है...'),
                      ],
                    ),
                  )
                : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVerificationData,
                            child: const Text('पुनः प्रयास करें'),
                          ),
                        ],
                      ),
                    )
                  : filteredData.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppTheme.gray,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'कोई डेटा नहीं मिला',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final data = filteredData[index];
                          return _buildDataCard(data);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = value;
        });
      },
      backgroundColor: AppTheme.white,
      selectedColor: AppTheme.purple.withOpacity(0.2),
      checkmarkColor: AppTheme.purple,
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    Color statusColor;
    String statusText;
    switch (data['status']) {
      case 'pending':
        statusColor = AppTheme.orange;
        statusText = 'लंबित';
        break;
      case 'verified':
        statusColor = AppTheme.green;
        statusText = 'सत्यापित';
        break;
      case 'rejected':
        statusColor = AppTheme.red;
        statusText = 'अस्वीकृत';
        break;
      default:
        statusColor = AppTheme.gray;
        statusText = 'अज्ञात';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['schoolName'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('छात्र: ${data['studentName']}'),
            Text('कक्षा: ${data['className']}'),
            Text('पेड़ का नाम: ${data['nameOfTree']}'),
            Text('UDISE कोड: ${data['udiseCode']}'),
            Text('डेटा प्रकार: ${data['dataType']}'),
            if (data['mobile'] != null && data['mobile'].toString().isNotEmpty)
              Text('मोबाइल: ${data['mobile']}'),
            Text('जमा दिनांक: ${data['submissionDate']}'),
            const SizedBox(height: 12),
            if (data['status'] == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _verifyData(data['id'] as int),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                      ),
                      child: const Text('सत्यापित करें'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectData(data['id'] as int),
                      child: const Text('अस्वीकार करें'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _verifyData(int id) async {
    try {
      // Get supervisor's UDISE code from app state
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final supervisorUdiseCode = appState.udiseCode;
      
      // Find the student data to get name and mobile
      final studentData = verificationData.firstWhere((data) => data['id'] == id);
      final studentName = studentData['studentName'] as String;
      final studentMobile = studentData['mobile'] as String;
      final currentStatus = studentData['status'] as String;
      
      print('Verifying student ID: $id');
      print('Student Name: $studentName, Mobile: $studentMobile');
      print('Current Status: $currentStatus');
      print('Using Supervisor UDISE code: $supervisorUdiseCode');
      
      // Check if already verified
      if (currentStatus == 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('यह छात्र पहले से सत्यापित है'),
            backgroundColor: AppTheme.orange,
          ),
        );
        return;
      }
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('सत्यापन हो रहा है...')),
      );
      
      // Call backend API with name, mobile, and supervisor's udise code
      final result = await ApiService.verifyStudentByNameMobile(
        name: studentName,
        mobile: studentMobile,
        udiseCode: supervisorUdiseCode,
      );
      
      print('Verification result: $result');
      
      if (result['success'] == true) {
        // Update local state
        setState(() {
          final index = verificationData.indexWhere((data) => data['id'] == id);
          if (index != -1) {
            verificationData[index]['status'] = 'verified';
            print('Updated student $id status to verified at index $index');
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('डेटा सफलतापूर्वक सत्यापित किया गया'),
            backgroundColor: AppTheme.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['data']['message'] as String?) ?? 'सत्यापन में त्रुटि हुई'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } catch (e) {
      print('Verify data error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('सत्यापन में त्रुटि हुई'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  void _rejectData(int id) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('अस्वीकार हो रहा है...')),
      );
      
      // Call backend API
      final result = await ApiService.updateStudentVerification(
        studentId: id,
        verified: false,
      );
      
      if (result['success'] == true) {
        // Update local state
        setState(() {
          final index = verificationData.indexWhere((data) => data['id'] == id);
          if (index != -1) {
            verificationData[index]['status'] = 'rejected';
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('डेटा सफलतापूर्वक अस्वीकार किया गया'),
            backgroundColor: AppTheme.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['data']['message'] as String?) ?? 'अस्वीकार करने में त्रुटि हुई'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } catch (e) {
      print('Reject data error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('अस्वीकार करने में त्रुटि हुई'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }
}
