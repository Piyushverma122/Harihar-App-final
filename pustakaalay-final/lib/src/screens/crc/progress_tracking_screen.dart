import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  String selectedPeriod = 'thisMonth';
  
  Map<String, dynamic> progressData = {
    'totalSchools': 145,
    'activeSchools': 138,
    'totalTeachers': 342,
    'activeTeachers': 298,
    'totalStudents': 8756,
    'registeredStudents': 8234,
    'photosUploaded': 12480,
    'targetsAchieved': 89.5,
    'monthlyGrowth': [
      {'month': 'जुलाई', 'value': 75},
      {'month': 'अगस्त', 'value': 82},
      {'month': 'सितंबर', 'value': 87},
      {'month': 'अक्टूबर', 'value': 89},
      {'month': 'नवंबर', 'value': 92},
    ],
    'districtWise': [
      {'name': 'रायपुर', 'schools': 45, 'completion': 94},
      {'name': 'बिलासपुर', 'schools': 38, 'completion': 91},
      {'name': 'धमतरी', 'schools': 32, 'completion': 87},
      {'name': 'कोरबा', 'schools': 30, 'completion': 85},
    ],
  };

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
          title: const Text('प्रगति ट्रैकिंग'),
          backgroundColor: AppTheme.orange,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => appState.goBack(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('प्रगति रिपोर्ट डाउनलोड की गई')),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Progress Cards
              const Text(
                'समग्र प्रगति',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildProgressCard(
                    'कुल स्कूल',
                    '${progressData['totalSchools']}',
                    '${progressData['activeSchools']} सक्रिय',
                    Icons.school,
                    AppTheme.blue,
                    (progressData['activeSchools'] as int) / (progressData['totalSchools'] as int),
                  ),
                  _buildProgressCard(
                    'कुल शिक्षक',
                    '${progressData['totalTeachers']}',
                    '${progressData['activeTeachers']} सक्रिय',
                    Icons.people,
                    AppTheme.green,
                    (progressData['activeTeachers'] as int) / (progressData['totalTeachers'] as int),
                  ),
                  _buildProgressCard(
                    'कुल छात्र',
                    '${progressData['totalStudents']}',
                    '${progressData['registeredStudents']} रजिस्टर्ड',
                    Icons.child_care,
                    AppTheme.purple,
                    (progressData['registeredStudents'] as int) / (progressData['totalStudents'] as int),
                  ),
                  _buildProgressCard(
                    'फोटो अपलोड',
                    '${progressData['photosUploaded']}',
                    'लक्ष्य पूर्ण',
                    Icons.photo_library,
                    AppTheme.orange,
                    0.89,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Monthly Progress Chart
              const Text(
                'मासिक प्रगति',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'लक्ष्य पूर्णता प्रतिशत',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: (progressData['monthlyGrowth'] as List).map((data) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${data['value']}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: (data['value'] as int) * 1.5,
                                      decoration: BoxDecoration(
                                        color: AppTheme.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['month'] as String,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // District-wise Progress
              const Text(
                'जिलेवार प्रगति',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: (progressData['districtWise'] as List).map<Widget>((district) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  district['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${district['completion']}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getCompletionColor(district['completion'] as int),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'स्कूल: ${district['schools']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkGray.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (district['completion'] as int) / 100,
                              backgroundColor: AppTheme.gray.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCompletionColor(district['completion'] as int),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('विस्तृत रिपोर्ट देखी गई')),
                        );
                      },
                      icon: const Icon(Icons.assessment),
                      label: const Text('विस्तृत रिपोर्ट'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('डेटा निर्यात किया गया')),
                        );
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('डेटा निर्यात'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.darkGray.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.gray.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(int completion) {
    if (completion >= 90) return AppTheme.green;
    if (completion >= 75) return AppTheme.blue;
    if (completion >= 50) return AppTheme.orange;
    return AppTheme.red;
  }
}
