import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _udiseIdController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _udiseIdController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call API login
        final result = await ApiService.teacherLogin(
          udiseCode: _udiseIdController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (result['success'] == true) {
          // Debug: Print full login response
          print('=== TEACHER LOGIN RESPONSE DEBUG ===');
          print('Full Response: $result');
          print('Response Data: ${result['data']}');

          if (result['data'] != null) {
            final data = result['data'];
            print('Available fields: ${data.keys}');
            print('Role field: ${data['role']}');
            print('User_type field: ${data['user_type']}');
            print('UserType field: ${data['userType']}');
            print('User_role field: ${data['user_role']}');
          }

          // Extract role from response
          String? userRole = 'teacher'; // Default to teacher
          if (result['data'] != null) {
            final data = result['data'];
            userRole = data['role']?.toString() ??
                data['user_type']?.toString() ??
                data['userType']?.toString() ??
                data['user_role']?.toString() ??
                'teacher';
            userRole = userRole.toLowerCase().trim();
          }

          print('Extracted role: $userRole');

          // Convert string role to UserType enum
          UserType userType;
          switch (userRole) {
            case 'teacher':
            case 'teacher_user':
            case 'school':
            case 'school_admin':
              userType = UserType.teacher;
              break;
            case 'crc':
            case 'supervisor':
            case 'crc_user':
              userType = UserType.crc;
              break;
            default:
              print(
                  'WARNING: Unrecognized role: $userRole, defaulting to teacher');
              userType = UserType.teacher;
              break;
          }

          print('Final UserType: $userType');

          // Login successful
          final appState =
              Provider.of<AppStateProvider>(context, listen: false);
          appState.handleLoginSuccess(userType,
              username: _usernameController.text.trim(),
              udiseCode: _udiseIdController.text.trim());

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('लॉगिन सफल रहा!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Login failed - Add comprehensive debugging
          print('=== LOGIN FAILED DEBUG ===');
          print('Full Response: $result');
          print('Status: ${result['status']}');
          print('Success: ${result['success']}');
          print('Message: ${result['message']}');
          print('Data: ${result['data']}');

          String errorMessage = 'लॉगिन असफल';

          // Check for message in different locations
          if (result['message'] != null) {
            errorMessage = result['message'].toString();
          } else if (result['data'] != null &&
              result['data']['message'] != null) {
            errorMessage = result['data']['message'].toString();
          }

          print('Final error message: $errorMessage');

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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('शिक्षक लॉगिन'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // हरिहर पाठशाला Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.2),
                            blurRadius: 10,
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
                              size: 60,
                              color: AppTheme.primaryGreen,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'हरिहर पाठशाला में स्वागत',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'कृपया अपनी लॉगिन जानकारी दर्ज करें',
                      style: TextStyle(
                        color: AppTheme.darkGray,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Login Card with UDISE Code and Password
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Title
                            const Text(
                              'लॉगिन विवरण',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppTheme.primaryGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // UDISE Code field
                            const Text(
                              'UDISE कोड',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _udiseIdController,
                              decoration: const InputDecoration(
                                hintText: 'अभी के लिए "1234" दर्ज करें',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.school_outlined),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'कृपया UDISE कोड दर्ज करें';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password field
                            const Text(
                              'पासवर्ड',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: 'अपना पासवर्ड दर्ज करें',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'कृपया पासवर्ड दर्ज करें';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username field (separate card)
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'उपयोगकर्ता नाम',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                hintText: 'अपना उपयोगकर्ता नाम दर्ज करें',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'कृपया उपयोगकर्ता नाम दर्ज करें';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'लॉगिन करें',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Help text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.blue.withOpacity(0.3),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.blue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'UDISE कोड आपके स्कूल का विशिष्ट पहचान कोड है।',
                                  style: TextStyle(
                                    color: AppTheme.darkGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'लॉगिन में समस्या? कृपया अपने स्कूल प्रशासक से संपर्क करें।',
                            style: TextStyle(
                              color: AppTheme.darkGray,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
