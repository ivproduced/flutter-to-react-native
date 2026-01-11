// React Native Component Definitions
// Maps Flutter widgets to React Native components

export const reactNativeType = {
  number: {
    type: "number",
    value: 0,
  },
  string: {
    type: "string",
    value: "",
  },
  boolean: {
    type: "boolean",
    value: false,
  }
}

export const reactNativeComponent = {
  View: {
    type: "component",
    class: "View",
    properties: {},
  },

  Text: {
    type: "component",
    class: "Text",
    properties: {},
  },

  ScrollView: {
    type: "component",
    class: "ScrollView",
    properties: {},
  },

  Image: {
    type: "component",
    class: "Image",
    properties: {},
  },

  TouchableOpacity: {
    type: "component",
    class: "TouchableOpacity",
    properties: {},
  },

  FlatList: {
    type: "component",
    class: "FlatList",
    properties: {},
  },
} as const

// Style properties that map from Flutter to React Native
export const styleMapping = {
  // Container -> View styles
  Container: {
    width: "width",
    height: "height",
    color: "backgroundColor",
    margin: "margin",
    padding: "padding",
  },
  
  // BoxDecoration -> View styles
  BoxDecoration: {
    color: "backgroundColor",
    border: "border",
    borderRadius: "borderRadius",
  },

  // Text -> Text styles
  TextStyle: {
    color: "color",
    fontSize: "fontSize",
    fontWeight: "fontWeight",
    fontFamily: "fontFamily",
    fontStyle: "fontStyle",
  },

  // Alignment
  MainAxisAlignment: {
    start: "flex-start",
    end: "flex-end",
    center: "center",
    spaceBetween: "space-between",
    spaceAround: "space-around",
    spaceEvenly: "space-evenly",
  },

  CrossAxisAlignment: {
    start: "flex-start",
    end: "flex-end",
    center: "center",
    stretch: "stretch",
    baseline: "baseline",
  },

  // Layout
  Row: {
    component: "View",
    style: {
      flexDirection: "row",
    },
  },

  Column: {
    component: "View",
    style: {
      flexDirection: "column",
    },
  },

  Stack: {
    component: "View",
    style: {
      position: "relative",
    },
  },

  Positioned: {
    component: "View",
    style: {
      position: "absolute",
    },
  },

  Expanded: {
    component: "View",
    style: {
      flex: 1,
    },
  },
}
