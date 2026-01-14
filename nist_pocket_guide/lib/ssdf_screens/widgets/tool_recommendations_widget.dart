// lib/ssdf_screens/widgets/tool_recommendations_widget.dart
import 'package:flutter/material.dart';
import '../../models/ssdf_models.dart';

class ToolRecommendationsWidget extends StatelessWidget {
  final SsdfPractice practice;

  const ToolRecommendationsWidget({
    super.key,
    required this.practice,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = _getToolRecommendations(practice.id);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.construction, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Recommended Tools',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tools to help implement this practice',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => _ToolCard(recommendation: rec)),
          ],
        ),
      ),
    );
  }

  List<SsdfToolRecommendation> _getToolRecommendations(String practiceId) {
    // This is a curated list based on SSDF best practices
    // In production, this could be loaded from a JSON file or database
    final Map<String, List<SsdfToolRecommendation>> toolMap = {
      'PO.1': [
        SsdfToolRecommendation(
          practiceId: 'PO.1',
          toolName: 'OWASP SAMM',
          category: 'Assessment Framework',
          description: 'Software Assurance Maturity Model for assessing security requirements',
          url: 'https://owaspsamm.org/',
        ),
        SsdfToolRecommendation(
          practiceId: 'PO.1',
          toolName: 'BSIMM',
          category: 'Maturity Model',
          description: 'Building Security In Maturity Model for software security initiatives',
        ),
      ],
      'PO.2': [
        SsdfToolRecommendation(
          practiceId: 'PO.2',
          toolName: 'OWASP Threat Modeling',
          category: 'Threat Modeling',
          description: 'Framework for identifying and analyzing threats',
          url: 'https://owasp.org/www-community/Threat_Modeling',
        ),
      ],
      'PO.3': [
        SsdfToolRecommendation(
          practiceId: 'PO.3',
          toolName: 'Secure Code Warrior',
          category: 'Training Platform',
          description: 'Interactive secure coding training for developers',
        ),
        SsdfToolRecommendation(
          practiceId: 'PO.3',
          toolName: 'HackTheBox',
          category: 'Training Platform',
          description: 'Hands-on cybersecurity training',
        ),
      ],
      'PS.1': [
        SsdfToolRecommendation(
          practiceId: 'PS.1',
          toolName: 'SonarQube',
          category: 'Code Quality',
          description: 'Continuous code quality and security inspection',
          url: 'https://www.sonarqube.org/',
        ),
        SsdfToolRecommendation(
          practiceId: 'PS.1',
          toolName: 'Semgrep',
          category: 'SAST',
          description: 'Static analysis tool for finding bugs and security issues',
        ),
      ],
      'PS.2': [
        SsdfToolRecommendation(
          practiceId: 'PS.2',
          toolName: 'GitHub Advanced Security',
          category: 'Repository Security',
          description: 'Code scanning, secret scanning, and dependency review',
        ),
        SsdfToolRecommendation(
          practiceId: 'PS.2',
          toolName: 'GitLab Security',
          category: 'Repository Security',
          description: 'Built-in security scanning for GitLab repositories',
        ),
      ],
      'PS.3': [
        SsdfToolRecommendation(
          practiceId: 'PS.3',
          toolName: 'pre-commit',
          category: 'Git Hooks',
          description: 'Framework for managing git hooks to prevent commits with issues',
          url: 'https://pre-commit.com/',
        ),
      ],
      'PW.1': [
        SsdfToolRecommendation(
          practiceId: 'PW.1',
          toolName: 'Snyk',
          category: 'Dependency Scanning',
          description: 'Find and fix vulnerabilities in dependencies',
          url: 'https://snyk.io/',
        ),
        SsdfToolRecommendation(
          practiceId: 'PW.1',
          toolName: 'OWASP Dependency-Check',
          category: 'SCA',
          description: 'Software Composition Analysis tool for detecting vulnerable components',
        ),
      ],
      'PW.2': [
        SsdfToolRecommendation(
          practiceId: 'PW.2',
          toolName: 'Coverity',
          category: 'SAST',
          description: 'Static Application Security Testing tool',
        ),
        SsdfToolRecommendation(
          practiceId: 'PW.2',
          toolName: 'CodeQL',
          category: 'Code Analysis',
          description: 'Semantic code analysis engine for finding vulnerabilities',
        ),
      ],
      'PW.4': [
        SsdfToolRecommendation(
          practiceId: 'PW.4',
          toolName: 'OWASP ZAP',
          category: 'DAST',
          description: 'Dynamic Application Security Testing tool',
          url: 'https://www.zaproxy.org/',
        ),
        SsdfToolRecommendation(
          practiceId: 'PW.4',
          toolName: 'Burp Suite',
          category: 'Web Security',
          description: 'Web vulnerability scanner and penetration testing tool',
        ),
      ],
      'PW.5': [
        SsdfToolRecommendation(
          practiceId: 'PW.5',
          toolName: 'Sigstore',
          category: 'Code Signing',
          description: 'Software signing and transparency service',
          url: 'https://www.sigstore.dev/',
        ),
      ],
      'PW.7': [
        SsdfToolRecommendation(
          practiceId: 'PW.7',
          toolName: 'JFrog Xray',
          category: 'Artifact Analysis',
          description: 'Universal artifact analysis and security scanning',
        ),
      ],
      'PW.8': [
        SsdfToolRecommendation(
          practiceId: 'PW.8',
          toolName: 'OWASP CycloneDX',
          category: 'SBOM',
          description: 'Software Bill of Materials standard',
          url: 'https://cyclonedx.org/',
        ),
        SsdfToolRecommendation(
          practiceId: 'PW.8',
          toolName: 'Syft',
          category: 'SBOM Generator',
          description: 'Generate SBOMs from container images and filesystems',
        ),
      ],
      'RV.1': [
        SsdfToolRecommendation(
          practiceId: 'RV.1',
          toolName: 'OWASP DefectDojo',
          category: 'Vulnerability Management',
          description: 'Application vulnerability management platform',
        ),
        SsdfToolRecommendation(
          practiceId: 'RV.1',
          toolName: 'Jira Service Management',
          category: 'Incident Management',
          description: 'Track and manage vulnerability reports',
        ),
      ],
      'RV.2': [
        SsdfToolRecommendation(
          practiceId: 'RV.2',
          toolName: 'NIST NVD',
          category: 'Vulnerability Database',
          description: 'National Vulnerability Database',
          url: 'https://nvd.nist.gov/',
        ),
        SsdfToolRecommendation(
          practiceId: 'RV.2',
          toolName: 'OSV',
          category: 'Vulnerability Database',
          description: 'Open Source Vulnerabilities database',
        ),
      ],
      'RV.3': [
        SsdfToolRecommendation(
          practiceId: 'RV.3',
          toolName: 'Renovate',
          category: 'Dependency Updates',
          description: 'Automated dependency updates',
        ),
        SsdfToolRecommendation(
          practiceId: 'RV.3',
          toolName: 'Dependabot',
          category: 'Dependency Updates',
          description: 'Automated dependency updates for GitHub',
        ),
      ],
    };

    return toolMap[practiceId] ?? [];
  }
}

class _ToolCard extends StatelessWidget {
  final SsdfToolRecommendation recommendation;

  const _ToolCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recommendation.toolName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
          if (recommendation.url != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.link, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recommendation.url!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
