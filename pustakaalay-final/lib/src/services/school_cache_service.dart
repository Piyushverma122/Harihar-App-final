import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SchoolCacheService {
  static const String _cacheKey = 'cached_schools_data';
  static const String _lastUpdateKey = 'schools_last_update';
  static const Duration _cacheValidDuration =
      Duration(days: 7); // Cache valid for 7 days
  static const int _maxRetries = 3;
  static const int _timeoutSeconds = 45;

  static List<Map<String, dynamic>>? _memoryCache;
  static bool _isLoading = false;

  /// Get schools with smart caching strategy
  static Future<List<Map<String, dynamic>>> getSchools({
    bool forceRefresh = false,
    void Function(String)? onStatusUpdate,
  }) async {
    try {
      // Return memory cache if available and not forcing refresh
      if (!forceRefresh && _memoryCache != null && _memoryCache!.isNotEmpty) {
        onStatusUpdate?.call('✅ डेटा मेमोरी से लोड किया गया');
        return _memoryCache!;
      }

      // Try to get cached data first (for instant loading)
      if (!forceRefresh) {
        final cachedData = await _getCachedSchools();
        if (cachedData.isNotEmpty) {
          _memoryCache = cachedData;
          onStatusUpdate?.call('📱 कैश से डेटा लोड किया गया');

          // Start background refresh if cache is old
          final isExpired = await _isCacheExpired();
          if (isExpired) {
            onStatusUpdate?.call('🔄 बैकग्राउंड में नया डेटा लोड हो रहा है...');
            _refreshInBackground(onStatusUpdate);
          }

          return cachedData;
        }
      }

      // If no cache or force refresh, fetch from API
      return await _fetchFromApiWithRetry(onStatusUpdate);
    } catch (e) {
      print('❌ Error in getSchools: $e');

      // If all else fails, try to return any cached data we have
      final fallbackData = await _getCachedSchools();
      if (fallbackData.isNotEmpty) {
        onStatusUpdate?.call('⚠️ नेटवर्क एरर - पुराना डेटा दिखाया जा रहा है');
        return fallbackData;
      }

      onStatusUpdate?.call('❌ डेटा लोड नहीं हो सका');
      throw Exception('स्कूल डेटा लोड करने में त्रुटि: $e');
    }
  }

  /// Get school by UDISE code (uses cached data for performance)
  static Future<Map<String, dynamic>?> getSchoolByUdise(
    String udiseCode, {
    void Function(String)? onStatusUpdate,
  }) async {
    try {
      final schools = await getSchools(onStatusUpdate: onStatusUpdate);

      final school = schools.firstWhere(
        (school) => school['udise_code']?.toString() == udiseCode,
        orElse: () => {},
      );

      return school.isNotEmpty ? school : null;
    } catch (e) {
      print('❌ Error getting school by UDISE: $e');
      onStatusUpdate?.call('❌ स्कूल की जानकारी नहीं मिली');
      return null;
    }
  }

  /// Background refresh without blocking UI
  static void _refreshInBackground(
      void Function(String)? onStatusUpdate) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      final newData =
          await _fetchFromApiWithRetry(onStatusUpdate, silent: true);
      if (newData.isNotEmpty) {
        _memoryCache = newData;
        onStatusUpdate?.call('✅ डेटा अपडेट हो गया');
      }
    } catch (e) {
      print('Background refresh failed: $e');
      // Silent fail for background updates
    } finally {
      _isLoading = false;
    }
  }

  /// Fetch from API with retry logic and timeout
  static Future<List<Map<String, dynamic>>> _fetchFromApiWithRetry(
    void Function(String)? onStatusUpdate, {
    bool silent = false,
  }) async {
    if (_isLoading && !silent) {
      onStatusUpdate?.call('⏳ डेटा लोड हो रहा है...');
      return _memoryCache ?? [];
    }

    _isLoading = true;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (!silent) {
          onStatusUpdate?.call(attempt == 1
              ? '🌐 सर्वर से डेटा लोड हो रहा है...'
              : '🔄 पुनः प्रयास ($attempt/$_maxRetries)...');
        }

        final response = await http
            .get(
              Uri.parse(ApiConfig.fetchSchoolUrl),
              headers: ApiConfig.headers,
            )
            .timeout(const Duration(seconds: _timeoutSeconds));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == true && responseData['data'] != null) {
            final List<dynamic> schoolsData =
                responseData['data'] as List<dynamic>;
            final schools = schoolsData.cast<Map<String, dynamic>>();

            // Cache the successful response
            await _cacheSchools(schools);
            _memoryCache = schools;

            if (!silent) {
              onStatusUpdate?.call('✅ ${schools.length} स्कूल लोड हो गए');
            }

            _isLoading = false;
            return schools;
          }
        }

        throw Exception('Invalid response: ${response.statusCode}');
      } catch (e) {
        print('❌ Attempt $attempt failed: $e');

        if (attempt == _maxRetries) {
          _isLoading = false;

          if (!silent) {
            String errorMessage = 'सर्वर से कनेक्ट नहीं हो सका';
            if (e.toString().contains('TimeoutException')) {
              errorMessage = 'सर्वर से जवाब आने में बहुत समय लग रहा है';
            } else if (e.toString().contains('SocketException')) {
              errorMessage = 'इंटरनेट कनेक्शन की जांच करें';
            } else if (e.toString().contains('Connection closed')) {
              errorMessage = 'सर्वर कनेक्शन बंद हो गया';
            }
            onStatusUpdate?.call('❌ $errorMessage');
          }

          throw Exception(e.toString());
        }

        // Wait before retry (exponential backoff)
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    _isLoading = false;
    return [];
  }

  /// Cache schools data locally
  static Future<void> _cacheSchools(List<Map<String, dynamic>> schools) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schoolsJson = jsonEncode(schools);
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_cacheKey, schoolsJson);
      await prefs.setInt(_lastUpdateKey, currentTime);

      print('✅ Schools cached: ${schools.length} items');
    } catch (e) {
      print('❌ Error caching schools: $e');
    }
  }

  /// Get cached schools data
  static Future<List<Map<String, dynamic>>> _getCachedSchools() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schoolsJson = prefs.getString(_cacheKey);

      if (schoolsJson != null) {
        final List<dynamic> schoolsList =
            jsonDecode(schoolsJson) as List<dynamic>;
        final schools = schoolsList.cast<Map<String, dynamic>>();
        print('📱 Loaded ${schools.length} schools from cache');
        return schools;
      }
    } catch (e) {
      print('❌ Error loading cached schools: $e');
    }

    return [];
  }

  /// Check if cache is expired
  static Future<bool> _isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);

      if (lastUpdate == null) return true;

      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);

      return difference > _cacheValidDuration;
    } catch (e) {
      print('❌ Error checking cache expiry: $e');
      return true;
    }
  }

  /// Clear cache (useful for debugging or reset)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
      _memoryCache = null;
      print('🗑️ School cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      final cachedData = prefs.getString(_cacheKey);

      return {
        'hasCachedData': cachedData != null,
        'cachedItemsCount':
            cachedData != null ? (jsonDecode(cachedData) as List).length : 0,
        'lastUpdate': lastUpdate != null
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toString()
            : 'Never',
        'isExpired': await _isCacheExpired(),
        'memoryCache': _memoryCache?.length ?? 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
