// lib/screens/settings_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/system_management_screen.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/parameter_management_screen.dart';
import 'package:nist_pocket_guide/services/module_preferences_service.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';
import 'package:nist_pocket_guide/services/feedback_service.dart';
import 'package:nist_pocket_guide/models/app_module.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nist_pocket_guide/onboarding/onboarding_service.dart';
import 'package:nist_pocket_guide/onboarding/feature_focused_onboarding_flow.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ModulePreferencesService? _modulePrefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _modulePrefs = ModulePreferencesService(prefs);
      _isLoading = false;
    });
  }

  void _handleRestorePurchases(
    BuildContext context,
    PurchaseService purchaseService,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Restoring purchases...'),
            ],
          ),
        );
      },
    );

    try {
      await purchaseService.restorePurchases();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Purchase restoration complete'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to restore purchases: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _openAppStore() async {
    // Actual app store information from project configuration
    const iosAppId = '6744904723'; // Published iOS App Store ID
    const androidPackageName =
        'life.eucann.nist_pocket_guide'; // From android/app/build.gradle.kts

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Try multiple iOS URLs in order of preference
        final iosUrls = [
          'itms-apps://apps.apple.com/app/id$iosAppId', // Native App Store app
          'https://apps.apple.com/app/id$iosAppId', // Web fallback
        ];

        for (final urlString in iosUrls) {
          final url = Uri.parse(urlString);
          debugPrint('Trying iOS URL: $url');

          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            debugPrint('Successfully launched iOS URL: $url');
            return;
          }
        }

        debugPrint('No iOS URLs could be launched');
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Try multiple Android URLs in order of preference
        final androidUrls = [
          'market://details?id=$androidPackageName', // Native Play Store app
          'https://play.google.com/store/apps/details?id=$androidPackageName', // Web fallback
        ];

        for (final urlString in androidUrls) {
          final url = Uri.parse(urlString);
          debugPrint('Trying Android URL: $url');

          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            debugPrint('Successfully launched Android URL: $url');
            return;
          }
        }

        debugPrint('No Android URLs could be launched');
      } else {
        debugPrint('Unsupported platform: $defaultTargetPlatform');
      }

      // If we get here, no URLs worked
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open app store')),
        );
      }
    } catch (e) {
      debugPrint('Error opening app store: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening app store: $e')));
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            _buildSectionHeader(context, 'MODULE VISIBILITY'),
            Card(
              child: Consumer<PurchaseService>(
                builder: (context, purchaseService, child) {
                  return Column(
                    children: [
                      // Build module switches dynamically based on available modules
                      ...AppModules.getAvailableModules().asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final module = entry.value;
                        final isVisible = _modulePrefs!.getModuleVisibility(
                          module.preferenceKey,
                        );

                        return Column(
                          children: [
                            SwitchListTile(
                              secondary: Icon(module.icon),
                              title: Text(module.title),
                              subtitle: Text(
                                purchaseService.isPro
                                    ? module.description
                                    : '${module.description} (Pro feature)',
                              ),
                              value: isVisible,
                              onChanged:
                                  purchaseService.isPro
                                      ? (bool value) async {
                                        await _modulePrefs!.setModuleVisibility(
                                          module.preferenceKey,
                                          value,
                                        );
                                        setState(() {});
                                      }
                                      : (bool value) {
                                        showUpgradeDialog(
                                          context,
                                          purchaseService,
                                        );
                                      },
                            ),
                            // Add divider between items (except for the last one)
                            if (index <
                                AppModules.getAvailableModules().length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Consumer<PurchaseService>(
                builder: (context, purchaseService, child) {
                  return ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Reset Module Visibility'),
                    subtitle: Text(
                      purchaseService.isPro
                          ? 'Reset all modules to default visibility'
                          : 'Reset all modules to default visibility (Pro feature)',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:
                        purchaseService.isPro
                            ? () async {
                              await _modulePrefs!.resetAllModulesToDefaults();
                              setState(() {});
                              if (mounted) {
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Module visibility reset to defaults',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                            : () {
                              showUpgradeDialog(context, purchaseService);
                            },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'ACCOUNT & PURCHASES'),
            Card(
              child: Consumer<PurchaseService>(
                builder: (context, purchaseService, child) {
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.restore),
                        title: const Text('Restore Purchases'),
                        subtitle: const Text(
                          'Restore previously purchased Pro features',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            () => _handleRestorePurchases(
                              context,
                              purchaseService,
                            ),
                      ),
                      if (purchaseService.isPro) const Divider(height: 1),
                      if (purchaseService.isPro)
                        ListTile(
                          leading: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Pro Status'),
                          subtitle: const Text(
                            'You have access to Pro features',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'FEEDBACK & SUPPORT'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Send Feedback'),
                    subtitle: const Text(
                      'Share your thoughts or report issues',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => FeedbackService.showFeedbackScreen(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate in App Store'),
                    subtitle: const Text(
                      'Help others discover NIST Pocket Guide',
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openAppStore(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'DATA MANAGEMENT - EXPERIMENTAL'),
            Card(
              child: Consumer<PurchaseService>(
                builder: (context, purchaseService, child) {
                  return ListTile(
                    leading: const Icon(Icons.business_center_outlined),
                    title: const Text('Project/System Management'),
                    subtitle: Text(
                      purchaseService.isPro
                          ? 'Create, edit, or delete your SSP projects'
                          : 'Create, edit, or delete your SSP projects (Pro)',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (purchaseService.isPro) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SystemListScreen(),
                          ),
                        );
                      } else {
                        showUpgradeDialog(context, purchaseService);
                      }
                    },
                  );
                },
              ),
            ),
            Card(
              child: Consumer<PurchaseService>(
                builder: (context, purchaseService, child) {
                  return ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Edit System Parameter Definitions'),
                    subtitle: Text(
                      purchaseService.isPro
                          ? 'Manage, search, and edit parameter values and examples'
                          : 'Manage, search, and edit parameter values and examples (Pro)',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (purchaseService.isPro) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const ParameterManagementScreen(),
                          ),
                        );
                      } else {
                        showUpgradeDialog(context, purchaseService);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'WELCOME'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Re-run Welcome'),
                subtitle: const Text('Reset and walk through intro again'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await OnboardingService().reset();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FeatureFocusedOnboardingFlow(
                            onFinished: () {
                              Navigator.pop(context); // close flow
                              setState(() {}); // refresh settings
                            },
                          ),
                    ),
                  );
                },
              ),
            ),
            // You can add more settings options here in the future
            // Example:
            // const SizedBox(height: 16),
            // _buildSectionHeader(context, 'APPEARANCE'),
            // Card(
            //   child: ListTile(
            //     leading: const Icon(Icons.color_lens_outlined),
            //     title: const Text('Theme Settings'),
            //     trailing: const Icon(Icons.chevron_right),
            //     onTap: () {
            //       // Navigate to Theme Settings Screen
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
