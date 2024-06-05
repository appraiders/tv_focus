import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tv_focus/src/utils/extension.dart';

import '../utils/focus_helper.dart';
import '../utils/remote_control_config.dart';
import 'types.dart';

class FocusableWidget extends StatefulWidget {
  final FWidgetBuilder builder;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onTap;
  final FWidgetTapped? onUpTap;
  final FWidgetTapped? onDownTap;
  final FWidgetTapped? onLeftTap;
  final FWidgetTapped? onRightTap;
  final FWidgetTapped? onBackTap;
  final FocusNode? parentFocusNode;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  const FocusableWidget({
    required this.builder,
    this.onFocusChange,
    this.parentFocusNode,
    this.onKeyEvent,
    this.onTap,
    this.onUpTap,
    this.onDownTap,
    this.onLeftTap,
    this.onRightTap,
    this.onBackTap,
    super.key,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> with SingleTickerProviderStateMixin {
  bool _isFocused = false;

  late AnimationController _focusAnimationController;
  late Animation<double> _animation;

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.01),
      child: GestureDetector(
        onTap: () {
          FocusHelper.getFocus(_focusNode);
          widget.onTap?.call();
        },
        child: Focus(
          focusNode: _focusNode,
          parentNode: widget.parentFocusNode,
          onFocusChange: (value) {
            widget.onFocusChange?.call(value);
            setState(() {
              _isFocused = value;
            });
            if (_isFocused) {
              _focusAnimationController.forward();
            } else {
              _focusAnimationController.reverse();
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
                    if (_focusNavigationHandler(node, event)) {
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  case KeyUpEvent _:
                    return _upKeyHandler(event) == true ? KeyEventResult.handled : KeyEventResult.ignored;
                  default:
                    return KeyEventResult.ignored;
                }
              },
          child: AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              return widget.builder(
                context,
                _isFocused,
                _focusAnimationController,
              );
            },
          ),
        ),
      ),
    );
  }

  bool? _manualHandler(KeyEvent event) {
    switch (event.logicalKey.keyId) {
      case RemoteControlConfig.selectKeyId:
        return false;
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

  bool _focusNavigationHandler(FocusNode node, KeyEvent event) {
    switch (event.logicalKey.keyId) {
      case RemoteControlConfig.upKeyId:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.up);
      case RemoteControlConfig.downKeyId:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.down);
      case RemoteControlConfig.leftKeyId:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.left);
      case RemoteControlConfig.rightKeyId:
        return node.parentFocusScopeNode.focusInDirection(TraversalDirection.right);
      default:
        return false;
    }
  }

  bool? _upKeyHandler(KeyEvent event) {
    switch (event.logicalKey.keyId) {
      case RemoteControlConfig.selectKeyId:
        if (widget.onTap != null) {
          widget.onTap!();
        }
        return true;
      case RemoteControlConfig.upKeyId:
      case RemoteControlConfig.downKeyId:
      case RemoteControlConfig.leftKeyId:
      case RemoteControlConfig.rightKeyId:
        return true;
      case RemoteControlConfig.backKeyId:
        return widget.onBackTap?.call();
      default:
        return null;
    }
  }
}
