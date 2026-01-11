// New index file for Flutter to React Native conversion

// Import removed - these are defined locally or not needed yet
// import { styleMapping, reactNativeComponent } from "./config/react-native-components";

// Parser for Dart/Flutter code - we'll need to implement this
// For now, let's create a basic structure

/**
 * Maps Flutter widgets to React Native components
 */
const mapFlutterWidgetToReactNative: any = {
  "Container": "View",
  "Text": "Text",
  "Row": "View",
  "Column": "View",
  "Stack": "View",
  "Positioned": "View",
  "Expanded": "View",
  "SizedBox": "View",
  "Padding": "View",
};

/**
 * Converts Flutter widget properties to React Native styles
 */
function convertFlutterPropsToReactNativeStyle(widgetType: string, props: any): any {
  const styles: any = {};

  // Handle Container properties
  if (widgetType === "Container") {
    if (props.width) styles.width = parseFlutterValue(props.width);
    if (props.height) styles.height = parseFlutterValue(props.height);
    if (props.color) styles.backgroundColor = convertFlutterColor(props.color);
    
    // Handle BoxDecoration
    if (props.decoration) {
      const decoration = props.decoration;
      if (decoration.color) styles.backgroundColor = convertFlutterColor(decoration.color);
      if (decoration.borderRadius) {
        const radius = parseFlutterValue(decoration.borderRadius);
        styles.borderRadius = radius;
      }
      if (decoration.border) {
        styles.borderWidth = parseFlutterValue(decoration.border.width);
        if (decoration.border.color) {
          styles.borderColor = convertFlutterColor(decoration.border.color);
        }
      }
    }

    // Handle padding
    if (props.padding) {
      const padding = parseEdgeInsets(props.padding);
      Object.assign(styles, padding);
    }

    // Handle margin
    if (props.margin) {
      const margin = parseEdgeInsets(props.margin);
      Object.assign(styles, margin);
    }
  }

  // Handle Row properties
  if (widgetType === "Row") {
    styles.flexDirection = "row";
    if (props.mainAxisAlignment) {
      styles.justifyContent = convertMainAxisAlignment(props.mainAxisAlignment);
    }
    if (props.crossAxisAlignment) {
      styles.alignItems = convertCrossAxisAlignment(props.crossAxisAlignment);
    }
  }

  // Handle Column properties
  if (widgetType === "Column") {
    styles.flexDirection = "column";
    if (props.mainAxisAlignment) {
      styles.justifyContent = convertMainAxisAlignment(props.mainAxisAlignment);
    }
    if (props.crossAxisAlignment) {
      styles.alignItems = convertCrossAxisAlignment(props.crossAxisAlignment);
    }
  }

  // Handle Stack properties
  if (widgetType === "Stack") {
    styles.position = "relative";
  }

  // Handle Positioned properties
  if (widgetType === "Positioned") {
    styles.position = "absolute";
    if (props.top !== undefined) styles.top = parseFlutterValue(props.top);
    if (props.bottom !== undefined) styles.bottom = parseFlutterValue(props.bottom);
    if (props.left !== undefined) styles.left = parseFlutterValue(props.left);
    if (props.right !== undefined) styles.right = parseFlutterValue(props.right);
  }

  // Handle Expanded properties
  if (widgetType === "Expanded") {
    styles.flex = props.flex || 1;
  }

  // Handle Text properties
  if (widgetType === "Text" && props.style) {
    const textStyle = props.style;
    if (textStyle.color) styles.color = convertFlutterColor(textStyle.color);
    if (textStyle.fontSize) styles.fontSize = parseFlutterValue(textStyle.fontSize);
    if (textStyle.fontWeight) styles.fontWeight = convertFontWeight(textStyle.fontWeight);
    if (textStyle.fontStyle) styles.fontStyle = convertFontStyle(textStyle.fontStyle);
    if (textStyle.fontFamily) styles.fontFamily = textStyle.fontFamily;
  }

  return styles;
}

/**
 * Converts Flutter Color to React Native color
 * Example: Color(0xFF000000) -> "#000000"
 */
