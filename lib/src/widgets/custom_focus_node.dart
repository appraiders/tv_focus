import 'package:flutter/material.dart';

import 'index.dart';

class CustomFocusNode extends FocusNode with CustomNodeMixin {
  CustomFocusNode({
    bool? isFirstFocus,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
  }) {
    isRequireFirstFocus = isFirstFocus ?? true;
  }
}
