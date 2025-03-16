import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isCheckingForUpdates = false;
  UpdateInfo? _updateInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Material 3 dynamic color toggle
                      SwitchListTile(
                        title: const Text('Use Dynamic Colors'),
                        subtitle: const Text('Use colors from your device wallpaper (Android 12+)'),
                        value: themeProvider.useDynamicColor,
                        onChanged: (value) {
                          themeProvider.setUseDynamicColor(value);
                        },
                        secondary: Icon(
                          Icons.color_lens,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      
                      const Divider(),
                      
                      // Only show color options when dynamic color is disabled
                      if (!themeProvider.useDynamicColor) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                          child: Text(
                            'Theme Color', 
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: AppConstants.colorOptions
                            .map((color) => GestureDetector(
                              onTap: () {
                                themeProvider.setSeedColor(color);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: themeProvider.seedColor.value == color.value
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                            .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      const Divider(),
                      
                      // Theme mode selection
                      ListTile(
                        leading: Icon(
                          Icons.brightness_6,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: const Text('Theme Mode'),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeProvider.themeMode,
                          onChanged: (ThemeMode? newValue) {
                            if (newValue != null) {
                              themeProvider.setThemeMode(newValue);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                          underline: const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Updates Card
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.system_update_outlined,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      title: const Text('Check for Updates'),
                      subtitle: _updateInfo != null
                          ? Text(_updateInfo!.isNewerVersion
                              ? 'New version available: ${_updateInfo!.version}'
                              : 'You have the latest version')
                          : null,
                      trailing: _isCheckingForUpdates
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onTap: _checkForUpdates,
                    ),
                    
                    // Show update info if available
                    if (_updateInfo != null && _updateInfo!.isNewerVersion) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _updateInfo!.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _updateInfo!.body,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _launchUrl(_updateInfo!.url),
                              icon: const Icon(Icons.download),
                              label: const Text('Download Update'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Always provide a direct link to GitHub as backup
                    const Divider(),
                    ListTile(
                      title: const Text('Visit GitHub Repository'),
                      subtitle: const Text('Check for latest releases manually'),
                      leading: const Icon(Icons.open_in_new),
                      onTap: () => UpdateService.openGitHubRepo(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // About Card
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('About GitTask'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: '1.0.1',
                      applicationLegalese: '©2025 GitTask',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'GitTask is a task management app that implements Git concepts for better task tracking and management.',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Check for updates
  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
    });
    
    // On macOS, check for network permissions first
    if (Platform.isMacOS) {
      final permissionsOk = await UpdateService.openNetworkPermissionsIfNeeded();
      if (!permissionsOk && mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.security, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('GitTask needs network permission to check for updates. Please check system preferences.'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
    }
    
    try {
      final updateInfo = await UpdateService.checkForUpdate();
      
      setState(() {
        _updateInfo = updateInfo;
        _isCheckingForUpdates = false;
      });
      
      // Show snackbar with result
      if (!mounted) return;
      
      if (updateInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Unable to check for updates. Please make sure you have an internet connection and try again.'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _checkForUpdates,
            ),
          ),
        );
      } else if (!updateInfo.isNewerVersion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('You have the latest version'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking for updates: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _isCheckingForUpdates = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Error checking for updates: ${e.toString().split('\n').first}'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'RETRY',
            onPressed: _checkForUpdates,
          ),
        ),
      );
    }
  }
  
  // Launch URL
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open $url'),
      ));
    }
  }
}