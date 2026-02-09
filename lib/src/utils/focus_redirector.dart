import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../widgets/index.dart';
import 'index.dart';

class CustomFocusRedirector {
  static final CustomFocusRedirector instance = CustomFocusRedirector._();
  CustomFocusRedirector._();

  bool _initialized = false;
  final Set<CustomFocusScopeNode> _activeScopes = {};
  final Set<Animation<double>> _observingAnimations = {};

  void registerScope(CustomFocusScopeNode node) {
    _activeScopes.add(node);
    _ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleFocusChange());
  }

  void unregisterScope(CustomFocusScopeNode node) {
    _activeScopes.remove(node);
    if (_activeScopes.isEmpty) {
      _dispose();
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      FocusManager.instance.addListener(_handleFocusChange);
      _initialized = true;
    }
  }

  void _dispose() {
    if (_initialized) {
      FocusManager.instance.removeListener(_handleFocusChange);
      _initialized = false;
    }
  }

  void _handleFocusChange() {
    if (WidgetsBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleFocusChange());
      return;
    }

    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) {
      return;
    }

    final primaryContext = primaryFocus.context;
    if (primaryContext != null) {
      final route = ModalRoute.of(primaryContext);
      final animation = route?.animation;
      final secondaryAnimation = route?.secondaryAnimation;

      final isAnimating = (animation != null &&
              (animation.status == AnimationStatus.forward || animation.status == AnimationStatus.reverse)) ||
          (secondaryAnimation != null &&
              (secondaryAnimation.status == AnimationStatus.forward ||
                  secondaryAnimation.status == AnimationStatus.reverse));

      if (route != null && isAnimating) {
        final activeAnim = (animation != null &&
                (animation.status == AnimationStatus.forward || animation.status == AnimationStatus.reverse))
            ? animation
            : secondaryAnimation;

        if (activeAnim != null && !_observingAnimations.contains(activeAnim)) {
          _observingAnimations.add(activeAnim);
          activeAnim.addStatusListener((status) {
            if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
              _observingAnimations.remove(activeAnim);
              _handleFocusChange();
            }
          });
        }
        return;
      }
    }

    CustomFocusScopeNode? scope =
        primaryFocus is CustomFocusScopeNode ? primaryFocus : FocusHelper.getFirstFocusCustomFocusScope();

    if (scope != null) {
      final context = scope.context;
      if (context != null) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          scope = null;
        } else if (!scope.isRequireFirstFocus && scope.isCustomChildrenRequireFocus) {
          if (scope.hasFocusableCustomChildren) {
            return;
          } else {
            scope = scope.parentCustomFocusScopeNode;
          }
        }
      }
    }

    if (scope == null) {
      for (final s in _activeScopes.toList().reversed) {
        final context = s.context;
        if (context == null) {
          continue;
        }

        final route = ModalRoute.of(context);
        if ((route?.isCurrent ?? false) && s.isRequireFirstFocus) {
          scope = s;
          break;
        }
      }
    }

    if (scope == null) {
      return;
    }
    _applyRedirect(scope);
  }

  void _applyRedirect(CustomFocusScopeNode node) {
    final context = node.context;
    if (context == null) {
      return;
    }

    final route = ModalRoute.of(context);
    if ((route?.isCurrent != true || node.isCustomFocused) && !node.isRequireFirstFocus && !node.hasPrimaryFocus) {
      return;
    }

    if (node.customChildren.isEmpty) {
      return;
    }

    try {
      final target = node.customChildren.elementAtOrNull(node.initialIndex) ??
          node.customChildren.firstWhere(
            (n) => n.isRequireFirstFocus,
            orElse: () => node.customChildren.first,
          );

      if (node.isRequireFirstFocus) {
        node.setIsRequireFirstFocus(false);
      }
      target.requestFocus();

      if (target is CustomFocusScopeNode) {
        target.setIsRequireFirstFocus(true);
      }
      if (target is CustomFocusScopeNode) {
        _applyRedirect(target);
      }
    } catch (e) {
      debugPrint('logger: CustomFocusRedirector: redirect failed for ${node.label}: $e');
    }
  }
}
