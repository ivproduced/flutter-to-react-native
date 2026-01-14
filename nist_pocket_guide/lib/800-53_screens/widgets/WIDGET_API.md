# 🔧 Widget Components API Reference

## Core Display Components

### ControlTile
Primary widget for displaying controls in lists and grids.

```dart
class ControlTile extends StatelessWidget {
  final Control control;
  final PurchaseService purchaseService;
  
  const ControlTile({
    super.key,
    required this.control,
    required this.purchaseService,
  });
}
```

**Features:**
- Automatic Pro/Free routing
- Built-in favorite star and implementation badges
- Handles both controls and enhancements
- Optimized for ListView performance

**Usage:**
```dart
ControlTile(
  control: myControl,
  purchaseService: purchaseService,
)
```

### ControlListItem
Optimized wrapper for ControlTile with proper keys for ListView performance.

```dart
class ControlListItem extends StatelessWidget {
  final Control control;
  final PurchaseService purchaseService;
  
  const ControlListItem({
    super.key,
    required this.control,
    required this.purchaseService,
  });
}
```

**Key Benefits:**
- Uses `ValueKey(control.id)` for optimal ListView performance
- Consistent margin and padding
- Ready for animations and reordering

## Loading & Error States

### StandardLoadingState
Consistent loading indicator across all screens.

```dart
class StandardLoadingState extends StatelessWidget {
  final String? message;
  
  const StandardLoadingState({super.key, this.message});
}
```

**Usage:**
```dart
// Basic loading
StandardLoadingState()

// With custom message
StandardLoadingState(message: 'Loading controls...')
```

### ErrorBoundary
Wraps widgets to provide consistent error handling.

```dart
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
  });
}
```

**Usage:**
```dart
ErrorBoundary(
  errorMessage: error?.toString(),
  onRetry: () => _loadData(),
  child: MyWidget(),
)
```

## Search & Performance Components

### SearchableListView<T>
Generic list widget with built-in loading, error, and empty states.

```dart
class SearchableListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
}
```

**Features:**
- Automatic performance optimizations (`itemExtent`, `cacheExtent`)
- Built-in loading, error, and empty states
- Type-safe generic implementation

**Usage:**
```dart
SearchableListView<Control>(
  items: controls,
  itemBuilder: (context, control) => ControlTile(
    control: control,
    purchaseService: purchaseService,
  ),
  isLoading: _isLoading,
  errorMessage: _error,
  onRetry: _retryLoad,
  emptyMessage: 'No controls found',
)
```

### DebouncedSearchMixin
Mixin for adding debounced search functionality to StatefulWidgets.

```dart
mixin DebouncedSearchMixin<T extends StatefulWidget> on State<T> {
  void debouncedSearch(String query, Function(String) onSearch);
}
```

**Usage:**
```dart
class MySearchScreen extends StatefulWidget {
  // ...
}

class _MySearchScreenState extends State<MySearchScreen> 
    with DebouncedSearchMixin {
  
  void _handleSearch(String query) {
    debouncedSearch(query, (debouncedQuery) {
      // Perform actual search operation
      _performSearch(debouncedQuery);
    });
  }
}
```

## Control-Specific Widgets

### ControlHeader
Displays control ID, title, and status badges.

```dart
class ControlHeader extends StatelessWidget {
  final Control control;
  final PurchaseService purchaseService;
  final List<String> baselines;
  final String title;
  
  // Implementation handles status badges, implementation levels, etc.
}
```

### ControlStatementSection  
Renders the main control implementation statement with parameter substitution.

```dart
class ControlStatementSection extends StatelessWidget {
  final List<Part> parts;
  final List<Parameter> params;
  
  // Handles prose parsing and parameter replacement
}
```

### EnhancementSection
Shows control enhancements with expand/collapse functionality.

```dart
class EnhancementSection extends StatelessWidget {
  final List<Control> enhancements;
  final PurchaseService purchaseService;
  
  // Displays enhancements in organized, navigable format
}
```

## Utility Widgets

### FavoritesStar
Toggle widget for marking controls as favorites.

```dart
class FavoritesStar extends StatelessWidget {
  final String controlId;
  
  // Handles favorite state management automatically
}
```

### BadgeBuilder
Creates consistent badges for implementation levels and status.

