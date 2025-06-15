import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tv_focus/src/utils/extension.dart'; 

import '../utils/focus_helper.dart';
import 'index.dart';

class FocusableWidget extends StatefulWidget {
  final FWidgetBuilder builder;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final FWidgetTapped? onUpTap;
  final FWidgetTapped? onDownTap;
  final FWidgetTapped? onLeftTap;
  final FWidgetTapped? onRightTap;
  final FWidgetTapped? onBackTap;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  /// set this widget as focusable on first time when parent focus scope has primary focus
  final bool isFirstFocus;
  final bool autofocus;
  
  /// Enable long press animation (similar to LongPressAnimation widget)
  final bool enableLongPressAnimation;
  
  /// Duration for long press animation
  final Duration longPressAnimationDuration;
  

  const FocusableWidget({
    required this.builder,
    this.onFocusChange,
    this.onKeyEvent,
    this.onTap,
    this.onLongTap,
    this.onUpTap,
    this.onDownTap,
    this.onLeftTap,
    this.onRightTap,
    this.onBackTap,
    this.isFirstFocus = false,
    this.autofocus = false,
    this.enableLongPressAnimation = false,
    this.longPressAnimationDuration = const Duration(milliseconds: 500),
    
    super.key,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> with TickerProviderStateMixin {
  bool _isFocused = false;

  late final AnimationController _focusAnimationController;
  late final Animation<double> _focusAnimation;

  // Long press animation controllers
  late final AnimationController _longPressAnimationController;
  late final Animation<double> _scaleAnimation;

  late final CustomFocusNode _focusNode;

  // Long press state tracking
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();

    _focusNode = CustomFocusNode(
      isFirstFocus: widget.isFirstFocus,
    );

    // Focus animation controller
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _focusAnimation = CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeIn,
    );

    // Long press animation controller
    _longPressAnimationController = AnimationController(
      duration: widget.longPressAnimationDuration,
      vsync: this,
    );

    _longPressAnimationController.addStatusListener(_onLongPressAnimationStatusChange);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _longPressAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autofocus) {
        _focusNode.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_focusNode.hasPrimaryFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    _longPressAnimationController.dispose();
    super.dispose();
  }

  void _onLongPressAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isLongPressing) {
      // Trigger long press callback
      widget.onLongTap?.call();
      
    
      
      // Reverse the animation
      _longPressAnimationController.reverse();
      _isLongPressing = false;
    }
  }

  void _startLongPress() {
    if (widget.enableLongPressAnimation && widget.onLongTap != null) {
      _isLongPressing = true;
      _longPressAnimationController.forward();
    }
  }

  void _cancelLongPress() {
    if (_isLongPressing) {
      _isLongPressing = false;
      _longPressAnimationController.reverse();
    }
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
        onTapDown: widget.enableLongPressAnimation ? (_) => _startLongPress() : null,
        onTapUp: widget.enableLongPressAnimation ? (_) => _cancelLongPress() : null,
        onTapCancel: widget.enableLongPressAnimation ? _cancelLongPress : null,
        onLongPress: widget.enableLongPressAnimation ? null : widget.onLongTap,
        child: Focus(
          autofocus: widget.autofocus,
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
            animation: Listenable.merge([_focusAnimation, _scaleAnimation]),
            builder: (_, __) {
              Widget child = widget.builder(
                context,
                _isFocused,
                _focusAnimationController,
              );

              // Apply scale animation if long press animation is enabled
              if (widget.enableLongPressAnimation) {
                child = Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              }

              return child;
            },
          ),
        ),
      ),
    );
  }

  bool? _manualHandler(KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
        if (event is KeyDownEvent && widget.enableLongPressAnimation) {
          _startLongPress();
          return true;
        } else if (event is KeyRepeatEvent && widget.onLongTap != null) {
          if (widget.enableLongPressAnimation) {
            // Long press animation handles this
            return true;
          } else {
            widget.onLongTap?.call();
            return true;
          }
        } else if (event is KeyUpEvent && widget.enableLongPressAnimation) {
          _cancelLongPress();
          return true;
        }
        return false;
      case LogicalKeyboardKey.arrowUp:
        if (event is KeyUpEvent && widget.enableLongPressAnimation) {
          _cancelLongPress();
        }
        return widget.onUpTap?.call();
      case LogicalKeyboardKey.arrowDown:
        if (event is KeyUpEvent && widget.enableLongPressAnimation) {
          _cancelLongPress();
        }
        return widget.onDownTap?.call();
      case LogicalKeyboardKey.arrowLeft:
        if (event is KeyUpEvent && widget.enableLongPressAnimation) {
          _cancelLongPress();
        }
        return widget.onLeftTap?.call();
      case LogicalKeyboardKey.arrowRight:
        if (event is KeyUpEvent && widget.enableLongPressAnimation) {
          _cancelLongPress();
        }
        return widget.onRightTap?.call();
      case LogicalKeyboardKey.goBack:
        if (event is KeyUpEvent && widget.enableLongPressAnimation) {
          _cancelLongPress();
        }
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
      case LogicalKeyboardKey.space:
        if (widget.enableLongPressAnimation) {
          _cancelLongPress();
        }
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
