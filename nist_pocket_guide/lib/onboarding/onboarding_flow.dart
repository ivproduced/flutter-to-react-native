import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/module_preferences_service.dart';
import 'onboarding_service.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingFlow({super.key, required this.onFinished});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _index = 0;
  String _selectedRole = '';
  bool _saving = false;

  final roles = const [
    'Security Assessor',
    'Implementer / Engineer',
    'Compliance Manager',
    'Executive / Sponsor',
    'Learner / Student',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 4) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a role to continue')),
      );
      return;
    }
    setState(() => _saving = true);
    final service = OnboardingService();
    await service.setCompleted(role: _selectedRole);
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _buildPage(
                    title: 'Welcome to NIST Pocket Guide',
                    icon: Icons.security,
                    body:
                        'Your fast, structured companion for NIST 800-53 controls, assessments, and SSP preparation.',
                    action: ElevatedButton(
                      onPressed: _next,
                      child: const Text('Get Started'),
                    ),
                  ),
                  _buildPage(
                    title: 'What Best Describes You?',
                    icon: Icons.person_outline,
                    body: 'We tailor in-app guidance based on your role.',
                    action: _buildRoleSelector(),
                  ),
                  _buildPage(
                    title: 'Select Active Modules',
                    icon: Icons.view_module_outlined,
                    body:
                        'Turn on the content areas you want to focus on first. You can change this later in Settings.',
                    action: _buildModuleToggles(),
                  ),
                  _buildPage(
                    title: 'Key Capabilities',
                    icon: Icons.bolt_outlined,
                    body:
                        '• Offline-first control reference\n• Assessment objectives explorer\n• SSP project scaffolding (Pro)\n• Parameter substitution engine\n• Evidence & implementation notes (coming soon)',
                    action: ElevatedButton(
                      onPressed: _next,
                      child: const Text('Continue'),
                    ),
                  ),
                  _buildPage(
                    title: 'All Set!',
                    icon: Icons.check_circle_outline,
                    body:
                        'You are ready to explore. You can re-run onboarding anytime from Settings.',
                    action: ElevatedButton(
                      onPressed: _saving ? null : _finish,
                      child:
                          _saving
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Finish'),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_index + 1) / 5;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LinearProgressIndicator(value: progress),
    );
  }

  Widget _buildPage({
    required String title,
    required String body,
    required IconData icon,
    required Widget action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Icon(icon, size: 72, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          Center(child: action),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          roles.map((r) {
            final selected = r == _selectedRole;
            return ChoiceChip(
              label: Text(r),
              selected: selected,
              onSelected: (_) => setState(() => _selectedRole = r),
            );
          }).toList(),
    );
  }

  Widget _buildModuleToggles() {
    final modulePrefs = Provider.of<ModulePreferencesService>(context);
    final modules = ModuleToggleDescriptor.defaults();
    return Column(
      children:
          modules.map((m) {
            final value = modulePrefs.getModuleVisibility(m.key);
            return SwitchListTile(
              title: Text(m.title),
              subtitle: Text(m.description),
              value: value,
              onChanged: (v) async {
                await modulePrefs.setModuleVisibility(m.key, v);
                setState(() {});
              },
            );
          }).toList(),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_index > 0)
            TextButton(
              onPressed: () {
                _controller.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 72),
          Text('${_index + 1}/5'),
          if (_index < 4)
            FilledButton(onPressed: _next, child: const Text('Next'))
          else
            const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class ModuleToggleDescriptor {
  final String key;
  final String title;
  final String description;
  const ModuleToggleDescriptor(this.key, this.title, this.description);

  static List<ModuleToggleDescriptor> defaults() => const [
    ModuleToggleDescriptor(
      'nist_800_53',
      '800-53 Controls',
      'Core catalog reference',
    ),
    ModuleToggleDescriptor(
      'assessment_objectives',
      'Assessment Objectives',
      'Evaluate controls',
    ),
    ModuleToggleDescriptor(
      'ssp_tools',
      'SSP Authoring Tools',
      'System Security Plan workspace',
    ),
    ModuleToggleDescriptor(
      'ai_assistant',
      'AI Assistant',
      'Chat-based guidance',
    ),
  ];
}
