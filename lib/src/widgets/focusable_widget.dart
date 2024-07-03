import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tv_focus/src/utils/extension.dart';

import '../utils/focus_helper.dart';
import 'index.dart';

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

  /// set this widget as focusable on first time when parent focus scope has primary focus
  final bool isFirstFocus;

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
    this.isFirstFocus = false,
    super.key,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> with SingleTickerProviderStateMixin {
  bool _isFocused = false;

  late final AnimationController _focusAnimationController;
  late final Animation<double> _animation;

  late final CustomFocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = CustomFocusNode(isFirstFocus: widget.isFirstFocus);

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
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
        return false;
      case LogicalKeyboardKey.arrowUp:
        return widget.onUpTap?.call();
      case LogicalKeyboardKey.arrowDown:
        return widget.onDownTap?.call();
      case LogicalKeyboardKey.arrowLeft:
        return widget.onLeftTap?.call();
      case LogicalKeyboardKey.arrowRight:
        return widget.onRightTap?.call();
      case LogicalKeyboardKey.goBack:
        return false;
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

  bool? _upKeyHandler(KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.open:
      case LogicalKeyboardKey.accept:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.open:
      case LogicalKeyboardKey.space:
        if (widget.onTap != null) {
          widget.onTap!();
        }
        return true;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        return true;
      case LogicalKeyboardKey.goBack:
        return widget.onBackTap?.call();
      default:
        return null;
    }
  }
}
