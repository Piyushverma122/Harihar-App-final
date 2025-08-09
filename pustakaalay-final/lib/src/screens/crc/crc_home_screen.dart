import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class CRCHomeScreen extends StatefulWidget {
  const CRCHomeScreen({super.key});

  @override
  State<CRCHomeScreen> createState() => _CRCHomeScreenState();
}

class _CRCHomeScreenState extends State<CRCHomeScreen> {
  Map<String, dynamic> dashboardData = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get app state to get UDISE code
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode;

      print('CRC Home - Loading dashboard with UDISE code: $udiseCode');

      final result =
          await ApiService.getSupervisorDashboard(udiseCode: udiseCode);

      if (result['success'] == true) {
        setState(() {
          dashboardData = result['data'] as Map<String, dynamic>? ?? {};
          isLoading = false;
        });
        print('Dashboard data loaded successfully: ${dashboardData.keys}');
      } else {
        setState(() {
          errorMessage = (result['data']['message'] as String?) ??
              'डैशबोर्ड डेटा लोड करने में त्रुटि';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard loading error: $e');
      setState(() {
        errorMessage = 'डैशबोर्ड डेटा लोड करने में त्रुटि';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    final supervisorActions = [
      {
        'id': AppScreen.teacherReports,
        'title': 'शिक्षक रिपोर्ट',
        'subtitle': 'शिक्षकों की गतिविधि रिपोर्ट',
        'icon': Icons.assessment,
        'color': AppTheme.green,
      },
      {
        'id': AppScreen.dataVerification,
        'title': 'डेटा वेरिफिकेशन',
        'subtitle': 'अपलोड किए गए डेटा की जांच',
        'icon': Icons.verified,
        'color': AppTheme.purple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.loggedInUser != null
            ? 'स्वागत, ${appState.loggedInUser}'
            : 'स्वागत, सुपरवाइजर'),
        backgroundColor: AppTheme.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, appState),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.darkGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          child: const Text('पुनः प्रयास करें'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header section
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppTheme.blue,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              // हरिहर पाठशाला Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.school,
                                        size: 50,
                                        color: AppTheme.blue,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'हरिहर पाठशाला',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'सुपरवाइजर डैशबोर्ड',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quick actions grid
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'निगरानी कार्य',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGray,
                                ),
                              ),
                              const SizedBox(height: 16),

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: supervisorActions.length,
                                itemBuilder: (context, index) {
                                  final action = supervisorActions[index];
                                  return _buildActionCard(
                                    context,
                                    appState,
                                    action['title'] as String,
                                    action['subtitle'] as String,
                                    action['icon'] as IconData,
                                    action['color'] as Color,
                                    action['id'] as AppScreen,
                                  );
                                },
                              ),

                              const SizedBox(height: 30),

                              // Statistics section with real data
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.analytics,
                                            color: AppTheme.blue,
                                            size: 28,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'जिला सांख्यिकी',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.darkGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatCard(
                                              'कुल स्कूल',
                                              _getStatValue(
                                                  'total_schools', '145'),
                                              Icons.school,
                                              AppTheme.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildStatCard(
                                              'सक्रिय शिक्षक',
                                              _getStatValue(
                                                  'active_teachers', '342'),
                                              Icons.people,
                                              AppTheme.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatCard(
                                              'अपलोडेड फोटो',
                                              _getStatValue(
                                                  'uploaded_photos', '1,248'),
                                              Icons.photo_library,
                                              AppTheme.purple,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildStatCard(
                                              'रजिस्टर्ड छात्र',
                                              _getStatValue(
                                                  'registered_students',
                                                  '8,756'),
                                              Icons.child_care,
                                              AppTheme.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _getStatValue(String key, String defaultValue) {
    // Handle special photo calculation (double the student count)
    if (key == 'uploaded_photos') {
      if (dashboardData.containsKey('total_number_of_student')) {
        final studentCount =
            dashboardData['total_number_of_student'] as int? ?? 0;
        return (studentCount * 2).toString();
      }
      return defaultValue;
    }

    // Map the display keys to API response keys
    String apiKey;
    switch (key) {
      case 'total_schools':
        apiKey = 'total_number_of_school';
        break;
      case 'active_teachers':
        apiKey = 'total_number_of_teacher';
        break;
      case 'registered_students':
        apiKey = 'total_number_of_student';
        break;
      default:
        apiKey = key;
    }

    if (dashboardData.containsKey(apiKey)) {
      return dashboardData[apiKey].toString();
    }
    return defaultValue;
  }

  Widget _buildActionCard(
    BuildContext context,
    AppStateProvider appState,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    AppScreen screen,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          appState.navigateToScreen(screen);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkGray.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppStateProvider appState) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('लॉगआउट'),
          content: const Text('क्या आप वाकई लॉगआउट करना चाहते हैं?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
              ),
              child: const Text('लॉगआउट'),
            ),
          ],
        );
      },
    );
  }
}
