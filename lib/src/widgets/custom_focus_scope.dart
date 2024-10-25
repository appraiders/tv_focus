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
  final String? label;

  /// set this widget as focusable on first time when parent focus scope has primary focus
  final bool isFirstFocus;

  final int? indexOfChildWithFirstFocus;

  const CustomFocusScope({
    required this.child,
    this.label,
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
    this.indexOfChildWithFirstFocus,
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

    _node = CustomFocusScopeNode(label: widget.label, isFirstFocus: widget.isFirstFocus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_node.parent?.hasPrimaryFocus == true && widget.isFirstFocus) {
          _node.requestFocus();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: widget.autofocus,
      node: _node,
      onFocusChange: (value) async {
        if (value && _node.children.isNotEmpty) {
          final node =
              widget.indexOfChildWithFirstFocus != null && widget.indexOfChildWithFirstFocus! < _node.children.length
                  ? _node.children.elementAt(widget.indexOfChildWithFirstFocus!)
                  : _node.children.indexed.firstWhere(_checkFocusNode, orElse: () => (0, _node.children.first)).$2;
          if (_node.isFirstFocus) {
            if (_node.children.any((child) => child.hasFocus)) {
              _moveFocusToStartNode(node);
            } else {
              _node.autofocus(node);
            }
            _node.focused();
          } else if (widget.indexOfChildWithFirstFocus != null) {
            _moveFocusToStartNode(node);
          } else if (!widget.saveFocus) {
            _moveFocusToStartNode(node);
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
                  return widget.onBackTap?.call() == true ? KeyEventResult.handled : KeyEventResult.ignored;
                }
                if (event.logicalKey == LogicalKeyboardKey.select) {
                  return widget.onTap?.call() == true ? KeyEventResult.handled : KeyEventResult.ignored;
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
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.up);
      case LogicalKeyboardKey.arrowDown:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.down);
      case LogicalKeyboardKey.arrowLeft:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.left);
      case LogicalKeyboardKey.arrowRight:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.right);
      default:
        return false;
    }
  }

  bool _checkFocusNode((int i, FocusNode node) a) =>
      a.$2 is CustomNodeMixin && (a.$2 as CustomNodeMixin).isRequireFirstFocus;

  void _moveFocusToStartNode(FocusNode startNode) {
    final startIndex = widget.indexOfChildWithFirstFocus != null
        ? _node.children.indexed.elementAt(widget.indexOfChildWithFirstFocus!).$1
        : _node.children.indexed.firstWhere((node) => node.$2 == startNode).$1;
    final index = _node.children.indexed
        .firstWhere((element) => element.$2.hasFocus, orElse: () => _node.children.indexed.first)
        .$1;

    if (startIndex == index) {
      if (index > 0) {
        _node.previousFocus();
        _node.nextFocus();
      } else {
        _node.nextFocus();
        _node.previousFocus();
      }
      return;
    }

    for (int i = startIndex; i != index; startIndex > index ? i-- : i++) {
      startIndex > index ? _node.nextFocus() : _node.previousFocus();
    }
  }
}
