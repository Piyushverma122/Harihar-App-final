import 'dart:convert';
import 'package:http/http.dart' as http;

// Test registration with dummy data (for debugging only)
const String baseUrl = 'http://10.0.2.2:5003'; // Android emulator

void main() async {
  print('🧪 Testing Student Registration API...');

  // Test 1: Check if backend is running
  try {
    final response = await http.get(Uri.parse('$baseUrl/'));
    print('✅ Backend is running - Status: ${response.statusCode}');
  } catch (e) {
    print('❌ Backend connection failed: $e');
    return;
  }

  // Test 2: Test student registration without files (should fail)
  try {
    print('\n📝 Testing registration endpoint structure...');
    final testResponse = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': 'Test Student',
        'school_name': 'Test School',
        'class': '5th',
        'name_of_tree': 'Mango',
        'udise_code': '12345',
        'date': '2025-01-01',
      }),
    );

    print('📝 Registration test response:');
    print('Status: ${testResponse.statusCode}');
    print('Response: ${testResponse.body}');

    if (testResponse.statusCode == 400) {
      print('✅ Expected error - file upload required');
    }
  } catch (e) {
    print('❌ Registration test failed: $e');
  }

  // Test 3: Check current students
  try {
    print('\n📚 Checking current students...');
    final studentsResponse = await http.post(
      Uri.parse('$baseUrl/fetch_student'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'udise_code': '12345',
      }),
    );

    print('📚 Current students:');
    print('Status: ${studentsResponse.statusCode}');
    print('Response: ${studentsResponse.body}');
  } catch (e) {
    print('❌ Students fetch failed: $e');
  }

  print('\n🎉 API tests completed!');
  print('\n💡 Tips for mobile app:');
  print('1. Make sure API config uses: http://10.0.2.2:5003');
  print('2. Check image file paths in Flutter console');
  print('3. Verify files exist before upload');
  print('4. Look for detailed logs during upload process');
}
