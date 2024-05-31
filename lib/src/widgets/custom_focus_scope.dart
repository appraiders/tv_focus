import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/remote_control_config.dart';
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

  final CustomFocusScopeNode node;

  CustomFocusScope({
    required this.child,
    required String label,
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
  }) : node = CustomFocusScopeNode(label: label);

  @override
  State<CustomFocusScope> createState() => _CustomFocusScopeState();
}

class _CustomFocusScopeState extends State<CustomFocusScope> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autofocus) {
        widget.node.autofocus(widget.node.children.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: widget.autofocus,
      node: widget.node,
      onFocusChange: (value) async {
        if (value) {
          if (!widget.saveFocus && !widget.node.children.first.hasFocus) {
            final index = widget.node.children.indexed.where((element) => element.$2.hasFocus).first.$1;
            for (int i = 0; i < index; i++) {
              widget.node.previousFocus();
            }
          }
        }
      },
      onKeyEvent: widget.onKeyEvent ??
          (node, event) {
            switch (event) {
              case KeyDownEvent _:
              case KeyRepeatEvent _:
                final result = _manualHandler(event);
                if (result != null) {
                  return result ? KeyEventResult.handled : KeyEventResult.ignored;
                }
                return KeyEventResult.ignored;
              case KeyUpEvent _:
                if (event.logicalKey.keyId == RemoteControlConfig.backKeyId) {
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
    switch (event.logicalKey.keyId) {
      case RemoteControlConfig.upKeyId:
        return widget.onUpTap?.call();
      case RemoteControlConfig.downKeyId:
        return widget.onDownTap?.call();
      case RemoteControlConfig.leftKeyId:
        return widget.onLeftTap?.call();
      case RemoteControlConfig.rightKeyId:
        return widget.onRightTap?.call();
      case RemoteControlConfig.backKeyId:
        return false;
      default:
        return null;
    }
  }
}
