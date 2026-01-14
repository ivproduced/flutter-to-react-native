/**
 * Anthropic Skill Handler
 * Implements the flutter_to_react_native skill according to Anthropic's skill specification
 */

const { convertFlutterToReactNative } = require('./dist/index.js');

/**
 * Main skill handler function
 * @param {Object} params - The skill parameters
 * @param {string} params.flutter_code - The Flutter/Dart code to convert
 * @param {Object} params.options - Optional conversion settings
 * @param {boolean} params.options.include_imports - Whether to include React Native imports
 * @param {number} params.options.indent_size - Number of spaces for indentation
 * @returns {Promise<Object>} The conversion result
 */
async function convert_flutter_to_react_native(params) {
  try {
    // Validate input
    if (!params || !params.flutter_code) {
      return {
        success: false,
        error: 'Missing required parameter: flutter_code',
        output: null
      };
    }

    const { flutter_code, options = {} } = params;
    const { include_imports = false, indent_size = 2 } = options;

    // Validate flutter_code is a string
    if (typeof flutter_code !== 'string') {
      return {
        success: false,
        error: 'Parameter flutter_code must be a string',
        output: null
      };
    }

    // Trim whitespace
    const cleanCode = flutter_code.trim();
    
    if (cleanCode.length === 0) {
      return {
        success: false,
        error: 'flutter_code cannot be empty',
        output: null
      };
    }

    // Detect widget type for metadata
    const widgetMatch = cleanCode.match(/^(\w+)\s*\(/);
    const detectedWidget = widgetMatch ? widgetMatch[1] : 'Unknown';

    // Perform conversion
    let output = convertFlutterToReactNative(cleanCode);

    // Add React Native imports if requested
    if (include_imports) {
      const imports = [
        "import React from 'react';",
        "import { View, Text, StyleSheet } from 'react-native';",
        ""
      ].join('\n');
      output = imports + output;
    }

    // Apply custom indentation if needed
    if (indent_size !== 2) {
      output = reformatIndentation(output, indent_size);
    }

    // Detect output component type
    const outputMatch = output.match(/<(\w+)/);
    const outputComponent = outputMatch ? outputMatch[1] : 'Unknown';

    // Build warnings array
    const warnings = [];
    const knownWidgets = ['Container', 'Text', 'Row', 'Column', 'Stack', 'Positioned', 'Expanded', 'SizedBox', 'Padding'];
    
    if (!knownWidgets.includes(detectedWidget)) {
      warnings.push(`Widget '${detectedWidget}' may not be fully supported. Supported widgets: ${knownWidgets.join(', ')}`);
    }

    // Return success result following Anthropic skill spec
    return {
      success: true,
      output: output,
      metadata: {
        input_widget: detectedWidget,
        output_component: outputComponent,
        warnings: warnings.length > 0 ? warnings : undefined
      }
    };

  } catch (error) {
    // Return error result following Anthropic skill spec
    return {
      success: false,
      error: error.message || String(error),
      output: null,
      metadata: {
        error_type: error.name || 'Error'
      }
    };
  }
}

/**
 * Helper function to reformat code indentation
 * @param {string} code - The code to reformat
 * @param {number} targetIndent - Target indentation size
 * @returns {string} Reformatted code
 */
function reformatIndentation(code, targetIndent) {
  const defaultIndent = 2;
  if (targetIndent === defaultIndent) return code;
  
  return code.split('\n').map(line => {
    const leadingSpaces = line.match(/^(\s*)/)[1].length;
    if (leadingSpaces === 0) return line;
    
    const indentLevel = leadingSpaces / defaultIndent;
    const newSpaces = ' '.repeat(indentLevel * targetIndent);
    return newSpaces + line.trim();
  }).join('\n');
}

// Export the skill handler
module.exports = {
  convert_flutter_to_react_native
};

// For ES modules
if (typeof exports !== 'undefined') {
  exports.convert_flutter_to_react_native = convert_flutter_to_react_native;
}
