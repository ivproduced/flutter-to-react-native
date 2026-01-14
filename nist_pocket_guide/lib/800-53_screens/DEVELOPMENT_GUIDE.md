# 🛠️ Development Guide: 800-53 Screens

## Quick Start

### Setting Up a New Screen

1. **Determine Screen Type**
   - **List Screen**: Use `BaseListScreen<Control>` for consistent behavior
   - **Detail Screen**: Create custom StatelessWidget
   - **Search Screen**: Use `DebouncedSearchMixin` + `SearchableListView`

2. **Choose Free vs Pro**
   - Place in `/free_screens/` for basic functionality
   - Place in `/pro_screens/` for premium features
   - Use `PurchaseService.isPro` for feature gating

3. **Follow Performance Guidelines**
   - Use StatelessWidget when possible
   - Add ListView optimizations (`itemExtent`, `cacheExtent`)
   - Implement proper disposal for StatefulWidgets

### Example: Creating a New List Screen

```dart
// 1. Create the screen file
// /lib/800-53_screens/pro_screens/my_new_list_screen.dart

import 'package:flutter/material.dart';
import '../base/base_list_screen.dart';
import '../widgets/lists/control_list_item.dart';
import '../../models/oscal_models.dart';
import '../../services/purchase_service.dart';

class MyNewListScreen extends BaseListScreen<Control> {
  const MyNewListScreen({
    super.key,
    required List<Control> controls,
    required PurchaseService purchaseService,
  }) : super(
    title: 'My Custom List',
    items: controls,
    purchaseService: purchaseService,
  );

  @override
  Widget buildItem(BuildContext context, Control control) {
    return ControlListItem(
      control: control,
      purchaseService: purchaseService,
    );
  }
}
```

## Architecture Patterns

### 1. Service Layer Integration

**Always use services for business logic:**

```dart
// ❌ Don't do this - direct data access in widgets
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controls = AppDataManager.instance.catalog.controls
        .where((c) => c.id.contains('AC'))
        .toList();
    // ...
  }
}

// ✅ Do this - use service layer
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controls = ControlSearchService.searchControls(
      'AC', 
      AppDataManager.instance.catalog.controls,
    );
    // ...
  }
}
```

### 2. Navigation Patterns

**Use NistRouteService for consistent navigation:**

```dart
// ❌ Don't do this - manual navigation
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ControlDetailScreenPro(
        control: control,
        purchaseService: purchaseService,
      ),
    ),
  );
}

// ✅ Do this - use route service
onTap: () {
  NistRouteService.navigateToControlDetail(
    context,
    control: control,
    purchaseService: purchaseService,
  );
}
```

### 3. State Management Patterns

**Use StatelessWidget when possible:**

```dart
// ❌ Unnecessary StatefulWidget
class SimpleListScreen extends StatefulWidget {
  final List<Control> controls;
  const SimpleListScreen({super.key, required this.controls});
  
  @override
  State<SimpleListScreen> createState() => _SimpleListScreenState();
}

class _SimpleListScreenState extends State<SimpleListScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.controls.length,
      itemBuilder: (context, index) => ControlTile(
        control: widget.controls[index],
        purchaseService: widget.purchaseService,
      ),
    );
  }
}

// ✅ Use StatelessWidget for display-only components
class SimpleListScreen extends StatelessWidget {
  final List<Control> controls;
  final PurchaseService purchaseService;
  
  const SimpleListScreen({
    super.key, 
    required this.controls,
    required this.purchaseService,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: controls.length,
      itemExtent: 80.0,
      cacheExtent: 1000.0,
      itemBuilder: (context, index) => ControlTile(
        control: controls[index],
        purchaseService: purchaseService,
      ),
    );
  }
}
```

## Performance Best Practices

### 1. ListView Optimization

**Always add performance parameters:**

```dart
ListView.builder(
  itemCount: items.length,
  
  // Critical performance parameters
  itemExtent: 80.0,        // Fixed height prevents expensive layout calculations
  cacheExtent: 1000.0,     // Cache items outside viewport for smooth scrolling
  
  // Optional: Disable automatic keep-alives for memory efficiency
  addAutomaticKeepAlives: false,
  
  itemBuilder: (context, index) => ControlListItem(
    key: ValueKey(items[index].id), // Important for animations/reordering
    control: items[index],
    purchaseService: purchaseService,
  ),
)
```

