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

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _index = 0;
  String _selectedRole = '';
  bool _saving = false;
  final List<int> _stepDurations = [];
  DateTime? _stepStartTime;

  final roles = const [
    {
      'title': 'Security Assessor',
      'description': 'Evaluate and assess security controls',
      'icon': Icons.security,
      'color': Colors.red,
    },
    {
      'title': 'Implementer / Engineer',
      'description': 'Build and configure security systems',
      'icon': Icons.engineering,
      'color': Colors.blue,
    },
    {
      'title': 'Compliance Manager',
      'description': 'Manage compliance frameworks and audits',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'title': 'Executive / Sponsor',
      'description': 'Oversee security strategy and investment',
      'icon': Icons.business_center,
      'color': Colors.purple,
    },
    {
      'title': 'Learner / Student',
      'description': 'Study cybersecurity frameworks',
      'icon': Icons.school,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _trackOnboardingStart();
    _startStepTimer();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _trackOnboardingStart() async {
    await OnboardingService().trackStart();
  }

  void _startStepTimer() {
    _stepStartTime = DateTime.now();
  }

  void _recordStepDuration() {
    if (_stepStartTime != null) {
      final duration =
          DateTime.now().difference(_stepStartTime!).inMilliseconds;
      _stepDurations.add(duration);
    }
    _startStepTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 5) {
      _recordStepDuration();
      _resetAnimations();
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_index > 0) {
      _recordStepDuration();
      _resetAnimations();
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _skip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Skip Onboarding?'),
            content: const Text(
              'You can always access these settings later. Would you like to skip the setup and use default settings?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue Setup'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Skip'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      final service = OnboardingService();
      await service.setCompleted(
        role: 'General User',
        stepDurations: _stepDurations,
        skipped: true,
      );
      if (mounted) {
        widget.onFinished();
      }
    }
  }

  Future<void> _finish() async {
    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your role to continue'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            onPressed:
                () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    _recordStepDuration();

    final service = OnboardingService();
    final modulePrefs = Provider.of<ModulePreferencesService>(
      context,
      listen: false,
    );

    // Apply role-based defaults
    await OnboardingService.applyRoleDefaults(_selectedRole, modulePrefs);

    await service.setCompleted(
      role: _selectedRole,
      stepDurations: _stepDurations,
      skipped: false,
    );

    if (mounted) {
      // Show success animation
      await _showCompletionAnimation();
      widget.onFinished();
    }
  }

  Future<void> _showCompletionAnimation() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Setup Complete!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Welcome to NIST Pocket Guide'),
                  ],
                ),
              ),
            ),
          ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _buildWelcomePage(),
                  _buildValuePage(),
                  _buildRolePage(),
                  _buildModulesPage(),
                  _buildCapabilitiesPage(),
                  _buildCompletionPage(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_index > 0)
            IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            )
          else
            const SizedBox(width: 48),
          Text(
            'NIST Pocket Guide',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(6, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color:
                    index <= _index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnimatedPage({required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: child),
    );
  }

  Widget _buildWelcomePage() {
    return _buildAnimatedPage(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Hero(
              tag: 'app_icon',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to NIST Pocket Guide',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your comprehensive companion for NIST 800-53 security controls, assessments, and compliance workflows.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildValuePage() {
    final features = [
      {
        'icon': Icons.offline_bolt,
        'title': 'Offline-First',
        'description': 'Access controls without internet',
      },
      {
        'icon': Icons.assessment,
        'title': 'Assessment Ready',
        'description': 'Built-in NIST 800-53A procedures',
      },
      {
        'icon': Icons.engineering,
        'title': 'Implementation Focused',
        'description': 'Practical guidance for real systems',
      },
    ];

    return _buildAnimatedPage(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              'Why NIST Pocket Guide?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...features.map(
              (feature) => Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature['description'] as String,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePage() {
    return _buildAnimatedPage(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'What\'s Your Role?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll customize your experience based on your primary role',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final isSelected = _selectedRole == role['title'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            () => setState(
                              () => _selectedRole = role['title'] as String,
                            ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                isSelected
                                    ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                    : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (role['color'] as Color).withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  role['icon'] as IconData,
                                  color: role['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['title'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      role['description'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesPage() {
    final modulePrefs = Provider.of<ModulePreferencesService>(context);
    final roleDefaults =
        _selectedRole.isNotEmpty
            ? OnboardingService.getRoleDefaults(_selectedRole)
            : <String, bool>{};

    return _buildAnimatedPage(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Customize Your Modules',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_selectedRole.isNotEmpty)
              Text(
                'Based on your role as $_selectedRole, we\'ve pre-selected recommended modules',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children:
                    ModuleToggleDescriptor.enhanced().map((module) {
                      final recommended = roleDefaults[module.key] ?? true;
                      final value = modulePrefs.getModuleVisibility(module.key);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              recommended
                                  ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3),
                                  )
                                  : null,
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          secondary: Icon(
                            module.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Row(
                            children: [
                              Text(
                                module.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (recommended) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Recommended',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(module.description),
                          value: value,
                          onChanged: (v) async {
                            await modulePrefs.setModuleVisibility(
                              module.key,
                              v,
                            );
                            setState(() {});
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesPage() {
    return _buildAnimatedPage(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              'Powerful Features',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.search,
                      title: 'Smart Search',
                      description:
                          'Find controls by ID, family, or keyword with instant results',
                    ),
                    _buildFeatureCard(
                      icon: Icons.assessment,
                      title: 'Assessment Objectives',
                      description:
                          'NIST 800-53A procedures with evidence guidance',
                    ),
                    _buildFeatureCard(
                      icon: Icons.settings,
                      title: 'Parameter Substitution',
                      description:
                          'Dynamic control text with organization-specific values',
                    ),
                    _buildFeatureCard(
                      icon: Icons.feedback,
                      title: 'Continuous Improvement',
                      description:
                          'Built-in feedback system to enhance your experience',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPage() {
    return _buildAnimatedPage(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'You\'re All Set!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your NIST Pocket Guide is configured and ready. You can always adjust these settings later.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedRole.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Configured for: $_selectedRole',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_index == 5)
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _saving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check),
                            const SizedBox(width: 8),
                            Text(
                              'Complete Setup',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              ),
            )
          else ...[
            const Spacer(),
            FilledButton(
              onPressed: _next,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Continue'),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ModuleToggleDescriptor {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const ModuleToggleDescriptor(
    this.key,
    this.title,
    this.description,
    this.icon,
  );

  static List<ModuleToggleDescriptor> enhanced() => const [
    ModuleToggleDescriptor(
      'nist_800_53',
      '800-53 Controls',
      'Core security control catalog with search and filtering',
      Icons.security,
    ),
    ModuleToggleDescriptor(
      'assessment_objectives',
      'Assessment Objectives',
      'NIST 800-53A assessment procedures and guidance',
      Icons.assessment,
    ),
    ModuleToggleDescriptor(
      'ssp_tools',
      'SSP Authoring Tools',
      'System Security Plan creation and management',
      Icons.description,
    ),
    ModuleToggleDescriptor(
      'ai_assistant',
      'AI Assistant',
      'Intelligent chat support for cybersecurity questions',
      Icons.psychology,
    ),
  ];
}