function convertFlutterColor(colorValue: string): string {
  if (typeof colorValue === 'string') {
    // Handle Color(0xFFRRGGBB) format
    const match = colorValue.match(/Color\(0x([A-Fa-f0-9]{8})\)/);
    if (match) {
      const hex = match[1];
      // Extract RGB (skip first 2 chars which are alpha)
      const rgb = hex.substring(2);
      return `#${rgb}`;
    }
    
    // Handle Colors.colorName format
    if (colorValue.startsWith('Colors.')) {
      const colorName = colorValue.replace('Colors.', '');
      return convertNamedColor(colorName);
    }
  }
  
  return colorValue;
}

/**
 * Converts Flutter named colors to hex
 */
function convertNamedColor(colorName: string): string {
  const colorMap: any = {
    'red': '#F44336',
    'blue': '#2196F3',
    'green': '#4CAF50',
    'white': '#FFFFFF',
    'black': '#000000',
    'transparent': 'transparent',
    // Add more colors as needed
  };
  
  return colorMap[colorName] || colorName;
}

/**
 * Parses Flutter numeric values (removes .0, converts to number)
 */
function parseFlutterValue(value: any): number | string {
  if (typeof value === 'string') {
    const numMatch = value.match(/(\d+\.?\d*)/);
    if (numMatch) {
      return parseFloat(numMatch[1]);
    }
  }
  return value;
}

/**
 * Converts Flutter EdgeInsets to React Native padding/margin
 */
function parseEdgeInsets(edgeInsets: any): any {
  const result: any = {};
  
  if (typeof edgeInsets === 'string') {
    // EdgeInsets.all(value)
    if (edgeInsets.includes('EdgeInsets.all')) {
      const match = edgeInsets.match(/EdgeInsets\.all\((\d+\.?\d*)\)/);
      if (match) {
        const value = parseFloat(match[1]);
        return { padding: value };
      }
    }
    
    // EdgeInsets.only(...)
    if (edgeInsets.includes('EdgeInsets.only')) {
      // Parse individual values
      const topMatch = edgeInsets.match(/top:\s*(\d+\.?\d*)/);
      const bottomMatch = edgeInsets.match(/bottom:\s*(\d+\.?\d*)/);
      const leftMatch = edgeInsets.match(/left:\s*(\d+\.?\d*)/);
      const rightMatch = edgeInsets.match(/right:\s*(\d+\.?\d*)/);
      
      if (topMatch) result.paddingTop = parseFloat(topMatch[1]);
      if (bottomMatch) result.paddingBottom = parseFloat(bottomMatch[1]);
      if (leftMatch) result.paddingLeft = parseFloat(leftMatch[1]);
      if (rightMatch) result.paddingRight = parseFloat(rightMatch[1]);
    }
    
    // EdgeInsets.symmetric(...)
    if (edgeInsets.includes('EdgeInsets.symmetric')) {
      const verticalMatch = edgeInsets.match(/vertical:\s*(\d+\.?\d*)/);
      const horizontalMatch = edgeInsets.match(/horizontal:\s*(\d+\.?\d*)/);
      
      if (verticalMatch) {
        const value = parseFloat(verticalMatch[1]);
        result.paddingTop = value;
        result.paddingBottom = value;
      }
      if (horizontalMatch) {
        const value = parseFloat(horizontalMatch[1]);
        result.paddingLeft = value;
        result.paddingRight = value;
      }
    }
  }
  
  return result;
}

/**
 * Converts Flutter MainAxisAlignment to React Native justifyContent
 */
function convertMainAxisAlignment(alignment: string): string {
  const alignmentMap: any = {
    'MainAxisAlignment.start': 'flex-start',
    'MainAxisAlignment.end': 'flex-end',
    'MainAxisAlignment.center': 'center',
    'MainAxisAlignment.spaceBetween': 'space-between',
    'MainAxisAlignment.spaceAround': 'space-around',
    'MainAxisAlignment.spaceEvenly': 'space-evenly',
  };
  
  return alignmentMap[alignment] || 'flex-start';
}

/**
 * Converts Flutter CrossAxisAlignment to React Native alignItems
 */
function convertCrossAxisAlignment(alignment: string): string {
  const alignmentMap: any = {
    'CrossAxisAlignment.start': 'flex-start',
    'CrossAxisAlignment.end': 'flex-end',
    'CrossAxisAlignment.center': 'center',
    'CrossAxisAlignment.stretch': 'stretch',
    'CrossAxisAlignment.baseline': 'baseline',
  };
  
  return alignmentMap[alignment] || 'stretch';
}

