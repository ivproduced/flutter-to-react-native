/**
 * Utility functions for converting Flutter values to React Native values
 */

/**
 * Converts Flutter double values to React Native numbers
 * Example: "24.0" -> 24
 */
export function toNumber(value: any): number {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const match = value.match(/(\d+\.?\d*)/);
    if (match) {
      return parseFloat(match[1]);
    }
  }
  return 0;
}

/**
 * Converts Flutter Color to hex string
 * Example: "Color(0xFFFF5722)" -> "#FF5722"
 */
export function flutterColorToHex(colorStr: string): string {
  if (typeof colorStr !== 'string') return '#000000';
  
  // Handle Color(0xFFRRGGBB) format
  const match = colorStr.match(/Color\(0x([A-Fa-f0-9]{8})\)/);
  if (match) {
    const hex = match[1];
    // Skip alpha channel (first 2 chars) and return RGB
    return `#${hex.substring(2)}`;
  }
  
  // Handle Colors.colorName
  if (colorStr.startsWith('Colors.')) {
    return convertFlutterNamedColor(colorStr.replace('Colors.', ''));
  }
  
  return colorStr;
}

/**
 * Maps Flutter named colors to hex values
 */
function convertFlutterNamedColor(colorName: string): string {
  const colorMap: Record<string, string> = {
    'red': '#F44336',
    'pink': '#E91E63',
    'purple': '#9C27B0',
    'deepPurple': '#673AB7',
    'indigo': '#3F51B5',
    'blue': '#2196F3',
    'lightBlue': '#03A9F4',
    'cyan': '#00BCD4',
    'teal': '#009688',
    'green': '#4CAF50',
    'lightGreen': '#8BC34A',
    'lime': '#CDDC39',
    'yellow': '#FFEB3B',
    'amber': '#FFC107',
    'orange': '#FF9800',
    'deepOrange': '#FF5722',
    'brown': '#795548',
    'grey': '#9E9E9E',
    'blueGrey': '#607D8B',
    'black': '#000000',
    'white': '#FFFFFF',
    'transparent': 'transparent',
  };
  
  return colorMap[colorName] || '#000000';
}

/**
 * Converts Flutter MainAxisAlignment to React Native justifyContent
 */
export function convertMainAxisAlignment(alignment: string): string {
  const map: Record<string, string> = {
    'MainAxisAlignment.start': 'flex-start',
    'MainAxisAlignment.end': 'flex-end',
    'MainAxisAlignment.center': 'center',
    'MainAxisAlignment.spaceBetween': 'space-between',
    'MainAxisAlignment.spaceAround': 'space-around',
    'MainAxisAlignment.spaceEvenly': 'space-evenly',
  };
  
  return map[alignment] || 'flex-start';
}

/**
 * Converts Flutter CrossAxisAlignment to React Native alignItems
 */
export function convertCrossAxisAlignment(alignment: string): string {
  const map: Record<string, string> = {
    'CrossAxisAlignment.start': 'flex-start',
    'CrossAxisAlignment.end': 'flex-end',
    'CrossAxisAlignment.center': 'center',
    'CrossAxisAlignment.stretch': 'stretch',
    'CrossAxisAlignment.baseline': 'baseline',
  };
  
  return map[alignment] || 'stretch';
}

/**
 * Converts Flutter TextAlign to React Native textAlign
 */
export function convertTextAlign(textAlign: string): string {
  const map: Record<string, string> = {
    'TextAlign.left': 'left',
    'TextAlign.right': 'right',
    'TextAlign.center': 'center',
    'TextAlign.justify': 'justify',
    'TextAlign.start': 'left',
    'TextAlign.end': 'right',
  };
  
  return map[textAlign] || 'left';
}

/**
 * Converts Flutter FontWeight to React Native fontWeight
 */
export function convertFontWeight(fontWeight: string): string | number {
  const map: Record<string, string> = {
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
  
  return map[fontWeight] || 'normal';
}

/**
 * Converts Flutter FontStyle to React Native fontStyle
 */
export function convertFontStyle(fontStyle: string): string {
  if (fontStyle === 'FontStyle.italic') return 'italic';
  if (fontStyle === 'FontStyle.normal') return 'normal';
  return 'normal';
}

/**
 * Parses Flutter EdgeInsets and converts to React Native padding object
 */
export function parseEdgeInsetsToPadding(edgeInsets: string): Record<string, number> {
  const result: Record<string, number> = {};
  
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
  
  return result;
}

/**
 * Parses Flutter EdgeInsets and converts to React Native margin object
 */
export function parseEdgeInsetsToMargin(edgeInsets: string): Record<string, number> {
  const padding = parseEdgeInsetsToPadding(edgeInsets);
  const margin: Record<string, number> = {};
  
  // Convert padding keys to margin keys
  Object.keys(padding).forEach(key => {
    const marginKey = key.replace('padding', 'margin');
    margin[marginKey] = padding[key];
  });
  
  return margin;
}

/**
 * Parses Flutter BorderRadius
 */
export function parseBorderRadius(borderRadius: string): number | Record<string, number> {
  // BorderRadius.circular(value)
  if (borderRadius.includes('BorderRadius.circular')) {
    const match = borderRadius.match(/BorderRadius\.circular\((\d+\.?\d*)\)/);
    if (match) {
      return parseFloat(match[1]);
    }
  }
  
  // BorderRadius.only(...)
  if (borderRadius.includes('BorderRadius.only')) {
    const result: Record<string, number> = {};
    const topLeftMatch = borderRadius.match(/topLeft:\s*Radius\.circular\((\d+\.?\d*)\)/);
    const topRightMatch = borderRadius.match(/topRight:\s*Radius\.circular\((\d+\.?\d*)\)/);
    const bottomLeftMatch = borderRadius.match(/bottomLeft:\s*Radius\.circular\((\d+\.?\d*)\)/);
    const bottomRightMatch = borderRadius.match(/bottomRight:\s*Radius\.circular\((\d+\.?\d*)\)/);
    
    if (topLeftMatch) result.borderTopLeftRadius = parseFloat(topLeftMatch[1]);
    if (topRightMatch) result.borderTopRightRadius = parseFloat(topRightMatch[1]);
    if (bottomLeftMatch) result.borderBottomLeftRadius = parseFloat(bottomLeftMatch[1]);
    if (bottomRightMatch) result.borderBottomRightRadius = parseFloat(bottomRightMatch[1]);
    
    return result;
  }
  
  return 0;
}

/**
 * Parses Flutter Border
 */
export function parseBorder(border: string): Record<string, any> {
  const result: Record<string, any> = {};
  
  // Border.all(...)
  if (border.includes('Border.all')) {
    const widthMatch = border.match(/width:\s*(\d+\.?\d*)/);
    const colorMatch = border.match(/color:\s*(Color\(0x[A-Fa-f0-9]{8}\)|Colors\.\w+)/);
    
    if (widthMatch) result.borderWidth = parseFloat(widthMatch[1]);
    if (colorMatch) result.borderColor = flutterColorToHex(colorMatch[1]);
  }
  
  return result;
}