### 2. Widget Keys

**Use appropriate keys for ListView items:**

```dart
// For simple lists with stable data
key: ValueKey(control.id)

// For lists that might reorder
key: ObjectKey(control)

// For complex items with state
key: GlobalKey()
```

### 3. Const Constructors

**Use const wherever possible:**

```dart
// ✅ Good - const constructor
class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.star),        // const widget
        SizedBox(height: 8.0),   // const spacing
      ],
    );
  }
}
```

### 4. Memory Management

**Proper disposal in StatefulWidgets:**

```dart
class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> 
    with DebouncedSearchMixin {
  
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _subscription = dataStream.listen(_handleData);
  }
  
  @override
  void dispose() {
    // Dispose controllers
    _searchController.dispose();
    _scrollController.dispose();
    
    // Cancel subscriptions
    _subscription?.cancel();
    
    // DebouncedSearchMixin handles its own disposal
    super.dispose();
  }
}
```

## Error Handling Patterns

### 1. Using ErrorBoundary

**Wrap potentially failing widgets:**

```dart
class MyDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Data')),
      body: ErrorBoundary(
        errorMessage: _error,
        onRetry: _loadData,
        child: _isLoading 
            ? const StandardLoadingState()
            : _buildContent(),
      ),
    );
  }
}
```

### 2. Async Error Handling

**Handle async operations safely:**

```dart
Future<void> _loadData() async {
  if (!mounted) return;
  
  setState(() {
    _isLoading = true;
    _error = null;
  });
  
  try {
    final data = await ApiService.fetchData();
    if (!mounted) return;
    
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (error) {
    if (!mounted) return;
    
    setState(() {
      _error = error.toString();
      _isLoading = false;
    });
  }
}
```

## Testing Strategies

### 1. Widget Tests

**Test widget behavior and user interactions:**

```dart
group('ControlTile Tests', () {
  late Control mockControl;
  late PurchaseService mockPurchaseService;
  
  setUp(() {
    mockControl = Control(
      id: 'AC-1',
      title: 'Access Control Policy',
      // ... other properties
    );
    mockPurchaseService = MockPurchaseService();
  });
  
  testWidgets('displays control information correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ControlTile(
            control: mockControl,
            purchaseService: mockPurchaseService,
          ),
        ),
      ),
    );
    
    expect(find.text('AC-1'), findsOneWidget);
    expect(find.text('Access Control Policy'), findsOneWidget);
  });
  
  testWidgets('navigates to detail screen when tapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ControlTile(
            control: mockControl,
            purchaseService: mockPurchaseService,
          ),
        ),
      ),
    );
    
    await tester.tap(find.byType(ControlTile));
    await tester.pumpAndSettle();
    
    // Verify navigation occurred
    expect(find.byType(ControlDetailScreenPro), findsOneWidget);
  });
});
```

### 2. Integration Tests

**Test screen interactions and flows:**

```dart
testWidgets('search flow works correctly', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to search screen
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();
  
  // Enter search query
  await tester.enterText(find.byType(TextField), 'access control');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
  
  // Verify results
  expect(find.byType(ControlTile), findsWidgets);
  expect(find.textContaining('AC-'), findsWidgets);
});
```

### 3. Performance Tests

**Monitor ListView performance:**

```dart
testWidgets('large list scrolls smoothly', (tester) async {
  final largeControlList = List.generate(
    1000, 
    (i) => Control(id: 'AC-$i', title: 'Control $i'),
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: SimpleListScreen(
        controls: largeControlList,
        purchaseService: mockPurchaseService,
      ),
    ),
  );
  
  // Test scrolling performance
  final listFinder = find.byType(Scrollable);
  await tester.fling(listFinder, const Offset(0, -500), 1000);
  await tester.pumpAndSettle();
  
  // Should complete without performance issues
});
```

## Common Pitfalls & Solutions

