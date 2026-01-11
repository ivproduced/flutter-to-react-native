# Flutter to React Native - Conversion Architecture

## Overview

This project has been reversed from "React Native to Flutter" to "Flutter to React Native". The tool now converts Flutter/Dart widget code into React Native JSX components.

## Architecture Changes

### Previous Flow (React Native → Flutter)
1. Parse React Native JSX using @babel/parser
2. Extract style props (backgroundColor, padding, etc.)
3. Map to Flutter widgets (Container, Text, etc.)
4. Generate Dart code

### New Flow (Flutter → React Native)
1. Parse Flutter/Dart widget code
2. Extract widget properties and styles
3. Map to React Native components (View, Text, etc.)
4. Generate JSX code

## Key Mappings

### Widget/Component Mapping

| Flutter Widget | React Native Component |
|---------------|------------------------|
| Container     | View                   |
| Row           | View (flexDirection: 'row') |
| Column        | View (flexDirection: 'column') |
| Stack         | View (position: 'relative') |
| Positioned    | View (position: 'absolute') |
| Expanded      | View (flex: 1) |
| Text          | Text                   |
| SizedBox      | View                   |
| Padding       | View (with padding)    |

### Style Property Mapping

| Flutter Property | React Native Style |
|-----------------|-------------------|
| width           | width             |
| height          | height            |
| color           | backgroundColor   |
| decoration.color | backgroundColor  |
| decoration.borderRadius | borderRadius |
| decoration.border | borderWidth, borderColor |
| padding         | padding*          |
| margin          | margin*           |

### Layout Alignment Mapping

| Flutter Alignment | React Native Style |
|------------------|-------------------|
| MainAxisAlignment.start | justifyContent: 'flex-start' |
| MainAxisAlignment.end | justifyContent: 'flex-end' |
| MainAxisAlignment.center | justifyContent: 'center' |
| MainAxisAlignment.spaceBetween | justifyContent: 'space-between' |
| MainAxisAlignment.spaceAround | justifyContent: 'space-around' |
| MainAxisAlignment.spaceEvenly | justifyContent: 'space-evenly' |
| CrossAxisAlignment.start | alignItems: 'flex-start' |
| CrossAxisAlignment.end | alignItems: 'flex-end' |
| CrossAxisAlignment.center | alignItems: 'center' |
| CrossAxisAlignment.stretch | alignItems: 'stretch' |

### Text Style Mapping

| Flutter TextStyle | React Native Style |
|------------------|-------------------|
| color           | color             |
| fontSize        | fontSize          |
| fontWeight      | fontWeight        |
| fontStyle       | fontStyle         |
| fontFamily      | fontFamily        |

### Color Conversion

Flutter colors are converted to hex format:
- `Color(0xFFFF5722)` → `#FF5722`
- `Colors.red` → `#F44336`
- `Colors.blue` → `#2196F3`

### EdgeInsets Conversion

Flutter EdgeInsets are converted to React Native padding/margin:
- `EdgeInsets.all(16.0)` → `padding: 16`
- `EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0)` → `paddingHorizontal: 20, paddingVertical: 10`
- `EdgeInsets.only(top: 10.0, left: 5.0)` → `paddingTop: 10, paddingLeft: 5`

## File Structure

### Configuration Files
- `src/config/react-native-components.ts` - React Native component definitions (NEW)
- `src/config/flutter-widgets.ts` - Flutter widget definitions (LEGACY - kept for reference)

### Conversion Logic
- `src/index-new.tsx` - New Flutter → React Native conversion logic
- `src/index.tsx` - Old React Native → Flutter logic (LEGACY)

### Utilities
- `src/utils/flutter-to-rn-converter.tsx` - Conversion utility functions (NEW)
- `src/utils/converter.tsx` - Legacy converter utilities

## Implementation Status

### ✅ Completed
- Basic widget mapping (Container, Row, Column, Stack, Text)
- Style property conversion
- Color conversion
- EdgeInsets/Padding conversion
- Alignment conversion
- Text style conversion
- Documentation updates

### 🚧 In Progress
- Dart parser implementation (currently using placeholder structure)
- Complex nested widget support
- Custom widget handling

### 📋 To Do
- Full Dart/Flutter parser integration
- Advanced widget support (ListView, GridView, etc.)
- Animation conversion
- State management conversion
- Testing suite

## Usage Example

### Input (Flutter Code)
```dart
Container(
  width: 200.0,
  height: 100.0,
  decoration: BoxDecoration(
    color: Color(0xFF2196F3),
    borderRadius: BorderRadius.circular(8.0),
  ),
  padding: EdgeInsets.all(16.0),
  child: Text(
    'Hello World',
    style: TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Output (React Native Code)
```jsx
<View style={{width: 200, height: 100, backgroundColor: '#2196F3', borderRadius: 8, padding: 16}}>
  <Text style={{color: '#FFFFFF', fontSize: 16, fontWeight: 'bold'}}>Hello World</Text>
</View>
```

## Next Steps

1. **Parser Integration**: Implement a proper Dart/Flutter parser to parse actual Flutter code
2. **Widget Library**: Expand the widget mapping library to cover more Flutter widgets
3. **Testing**: Create comprehensive test suite for various conversion scenarios
4. **UI Tool**: Build interactive UI tool similar to the original project

## Contributing

When contributing to the reversed conversion logic:
1. Add widget mappings to `react-native-components.ts`
2. Implement conversion utilities in `flutter-to-rn-converter.tsx`
3. Update the main conversion logic in `index-new.tsx`
4. Add tests for new conversions
5. Update documentation

## Notes

- The original React Native → Flutter code is preserved for reference
- Migration is incremental - both directions can coexist during transition
- Focus on common widgets first, then expand to advanced widgets
