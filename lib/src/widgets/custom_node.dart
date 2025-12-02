import 'package:flutter/material.dart';
import 'package:tv_focus/src/utils/index.dart';

import 'scope_node_mixin.dart';

part 'custom_focus_node.dart';
part 'custom_focus_scope_node.dart';

sealed class CustomNode extends FocusNode {
  bool get isRequireFirstFocus;

  void setIsRequireFirstFocus(bool value);

  factory CustomNode.node() = CustomFocusNode;

  factory CustomNode.scope({required String label}) = CustomFocusScopeNode;
}
