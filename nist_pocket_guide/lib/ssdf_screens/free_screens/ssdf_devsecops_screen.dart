// lib/ssdf_screens/free_screens/ssdf_devsecops_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_data_manager.dart';
import '../../models/ssdf_models.dart';
import '../widgets/sdlc_phase_mapper_widget.dart';
import '../widgets/tool_recommendations_widget.dart';
import '../pro_screens/ssdf_maturity_assessment_screen.dart';
import '../../services/purchase_service.dart';
import '../../services/utils/upgrade_dialog.dart';

class SsdfDevSecOpsScreen extends StatelessWidget {
  const SsdfDevSecOpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<AppDataManager>(context);
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final catalog = dataManager.ssdfCatalog;

    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SSDF DevSecOps Tools'),
        ),
        body: const Center(
          child: Text('SSDF catalog not loaded'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSDF DevSecOps Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () {
              if (purchaseService.isPro) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SsdfMaturityAssessmentScreen(),
                  ),
                );
              } else {
                showUpgradeDialog(context, purchaseService);
              }
            },
            tooltip: 'Maturity Assessment',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(),
            const SizedBox(height: 24),
            _QuickActionsRow(purchaseService: purchaseService),
            const SizedBox(height: 24),
            SdlcPhaseMapperWidget(
              practiceGroups: catalog.practiceGroups,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange,
            Colors.orange.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.developer_mode, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DevSecOps Integration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Map SSDF practices to your software development lifecycle, discover recommended tools, and assess your security maturity.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final PurchaseService purchaseService;

  const _QuickActionsRow({required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.timeline,
            title: 'SDLC Phases',
            description: 'Map practices',
            color: Colors.blue,
            onTap: () {
              // Already on this screen, could scroll to section
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scroll down to view SDLC phase mapping'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.construction,
            title: 'Tool Guide',
            description: 'View recommendations',
            color: Colors.green,
            onTap: () {
              _showToolsOverview(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.assessment,
            title: 'Assessment',
            description: 'Rate maturity',
            color: Colors.purple,
            isPro: true,
            onTap: () {
              if (purchaseService.isPro) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SsdfMaturityAssessmentScreen(),
                  ),
                );
              } else {
                showUpgradeDialog(context, purchaseService);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showToolsOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(
                    width: 40,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DevSecOps Tool Categories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Common tool types used in SSDF implementation',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: const [
                      _ToolCategoryCard(
                        icon: Icons.search,
                        title: 'SAST (Static Analysis)',
                        description: 'Analyze source code for vulnerabilities',
                        examples: 'SonarQube, Semgrep, CodeQL',
                      ),
                      _ToolCategoryCard(
                        icon: Icons.bug_report,
                        title: 'DAST (Dynamic Analysis)',
                        description: 'Test running applications for vulnerabilities',
                        examples: 'OWASP ZAP, Burp Suite',
                      ),
                      _ToolCategoryCard(
                        icon: Icons.inventory_2,
                        title: 'SCA (Composition Analysis)',
                        description: 'Scan dependencies for known vulnerabilities',
                        examples: 'Snyk, OWASP Dependency-Check',
                      ),
                      _ToolCategoryCard(
                        icon: Icons.list_alt,
                        title: 'SBOM Generation',
                        description: 'Create Software Bill of Materials',
                        examples: 'CycloneDX, Syft, SPDX',
                      ),
                      _ToolCategoryCard(
                        icon: Icons.security,
                        title: 'Secret Scanning',
                        description: 'Detect exposed credentials and API keys',
                        examples: 'GitGuardian, TruffleHog',
                      ),
                      _ToolCategoryCard(
                        icon: Icons.shield,
                        title: 'Container Security',
                        description: 'Scan container images for vulnerabilities',
                        examples: 'Trivy, Clair, Anchore',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isPro;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isPro = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isPro) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String examples;

  const _ToolCategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.label_outline, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          examples,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
