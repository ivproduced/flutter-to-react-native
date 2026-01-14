import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import 'onboarding_service.dart';

class FeatureFocusedOnboardingFlow extends StatefulWidget {
  final VoidCallback onFinished;
  const FeatureFocusedOnboardingFlow({super.key, required this.onFinished});

  @override
  State<FeatureFocusedOnboardingFlow> createState() =>
      _FeatureFocusedOnboardingFlowState();
}

class _FeatureFocusedOnboardingFlowState
    extends State<FeatureFocusedOnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _index = 0;
  bool _saving = false;
  final List<int> _stepDurations = [];
  DateTime? _stepStartTime;

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
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
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      // Changed to 3 steps total
      _recordStepDuration();
      _resetAnimation();
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_index > 0) {
      _recordStepDuration();
      _resetAnimation();
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetAnimation() {
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _skip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Skip Welcome?'),
            content: const Text(
              'You can always configure these settings later in the Settings menu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Skip'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _completeOnboarding(skipped: true);
    }
  }

  Future<void> _finish() async {
    await _completeOnboarding(skipped: false);
  }

  Future<void> _completeOnboarding({required bool skipped}) async {
    setState(() => _saving = true);
    _recordStepDuration();

    final service = OnboardingService();

    await service.setCompleted(
      role: skipped ? 'Skipped' : 'Completed',
      stepDurations: _stepDurations,
      skipped: skipped,
    );

    // Mark welcome as seen for the new first-time-only logic
    await service.setWelcomeSeen();

    if (mounted) {
      widget.onFinished();
    }
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
                  _buildFeaturesAndValuePage(),
                  _buildNavigationGuidePage(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            'Welcome',
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: List.generate(3, (index) {
          // Changed to 3 steps
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
    return FadeTransition(opacity: _fadeAnimation, child: child);
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/nist_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading app logo: $error');
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to NIST Pocket Guide',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your comprehensive companion for NIST 800-53 security controls and compliance workflows.',
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

  Widget _buildFeaturesAndValuePage() {
    final purchaseService = Provider.of<PurchaseService>(context);

    return _buildAnimatedPage(
      child: Column(
        children: [
          // Compact header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Text(
                  'Features & What\'s Included',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete NIST 800-53 control catalog with advanced workflow tools',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Expanded scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  // Core Features - Available to Everyone
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'FREE - Complete Control Catalog',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...[
                          '• All 1,100+ NIST 800-53 rev 5 security controls',
                          '• Complete control descriptions and guidance',
                          '• Assessment objectives for each control',
                          '• Browse by family, baseline, or implementation level',
                          '• Related controls and enhancements',
                          '• Works completely offline - perfect for secure environments',
                        ].map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              feature,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(height: 1.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pro Features - Advanced Workflow
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PRO - Advanced Workflow Tools',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                  Text(
                                    '\$9.99',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...[
                          '• Personal notes on any control',
                          '• Favorites system for quick access',
                          '• Recent controls history',
                          '• Create custom control baselines',
                          '• AI Risk Management Framework (AI RMF)',
                          '• Module management - toggle frameworks on/off',
                        ].map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              feature,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                height: 1.3,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'First look at upcoming features:',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...[
                          '• System Security Plan (SSP) authoring tools (Beta)',
                          '• NISTBot AI assistant for guidance (Coming Soon)',
                        ].map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              feature,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                height: 1.3,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!purchaseService.isPro) ...[
                    const SizedBox(height: 20),
                    Text(
                      'You can upgrade to Pro or restore your purchase anytime from the Settings menu',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You\'re a Pro user! All features unlocked.',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationGuidePage() {
    return _buildAnimatedPage(
      child: Column(
        children: [
          // Compact header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Text(
                  'Where to Find Everything',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick guide to navigating your NIST 800-53 controls',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Expanded scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  _buildNavigationItem(
                    icon: Icons.menu_book_outlined,
                    title: '800-53 Pocket Guide',
                    description:
                        'Browse all control families (AC, AU, CA, etc.) and their controls',
                    location: 'Main screen → Tap "800-53 Pocket Guide"',
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationItem(
                    icon: Icons.family_restroom,
                    title: 'Control Families',
                    description:
                        'See all 20 control families with control counts',
                    location: 'From 800-53 module → Family list screen',
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationItem(
                    icon: Icons.list_alt,
                    title: 'Controls in Family',
                    description:
                        'View all controls within a specific family (e.g., AC, AU)',
                    location: 'Tap any family → See controls list',
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationItem(
                    icon: Icons.description,
                    title: 'Control Details',
                    description:
                        'Full control information, guidance, and related controls',
                    location: 'Tap any control → Detail screen',
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationItem(
                    icon: Icons.search,
                    title: 'Search All Controls',
                    description:
                        'Search across all controls by ID, title, or keywords',
                    location: 'Search bar on any control list screen',
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationItem(
                    icon: Icons.star_border,
                    title: 'Favorites',
                    description:
                        'Your saved favorite controls for quick access',
                    location: 'Main screen → Tap "Favorites"',
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    description:
                        'App preferences, Pro upgrade, and module management',
                    location: 'Main screen → Bottom of the list',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tip: Tap any control to see its full details, assessment objectives, and related controls',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required String description,
    required String location,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          if (_index == 2) // Last step
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _saving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            )
          else ...[
            const Spacer(),
            FilledButton(
              onPressed: _next,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continue'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
