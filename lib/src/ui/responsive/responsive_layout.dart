import 'package:flutter/widgets.dart';

/// Simple set of size classes inspired by Material 3 window size classes.
enum ScreenSizeClass { compact, medium, expanded }

/// Utility that determines [ScreenSizeClass] based on the shortest side.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 1024;

  static ScreenSizeClass fromSize(Size size) {
    final shortest = size.shortestSide;
    if (shortest < compactMax) {
      return ScreenSizeClass.compact;
    }
    if (shortest < mediumMax) {
      return ScreenSizeClass.medium;
    }
    return ScreenSizeClass.expanded;
  }
}

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  ScreenSizeClass sizeClass,
);

/// Wrapper around [LayoutBuilder] that exposes a size class to its builder.
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = ResponsiveBreakpoints.fromSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return builder(context, sizeClass);
      },
    );
  }
}
