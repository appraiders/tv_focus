import 'package:flutter/material.dart';

typedef FWidgetBuilder = Widget Function(
  BuildContext context,
  bool isFocused,
  AnimationController animationController,
);

/// the return value indicates whether the event was handled, if false, it will be passed on to the parent node
typedef FWidgetTapped = bool Function();
