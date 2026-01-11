# Flutter to React Native Widgets

![alt text](https://github.com/GeekyAnts/react-native-to-flutter/blob/main/banner/Cover.png?raw=true)

The goal of `Flutter to React Native Widgets` is to convert any Flutter Widget to React Native Component. This helps Flutter developers who want to transition to React Native by understanding the Flutter to React Native equivalent code.


This tool will take the Flutter widget code on the left hand side editor and convert that to the React Native component on the right hand side.

> **Note**: This project has been reversed from "React Native to Flutter" to "Flutter to React Native". See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed information about the conversion logic and mappings.

## Quick Example

**Flutter Input:**
```dart
Container(
  width: 200.0,
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFF2196F3),
    borderRadius: BorderRadius.circular(8.0),
  ),
  child: Text('Hello', style: TextStyle(color: Colors.white))
)
```

**React Native Output:**
```jsx
<View style={{width: 200, padding: 16, backgroundColor: '#2196F3', borderRadius: 8}}>
  <Text style={{color: '#FFFFFF'}}>Hello</Text>
</View>
```

### List of Supported Flutter Widgets

The entire checklist of which widgets are already supported is [here](https://github.com/GeekyAnts/nativebase-theme-to-flutter/blob/main/README_API_CHECKLIST.md) 

### Working Example

<img src="https://raw.githubusercontent.com/GeekyAnts/react-native-to-flutter/main/banner/high-res-example.gif" >


### Folder Structure

```
.
├── LICENSE
├── README.md
├── README_API_CHECKLIST.md
├── package-lock.json
├── package.json
├── src
│   ├── addProperty.tsx
│   ├── buildDartASTfromAST.tsx
│   ├── clearProperties.tsx
│   ├── config
│   │   ├── flutter-widgets.ts
│   │   ├── index.ts
│   │   ├── layout-props.ts
│   │   └── text-props.ts
│   ├── index.tsx
│   └── utils
│       ├── arr.js
│       ├── camel.ts
│       ├── converter.tsx
│       ├── getAlignmentAxis.tsx
│       ├── getBorder.tsx
│       ├── getBorderRadius.tsx
│       ├── getExpanded.tsx
│       ├── getFlex.tsx
│       ├── getFlexDirection.tsx
│       ├── getFontFamily.tsx
│       ├── getFontStyle.tsx
│       ├── getFontWeight.tsx
│       ├── getMargin.tsx
│       ├── getPadding.tsx
│       ├── getPositioned.tsx
│       ├── getTextAlign.tsx
│       ├── num.ts
│       ├── pos.js
│       ├── pushPropToWidget.tsx
│       ├── str.js
│       └── unit.ts
├── test
│   └── blah.test.tsx
├── tsconfig.json
└── yarn.lock


```

### Run this project

Clone the repo, run

``` 
git clone https://github.com/GeekyAnts/flutter-to-react-native.git 

```

### Dependencies 

```
@babel/parser
@babel/preset-react

```

Install Dependencies
```
yarn install
```

Run the below command in root folder of the project

```
yarn start
```
Now to run the example, open new terminal and change your pwd to example folder

```
cd example
```
and then run
```
yarn start
````
Now head to ```http://localhost:1234/``` app should be working fine.

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide with examples
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture and conversion mappings
- **[MIGRATION_STATUS.md](MIGRATION_STATUS.md)** - Implementation roadmap and status

## Conversion Examples

### Container → View
```dart
// Flutter
Container(
  width: 200.0,
  height: 100.0,
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFF2196F3),
    borderRadius: BorderRadius.circular(8.0),
  ),
)
```
```jsx
// React Native
<View style={{
  width: 200,
  height: 100,
  padding: 16,
  backgroundColor: '#2196F3',
  borderRadius: 8
}} />
```

### Row → View with Flex
```dart
// Flutter
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('Hello'),
    Text('World'),
  ]
)
```
```jsx
// React Native
<View style={{flexDirection: 'row', justifyContent: 'center'}}>
  <Text>Hello</Text>
  <Text>World</Text>
</View>
```

### Know Issues
❌ Deep Nesting of Tags might not work as expected.
❌ Dart parser is basic - complex Flutter expressions may not parse correctly.
⚠️ This is a work in progress - see [MIGRATION_STATUS.md](MIGRATION_STATUS.md) for current status.

### How to Contribute

Thank you for your interest in contributing to Flutter to React Native Widgets! We are lucky to have you 🙂 Head over to [Contribution](https://github.com/GeekyAnts/flutter-to-react-native/blob/main/CONTRIBUTION.md) Guidelines and learn how you can be a part of a wonderful, growing community.

### Contributors 

<a href="https://github.com/GeekyAnts/flutter-to-react-native/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=GeekyAnts/flutter-to-react-native" />
</a>

### License

Licensed under the [MIT](https://github.com/GeekyAnts/flutter-to-react-native/blob/main/LICENSE) License, Copyright © 2023 GeekyAnts. See LICENSE for more information.


Made with ❤️ by <a href="https://geekyants.com/" ><img src="https://s3.ap-southeast-1.amazonaws.com/cdn.elitmus.com/sy0zfezmfdovlb4vaz6siv1l7g30" height="17"/></a>
