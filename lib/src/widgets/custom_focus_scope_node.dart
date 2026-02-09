part of 'custom_node.dart';

class CustomFocusScopeNode extends FocusScopeNode implements CustomNode {
  @override
  final String label;

  int initialIndex;

  CustomFocusScopeNode({
    required this.label,
    bool? isFirstFocus,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
    super.traversalEdgeBehavior = TraversalEdgeBehavior.closedLoop,
    this.initialIndex = 0,
  }) : isRequireFirstFocus = isFirstFocus ?? true;

  @override
  bool isRequireFirstFocus = false;

  @override
  void setIsRequireFirstFocus(bool value) {
    isRequireFirstFocus = value;
    if (value == false) {
      return;
    }
    if (customChildren.isEmpty) {
      return;
    }
    for (final child in customChildren) {
      if (child is CustomFocusScopeNode) {
        child.setIsRequireFirstFocus(value);
      }
    }
  }

  @override
  bool get isCustomFocused {
    if (isRequireFirstFocus) {
      return false;
    }
    return customChildren.any((node) => node.isCustomFocused);
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

  bool get isCustomChildrenRequireFocus {
    return customChildren.every(
      (node) {
        final context = node.context;
        if (context == null) {
          return true;
        }
        final route = ModalRoute.of(context);
        if (route == null) {
          return true;
        }
        if (!route.isCurrent) {
          return true;
        }
        return !node.isRequireFirstFocus;
      },
    );
  }

  bool get hasFocusableCustomChildren => customChildren.any((node) {
        final context = node.context;
        if (context == null) {
          return false;
        }
        final route = ModalRoute.of(context);
        if (route == null) {
          return false;
        }
        if (!route.isCurrent) {
          return false;
        }
        return node is CustomFocusScopeNode ? node.hasFocusableCustomChildren : node.canRequestFocus;
      });
}
