// lib/ssp_generator_screens/widgets/ssp_generator_bottom_nav_bar.dart
import 'package:flutter/material.dart';
// Ensure this path correctly points to your ProjectManagementScreen
// Assuming it's in lib/screens/project_management_screen.dart
import 'package:nist_pocket_guide/ssp_generator_screens/system_management_screen.dart';


class SspGeneratorBottomNavBar extends StatelessWidget {
  const SspGeneratorBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          // Using a known valid icon. You can change this if you find the exact one you want.
          icon: const Icon(Icons.folder_copy_outlined), // Or Icons.settings_applications_outlined
          label: const Text('Project/System Management'),
          onPressed: () {
            // The previous check for isOnProjectManagementScreen was fragile.
            // Navigator.pushAndRemoveUntil is a more direct way to achieve
            // the goal of getting to ProjectManagementScreen and potentially
            // cleaning up the stack.

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                // Optional: give it a name if you use named routes for other checks
                // settings: const RouteSettings(name: '/projectManagement'),
                builder: (context) => const SystemListScreen(),
              ),
              // This predicate removes all routes until the very first one in the stack
              // (typically your MyHomePage or root screen).
              // If ProjectManagementScreen itself is pushed from MyHomePage,
              // this will result in MyHomePage -> ProjectManagementScreen.
              (Route<dynamic> route) => route.isFirst,
            );

            // Alternative: If you simply want to push ProjectManagementScreen on top
            // and allow the user to navigate back through the SSP screens:
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => const ProjectManagementScreen(),
            //   ),
            // );

            // Alternative: If ProjectManagementScreen might already be in the stack
            // and you want to pop back to it if it exists, otherwise push it.
            // This is more complex and usually involves named routes or a custom routing solution.
            // For simplicity, pushAndRemoveUntil (to first) or simple push are common.
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48), // Make button full width
          ),
        ),
      ),
    );
  }
}