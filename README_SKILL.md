# Flutter to React Native - Anthropic Skill

This package implements an Anthropic skill for converting Flutter widget code to React Native components.

## Skill Overview

**Name:** `flutter_to_react_native`  
**Type:** Function skill  
**Version:** 0.1.0

## Installation

```bash
npm install flutter-to-react-native
```

## Skill Configuration

The skill is defined in `skill.yaml` following the Anthropic skills specification.

### Function Signature

```javascript
convert_flutter_to_react_native({
  flutter_code: string,
  options?: {
    include_imports?: boolean,
    indent_size?: number
  }
})
```

### Parameters

- **flutter_code** (required, string): The Flutter/Dart widget code to convert
- **options** (optional, object):
  - **include_imports** (boolean, default: false): Include React Native import statements
  - **indent_size** (number, default: 2): Number of spaces for indentation

### Return Value

```javascript
{
  success: boolean,
  output: string | null,
  error?: string,
  metadata?: {
    input_widget: string,
    output_component: string,
    warnings?: string[]
  }
}
```

## Usage with Anthropic API

### Using Claude with Skills

```python
import anthropic

client = anthropic.Anthropic(api_key="your-api-key")

# Register the skill
skill_definition = {
    "type": "custom",
    "custom": {
        "name": "convert_flutter_to_react_native",
        "description": "Converts Flutter widget code to React Native components",
        "input_schema": {
            "type": "object",
            "properties": {
                "flutter_code": {
                    "type": "string",
                    "description": "Flutter/Dart widget code to convert"
                },
                "options": {
                    "type": "object",
                    "properties": {
                        "include_imports": {"type": "boolean"},
                        "indent_size": {"type": "number"}
                    }
                }
            },
            "required": ["flutter_code"]
        }
    }
}

# Use in a conversation
response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    tools=[skill_definition],
    messages=[{
        "role": "user",
        "content": "Convert this Flutter code to React Native: Container(width: 200, child: Text('Hello'))"
    }]
)
```

### Direct Node.js Usage

```javascript
const { convert_flutter_to_react_native } = require('flutter-to-react-native/skill_handler');

async function convert() {
  const result = await convert_flutter_to_react_native({
    flutter_code: `
      Container(
        width: 200.0,
        padding: EdgeInsets.all(16.0),
        child: Text('Hello World')
      )
    `,
    options: {
      include_imports: true,
      indent_size: 2
    }
  });

  if (result.success) {
    console.log('Converted code:');
    console.log(result.output);
    
    if (result.metadata?.warnings) {
      console.log('\nWarnings:');
      result.metadata.warnings.forEach(w => console.log('- ' + w));
    }
  } else {
    console.error('Conversion failed:', result.error);
  }
}

convert();
```

## Examples

### Example 1: Simple Container

**Input:**
```dart
Container(
  width: 200.0,
  height: 100.0,
  child: Text('Hello World')
)
```

**Output:**
```jsx
<View style={{width: 200, height: 100}}>
  <Text>Hello World</Text>
</View>
```

### Example 2: Row with Alignment

**Input:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('First'),
    Text('Second')
  ]
)
```

**Output:**
```jsx
<View style={{flexDirection: 'row', justifyContent: 'center'}}>
  <Text>First</Text>
  <Text>Second</Text>
</View>
```

### Example 3: Styled Container

**Input:**
```dart
Container(
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFF2196F3),
    borderRadius: BorderRadius.circular(8.0)
  ),
  child: Text(
    'Styled Text',
    style: TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.bold
    )
  )
)
```

**Output:**
```jsx
<View style={{padding: 16, backgroundColor: '#2196F3', borderRadius: 8}}>
  <Text style={{color: '#FFFFFF', fontSize: 16, fontWeight: 'bold'}}>Styled Text</Text>
</View>
```

## Supported Widgets

- Container → View
- Row → View (flexDirection: 'row')
- Column → View (flexDirection: 'column')
- Stack → View (position: 'relative')
- Positioned → View (position: 'absolute')
- Expanded → View (flex: 1)
- Text → Text
- SizedBox → View
- Padding → View

## Supported Properties

**Layout:** width, height, padding, margin, alignment, flex  
**Decoration:** color, backgroundColor, borderRadius, border  
**Text Styles:** color, fontSize, fontWeight, fontStyle, fontFamily

## Error Handling

The skill returns detailed error information:

```javascript
{
  success: false,
  error: "Error message here",
  output: null,
  metadata: {
    error_type: "ErrorType"
  }
}
```

## Testing the Skill

```bash
# Build the project
npm run build

# Run tests
npm test

# Test the skill handler directly
node -e "
  const { convert_flutter_to_react_native } = require('./skill_handler.js');
  convert_flutter_to_react_native({
    flutter_code: 'Container(width: 200, child: Text(\"Test\"))'
  }).then(result => {
    console.log('Success:', result.success);
    console.log('Output:', result.output);
  });
"
```

## Limitations

- Custom Flutter widgets are not supported
- Complex nested structures may require manual adjustment
- Animations and gestures require manual implementation
- StatefulWidget and state management need to be rewritten

## Contributing

See [CONTRIBUTION.md](CONTRIBUTION.md) for guidelines.

## License

MIT License - See [LICENSE](LICENSE) file.

## Links

- [Anthropic Skills Specification](https://github.com/anthropics/skills)
- [Flutter Documentation](https://flutter.dev/docs)
- [React Native Documentation](https://reactnative.dev/docs/getting-started)
