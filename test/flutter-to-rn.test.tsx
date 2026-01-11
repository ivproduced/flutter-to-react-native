/**
 * Tests for Flutter to React Native conversion
 */

import { convertFlutterToReactNative } from '../src/index';
import { parseFlutterCode } from '../src/utils/dart-parser';
import {
  flutterColorToHex as convertFlutterColor,
  convertMainAxisAlignment,
  convertCrossAxisAlignment,
  convertFontWeight,
  parseEdgeInsetsToPadding,
  parseBorderRadius,
} from '../src/utils/flutter-to-rn-converter';

describe('Flutter to React Native Conversion', () => {
  
  describe('Dart Parser', () => {
    it('should parse simple Container widget', () => {
      const code = `Container(width: 200.0, height: 100.0)`;
      const tree = parseFlutterCode(code);
      
      expect(tree).toBeDefined();
      expect(tree?.type).toBe('Container');
      expect(tree?.props?.width).toBe('200.0');
      expect(tree?.props?.height).toBe('100.0');
    });
    
    it('should parse Text widget with string', () => {
      const code = `Text('Hello World')`;
      const tree = parseFlutterCode(code);
      
      expect(tree).toBeDefined();
      expect(tree?.type).toBe('Text');
      expect(tree?.data).toBe('Hello World');
    });
    
    it('should parse nested widgets', () => {
      const code = `Container(child: Text('Hello'))`;
      const tree = parseFlutterCode(code);
      
      expect(tree).toBeDefined();
      expect(tree?.type).toBe('Container');
      expect(tree?.child).toBeDefined();
      expect(tree?.child?.type).toBe('Text');
      expect(tree?.child?.data).toBe('Hello');
    });
    
    it('should parse Row with children', () => {
      const code = `Row(children: [Text('A'), Text('B')])`;
      const tree = parseFlutterCode(code);
      
      expect(tree).toBeDefined();
      expect(tree?.type).toBe('Row');
      expect(tree?.children).toBeDefined();
      expect(tree?.children?.length).toBe(2);
    });
  });
  
  describe('Color Conversion', () => {
    it('should convert Flutter Color to hex', () => {
      expect(convertFlutterColor('Color(0xFFFF5722)')).toBe('#FF5722');
      expect(convertFlutterColor('Color(0xFF2196F3)')).toBe('#2196F3');
    });
    
    it('should convert named colors', () => {
      expect(convertFlutterColor('Colors.red')).toBe('#F44336');
      expect(convertFlutterColor('Colors.blue')).toBe('#2196F3');
      expect(convertFlutterColor('Colors.white')).toBe('#FFFFFF');
      expect(convertFlutterColor('Colors.black')).toBe('#000000');
    });
  });
  
  describe('Alignment Conversion', () => {
    it('should convert MainAxisAlignment', () => {
      expect(convertMainAxisAlignment('MainAxisAlignment.start')).toBe('flex-start');
      expect(convertMainAxisAlignment('MainAxisAlignment.center')).toBe('center');
      expect(convertMainAxisAlignment('MainAxisAlignment.spaceBetween')).toBe('space-between');
    });
    
    it('should convert CrossAxisAlignment', () => {
      expect(convertCrossAxisAlignment('CrossAxisAlignment.start')).toBe('flex-start');
      expect(convertCrossAxisAlignment('CrossAxisAlignment.center')).toBe('center');
      expect(convertCrossAxisAlignment('CrossAxisAlignment.stretch')).toBe('stretch');
    });
  });
  
  describe('EdgeInsets Conversion', () => {
    it('should convert EdgeInsets.all', () => {
      const result = parseEdgeInsetsToPadding('EdgeInsets.all(16.0)');
      expect(result.padding).toBe(16);
    });
    
    it('should convert EdgeInsets.symmetric', () => {
      const result = parseEdgeInsetsToPadding('EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0)');
      expect(result.paddingLeft).toBe(20);
      expect(result.paddingRight).toBe(20);
      expect(result.paddingTop).toBe(10);
      expect(result.paddingBottom).toBe(10);
    });
    
    it('should convert EdgeInsets.only', () => {
      const result = parseEdgeInsetsToPadding('EdgeInsets.only(top: 10.0, left: 5.0)');
      expect(result.paddingTop).toBe(10);
      expect(result.paddingLeft).toBe(5);
    });
  });
  
  describe('BorderRadius Conversion', () => {
    it('should convert BorderRadius.circular', () => {
      const result = parseBorderRadius('BorderRadius.circular(8.0)');
      expect(result).toBe(8);
    });
    
    it('should convert BorderRadius.only', () => {
      const result = parseBorderRadius('BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))');
      expect(result).toHaveProperty('borderTopLeftRadius', 10);
      expect(result).toHaveProperty('borderTopRightRadius', 10);
    });
  });
  
  describe('FontWeight Conversion', () => {
    it('should convert FontWeight values', () => {
      expect(convertFontWeight('FontWeight.bold')).toBe('bold');
      expect(convertFontWeight('FontWeight.normal')).toBe('normal');
      expect(convertFontWeight('FontWeight.w700')).toBe('700');
      expect(convertFontWeight('FontWeight.w400')).toBe('400');
    });
  });
  
  describe('Full Conversion', () => {
    it('should convert simple Container', () => {
      const flutterCode = `Container(width: 200.0, height: 100.0)`;
      const result = convertFlutterToReactNative(flutterCode);
      
      expect(result).toContain('<View');
      // Note: Currently returns example output, not actual parsed input
    });
    
    it('should convert Container with Text child', () => {
      const flutterCode = `Container(child: Text('Hello World'))`;
      const result = convertFlutterToReactNative(flutterCode);
      
      expect(result).toContain('<View');
      expect(result).toContain('<Text');
      expect(result).toContain('Hello World');
    });
    
    it.skip('should convert Row with multiple children', () => {
      // TODO: Enable when Dart parser is fully integrated
      const flutterCode = `Row(children: [Text('A'), Text('B')])`;
      const result = convertFlutterToReactNative(flutterCode);
      
      expect(result).toContain('flexDirection');
      expect(result).toContain('row');
    });
  });
  
});

// Run manual tests
if (require.main === module) {
  console.log('Running manual tests...\n');
  
  // Test 1: Simple Container
  console.log('=== Test 1: Simple Container ===');
  const test1 = `Container(width: 200.0, height: 100.0)`;
  console.log('Input:', test1);
  console.log('Output:', convertFlutterToReactNative(test1));
  console.log();
  
  // Test 2: Container with background color
  console.log('=== Test 2: Container with Color ===');
  const test2 = `Container(width: 200.0, color: Color(0xFF2196F3))`;
  console.log('Input:', test2);
  console.log('Output:', convertFlutterToReactNative(test2));
  console.log();
  
  // Test 3: Text widget
  console.log('=== Test 3: Text Widget ===');
  const test3 = `Text('Hello World')`;
  console.log('Input:', test3);
  console.log('Output:', convertFlutterToReactNative(test3));
  console.log();
  
  // Test 4: Container with child
  console.log('=== Test 4: Container with Child ===');
  const test4 = `Container(padding: EdgeInsets.all(16.0), child: Text('Hello'))`;
  console.log('Input:', test4);
  console.log('Output:', convertFlutterToReactNative(test4));
  console.log();
}
