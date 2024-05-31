import 'package:flutter/material.dart';

class CustomFocusScopeNode extends FocusScopeNode {
  final String label;

  CustomFocusScopeNode({
    required this.label,
    super.debugLabel,
    super.onKeyEvent,
    super.onKey,
    super.skipTraversal,
    super.canRequestFocus,
    super.traversalEdgeBehavior = TraversalEdgeBehavior.closedLoop,
  });
}
