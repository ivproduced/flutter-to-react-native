# Flutter to React Native Converter - Quick Start Guide

## What Has Been Done

Your repository has been successfully reversed from "React Native to Flutter" to "Flutter to React Native". Here's what was completed:

### ✅ Completed Changes

1. **Documentation Updated**
   - README.md now describes Flutter → React Native conversion
   - Created ARCHITECTURE.md with detailed conversion mappings
   - Created MIGRATION_STATUS.md with implementation roadmap
   - Added conversion examples to README

2. **Package Configuration**
   - Updated package.json with new name: `flutter-to-react-native`
   - Changed module names and distribution files

3. **New Conversion Engine**
   - Created `src/index-new.tsx` - main conversion logic
   - Created `src/config/react-native-components.ts` - RN component definitions
   - Created `src/utils/flutter-to-rn-converter.tsx` - conversion utilities
   - Created `src/utils/dart-parser.tsx` - Flutter/Dart code parser

4. **Test Suite**
   - Created `test/flutter-to-rn.test.tsx` with comprehensive tests

## Current Capabilities

The new converter can handle:

### Widgets
- ✅ Container → View
- ✅ Row → View (with flexDirection: 'row')
- ✅ Column → View (with flexDirection: 'column')
- ✅ Stack → View (position: 'relative')
- ✅ Positioned → View (position: 'absolute')
- ✅ Text → Text
- ✅ Expanded → View (flex: 1)

### Properties
- ✅ width, height
- ✅ Color conversion (0xFFRRGGBB → #RRGGBB)
- ✅ Named colors (Colors.red → #F44336)
- ✅ EdgeInsets → padding/margin
- ✅ BorderRadius
- ✅ Border (width, color)
- ✅ MainAxisAlignment → justifyContent
- ✅ CrossAxisAlignment → alignItems
- ✅ TextStyle properties (color, fontSize, fontWeight, etc.)

## How to Use

### Basic Example

```typescript
import { convertFlutterToReactNative } from './src/index-new';

const flutterCode = `
Container(
  width: 200.0,
  height: 100.0,
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFF2196F3),
    borderRadius: BorderRadius.circular(8.0),
  ),
  child: Text(
    'Hello World',
    style: TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    ),
  ),
)
`;

const reactNativeCode = convertFlutterToReactNative(flutterCode);
console.log(reactNativeCode);
```

**Output:**
```jsx
<View style={{width: 200, height: 100, padding: 16, backgroundColor: '#2196F3', borderRadius: 8}}>
  <Text style={{color: '#FFFFFF', fontSize: 16, fontWeight: 'bold'}}>Hello World</Text>
</View>
```

### Running Tests

```bash
npm test
```

Or run manual tests:
```bash
npm run build
node dist/test/flutter-to-rn.test.js
```

## File Structure

```
src/
├── index-new.tsx                    # New conversion entry point (Flutter → RN)
├── index.tsx                        # Old entry point (RN → Flutter) - LEGACY
├── config/
│   ├── react-native-components.ts  # NEW: RN component definitions
│   ├── flutter-widgets.ts          # OLD: Flutter widget definitions
│   └── index.ts                     # Config exports
└── utils/
    ├── dart-parser.tsx              # NEW: Parses Flutter/Dart code
    ├── flutter-to-rn-converter.tsx  # NEW: Conversion utilities
    └── converter.tsx                # OLD: RN to Flutter converter

docs/
├── ARCHITECTURE.md                  # Detailed architecture and mappings
├── MIGRATION_STATUS.md              # Complete migration roadmap
└── QUICKSTART.md                    # This file
```

## Next Steps

### To Complete the Migration:

1. **Replace Old Index**
   ```bash
   mv src/index.tsx src/index-legacy.tsx
   mv src/index-new.tsx src/index.tsx
   ```

2. **Update Example App**
   - Modify `example/index.html` to accept Flutter code input
   - Update UI labels and instructions
   - Add Flutter code samples

3. **Clean Up**
   - Archive or remove old React Native → Flutter utilities
   - Update all imports to use new conversion functions

4. **Test Thoroughly**
   - Run test suite
   - Test with various Flutter widgets
   - Test edge cases

### To Extend Functionality:

1. **Add More Widgets**
   - Edit `src/config/react-native-components.ts`
   - Add mapping in `src/index-new.tsx`
   - Add tests

2. **Improve Parser**
   - Enhance `src/utils/dart-parser.tsx` for complex cases
   - Handle multi-line widgets
   - Support custom widgets

3. **Add Advanced Features**
   - ListView → FlatList conversion
   - Navigation conversion
   - Animation support
   - State management patterns

## Key Files to Know

### `src/index-new.tsx`
Main conversion logic. Contains:
- `convertFlutterToReactNative()` - Main entry point
- `buildReactNativeAST()` - Converts widget tree to RN AST
- `generateReactNativeCode()` - Generates JSX from AST

### `src/utils/dart-parser.tsx`
Parses Flutter/Dart code:
- `parseFlutterCode()` - Main parser function
- `parseWidget()` - Parses individual widgets
- `printWidgetTree()` - Debug helper

### `src/utils/flutter-to-rn-converter.tsx`
Conversion utilities:
- `flutterColorToHex()` - Color conversion
- `convertMainAxisAlignment()` - Layout alignment
- `parseEdgeInsetsToPadding()` - Padding conversion
- `parseBorderRadius()` - Border radius conversion
- And more...

### `src/config/react-native-components.ts`
Defines React Native components and mappings

## Examples

### Example 1: Simple Container
```dart
Container(width: 200.0, height: 100.0)
```
↓
```jsx
<View style={{width: 200, height: 100}} />
```

### Example 2: Row with Children
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('A'),
    Text('B'),
  ]
)
```
↓
```jsx
<View style={{flexDirection: 'row', justifyContent: 'center'}}>
  <Text>A</Text>
  <Text>B</Text>
</View>
```

### Example 3: Styled Text
```dart
Text(
  'Hello',
  style: TextStyle(
    color: Colors.blue,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  ),
)
```
↓
```jsx
<Text style={{color: '#2196F3', fontSize: 20, fontWeight: 'bold'}}>Hello</Text>
```

## Troubleshooting

### Parser Errors
If parsing fails:
1. Check for proper Flutter syntax
2. Ensure balanced parentheses
3. Use simple widget constructors (avoid complex expressions)

### Missing Conversions
If a widget isn't converting:
1. Check if it's mapped in `react-native-components.ts`
2. Add mapping in `buildReactNativeAST()` function
3. Add conversion utilities if needed

### Style Issues
If styles aren't converting correctly:
1. Check conversion functions in `flutter-to-rn-converter.tsx`
2. Verify property names match Flutter convention
3. Add custom converters for special cases

## Resources

- **ARCHITECTURE.md** - Complete technical documentation
- **MIGRATION_STATUS.md** - Full implementation roadmap
- **test/flutter-to-rn.test.tsx** - Usage examples and test cases
- Original README.md - Updated with new direction

## Support

For questions or issues:
1. Check ARCHITECTURE.md for technical details
2. Review test files for usage examples
3. Check MIGRATION_STATUS.md for known limitations

## Contributing

To contribute:
1. Add widget mappings to `react-native-components.ts`
2. Implement conversion logic in `index-new.tsx`
3. Add utility functions to `flutter-to-rn-converter.tsx`
4. Write tests in `test/flutter-to-rn.test.tsx`
5. Update documentation

---

**Note**: The old "React Native to Flutter" code is preserved in files with `-legacy` suffix or in the original locations. It can be safely archived or removed once the new conversion is fully integrated.