### 1. Memory Leaks

**Problem**: Controllers not disposed

```dart
// ❌ Memory leak
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();
  
  // Missing dispose() method!
}
```

**Solution**: Always dispose controllers

```dart
// ✅ Proper cleanup
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### 2. setState After Dispose

**Problem**: Calling setState after widget is disposed

```dart
// ❌ Can cause errors
Future<void> _loadData() async {
  final data = await fetchData();
  setState(() => _data = data); // Might be called after dispose
}
```

**Solution**: Check mounted before setState

```dart
// ✅ Safe state updates
Future<void> _loadData() async {
  final data = await fetchData();
  if (mounted) {
    setState(() => _data = data);
  }
}
```

### 3. Inefficient ListView

**Problem**: ListView without performance optimizations

```dart
// ❌ Poor performance with large lists
ListView.builder(
  itemCount: 10000,
  itemBuilder: (context, index) => ExpensiveWidget(items[index]),
)
```

**Solution**: Add performance parameters

```dart
// ✅ Optimized for performance
ListView.builder(
  itemCount: 10000,
  itemExtent: 80.0,      // Fixed height
  cacheExtent: 1000.0,   // Cache more items
  itemBuilder: (context, index) => OptimizedWidget(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

### 4. Unnecessary Rebuilds

**Problem**: Widget rebuilds on every parent rebuild

```dart
// ❌ Rebuilds unnecessarily
class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveWidget(), // Rebuilds every time
      ],
    );
  }
}
```

**Solution**: Use const or extract to separate widget

```dart
// ✅ Optimized rebuilds
class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ExpensiveWidget(), // Now const, won't rebuild
      ],
    );
  }
}
```

## Debugging Tips

### 1. Widget Inspector

**Use Flutter Widget Inspector to:**
- Identify rebuild performance issues
- Verify widget tree structure
- Check constraint problems

### 2. Performance Profiling

**Profile ListView performance:**
```dart
// Add to problematic ListView
debugPrint('Building item $index');
```

**Monitor memory usage:**
```dart
// Check if widgets are being disposed
@override
void dispose() {
  debugPrint('Disposing ${widget.runtimeType}');
  super.dispose();
}
```

### 3. Debug Flags

**Enable helpful debug information:**
```dart
// In main.dart for development
void main() {
  // Show widget rebuild information
  debugPrintRebuildDirtyWidgets = true;
  
  // Show performance timeline
  debugProfileBuildsEnabled = true;
  
  runApp(MyApp());
}
```

## Code Style Guidelines

### 1. File Organization
```dart
// Import order: Flutter → Third-party → Internal
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/oscal_models.dart';
import '../services/purchase_service.dart';

// Class organization
class MyWidget extends StatelessWidget {
  // 1. Fields
  final String title;
  final VoidCallback? onTap;
  
  // 2. Constructor
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });
  
  // 3. Getters/computed properties
  bool get isEnabled => onTap != null;
  
  // 4. Build method
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
  
  // 5. Private helper methods
  void _handleTap() {
    onTap?.call();
  }
}
```

### 2. Naming Conventions
- **Screens**: `*Screen` or `*ScreenPro`
- **Widgets**: Descriptive noun (e.g., `ControlTile`, `SearchBar`)
- **Services**: `*Service` (e.g., `ControlSearchService`)
- **Private methods**: Start with underscore (`_handleTap`)

### 3. Documentation
```dart
/// Primary widget for displaying NIST 800-53 controls.
/// 
/// Handles both base controls and enhancements, automatically
/// routing to appropriate detail screens based on Pro status.
/// 
/// Example:
/// ```dart
/// ControlTile(
///   control: myControl,
///   purchaseService: purchaseService,
/// )
/// ```
class ControlTile extends StatelessWidget {
  /// The control or enhancement to display
  final Control control;
  
  /// Service for checking Pro feature access
  final PurchaseService purchaseService;
  
  const ControlTile({
    super.key,
    required this.control,
    required this.purchaseService,
  });
}
```

This development guide provides comprehensive patterns and best practices for maintaining and extending the 800-53 screens architecture.