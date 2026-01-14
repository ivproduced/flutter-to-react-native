// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for Material Scaffold, AppBar etc.
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_dashboard_screen_pro.dart';
import 'package:nist_pocket_guide/about_screen.dart';
import 'package:nist_pocket_guide/ai_rmf_screens/free_screens/ai_rmf_browse_by_screen.dart';
import 'package:nist_pocket_guide/csf_screens/csf_functions_screen.dart';
import 'package:nist_pocket_guide/sp800_171_screens/sp800_171_families_screen.dart';
import 'package:nist_pocket_guide/ssdf_screens/free_screens/ssdf_practice_groups_screen.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/provider/web_project_data_manager.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/services/module_preferences_service.dart';
import 'package:nist_pocket_guide/services/feedback_service.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/settings_screen.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/system_management_screen.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';
import 'package:nist_pocket_guide/utils/optimized_navigation.dart'; // Add optimized navigation
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:nist_pocket_guide/onboarding/onboarding_service.dart';
import 'package:nist_pocket_guide/onboarding/feature_focused_onboarding_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for sqflite on desktop platforms
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi; // Use FFI database factory
    // debugPrint("SQFlite FFI initialized for desktop.");
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final purchaseService = PurchaseService(prefs);
  final modulePreferencesService = ModulePreferencesService(prefs);
  // It's crucial to initialize PurchaseService before it's used.
  // This await ensures synchronous parts of initialize() complete.
  await purchaseService.initialize();

  // Initialize AppDataManager
  await AppDataManager.instance.initialize();
  // Create ProjectDataManager
  final projectDataManager =
      kIsWeb ? WebProjectDataManager() : ProjectDataManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppDataManager>(
          create: (context) => AppDataManager.instance,
        ),
        ChangeNotifierProvider<ProjectDataManager>(
          create: (context) => projectDataManager,
        ),
        ChangeNotifierProvider<PurchaseService>(
          create: (context) => purchaseService,
        ),
        ChangeNotifierProvider<ModulePreferencesService>(
          create: (context) => modulePreferencesService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _onboardingCompleted = false;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final hasSeenWelcome = await OnboardingService().hasSeenWelcome();
      if (mounted) {
        setState(() {
          _onboardingCompleted = hasSeenWelcome;
          _checkingOnboarding = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // Default to showing onboarding if there's an error
      if (mounted) {
        setState(() {
          _onboardingCompleted = false;
          _checkingOnboarding = false;
        });
      }
    }
  }

  void _onOnboardingFinished() async {
    // Mark welcome as seen
    await OnboardingService().setWelcomeSeen();
    if (mounted) {
      setState(() {
        _onboardingCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: Ensure we're in a valid context with providers
    if (!mounted) {
      return const SizedBox.shrink();
    }

    // 1. Get AppDataManager to determine the current theme mode with error handling
    AppDataManager? appDataManager;
    try {
      appDataManager = Provider.of<AppDataManager>(context, listen: false);
    } catch (e) {
      debugPrint('Error accessing AppDataManager: $e');
      // Return a minimal loading screen if providers aren't ready
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // 2. Define your refined Material Design themes
    // Base TextThemes
    TextTheme baseTextTheme = ThemeData.light().textTheme.copyWith(
      bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.black87),
      bodyMedium: const TextStyle(fontSize: 14.0, color: Colors.black87),
      titleMedium: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
      ),
      labelLarge: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      // For ListTile subtitles, let's ensure they are clear in light mode too
      titleSmall: TextStyle(
        fontSize: 13.0,
        color: Colors.grey.shade700,
      ), // Example for subtitles
    );

    TextTheme baseDarkTextTheme = ThemeData.dark().textTheme.copyWith(
      bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.white),
      // Using higher opacity white for bodyMedium for better general readability
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: Colors.white.withAlpha((0.90 * 255).round()),
      ),
      // Brighter blue or white for headers in dark mode
      titleMedium: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Colors.lightBlue.shade200,
      ),
      labelLarge: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      // For ListTile subtitles in dark mode
      titleSmall: TextStyle(
        fontSize: 13.0,
        color: Colors.white.withAlpha((0.90 * 255).round()),
      ),
    );

    // Light Material Theme
    ThemeData lightMaterialTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias, // Prevent overflow
      ),
      listTileTheme: ListTileThemeData(
        // Added for subtitle styling consistency
        subtitleTextStyle: baseTextTheme.titleSmall,
      ),
      // ... other light theme properties
    );

    // Dark Material Theme (with readability enhancements)
    ThemeData darkMaterialTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF1E1E1E), // Text on main background
        onSurface: Colors.white, // Text on cards/dialogs (primary text)
        primary:
            Colors
                .lightBlue
                .shade200, // Brighter primary for dark theme (used by headers)
        onPrimary: Colors.black, // Text on primary color buttons/elements
        shadow: Colors.black.withAlpha((0.4 * 255).round()),
        surfaceTint: Colors.transparent,
      ),
      textTheme: baseDarkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: baseDarkTextTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4.0,
        shadowColor: Colors.black.withAlpha((0.5 * 255).round()),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade800, width: 0.75),
        ),
        color: const Color(0xFF1E1E1E), // Match colorScheme.surface
        clipBehavior: Clip.antiAlias, // Prevent overflow
      ),
      dialogTheme: DialogThemeData(
        // Example dialog theme for consistency
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: baseDarkTextTheme.titleMedium?.copyWith(
          color: Colors.white.withAlpha((0.9 * 255).round()),
        ),
        contentTextStyle: baseDarkTextTheme.bodyMedium,
        elevation: 6.0,
        shadowColor: Colors.black.withAlpha((0.6 * 255).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey.shade700, width: 1.0),
        ),
      ),
      listTileTheme: ListTileThemeData(
        // Added for subtitle styling consistency in dark mode
        subtitleTextStyle: baseDarkTextTheme.titleSmall,
      ),
      // ... other dark theme properties
    );

    // 3. Determine which Material theme to apply
    // Make sure AppDataManager has 'currentThemeMode' getter
    final ThemeMode currentThemeModeFromManager =
        appDataManager.currentThemeMode;
    final ThemeData currentMaterialThemeToApply =
        currentThemeModeFromManager == ThemeMode.dark
            ? darkMaterialTheme
            : lightMaterialTheme;

    // 4. Build the FluentApp, applying the Material theme via the builder
    // If running on web, use MaterialApp for compatibility
    if (kIsWeb) {
      return MaterialApp(
        title: 'NIST Pocket Guide',
        debugShowCheckedModeBanner: false,
        theme: currentMaterialThemeToApply,
        home:
            _checkingOnboarding
                ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
                : _onboardingCompleted
                ? const MyHomePage()
                : FeatureFocusedOnboardingFlow(
                  onFinished: _onOnboardingFinished,
                ),
      );
    }
    return fluent.FluentApp(
      title: 'NIST Pocket Guide',
      debugShowCheckedModeBanner: false,

      // FluentApp still needs its own basic Fluent themes for any Fluent widgets
      theme: fluent.FluentThemeData(
        brightness: Brightness.light,
        accentColor: fluent.Colors.blue, // Example
        // ... other Fluent light theme settings ...
      ),
      darkTheme: fluent.FluentThemeData(
        brightness: Brightness.dark,
        accentColor: fluent.Colors.blue, // Example
        // ... other Fluent dark theme settings ...
      ),
      themeMode: currentThemeModeFromManager, // Drive FluentApp's themeMode
      // Gated home with onboarding for non-web platforms
      home:
          _checkingOnboarding
              ? const fluent.Center(child: fluent.ProgressRing())
              : _onboardingCompleted
              ? const MyHomePage()
              : FeatureFocusedOnboardingFlow(onFinished: _onOnboardingFinished),
      builder: (context, child) {
        // This is crucial: Apply the selected MATERIAL Theme to the widget tree
        // so that Material components (Scaffold, Card, ListTile, etc.) are styled correctly.
        return Theme(
          data: currentMaterialThemeToApply,
          child: ScaffoldMessenger(
            // Keep your ScaffoldMessenger
            child: child ?? const fluent.SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key}); // Updated constructor

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Track app usage for feedback prompts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeedbackService.trackAppUsage(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access AppDataManager and PurchaseService via Provider
    final appDataManager = Provider.of<AppDataManager>(context, listen: false);
    final purchaseService = Provider.of<PurchaseService>(
      context,
      listen: true, // Changed to listen: true to catch any changes
    ); // Can listen: true or false based on needs
    final modulePrefs = Provider.of<ModulePreferencesService>(
      context,
      listen: true,
    );

    debugPrint(
      "🔍 MyHomePage build - purchaseService.isPro: ${purchaseService.isPro}",
    );

    // ✨ CORRECTED CHECK: Only wait for AppDataManager initialization here.
    // PurchaseService's initialize() was awaited in main().
    if (!appDataManager.isInitialized) {
      return const Scaffold(
        // Material Scaffold for the loading screen
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Using Material Scaffold and AppBar as your list items use Material Icons & Navigation
    return Scaffold(
      appBar: AppBar(title: const Text('NIST Pocket Guide')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12.0),
          children: <Widget>[
            _buildSectionHeader(context, 'MODULES'),
            // 800-53 Module
            if (modulePrefs.showNist80053Module)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    '800-53 Pocket Guide',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Browse NIST 800-53 controls and guidance',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    debugPrint(
                      "🔍 Main screen - purchaseService.isPro: ${purchaseService.isPro}",
                    );
                    // Both free and pro users now get the dashboard (control hub)
                    // This gives free users access to filtering while keeping custom baselines Pro-only
                    debugPrint("🔍 Navigating to control dashboard");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ControlDashboardScreenPro(
                              purchaseService: purchaseService,
                            ),
                        settings: const RouteSettings(name: '/dashboard'),
                      ),
                    );
                  },
                ),
              ),
            if (modulePrefs.showNist80053Module) const SizedBox(height: 10),
            // CSF 2.0 Module
            if (modulePrefs.showCsf20Module)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.security_outlined,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'NIST CSF 2.0',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Browse the Cybersecurity Framework v2.0',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    OptimizedNavigation.pushScreen(
                      context,
                      () => const CsfFunctionsScreen(),
                      routeName: '/csf_functions',
                    );
                  },
                ),
              ),
            if (modulePrefs.showCsf20Module) const SizedBox(height: 10),
            // SP 800-171 Rev 3 Module
            if (modulePrefs.showSp800171Module)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'SP 800-171 Rev 3',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Protecting CUI in Nonfederal Systems',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    OptimizedNavigation.pushScreen(
                      context,
                      () => const Sp800171FamiliesScreen(),
                      routeName: '/sp800_171_families',
                    );
                  },
                ),
              ),
            if (modulePrefs.showSp800171Module) const SizedBox(height: 10),
            // SSDF SP 800-218 Module
            if (modulePrefs.showSsdfModule)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.developer_mode,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'SSDF SP 800-218',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Secure Software Development Framework',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    OptimizedNavigation.pushScreen(
                      context,
                      () => const SsdfPracticeGroupsScreen(),
                      routeName: '/ssdf_practice_groups',
                    );
                  },
                ),
              ),
            if (modulePrefs.showSsdfModule) const SizedBox(height: 10),
            // AI RMF Module
            if (modulePrefs.showAiRmfModule)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.psychology_alt_outlined,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'AI RMF Playbook',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Step through the NIST AI Risk Management Framework',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final purchaseService = Provider.of<PurchaseService>(
                      context,
                      listen: false,
                    );
                    if (purchaseService.isPro) {
                      OptimizedNavigation.pushScreen(
                        context,
                        () => const AiRmfBrowseByScreen(),
                        routeName: '/ai_rmf_browse',
                      );
                    } else {
                      // Show the upgrade dialog
                      showUpgradeDialog(context, purchaseService);
                    }
                  },
                ),
              ),
            if (modulePrefs.showAiRmfModule) const SizedBox(height: 10),
            // SSP Generator Module
            if (modulePrefs.showSspGeneratorModule)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.folder_shared_outlined,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'Systems & SSPs - Experimental',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Manage systems and generate SSP statements (Beta)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final purchaseService = Provider.of<PurchaseService>(
                      context,
                      listen: false,
                    );
                    if (purchaseService.isPro) {
                      OptimizedNavigation.pushScreen(
                        context,
                        () => const SystemListScreen(),
                        routeName: '/system_list',
                      );
                    } else {
                      // Show the upgrade dialog
                      showUpgradeDialog(context, purchaseService);
                    }
                  },
                ),
              ),
            if (modulePrefs.showSspGeneratorModule) const SizedBox(height: 10),
            // NISTBot Module
            if (modulePrefs.showNistBotModule)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    radius: 26,
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'NISTBot Chat - Coming Soon',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'AI assistant with TIMA intelligence (Future Release)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // NISTBot is currently unavailable - higher tier feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'NISTBot Chat - Coming Soon in a future release',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
            if (modulePrefs.showNistBotModule) const SizedBox(height: 10),

            // Enhanced NISTBot functionality is now merged into the main NISTBot module above
            // The separate Enhanced NISTBot module is disabled to avoid duplication
            const SizedBox(height: 18),
            _buildSectionHeader(context, 'INFO'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.withAlpha(
                    (0.15 * 255).round(),
                  ),
                  radius: 24,
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'About',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  OptimizedNavigation.pushScreen(
                    context,
                    () => AboutScreen(purchaseService: purchaseService),
                    routeName: '/about',
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.withAlpha((0.15 * 255).round()),
                  radius: 24,
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  OptimizedNavigation.pushScreen(
                    context,
                    () => const SettingsScreen(),
                    routeName: '/settings',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    // Attempt to use FluentTheme for styling if within FluentApp context,
    // otherwise fallback to Material's Theme.
    TextStyle sectionStyle;
    try {
      final fluentTheme = fluent.FluentTheme.of(context);
      sectionStyle =
          fluentTheme.typography.bodyStrong?.copyWith(
            color: fluentTheme.accentColor,
          ) ??
          TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 14,
          ); // Fallback if bodyStrong is null
    } catch (e) {
      // Catch if FluentTheme.of(context) fails (e.g. not in FluentApp context, though MyApp is)
      final materialTheme = Theme.of(context);
      sectionStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: materialTheme.colorScheme.primary,
        fontSize: 14,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 16.0, bottom: 8.0),
      child: Text(title, style: sectionStyle),
    );
  }
}
