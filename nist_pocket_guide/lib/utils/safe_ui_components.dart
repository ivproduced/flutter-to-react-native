import 'package:flutter/material.dart';

/// A wrapper widget that ensures proper SafeArea usage and prevents overflow issues
/// throughout the NIST Pocket Guide application.
class SafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? persistentFooterButtons;

  const SafeScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.floatingActionButtonLocation,
    this.persistentFooterButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body != null ? SafeArea(child: body!) : null,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButtonLocation: floatingActionButtonLocation,
      persistentFooterButtons: persistentFooterButtons,
    );
  }
}

/// A ListView wrapper that prevents overflow issues and ensures proper scrolling behavior
class SafeListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;

  const SafeListView({
    super.key,
    required this.children,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          controller: controller,
          padding: padding ?? const EdgeInsets.all(12.0),
          shrinkWrap: shrinkWrap,
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          scrollDirection: scrollDirection,
          reverse: reverse,
          primary: primary,
          children: children,
        );
      },
    );
  }
}

/// A Card wrapper that prevents overflow and ensures consistent styling
class SafeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  const SafeCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: margin,
      color: color,
      elevation: elevation,
      shape: shape,
      borderOnForeground: borderOnForeground,
      clipBehavior: clipBehavior,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius:
            shape is RoundedRectangleBorder
                ? (shape as RoundedRectangleBorder).borderRadius
                    as BorderRadius?
                : BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

/// A ListTile wrapper that prevents overflow and ensures proper text handling
class SafeListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool? dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final ListTileStyle? style;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MouseCursor? mouseCursor;
  final bool selected;
  final Color? focusColor;
  final Color? hoverColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? tileColor;
  final Color? selectedTileColor;
  final bool? enableFeedback;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;

  const SafeListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.style,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.mouseCursor,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title:
          title != null
              ? DefaultTextStyle(
                style: DefaultTextStyle.of(context).style,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                child: title!,
              )
              : null,
      subtitle:
          subtitle != null
              ? DefaultTextStyle(
                style: DefaultTextStyle.of(context).style,
                overflow: TextOverflow.ellipsis,
                maxLines: isThreeLine ? 3 : 2,
                child: subtitle!,
              )
              : null,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      style: style,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      mouseCursor: mouseCursor,
      selected: selected,
      focusColor: focusColor,
      hoverColor: hoverColor,
      focusNode: focusNode,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding ?? 8,
      minLeadingWidth: minLeadingWidth,
    );
  }
}

/// Extension methods for adding safe area protection to existing widgets
extension SafeAreaExtensions on Widget {
  /// Wrap any widget with SafeArea protection
  Widget withSafeArea({
    bool left = true,
    bool top = true,
    bool right = true,
    bool bottom = true,
    EdgeInsets minimum = EdgeInsets.zero,
    bool maintainBottomViewPadding = false,
  }) {
    return SafeArea(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      minimum: minimum,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: this,
    );
  }

  /// Wrap any widget with flexible sizing to prevent overflow
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) {
    return Flexible(flex: flex, fit: fit, child: this);
  }

  /// Wrap any widget with expanded to take available space
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }
}

/// Utility class for common safe measurements and responsive design
class SafeDimensions {
  static const double minTouchTarget = 48.0;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listPadding = EdgeInsets.all(12.0);
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  /// Get safe padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const EdgeInsets.all(12.0); // Mobile
    } else if (screenWidth < 1200) {
      return const EdgeInsets.all(16.0); // Tablet
    } else {
      return const EdgeInsets.all(24.0); // Desktop
    }
  }

  /// Get safe card margin based on screen size
  static EdgeInsets getResponsiveCardMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 4); // Mobile
    } else {
      return const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ); // Tablet/Desktop
    }
  }

  /// Get safe list item height
  static double getListItemHeight(
    BuildContext context, {
    bool hasSubtitle = false,
  }) {
    if (hasSubtitle) {
      return 80.0; // Height for items with subtitle
    } else {
      return 56.0; // Height for simple items
    }
  }
}
