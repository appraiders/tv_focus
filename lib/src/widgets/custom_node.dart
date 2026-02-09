import 'package:flutter/material.dart';
import 'package:tv_focus/src/utils/index.dart';

part 'custom_focus_node.dart';
part 'custom_focus_scope_node.dart';

sealed class CustomNode extends FocusNode {
  bool get isRequireFirstFocus;

  bool get isCustomFocused;

  String get label;

  void setIsRequireFirstFocus(bool value);

  factory CustomNode.node({required String label}) = CustomFocusNode;

  factory CustomNode.scope({required String label}) = CustomFocusScopeNode;
}