```dart
class BadgeBuilder {
  static Widget buildImplementationLevelBadge(String level);
  static Widget buildStatusBadge(String status);
  static Widget buildBaselineBadge(String baseline);
}
```

**Usage:**
```dart
BadgeBuilder.buildImplementationLevelBadge('Organization')
BadgeBuilder.buildStatusBadge('Active')
BadgeBuilder.buildBaselineBadge('HIGH')
```

## Navigation Components

### BottomNavBarPro
Pro screen bottom navigation with quick access actions.

```dart
class BottomNavBarPro extends StatelessWidget {
  final Control control;
  final List<Control> enhancements;
  final PurchaseService purchaseService;
  
  // Provides enhancement navigation, related controls, etc.
}
```

### SearchBarWidget
Reusable search input component with consistent styling.

```dart
class SearchBarWidget extends StatelessWidget {
  final Function(String) onSubmitted;
  final String? hintText;
  final TextEditingController? controller;
}
```

## Performance Guidelines

### ListView Optimization Pattern
All list components should follow this pattern:

```dart
ListView.builder(
  itemCount: items.length,
  itemExtent: 80.0,           // Fixed height - prevents layout calculations
  cacheExtent: 1000.0,        // Cache items outside viewport  
  itemBuilder: (context, index) => ControlListItem(
    key: ValueKey(items[index].id), // Important for reordering
    control: items[index],
    purchaseService: purchaseService,
  ),
)
```

### Widget Key Usage
Always use proper keys for ListView items:

```dart
// For controls - use control ID
key: ValueKey(control.id)

// For dynamic content - use unique identifiers  
key: ValueKey('${control.id}-${index}')

// For stateful widgets in lists - use ObjectKey
key: ObjectKey(control)
```

### Memory Management
Ensure proper disposal in StatefulWidgets:

```dart
class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
```

## Theming & Styling

### Material Design 3 Integration
All widgets support both light and dark themes:

```dart
// Use theme colors instead of hardcoded colors
color: Theme.of(context).colorScheme.primary
textStyle: Theme.of(context).textTheme.titleMedium

// For surface colors with transparency
backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(200)
```

### Consistent Spacing
Follow the 8dp grid system:

```dart
// Padding
EdgeInsets.all(8.0)          // Small
EdgeInsets.all(16.0)         // Medium  
EdgeInsets.all(24.0)         // Large

// Margins
SizedBox(height: 8.0)        // Small gap
SizedBox(height: 16.0)       // Medium gap
SizedBox(height: 24.0)       // Large gap
```

## Testing Considerations

### Widget Testing
When testing these widgets:

```dart
testWidgets('ControlTile displays control information', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ControlTile(
        control: mockControl,
        purchaseService: mockPurchaseService,
      ),
    ),
  );
  
  expect(find.text(mockControl.id), findsOneWidget);
  expect(find.text(mockControl.title), findsOneWidget);
});
```

### Performance Testing
Monitor ListView performance:

```dart
testWidgets('Large list scrolls smoothly', (tester) async {
  final controls = List.generate(1000, (i) => mockControl);
  
  await tester.pumpWidget(
    MaterialApp(
      home: SearchableListView<Control>(
        items: controls,
        itemBuilder: (context, control) => ControlListItem(
          control: control,
          purchaseService: mockPurchaseService,
        ),
      ),
    ),
  );
  
  // Test scrolling performance
  await tester.fling(find.byType(ListView), Offset(0, -500), 1000);
  await tester.pumpAndSettle();
});
```

## Common Integration Patterns

### Screen with Search
```dart
class MyListScreen extends StatefulWidget {
  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> 
    with DebouncedSearchMixin {
  
  List<Control> _filteredControls = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBarWidget(
          onSubmitted: _handleSearch,
        ),
      ),
      body: ErrorBoundary(
        errorMessage: _error,
        onRetry: _retryLoad,
        child: SearchableListView<Control>(
          items: _filteredControls,
          isLoading: _isLoading,
          itemBuilder: (context, control) => ControlListItem(
            control: control,
            purchaseService: widget.purchaseService,
          ),
        ),
      ),
    );
  }
  
  void _handleSearch(String query) {
    debouncedSearch(query, _performSearch);
  }
  
  void _performSearch(String query) {
    // Implementation
  }
}
```

This API reference provides the technical details needed for developers to effectively use and extend the 800-53 screens widget system.