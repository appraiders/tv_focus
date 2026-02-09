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
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final String label;

  final int initialIndex;

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
    this.initialIndex = 0,
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
      label: widget.label,
      debugLabel: widget.label,
      initialIndex: widget.initialIndex,
    );
    CustomFocusRedirector.instance.registerScope(_node);
  }

  @override
  void dispose() {
    CustomFocusRedirector.instance.unregisterScope(_node);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _node,
      onFocusChange: (value) {
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
}
