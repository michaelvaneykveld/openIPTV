import 'package:flutter/material.dart';

class PlayerThemeData {
  const PlayerThemeData({
    this.overlayPadding = const EdgeInsets.fromLTRB(32, 24, 32, 32),
    this.buttonSpacing = 12,
    this.focusScale = 1.08,
    this.focusBorderRadius = 12,
    this.focusBorderWidth = 2,
    this.autoHideDelay = const Duration(seconds: 4),
  });

  final EdgeInsets overlayPadding;
  final double buttonSpacing;
  final double focusScale;
  final double focusBorderRadius;
  final double focusBorderWidth;
  final Duration autoHideDelay;

  PlayerThemeData copyWith({
    EdgeInsets? overlayPadding,
    double? buttonSpacing,
    double? focusScale,
    double? focusBorderRadius,
    double? focusBorderWidth,
    Duration? autoHideDelay,
  }) {
    return PlayerThemeData(
      overlayPadding: overlayPadding ?? this.overlayPadding,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      focusScale: focusScale ?? this.focusScale,
      focusBorderRadius: focusBorderRadius ?? this.focusBorderRadius,
      focusBorderWidth: focusBorderWidth ?? this.focusBorderWidth,
      autoHideDelay: autoHideDelay ?? this.autoHideDelay,
    );
  }
}

class PlayerTheme extends InheritedWidget {
  const PlayerTheme({super.key, required this.data, required super.child});

  final PlayerThemeData data;

  static PlayerThemeData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<PlayerTheme>();
    return inherited?.data ?? const PlayerThemeData();
  }

  @override
  bool updateShouldNotify(PlayerTheme oldWidget) => data != oldWidget.data;
}
