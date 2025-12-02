part of 'custom_node.dart';

class CustomFocusNode extends FocusNode implements CustomNode {
  CustomFocusNode({
    bool? isFirstFocus,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
  }) : isRequireFirstFocus = isFirstFocus ?? true;

  @override
  bool isRequireFirstFocus = false;

  @override
  void setIsRequireFirstFocus(bool value) {
    isRequireFirstFocus = value;
  }
}