/**
 * Converts Flutter FontWeight to React Native fontWeight
 */
function convertFontWeight(fontWeight: string): string {
  const weightMap: any = {
    'FontWeight.w100': '100',
    'FontWeight.w200': '200',
    'FontWeight.w300': '300',
    'FontWeight.w400': '400',
    'FontWeight.w500': '500',
    'FontWeight.w600': '600',
    'FontWeight.w700': '700',
    'FontWeight.w800': '800',
    'FontWeight.w900': '900',
    'FontWeight.normal': 'normal',
    'FontWeight.bold': 'bold',
  };
  
  return weightMap[fontWeight] || 'normal';
}

/**
 * Converts Flutter FontStyle to React Native fontStyle
 */
function convertFontStyle(fontStyle: string): string {
  if (fontStyle === 'FontStyle.italic') return 'italic';
  return 'normal';
}

/**
 * Builds React Native JSX from Flutter widget tree
 */
export function buildReactNativeAST(widget: any): any {
  const reactNativeAST: any = {
    component: mapFlutterWidgetToReactNative[widget.type] || "View",
    props: {
      style: convertFlutterPropsToReactNativeStyle(widget.type, widget.props || {})
    },
    children: []
  };

  // Handle child or children
  if (widget.child) {
    reactNativeAST.children.push(buildReactNativeAST(widget.child));
  } else if (widget.children && Array.isArray(widget.children)) {
    reactNativeAST.children = widget.children.map((child: any) => buildReactNativeAST(child));
  }

  // Handle text content for Text widget
  if (widget.type === "Text" && widget.data) {
    reactNativeAST.textContent = widget.data;
  }

  return reactNativeAST;
}

/**
 * Generates React Native JSX code from AST
 */
export function generateReactNativeCode(ast: any, indent: number = 0): string {
  const indentStr = "  ".repeat(indent);
  const component = ast.component;
  
  let code = `${indentStr}<${component}`;
  
  // Add style prop
  if (ast.props && ast.props.style && Object.keys(ast.props.style).length > 0) {
    code += ` style={{${Object.entries(ast.props.style)
      .map(([key, value]) => {
        if (typeof value === 'string') {
          return `${key}: '${value}'`;
        }
        return `${key}: ${value}`;
      })
      .join(', ')}}}`;
  }
  
  // Handle children
  if (ast.children && ast.children.length > 0) {
    code += ">\n";
    ast.children.forEach((child: any) => {
      code += generateReactNativeCode(child, indent + 1);
    });
    code += `${indentStr}</${component}>\n`;
  } else if (ast.textContent) {
    code += `>${ast.textContent}</${component}>\n`;
  } else {
    code += " />\n";
  }
  
  return code;
}

/**
 * Main conversion function: Flutter Widget to React Native Component
 * Parses Flutter/Dart code and converts it to React Native JSX
 */
export const convertFlutterToReactNative = (flutterCode: string): string => {
  try {
    // TODO: Parse flutterCode using Dart parser
    // For now, use example widget tree structure
    console.log('Input Flutter code:', flutterCode.substring(0, 50) + '...');
    
    const exampleWidgetTree = {
      type: "Container",
      props: {
        width: "200.0",
        height: "100.0",
        decoration: {
          color: "Color(0xFF2196F3)",
          borderRadius: "BorderRadius.circular(8.0)"
        },
        padding: "EdgeInsets.all(16.0)"
      },
      child: {
        type: "Text",
        data: "Hello World",
        props: {
          style: {
            color: "Colors.white",
            fontSize: "16.0",
            fontWeight: "FontWeight.bold"
          }
        }
      }
    };
    
    // Build React Native AST
    const reactNativeAST = buildReactNativeAST(exampleWidgetTree);
    
    // Generate React Native code
    const code = generateReactNativeCode(reactNativeAST);
    
    return code;
    
  } catch (error) {
    console.error("Conversion error:", error);
    return `// Error during conversion: ${error}`;
  }
};

// Export the main conversion function
export { convertFlutterPropsToReactNativeStyle, convertFlutterColor };
