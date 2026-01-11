/**
 * Simple Dart/Flutter Parser
 * Parses basic Flutter widget code into a widget tree structure
 */

export interface WidgetNode {
  type: string;
  props?: Record<string, any>;
  data?: string;
  child?: WidgetNode;
  children?: WidgetNode[];
}

/**
 * Main parser function - converts Flutter/Dart code to widget tree
 */
export function parseFlutterCode(code: string): WidgetNode | null {
  // Remove whitespace and newlines for easier parsing
  const cleanCode = code.trim();
  
  // Find the root widget
  const widgetMatch = cleanCode.match(/^(\w+)\s*\(/);
  if (!widgetMatch) {
    throw new Error('No widget found in code');
  }
  
  const widgetType = widgetMatch[1];
  
  // Extract the content inside the widget constructor
  const content = extractConstructorContent(cleanCode);
  
  // Parse the widget
  return parseWidget(widgetType, content);
}

/**
 * Extracts content inside constructor parentheses
 */
function extractConstructorContent(code: string): string {
  let level = 0;
  let start = -1;
  
  for (let i = 0; i < code.length; i++) {
    if (code[i] === '(') {
      if (level === 0) start = i + 1;
      level++;
    } else if (code[i] === ')') {
      level--;
      if (level === 0) {
        return code.substring(start, i);
      }
    }
  }
  
  return '';
}

/**
 * Parses a widget and its properties
 */
function parseWidget(widgetType: string, content: string): WidgetNode {
  const node: WidgetNode = { type: widgetType, props: {} };
  
  // Handle Text widget with direct string
  if (widgetType === 'Text') {
    const textMatch = content.match(/^['"](.+?)['"]/);
    if (textMatch) {
      node.data = textMatch[1];
      // Parse remaining as properties
      const remaining = content.substring(textMatch[0].length).trim();
      if (remaining.startsWith(',')) {
        const props = parseProperties(remaining.substring(1));
        node.props = props;
      }
      return node;
    }
  }
  
  // Parse properties
  const props = parseProperties(content);
  node.props = props;
  
  // Extract child or children
  if (props.child) {
    node.child = props.child;
    delete props.child;
  } else if (props.children) {
    node.children = props.children;
    delete props.children;
  }
  
  return node;
}

/**
 * Parses widget properties
 */
function parseProperties(content: string): Record<string, any> {
  const props: Record<string, any> = {};
  let i = 0;
  
  while (i < content.length) {
    // Skip whitespace and commas
    while (i < content.length && /[\s,]/.test(content[i])) {
      i++;
    }
    
    if (i >= content.length) break;
    
    // Find property name
    const propMatch = content.substring(i).match(/^(\w+)\s*:/);
    if (!propMatch) {
      i++;
      continue;
    }
    
    const propName = propMatch[1];
    i += propMatch[0].length;
    
    // Skip whitespace
    while (i < content.length && /\s/.test(content[i])) {
      i++;
    }
    
    // Parse property value
    const { value, endIndex } = parsePropertyValue(content, i);
    props[propName] = value;
    i = endIndex;
  }
  
  return props;
}

/**
 * Parses a single property value
 */
function parsePropertyValue(content: string, startIndex: number): { value: any; endIndex: number } {
  let i = startIndex;
  
  // String value
  if (content[i] === '"' || content[i] === "'") {
    const quote = content[i];
    i++;
    let str = '';
    while (i < content.length && content[i] !== quote) {
      if (content[i] === '\\') {
        i++;
        str += content[i];
      } else {
        str += content[i];
      }
      i++;
    }
    return { value: str, endIndex: i + 1 };
  }
  
  // Number value
  if (/\d/.test(content[i]) || content[i] === '-') {
    const numMatch = content.substring(i).match(/^-?\d+\.?\d*/);
    if (numMatch) {
      return { value: numMatch[0], endIndex: i + numMatch[0].length };
    }
  }
  
  // Boolean value
  if (content.substring(i).startsWith('true')) {
    return { value: true, endIndex: i + 4 };
  }
  if (content.substring(i).startsWith('false')) {
    return { value: false, endIndex: i + 5 };
  }
  
  // Constructor/Widget value (e.g., Color(0xFF...), EdgeInsets.all(...), child widget)
  const constructorMatch = content.substring(i).match(/^(\w+(?:\.\w+)?)\s*\(/);
  if (constructorMatch) {
    const constructorName = constructorMatch[1];
    const constructorStart = i + constructorMatch[0].length;
    
    // Find the closing parenthesis
    let level = 1;
    let j = constructorStart;
    while (j < content.length && level > 0) {
      if (content[j] === '(') level++;
      else if (content[j] === ')') level--;
      j++;
    }
    
    const constructorContent = content.substring(constructorStart, j - 1);
    
    // Check if this is a child widget (starts with capital letter)
    if (/^[A-Z]/.test(constructorName) && !constructorName.includes('.')) {
      // It's a child widget
      const childWidget = parseWidget(constructorName, constructorContent);
      return { value: childWidget, endIndex: j };
    }
    
    // It's a property constructor (Color, EdgeInsets, etc.)
    const fullConstructor = content.substring(i, j);
    return { value: fullConstructor, endIndex: j };
  }
  
  // Enum value (e.g., MainAxisAlignment.center)
  const enumMatch = content.substring(i).match(/^(\w+\.\w+)/);
  if (enumMatch) {
    return { value: enumMatch[1], endIndex: i + enumMatch[0].length };
  }
  
  // List value (for children property)
  if (content[i] === '[') {
    const children: WidgetNode[] = [];
    i++; // Skip opening bracket
    
    while (i < content.length && content[i] !== ']') {
      // Skip whitespace and commas
      while (i < content.length && /[\s,]/.test(content[i])) {
        i++;
      }
      
      if (content[i] === ']') break;
      
      // Find widget name
      const widgetMatch = content.substring(i).match(/^(\w+)\s*\(/);
      if (widgetMatch) {
        const widgetType = widgetMatch[1];
        const widgetStart = i + widgetMatch[0].length;
        
        // Find closing parenthesis
        let level = 1;
        let j = widgetStart;
        while (j < content.length && level > 0) {
          if (content[j] === '(') level++;
          else if (content[j] === ')') level--;
          j++;
        }
        
        const widgetContent = content.substring(widgetStart, j - 1);
        const widget = parseWidget(widgetType, widgetContent);
        children.push(widget);
        i = j;
      } else {
        i++;
      }
    }
    
    return { value: children, endIndex: i + 1 };
  }
  
  // Unknown - try to extract until comma or closing paren
  let value = '';
  let level = 0;
  while (i < content.length) {
    if (content[i] === '(' || content[i] === '[') level++;
    else if (content[i] === ')' || content[i] === ']') {
      if (level === 0) break;
      level--;
    } else if (content[i] === ',' && level === 0) break;
    
    value += content[i];
    i++;
  }
  
  return { value: value.trim(), endIndex: i };
}

/**
 * Helper function to pretty-print widget tree (for debugging)
 */
export function printWidgetTree(node: WidgetNode, indent: number = 0): string {
  const spaces = '  '.repeat(indent);
  let result = `${spaces}${node.type}\n`;
  
  if (node.data) {
    result += `${spaces}  data: "${node.data}"\n`;
  }
  
  if (node.props && Object.keys(node.props).length > 0) {
    result += `${spaces}  props:\n`;
    for (const [key, value] of Object.entries(node.props)) {
      if (typeof value === 'object' && value !== null && 'type' in value) {
        // Skip - will be printed as child
        continue;
      }
      result += `${spaces}    ${key}: ${JSON.stringify(value)}\n`;
    }
  }
  
  if (node.child) {
    result += `${spaces}  child:\n`;
    result += printWidgetTree(node.child, indent + 2);
  }
  
  if (node.children) {
    result += `${spaces}  children:\n`;
    for (const child of node.children) {
      result += printWidgetTree(child, indent + 2);
    }
  }
  
  return result;
}

// Example usage:
// const flutterCode = `
//   Container(
//     width: 200.0,
//     height: 100.0,
//     child: Text('Hello World')
//   )
// `;
// const tree = parseFlutterCode(flutterCode);
// console.log(printWidgetTree(tree));
