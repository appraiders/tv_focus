import 'package:flutter/material.dart';

typedef FWidgetBuilder = Widget Function(
  BuildContext context,
  bool isFocused,
  AnimationController animationController,
);

typedef FWidgetTapped = bool Function();
