// lib/screens/ai_rmf_playbook_hub_screen.dart
import 'package:flutter/material.dart';
import 'ai_rmf_type_screen.dart';

class AiRmfPlaybookHubScreen extends StatelessWidget {
  const AiRmfPlaybookHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI RMF Playbook - Types'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
            double cardPadding = constraints.maxWidth > 700 ? 28.0 : 18.0;
            double iconSize = constraints.maxWidth > 700 ? 48.0 : 36.0;
            double avatarRadius = constraints.maxWidth > 700 ? 32.0 : 24.0;
            double fontSize = constraints.maxWidth > 700 ? 18.0 : 15.0;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1,
              children: [
                _buildTypeTile(context, 'Govern', 'Govern', Icons.gavel_rounded, cardPadding, iconSize, avatarRadius, fontSize, Colors.blueAccent),
                _buildTypeTile(context, 'Map', 'Map', Icons.map_outlined, cardPadding, iconSize, avatarRadius, fontSize, Colors.orange),
                _buildTypeTile(context, 'Measure', 'Measure', Icons.straighten_rounded, cardPadding, iconSize, avatarRadius, fontSize, Colors.green),
                _buildTypeTile(context, 'Manage', 'Manage', Icons.settings_applications_outlined, cardPadding, iconSize, avatarRadius, fontSize, Colors.purple),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeTile(BuildContext context, String title, String type, IconData icon, double cardPadding, double iconSize, double avatarRadius, double fontSize, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiRmfTypeScreen(
                aiType: type,
                screenTitle: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha((0.15 * 255).round()),
                radius: avatarRadius,
                child: Icon(icon, size: iconSize, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}