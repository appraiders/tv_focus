import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/index.dart';
import 'custom_focus_scope_node.dart';
import 'types.dart';

class CustomFocusScope extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool>? onFocusChange;
  final FWidgetTapped? onUpTap;
  final FWidgetTapped? onDownTap;
  final FWidgetTapped? onLeftTap;
  final FWidgetTapped? onRightTap;
  final FWidgetTapped? onBackTap;
  final bool saveFocus;
  final bool autofocus;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final String label;

  const CustomFocusScope({
    required this.child,
    required this.label,
    this.onFocusChange,
    this.onUpTap,
    this.onDownTap,
    this.onLeftTap,
    this.onRightTap,
    this.onBackTap,
    this.saveFocus = true,
    this.autofocus = false,
    this.onKeyEvent,
    super.key,
  });

  @override
  State<CustomFocusScope> createState() => _CustomFocusScopeState();
}

class _CustomFocusScopeState extends State<CustomFocusScope> {
  late final CustomFocusScopeNode node;

  @override
  void initState() {
    super.initState();

    node = CustomFocusScopeNode(label: widget.label);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autofocus) {
        node.autofocus(node.children.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: widget.autofocus,
      node: node,
      onFocusChange: (value) async {
        if (value) {
          if (!widget.saveFocus) {
            final index = node.children.indexed.where((element) => element.$2.hasFocus).first.$1;
            for (int i = 0; i < index; i++) {
              node.previousFocus();
            }
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.children.where((element) => element.hasFocus).isEmpty) {
                node.children.first.requestFocus();
              }
            });
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
