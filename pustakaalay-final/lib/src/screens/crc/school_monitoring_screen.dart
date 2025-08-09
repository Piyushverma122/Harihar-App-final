import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class SchoolMonitoringScreen extends StatefulWidget {
  const SchoolMonitoringScreen({super.key});

  @override
  State<SchoolMonitoringScreen> createState() => _SchoolMonitoringScreenState();
}

class _SchoolMonitoringScreenState extends State<SchoolMonitoringScreen> {
  String selectedFilter = 'all';
  String searchQuery = '';
  
  // Sample school data
  List<Map<String, dynamic>> schools = [
    {
      'id': 1,
      'name': 'राजकीय प्राथमिक शाला, नारायणपुर',
      'code': 'GPS001',
      'teachers': 8,
      'students': 156,
      'photos': 45,
      'lastActivity': '2 घंटे पहले',
      'status': 'active',
      'district': 'रायपुर',
      'block': 'नारायणपुर',
      'compliance': 92,
    },
    {
      'id': 2,
      'name': 'राजकीय मध्य शाला, धमतरी',
      'code': 'GMS002',
      'teachers': 12,
      'students': 234,
      'photos': 67,
      'lastActivity': '5 घंटे पहले',
      'status': 'warning',
      'district': 'धमतरी',
      'block': 'धमतरी',
      'compliance': 78,
    },
    {
      'id': 3,
      'name': 'राजकीय उच्च शाला, बिलासपुर',
      'code': 'GHS003',
      'teachers': 18,
      'students': 345,
      'photos': 89,
      'lastActivity': '1 दिन पहले',
      'status': 'inactive',
      'district': 'बिलासपुर',
      'block': 'बिलासपुर',
      'compliance': 56,
    },
    {
      'id': 4,
      'name': 'राजकीय प्राथमिक शाला, जगदलपुर',
      'code': 'GPS004',
      'teachers': 6,
      'students': 98,
      'photos': 23,
      'lastActivity': '3 घंटे पहले',
      'status': 'active',
      'district': 'बस्तर',
      'block': 'जगदलपुर',
      'compliance': 95,
    },
    {
      'id': 5,
      'name': 'राजकीय मध्य शाला, कोरबा',
      'code': 'GMS005',
      'teachers': 10,
      'students': 187,
      'photos': 34,
      'lastActivity': '8 घंटे पहले',
      'status': 'warning',
      'district': 'कोरबा',
      'block': 'कोरबा',
      'compliance': 71,
    },
  ];

  List<Map<String, dynamic>> get filteredSchools {
    return schools.where((school) {
      final matchesFilter = selectedFilter == 'all' || school['status'] == selectedFilter;
      final matchesSearch = searchQuery.isEmpty ||
          (school['name'] as String).toLowerCase().contains(searchQuery.toLowerCase()) ||
          (school['code'] as String).toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
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
          title: const Text('स्कूल मॉनिटरिंग'),
          backgroundColor: AppTheme.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => appState.goBack(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh data
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('डेटा रिफ्रेश किया गया')),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.lightGray,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'स्कूल खोजें...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('सभी', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('सक्रिय', 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('चेतावनी', 'warning'),
                        const SizedBox(width: 8),
                        _buildFilterChip('निष्क्रिय', 'inactive'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Statistics Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'कुल स्कूल',
                      schools.length.toString(),
                      AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'सक्रिय',
                      schools.where((s) => s['status'] == 'active').length.toString(),
                      AppTheme.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'चेतावनी',
                      schools.where((s) => s['status'] == 'warning').length.toString(),
                      AppTheme.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            // Schools List
            Expanded(
              child: filteredSchools.isEmpty
                  ? const Center(
                      child: Text(
                        'कोई स्कूल नहीं मिला',
                        style: TextStyle(fontSize: 16, color: AppTheme.darkGray),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredSchools.length,
                      itemBuilder: (context, index) {
                        final school = filteredSchools[index];
                        return _buildSchoolCard(school);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      backgroundColor: AppTheme.white,
      selectedColor: AppTheme.blue.withOpacity(0.2),
      checkmarkColor: AppTheme.blue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.blue : AppTheme.darkGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    Color statusColor;
    IconData statusIcon;
    switch (school['status']) {
      case 'active':
        statusColor = AppTheme.green;
        statusIcon = Icons.check_circle;
        break;
      case 'warning':
        statusColor = AppTheme.orange;
        statusIcon = Icons.warning;
        break;
      case 'inactive':
        statusColor = AppTheme.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppTheme.gray;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSchoolDetails(school),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'कोड: ${school['code']} | ${school['district']}, ${school['block']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkGray.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '${school['compliance']}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats Row
              Row(
                children: [
                  _buildSchoolStat(Icons.people, '${school['teachers']} शिक्षक'),
                  const SizedBox(width: 16),
                  _buildSchoolStat(Icons.child_care, '${school['students']} छात्र'),
                  const SizedBox(width: 16),
                  _buildSchoolStat(Icons.photo_library, '${school['photos']} फोटो'),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Last Activity
              Text(
                'अंतिम गतिविधि: ${school['lastActivity']}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkGray.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.darkGray.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.darkGray.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showSchoolDetails(Map<String, dynamic> school) {
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
                  
                  // School Header
                  Text(
                    school['name'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'कोड: ${school['code']}',
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
                        // Basic Info Card
                        _buildDetailCard(
                          'स्कूल जानकारी',
                          [
                            _buildDetailRow('जिला', school['district'] as String),
                            _buildDetailRow('ब्लॉक', school['block'] as String),
                            _buildDetailRow('शिक्षकों की संख्या', '${school['teachers']}'),
                            _buildDetailRow('छात्रों की संख्या', '${school['students']}'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Activity Card
                        _buildDetailCard(
                          'गतिविधि विवरण',
                          [
                            _buildDetailRow('अपलोडेड फोटो', '${school['photos']}'),
                            _buildDetailRow('अंतिम गतिविधि', school['lastActivity'] as String),
                            _buildDetailRow('अनुपालन स्कोर', '${school['compliance']}%'),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${school['name'] as String} की रिपोर्ट देखी गई')),
                                  );
                                },
                                icon: const Icon(Icons.assessment),
                                label: const Text('रिपोर्ट देखें'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${school['name'] as String} से संपर्क किया गया')),
                                  );
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('संपर्क करें'),
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
            width: 100,
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
