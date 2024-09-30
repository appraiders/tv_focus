import 'package:flutter/material.dart';

import 'index.dart';

class CustomFocusScopeNode extends FocusScopeNode with CustomNodeMixin, CustomScopeMixin {
  final String? label;

  CustomFocusScopeNode({
    this.label,
    bool? isFirstFocus,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
    super.traversalEdgeBehavior = TraversalEdgeBehavior.closedLoop,
  }) {
    isRequireFirstFocus = isFirstFocus ?? true;
  }
}
