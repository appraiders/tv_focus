part of 'custom_node.dart';

class CustomFocusNode extends FocusNode implements CustomNode {
  @override
  final String label;

  CustomFocusNode({
    required this.label,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
  }) : isRequireFirstFocus = true;

  @override
  bool isRequireFirstFocus = false;

  @override
  void setIsRequireFirstFocus(bool value) {
    isRequireFirstFocus = value;
  }
}
