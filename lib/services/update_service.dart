import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String name;
  final String url;
  final String publishedAt;
  final String body;
  final bool isNewerVersion;

  UpdateInfo({
    required this.version,
    required this.name,
    required this.url,
    required this.publishedAt,
    required this.body,
    required this.isNewerVersion,
  });
}

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/Bengerthelorf/gittask/releases/latest';
  static const String _githubRepoUrl = 'https://github.com/Bengerthelorf/gittask';
  
  // Check if network permission issues exist on macOS
  static Future<bool> openNetworkPermissionsIfNeeded() async {
    if (Platform.isMacOS) {
      try {
        // Try a simple network request
        await InternetAddress.lookup('api.github.com')
            .timeout(const Duration(seconds: 3));
        return true; // Connection works, permissions are OK
      } catch (e) {
        debugPrint('Network permission check failed: $e');
        
        // If we get a permission error, suggest opening system preferences
        if (e.toString().contains('Operation not permitted')) {
          // Show a dialog asking the user to grant network permissions
          bool? opened = await launchUrl(
            Uri.parse('x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'),
            mode: LaunchMode.externalApplication,
          );
          
          return opened ?? false;
        }
      }
    }
    return true; // Not macOS or no permission issues detected
  }
  
  // Open GitHub repo page in browser as fallback
  static Future<bool> openGitHubRepo() async {
    return await launchUrl(
      Uri.parse(_githubRepoUrl),
      mode: LaunchMode.externalApplication,
    );
  }
  
  // Check for updates from GitHub
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint('Current app version: $currentVersion');
      
      http.Response? response;
      
      // First try with standard http client
      try {
        final httpClient = http.Client();
        try {
          response = await httpClient.get(
            Uri.parse(_githubApiUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'GitTask-App/${packageInfo.version}',
            },
          ).timeout(const Duration(seconds: 10));
        } finally {
          httpClient.close();
        }
      } catch (e) {
        debugPrint('Standard HTTP request failed: $e');
        
        // If standard HTTP fails, try with HttpClient (may work better on some platforms)
        if (Platform.isMacOS || Platform.isIOS) {
          debugPrint('Trying with HttpClient for macOS/iOS...');
          try {
            final httpClient = HttpClient();
            final request = await httpClient.getUrl(Uri.parse(_githubApiUrl));
            request.headers.set('Accept', 'application/vnd.github.v3+json');
            request.headers.set('User-Agent', 'GitTask-App/${packageInfo.version}');
            
            final httpResponse = await request.close();
            final responseBody = await httpResponse.transform(utf8.decoder).join();
            
            response = http.Response(
              responseBody,
              httpResponse.statusCode,
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
              },
            );
            
            httpClient.close();
          } catch (httpClientError) {
            debugPrint('HttpClient attempt also failed: $httpClientError');
          }
        }
      }
      
      // If we still don't have a response, return null
      if (response == null) {
        debugPrint('Failed to get a response from GitHub API');
        return null;
      }
      
      debugPrint('GitHub API response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        int previewLength = response.body.length > 100 ? 100 : response.body.length;
        debugPrint('GitHub API response preview: ${response.body.substring(0, previewLength)}...');
      }
      
      if (response.statusCode == 200) {
        // Check for empty or invalid JSON response
        try {
          final data = json.decode(response.body);
          
          // Handle case where no releases exist
          if (data == null || (data is Map && data.isEmpty)) {
            debugPrint('No release information found on GitHub');
            return null;
          }
          
          // Make sure we have a tag_name
          if (!data.containsKey('tag_name') || data['tag_name'] == null) {
            debugPrint('No tag_name found in GitHub response');
            return null;
          }
          
          // Parse latest version (remove 'v' prefix if exists)
          String latestVersion = data['tag_name'] ?? '';
          if (latestVersion.isEmpty) {
            debugPrint('Empty tag_name found in GitHub response');
            return null;
          }
          
          if (latestVersion.startsWith('v')) {
            latestVersion = latestVersion.substring(1);
          }
          
          debugPrint('Latest version on GitHub: $latestVersion');
          
          // Compare versions
          final bool isNewerVersion = _isNewerVersion(currentVersion, latestVersion);
          
          return UpdateInfo(
            version: latestVersion,
            name: data['name'] ?? 'Version $latestVersion',
            url: data['html_url'] ?? '',
            publishedAt: data['published_at'] ?? '',
            body: data['body'] ?? 'No release notes available.',
            isNewerVersion: isNewerVersion,
          );
        } catch (jsonError) {
          debugPrint('Error parsing JSON response: $jsonError');
          return null;
        }
      } else {
        // Response wasn't successful
        debugPrint('Failed to check for updates: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          debugPrint('Response body: ${response.body}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking for updates: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Compare version strings (improved implementation)
  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      // Handle empty strings
      if (currentVersion.isEmpty || latestVersion.isEmpty) {
        return false;
      }
      
      // Split version strings like "1.0.1" into [1, 0, 1]
      final List<int> current = [];
      final List<int> latest = [];
      
      try {
        current.addAll(currentVersion.split('.').map((part) => int.parse(part.trim())));
      } catch (e) {
        debugPrint('Error parsing current version: $e');
        return false;
      }
      
      try {
        latest.addAll(latestVersion.split('.').map((part) => int.parse(part.trim())));
      } catch (e) {
        debugPrint('Error parsing latest version: $e');
        return false;
      }
      
      // Ensure both lists have the same length
      while (current.length < latest.length) {
        current.add(0);
      }
      while (latest.length < current.length) {
        latest.add(0);
      }
      
      // Compare version parts
      for (int i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) {
          return true;
        } else if (latest[i] < current[i]) {
          return false;
        }
      }
      
      // If all parts are equal, it's not a newer version
      return false;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }
}