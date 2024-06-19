import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/index.dart';
import 'index.dart';

class CustomFocusScope extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool>? onFocusChange;
  final FWidgetTapped? onUpTap;
  final FWidgetTapped? onDownTap;
  final FWidgetTapped? onLeftTap;
  final FWidgetTapped? onRightTap;
  final FWidgetTapped? onBackTap;
  final FWidgetTapped? onTap;
  final bool saveFocus;
  final bool autofocus;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final String label;

  /// set this widget as focusable on first time when parent focus scope has primary focus
  final bool isFirstFocus;

  const CustomFocusScope({
    required this.child,
    required this.label,
    this.onFocusChange,
    this.onUpTap,
    this.onDownTap,
    this.onLeftTap,
    this.onRightTap,
    this.onBackTap,
    this.onTap,
    this.saveFocus = true,
    this.autofocus = false,
    this.isFirstFocus = false,
    this.onKeyEvent,
    super.key,
  });

  @override
  State<CustomFocusScope> createState() => _CustomFocusScopeState();
}

class _CustomFocusScopeState extends State<CustomFocusScope> {
  late final CustomFocusScopeNode _node;

  @override
  void initState() {
    super.initState();

    _node = CustomFocusScopeNode(
        label: widget.label, isFirstFocus: widget.isFirstFocus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autofocus) {
        _node.autofocus(_node.children
            .firstWhere(_checkFocusNode, orElse: () => _node.children.first));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: widget.autofocus,
      node: _node,
      onFocusChange: (value) async {
        if (value) {
          if (!widget.saveFocus || _node.isFirstFocused) {
            if (_node.children.where((element) => element.hasFocus).isEmpty) {
              _requestFirstFocus();
            } else {
              _moveFocusToFirst();
            }
          } else {
            if (_node.children.where((element) => element.hasFocus).isEmpty) {
              _requestFirstFocus();
            }
          }
        }
        widget.onFocusChange?.call(value);
      },
      onKeyEvent: widget.onKeyEvent ??
          (node, event) {
            switch (event) {
              case KeyDownEvent _:
              case KeyRepeatEvent _:
                final result = _manualHandler(event);
                if (result == true) {
                  return KeyEventResult.handled;
                }
                if (_focusNavigationHandler(node, event)) {
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              case KeyUpEvent _:
                if (event.logicalKey == LogicalKeyboardKey.goBack) {
                  return widget.onBackTap?.call() == true
                      ? KeyEventResult.handled
                      : KeyEventResult.ignored;
                }
                if (event.logicalKey == LogicalKeyboardKey.select) {
                  return widget.onTap?.call() == true
                      ? KeyEventResult.handled
                      : KeyEventResult.ignored;
                }
                return KeyEventResult.ignored;
            }
            return KeyEventResult.ignored;
          },
      child: widget.child,
    );
  }

  bool? _manualHandler(KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        return widget.onUpTap?.call();
      case LogicalKeyboardKey.arrowDown:
        return widget.onDownTap?.call();
      case LogicalKeyboardKey.arrowLeft:
        return widget.onLeftTap?.call();
      case LogicalKeyboardKey.arrowRight:
        return widget.onRightTap?.call();
      case LogicalKeyboardKey.goBack:
        return true;
      default:
        return null;
    }
  }

  bool _focusNavigationHandler(FocusNode node, KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        return node.parentFocusScopeNode
            .focusInDirection(TraversalDirection.up);
      case LogicalKeyboardKey.arrowDown:
        return node.parentFocusScopeNode
            .focusInDirection(TraversalDirection.down);
      case LogicalKeyboardKey.arrowLeft:
        return node.parentFocusScopeNode
            .focusInDirection(TraversalDirection.left);
      case LogicalKeyboardKey.arrowRight:
        return node.parentFocusScopeNode
            .focusInDirection(TraversalDirection.right);
      default:
        return false;
    }
  }

  bool _checkFocusNode(FocusNode node) =>
      node is CustomNodeMixin && (node as CustomNodeMixin).isRequireFirstFocus;

  void _requestFirstFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _node.children
          .firstWhere(_checkFocusNode, orElse: () => _node.children.first)
          .requestFocus();
    });
  }

  void _moveFocusToFirst() {
    final startIndex = _node.children.indexed
        .firstWhere((node) => _checkFocusNode(node.$2),
            orElse: () => (0, _node.children.first))
        .$1;
    final index =
        _node.children.indexed.where((element) => element.$2.hasFocus).first.$1;
    for (int i = startIndex; i != index; startIndex > index ? i-- : i++) {
      startIndex > index ? _node.nextFocus() : _node.previousFocus();
    }
  }
}
