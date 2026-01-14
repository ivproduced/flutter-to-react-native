import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:nist_pocket_guide/services/purchase_service.dart'; // Import purchase service

class AboutScreen extends StatefulWidget {
  final PurchaseService purchaseService;
  const AboutScreen({required this.purchaseService, super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
   // Initialize purchase service
  String _versionInfo = 'Unknown';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _versionInfo = "Version: ${packageInfo.version} + Build: ${packageInfo.buildNumber}";
    });
  }

  // Helper function to launch the email app
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@eucann.life',
      query: 'subject=NIST Pocket Guide Feedback',
    );
    // Capture context beforehand for Snackbars
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Could not launch email app.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error launching email: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get text theme for styling
    final textTheme = Theme.of(context).textTheme;
    const double spacing = 20.0; // Spacing between sections
    const double internalSpacing = 10.0; // Spacing within sections

    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        // NO custom leading widget here, to get default back button
      ),
      body: SafeArea( // <--- WRAP with SafeArea
        child: SingleChildScrollView( // <--- SafeArea's child
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- App Title/Intro ---
                Text(
                  "About NIST Pocket Guide", // Added emoji back
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: internalSpacing),
                const Text(
                  "This app provides an interactive viewer for the NIST SP 800-53 control framework. It's designed to help professionals navigate complex compliance requirements efficiently.",
                ),
                const SizedBox(height: spacing),
                const Divider(),
                const SizedBox(height: spacing),

                // --- App Info Section ---
                Text("App Info", style: textTheme.headlineSmall),
                const SizedBox(height: internalSpacing),
                Text(
                  _versionInfo, // Display the app version here
                  style: textTheme.bodyMedium, // Adjust style as needed
                ),
                const SizedBox(height: internalSpacing / 2),
                const Text(
                  "Developed for professionals seeking quick access to NIST control references in a pocket-friendly format.",
                ),
                const SizedBox(height: spacing),
                const Divider(),
                const SizedBox(height: spacing),

                // --- Attribution Section ---
                Text("Attribution", style: textTheme.headlineSmall),
                const SizedBox(height: internalSpacing),
                const Text(
                  "Content is based on the NIST SP 800-53 Revision 5 framework, developed by the National Institute of Standards and Technology (NIST). All referenced material is in the public domain.",
                ),
                const SizedBox(height: spacing),
                const Divider(),
                const SizedBox(height: spacing),

                // --- Feedback Section ---
                Text("Feedback & Support", style: textTheme.headlineSmall),
                const SizedBox(height: internalSpacing),
                const Text("Got ideas or ran into a bug?"),
                const SizedBox(height: internalSpacing / 2),
                // Tappable Text Link
                InkWell(
                  onTap: _launchEmail, // Call the helper function
                  child: const Text(
                    "Email the Developer",
                    style: TextStyle(
                      color: Colors.blue, // Style like a link
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue, // Match link color
                    ),
                  ),
                ),
                const SizedBox(height: spacing),
                const Divider(),
                const SizedBox(height: spacing),

/*
              Text("Purchases", style: textTheme.headlineSmall),
                const SizedBox(height: internalSpacing),
                ElevatedButton(
                  // Disable button while restoring
                  onPressed: _isRestoring ? null : _restorePurchases,
                  child: _isRestoring
                      ? const SizedBox( // Show loading indicator
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Restore Purchases"),
                ),
                const SizedBox(height: internalSpacing),
                const Text(
                  "If you've previously purchased the Pro version, tap here to restore access.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: spacing), // Add spacing after
                const Divider(), // Add divider after
                const SizedBox(height: spacing), // Add spacing after
*/
                // --- Disclaimer ---
                Text(
                  "This app is not affiliated with or endorsed by NIST. All information is provided as-is for reference purposes only.",
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]), // Similar to .footnote/.secondary
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}