import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({super.key});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  List<Map<String, dynamic>> _allTeachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchTeachersData();
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachersData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode ?? '22010100101';

      print('🔍 DEBUG: Fetching teachers for UDISE Code: $udiseCode');
      print('🔍 DEBUG: App State UDISE: ${appState.udiseCode}');
      print('🔍 DEBUG: Logged in user: ${appState.loggedInUser}');

      final result = await ApiService.getTeachersByUdise(udiseCode);

      print('📡 DEBUG: Complete API Response: $result');
      print('✅ DEBUG: API Success: ${result['success']}');
      print('📄 DEBUG: API Data: ${result['data']}');

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          final responseData = result['data'];
          print('🗂️ DEBUG: Response Data Type: ${responseData.runtimeType}');
          print('🗂️ DEBUG: Response Data Content: $responseData');

          if (responseData['status'] == true && responseData['data'] != null) {
            final teachersList = responseData['data'] as List;
            print('👨‍🏫 DEBUG: Teachers Found: ${teachersList.length}');
            print(
                '👨‍🏫 DEBUG: First Teacher Sample: ${teachersList.isNotEmpty ? teachersList[0] : 'No teachers'}');

            _allTeachers = List<Map<String, dynamic>>.from(teachersList
                .map((item) => Map<String, dynamic>.from(item as Map)));
            _filteredTeachers = List<Map<String, dynamic>>.from(_allTeachers);
            _isLoading = false;

            print(
                '✅ DEBUG: Teachers loaded successfully: ${_allTeachers.length} teachers');
          } else {
            print(
                '❌ DEBUG: No teachers data - Status: ${responseData['status']}, Message: ${responseData['message']}');
            _allTeachers = [];
            _filteredTeachers = [];
            _errorMessage = responseData['message']?.toString() ??
                'इस UDISE कोड के लिए कोई शिक्षक डेटा नहीं मिला';
            _isLoading = false;
          }
        });
      } else {
        print(
            '❌ DEBUG: API call failed - Success: ${result['success']}, Data: ${result['data']}');
        setState(() {
          _errorMessage = result['data']?['message']?.toString() ??
              'इस UDISE कोड के लिए कोई शिक्षक डेटा नहीं मिला';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'नेटवर्क एरर: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers = _allTeachers.where((teacher) {
        final name = teacher['name']?.toString().toLowerCase() ?? '';
        final empId = teacher['employee_id']?.toString().toLowerCase() ?? '';
        return name.contains(query) || empId.contains(query);
      }).toList();
    });
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';

    try {
      final DateTime dateTime =
          DateTime.parse(dateTimeString.replaceAll('GMT', '').trim());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: AppTheme.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final udiseCode = appState.udiseCode ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('शिक्षक विवरण'),
            Text(
              'UDISE: $udiseCode',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeachersData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'शिक्षक का नाम या Employee ID खोजें...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Content area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(height: 16),
                        Text('शिक्षक डेटा लोड हो रहा है...'),
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
                              size: 80,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchTeachersData,
                              child: const Text('पुनः प्रयास करें'),
                            ),
                          ],
                        ),
                      )
                    : _filteredTeachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _allTeachers.isEmpty
                                      ? 'कोई शिक्षक डेटा नहीं मिला'
                                      : 'खोज के अनुकूल कोई शिक्षक नहीं मिला',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_allTeachers.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'इस UDISE कोड के लिए कोई पंजीकृत शिक्षक नहीं है',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _filteredTeachers[index];
                              final isExpanded =
                                  _expandedIndices.contains(index);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    // Main card content - always visible
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedIndices.remove(index);
                                          } else {
                                            _expandedIndices.add(index);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            const CircleAvatar(
                                              backgroundColor:
                                                  AppTheme.primaryGreen,
                                              radius: 25,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    teacher['name']
                                                            ?.toString() ??
                                                        'अज्ञात शिक्षक',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    'EMP ID: ${teacher['employee_id']?.toString() ?? 'N/A'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Expanded content - only visible when expanded
                                    if (isExpanded) ...[
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow(
                                                'नाम', teacher['name']),
                                            _buildDetailRow('Employee ID',
                                                teacher['employee_id']),
                                            _buildDetailRow('स्कूल का नाम',
                                                teacher['school_name']),
                                            _buildDetailRow(
                                                'पद',
                                                teacher['designation'] ??
                                                    'प्राथमिक शिक्षक'),
                                            _buildDetailRow(
                                                'मोबाइल', teacher['mobile']),
                                            _buildDetailRow(
                                                'ईमेल', teacher['email']),
                                            _buildDetailRow('UDISE कोड',
                                                teacher['udise_code']),
                                            _buildDetailRow(
                                                'ज्वॉइन दिनांक',
                                                _formatDate(teacher['join_date']
                                                    ?.toString())),
                                            _buildDetailRow(
                                                'अपडेट दिनांक',
                                                _formatDate(
                                                    teacher['updated_at']
                                                        ?.toString())),

                                            const SizedBox(height: 16),

                                            // Status badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: teacher['status'] ==
                                                        'active'
                                                    ? Colors.green
                                                        .withOpacity(0.2)
                                                    : Colors.orange
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    teacher['status'] ==
                                                            'active'
                                                        ? Icons.check_circle
                                                        : Icons.pending,
                                                    size: 16,
                                                    color: teacher['status'] ==
                                                            'active'
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    teacher['status'] ==
                                                            'active'
                                                        ? 'सक्रिय'
                                                        : 'निष्क्रिय',
                                                    style: TextStyle(
                                                      color:
                                                          teacher['status'] ==
                                                                  'active'
                                                              ? Colors.green
                                                              : Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
    );
  }
}
