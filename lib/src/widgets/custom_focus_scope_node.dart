part of 'custom_node.dart';

class CustomFocusScopeNode extends FocusScopeNode with CustomScopeMixin implements CustomNode {
  final String? label;

  CustomFocusScopeNode({
    this.label,
    bool? isFirstFocus,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
    super.traversalEdgeBehavior = TraversalEdgeBehavior.closedLoop,
  }) : isRequireFirstFocus = isFirstFocus ?? true;

  @override
  bool isRequireFirstFocus = false;

  @override
  void setIsRequireFirstFocus(bool value) {
    isRequireFirstFocus = value;
  }

  bool get canPreviousFocus {
    if (children.isEmpty) {
      return false;
    }
    final focusedIndex = children.indexed.firstWhere((node) => node.$2.hasFocus || node.$2.hasPrimaryFocus).$1;
    return focusedIndex > 0;
  }

  bool get canNextFocus {
    if (children.isEmpty) {
      return false;
    }
    final focusedIndex = children.indexed.firstWhere((node) => node.$2.hasFocus || node.$2.hasPrimaryFocus).$1;
    return focusedIndex >= 0 && focusedIndex < children.length - 1;
  }

  List<CustomNode> get customChildren {
    return children.map((node) => node.childCustomFocusNode).whereType<CustomNode>().toList();
  }
}
