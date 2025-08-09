import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class PreviousPhotosScreen extends StatefulWidget {
  const PreviousPhotosScreen({super.key});

  @override
  State<PreviousPhotosScreen> createState() => _PreviousPhotosScreenState();
}

class _PreviousPhotosScreenState extends State<PreviousPhotosScreen> {
  // Sample data for demonstration
  final List<Map<String, dynamic>> _uploadedPhotos = [
    {
      'id': '1',
      'title': 'छात्र + पेड़ + शिक्षिका',
      'date': '15/07/2025',
      'school': 'राजकीय प्राथमिक विद्यालय',
      'studentCount': 25,
      'status': 'अप्रूव्ड',
      'description': 'कक्षा 5 के छात्रों के साथ पेड़ लगाने की गतिविधि',
    },
    {
      'id': '2',
      'title': 'पर्यावरण गतिविधि',
      'date': '12/07/2025',
      'school': 'सरस्वती विद्या मंदिर',
      'studentCount': 18,
      'status': 'पेंडिंग',
      'description': 'छात्रों के साथ पेड़ पौधे की देखभाल',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('अपलोडेड फोटो देखें'),
        backgroundColor: AppTheme.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
      ),
      body: _uploadedPhotos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'कोई फोटो नहीं मिली',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'फोटो अपलोड करने के लिए होम स्क्रीन पर जाएं',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _uploadedPhotos.length,
              itemBuilder: (context, index) {
                final photo = _uploadedPhotos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo,
                        color: AppTheme.orange,
                      ),
                    ),
                    title: Text(
                      photo['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('दिनांक: ${photo['date']}'),
                        Text('स्कूल: ${photo['school']}'),
                        Text('छात्र: ${photo['studentCount']}'),
                        Text('स्थिति: ${photo['status']}'),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('देखें'),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Text('शेयर करें'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'view') {
                          _showPhotoDetails(photo);
                        } else if (value == 'share') {
                          _sharePhoto(photo);
                        }
                      },
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  void _showPhotoDetails(Map<String, dynamic> photo) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(photo['title'] as String),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text('दिनांक: ${photo['date']}'),
              Text('स्कूल: ${photo['school']}'),
              Text('छात्र संख्या: ${photo['studentCount']}'),
              Text('स्थिति: ${photo['status']}'),
              const SizedBox(height: 8),
              Text('विवरण: ${photo['description']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('बंद करें'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sharePhoto(photo);
              },
              child: const Text('शेयर करें'),
            ),
          ],
        );
      },
    );
  }

  void _sharePhoto(Map<String, dynamic> photo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${photo['title']} शेयर किया गया'),
        backgroundColor: AppTheme.green,
      ),
    );
  }
}
