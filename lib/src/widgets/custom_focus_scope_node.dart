part of 'custom_node.dart';

class CustomFocusScopeNode extends FocusScopeNode implements CustomNode {
  @override
  final String label;

  int _initialIndex;

  bool _isRequireFirstFocus;

  CustomFocusScopeNode({
    required this.label,
    super.debugLabel,
    super.onKeyEvent,
    super.skipTraversal,
    super.canRequestFocus,
    super.traversalEdgeBehavior = TraversalEdgeBehavior.closedLoop,
    int initialIndex = 0,
  })  : _isRequireFirstFocus = true,
        _initialIndex = initialIndex {
    if (customChildren.length > _initialIndex) {
      final node = customChildren.elementAt(_initialIndex);
      if (node is CustomFocusScopeNode) {
        setFirstFocus(node);
      }
    }
  }

  void setInitialIndex(int index) {
    if (index < 0) {
      debugPrint('CustomFocusScopeNode: initial index cannot be negative, ignoring $index\n${StackTrace.current}');
      return;
    }
    _initialIndex = index;
  }

  int get initialIndex => _initialIndex;

  @override
  bool get isRequireFirstFocus => _isRequireFirstFocus;

  bool get isCustomChildrenRequireFocus {
    final customScopeChildren =
        customChildren.whereType<CustomFocusScopeNode>().where((node) => node.hasFocusableCustomChildren);
    final customNodeChildren = customChildren.whereType<CustomFocusNode>().where((node) => node.canRequestFocus);

    if (customScopeChildren.isEmpty && customNodeChildren.isEmpty) {
      return false;
    }
    return customScopeChildren.every((node) => node.isRequireFirstFocus) &&
        customNodeChildren.every((node) => node.isRequireFirstFocus);
  }

  @override
  void setIsRequireFirstFocus(bool value) {
    _isRequireFirstFocus = value;
    if (value == false) {
      setInitialFocus();
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

  List<CustomNode> get customChildren => children
      .map((node) => node.childrenCustomFocusNode)
      .expand((element) => element)
      .whereType<CustomNode>()
      .toList();

  bool get hasFocusableCustomChildren {
    return customChildren
        .any((node) => node is CustomFocusScopeNode ? node.hasFocusableCustomChildren : node.canRequestFocus);
  }

  void setInitialFocus() {
    _isRequireFirstFocus = false;
    final focusableChildren = customChildren.where((node) => node.canRequestFocus);
    if (focusableChildren.length > initialIndex) {
      final node = focusableChildren.elementAt(initialIndex);
      node.requestFocus();
    } else if (focusableChildren.isNotEmpty) {
      focusableChildren.first.requestFocus();
    } else {
      debugPrint('CustomFocusScopeNode: setting focus no focusable children in scope $label to set focus to');
    }
  }

  @override
  void requestScopeFocus() {
    super.requestScopeFocus();
    if (isRequireFirstFocus) {
      setInitialFocus();
    }
  }
}
