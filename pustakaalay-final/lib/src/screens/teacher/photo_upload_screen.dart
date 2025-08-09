import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _childPlantImage; // बच्चे और पौधे की फोटो
  File? _certificateImage; // सर्टिफिकेट की फोटो
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _classController = TextEditingController();
  final _plantNameController = TextEditingController();
  // final _mobileController = TextEditingController(); // Hidden
  final _dinankController = TextEditingController(); // Date field (dinank)
  bool _isUploading = false;
  String? _selectedClass; // Selected class for dropdown

  @override
  void initState() {
    super.initState();
    // Set current date as default
    _dinankController.text = _getCurrentDate();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _schoolController.dispose();
    _classController.dispose();
    _plantNameController.dispose();
    // _mobileController.dispose(); // Hidden
    _dinankController.dispose();
    super.dispose();
  }

  // Copy image to permanent app directory to prevent cache cleanup
  Future<File> _copyImageToPermanentLocation(
      File sourceFile, String imageType) async {
    try {
      print('📁 Copying image to permanent location...');
      print('📁 Source: ${sourceFile.path}');

      // Get app documents directory (permanent storage)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      // Create images subdirectory if it doesn't exist
      final Directory imagesDir = Directory('$appDocPath/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        print('📁 Created images directory: ${imagesDir.path}');
      }

      // Generate unique filename with timestamp and type
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${imageType}_${timestamp}.jpg';
      final String newPath = '${imagesDir.path}/$fileName';

      print('📁 Copying to: $newPath');

      // Copy the file
      final File newFile = await sourceFile.copy(newPath);

      // Verify the copy was successful
      if (await newFile.exists()) {
        final int newFileSize = await newFile.length();
        print('✅ Image copied successfully!');
        print('📁 New path: ${newFile.path}');
        print('📁 New size: $newFileSize bytes');

        return newFile;
      } else {
        throw Exception(
            'Failed to copy image - file does not exist after copy');
      }
    } catch (e) {
      print('❌ Error copying image: $e');
      throw Exception('Failed to copy image to permanent location: $e');
    }
  }

  Future<void> _pickImage(ImageSource source, String imageType) async {
    try {
      print('📸 Starting image picker for: $imageType');
      print('📸 Source: $source');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('📸 Image selected from picker:');
        print('  Path: ${image.path}');
        print('  Name: ${image.name}');

        // Create File object
        final File imageFile = File(image.path);

        // Immediate validation
        print('📸 Validating selected image...');

        // Check if file exists immediately after selection
        final bool existsImmediately = await imageFile.exists();
        print('📸 File exists immediately: $existsImmediately');

        if (!existsImmediately) {
          throw Exception(
              'Selected image file does not exist immediately after selection');
        }

        // Check file size immediately
        final int fileSize = await imageFile.length();
        print('📸 File size: $fileSize bytes');

        if (fileSize == 0) {
          throw Exception('Selected image file is empty');
        }

        // Try to read a few bytes to ensure file is accessible
        try {
          final bytes = await imageFile.readAsBytes();
          print('📸 File is readable, total bytes: ${bytes.length}');

          // Verify it's a valid image by checking for image headers
          if (bytes.length < 10) {
            throw Exception('File too small to be a valid image');
          }
        } catch (e) {
          print('❌ Error reading image file: $e');
          throw Exception('Selected image file cannot be read: $e');
        }

        print('✅ Image validation successful for: $imageType');
        print('  Final path: ${imageFile.path}');
        print('  Final size: $fileSize bytes');

        // Copy image to permanent location to prevent cache deletion
        print('📁 Copying image to permanent storage...');
        final File permanentFile =
            await _copyImageToPermanentLocation(imageFile, imageType);

        setState(() {
          if (imageType == 'child_plant') {
            _childPlantImage = permanentFile;
            print('✅ Plant image stored: ${_childPlantImage!.path}');
          } else if (imageType == 'certificate') {
            _certificateImage = permanentFile;
            print('✅ Certificate image stored: ${_certificateImage!.path}');
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(imageType == 'child_plant'
                ? 'पौधे की फोटो सेलेक्ट हो गई ✅'
                : 'सर्टिफिकेट की फोटो सेलेक्ट हो गई ✅'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Log current state
        print('📱 Current state after selection:');
        print('  Plant image: ${_childPlantImage?.path ?? 'null'}');
        print('  Certificate image: ${_certificateImage?.path ?? 'null'}');
      } else {
        print('📸 No image selected (user cancelled)');
      }
    } catch (e) {
      print('❌ Image selection error: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Reset the problematic image
      setState(() {
        if (imageType == 'child_plant') {
          _childPlantImage = null;
        } else if (imageType == 'certificate') {
          _certificateImage = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('फोटो सेलेक्ट करने में त्रुटि: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dinankController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _uploadPhoto() async {
    // Prevent multiple simultaneous uploads
    if (_isUploading) {
      print('⚠️ Upload already in progress, ignoring duplicate request');
      return;
    }

    if (_formKey.currentState!.validate() &&
        _childPlantImage != null &&
        _certificateImage != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        // Validate files before uploading
        print('🔍 Validating files before upload...');
        print('🔍 Plant image object: $_childPlantImage');
        print('🔍 Certificate image object: $_certificateImage');

        // Check plant image with detailed debugging
        if (_childPlantImage == null) {
          throw Exception('पौधे की फोटो सेलेक्ट नहीं की गई है।');
        }

        print('🔍 Plant image path: ${_childPlantImage!.path}');
        print('🔍 Checking if plant image exists...');

        final bool plantExists = await _childPlantImage!.exists();
        print('🔍 Plant image exists: $plantExists');

        if (!plantExists) {
          print('❌ Plant image file not found at: ${_childPlantImage!.path}');
          throw Exception(
              'पौधे की फोटो फाइल उपलब्ध नहीं है। कृपया दोबारा सेलेक्ट करें।');
        }

        print('🔍 Getting plant image size...');
        final int plantImageSize = await _childPlantImage!.length();
        print('🔍 Plant image size: $plantImageSize bytes');

        if (plantImageSize == 0) {
          throw Exception('पौधे की फोटो खराब है। कृपया दोबारा सेलेक्ट करें।');
        }

        // Check certificate image with detailed debugging
        if (_certificateImage == null) {
          throw Exception('सर्टिफिकेट की फोटो सेलेक्ट नहीं की गई है।');
        }

        print('🔍 Certificate image path: ${_certificateImage!.path}');
        print('🔍 Checking if certificate image exists...');

        final bool certExists = await _certificateImage!.exists();
        print('🔍 Certificate image exists: $certExists');

        if (!certExists) {
          print(
              '❌ Certificate image file not found at: ${_certificateImage!.path}');
          throw Exception(
              'सर्टिफिकेट की फोटो फाइल उपलब्ध नहीं है। कृपया दोबारा सेलेक्ट करें।');
        }

        print('🔍 Getting certificate image size...');
        final int certificateImageSize = await _certificateImage!.length();
        print('🔍 Certificate image size: $certificateImageSize bytes');

        if (certificateImageSize == 0) {
          throw Exception(
              'सर्टिफिकेट की फोटो खराब है। कृपया दोबारा सेलेक्ट करें।');
        }

        print('✅ File validation passed:');
        print(
            '  Plant image: ${_childPlantImage!.path} (${plantImageSize} bytes)');
        print(
            '  Certificate image: ${_certificateImage!.path} (${certificateImageSize} bytes)');

        // Get UDISE code from app state
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final String udiseCode =
            appState.udiseCode ?? '12345'; // Use 12345 as fallback

        print('📤 Starting student registration...');
        print('  Name: ${_studentNameController.text.trim()}');
        print('  School: ${_schoolController.text.trim()}');
        print('  Class: ${_classController.text.trim()}');
        print('  Plant: ${_plantNameController.text.trim()}');
        print('  UDISE: $udiseCode');
        print('  Dinank (Date): ${_dinankController.text.trim()}');

        // Call API to register student with actual file objects
        final result = await ApiService.registerStudent(
          name: _studentNameController.text.trim(),
          schoolName: _schoolController.text.trim(),
          className: _classController.text.trim(),
          mobile: null, // Send null instead of mobile number
          nameOfTree: _plantNameController.text.trim(),
          plantImage: _childPlantImage!,
          certificateImage: _certificateImage!,
          udiseCode: udiseCode,
          dinank: _dinankController.text
              .trim(), // Send dinank (date) instead of employeeId
        );

        if (!mounted) return;

        print('📋 Registration result: ${result['success']}');
        print('📋 Status code: ${result['statusCode']}');
        print('📋 Response data: ${result['data']}');

        if (result['success'] == true) {
          // Registration successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 छात्र पंजीकरण सफल रहा!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Reset form
          setState(() {
            _childPlantImage = null;
            _certificateImage = null;
            _selectedClass = null; // Reset selected class
            _isUploading = false;
          });
          _formKey.currentState!.reset();
          _studentNameController.clear();
          _schoolController.clear();
          _classController.clear();
          _plantNameController.clear();
          // _mobileController.clear(); // Hidden
          _dinankController.clear();
        } else {
          // Registration failed
          String errorMessage = 'पंजीकरण असफल';
          if (result['data'] != null && result['data']['message'] != null) {
            errorMessage = result['data']['message'].toString();
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

      setState(() {
        _isUploading = false;
      });
    } else if (_childPlantImage == null || _certificateImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया दोनों फोटो सेलेक्ट करें')),
      );
    }
  }

  void _showImageSourceDialog(String imageType) {
    final String title =
        imageType == 'child_plant' ? 'पौधे की फोटो' : 'बच्चे और पौधे की फोटो';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$title कैसे लें?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('कैमरा से फोटो लें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, imageType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('गैलरी से चुनें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, imageType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('फोटो अपलोड'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions card
                const Card(
                  color: AppTheme.lightBlue,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppTheme.blue,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'फोटो अपलोड निर्देश',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• पहली फोटो: पौधे की तस्वीर\n'
                          '• दूसरी फोटो: छात्र, पेड़ और शिक्षक तीनों दिखने चाहिए\n'
                          '• दोनों फोटो साफ और स्पष्ट होनी चाहिए\n'
                          '• उचित रोशनी में फोटो लें',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Photo selection areas
                // 1. Child and Plant Photo
                const Text(
                  '1. पौधे की फोटो',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showImageSourceDialog('child_plant'),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color:
                          _childPlantImage != null ? null : AppTheme.lightGreen,
                    ),
                    child: _childPlantImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _childPlantImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: AppTheme.primaryGreen,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'पौधे की फोटो लें',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Certificate Photo
                const Text(
                  '2. बच्चे और पौधे की फोटो',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showImageSourceDialog('certificate'),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _certificateImage != null
                          ? null
                          : AppTheme.lightGreen,
                    ),
                    child: _certificateImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _certificateImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                size: 50,
                                color: AppTheme.primaryGreen,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'बच्चे और पौधे की फोटो लें',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Student details form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'छात्र की जानकारी',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _studentNameController,
                          decoration: const InputDecoration(
                            labelText: 'छात्र का नाम',
                            hintText: 'छात्र का पूरा नाम दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया छात्र का नाम दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _schoolController,
                          decoration: const InputDecoration(
                            labelText: 'स्कूल का नाम',
                            hintText: 'स्कूल का पूरा नाम दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया स्कूल का नाम दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'कक्षा',
                            hintText: 'कक्षा चुनें (1-12)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: List.generate(12, (index) {
                            final classNumber = index + 1;
                            return DropdownMenuItem<String>(
                              value: classNumber.toString(),
                              child: Text('कक्षा $classNumber'),
                            );
                          }),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedClass = newValue;
                              // Update the controller for API compatibility
                              _classController.text = newValue ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया कक्षा चुनें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _plantNameController,
                          decoration: const InputDecoration(
                            labelText: 'पेड़ का नाम',
                            hintText: 'उदाहरण: आम, नीम, पीपल',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.park),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया पेड़ का नाम दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Mobile number field - Hidden for now
                        /*
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'मोबाइल नंबर',
                            hintText: '10 अंकों का मोबाइल नंबर दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            counterText: '', // Hide character counter
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया मोबाइल नंबर दर्ज करें';
                            }
                            if (value.length != 10) {
                              return 'मोबाइल नंबर 10 अंकों का होना चाहिए';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'केवल अंक दर्ज करें';
                            }
                            if (value.startsWith('0') ||
                                value.startsWith('1') ||
                                value.startsWith('2') ||
                                value.startsWith('3') ||
                                value.startsWith('4') ||
                                value.startsWith('5')) {
                              return 'मोबाइल नंबर 6-9 से शुरू होना चाहिए';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        */
                        TextFormField(
                          controller: _dinankController,
                          decoration: const InputDecoration(
                            labelText: 'दिनांक',
                            hintText: 'YYYY-MM-DD',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया दिनांक दर्ज करें';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Upload button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadPhoto,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      _isUploading
                          ? 'पंजीकरण हो रहा है...'
                          : 'छात्र पंजीकरण करें',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
