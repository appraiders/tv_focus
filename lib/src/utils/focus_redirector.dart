import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../widgets/index.dart';
import 'index.dart';

class CustomFocusRedirector {
  static final CustomFocusRedirector instance = CustomFocusRedirector._();
  CustomFocusRedirector._();

  bool _initialized = false;
  final Set<CustomFocusScopeNode> _activeScopes = {};
  bool _navigationSettledCallbackScheduled = false;

  NavigatorObserver createNavigatorObserver() {
    return _FocusNavigationObserver(_scheduleFocusCheckAfterNavigation);
  }

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
    _navigationSettledCallbackScheduled = false;
  }

  void _handleFocusChange() {
    final primaryFocus = FocusManager.instance.primaryFocus;

    CustomFocusScopeNode? scope = primaryFocus is CustomFocusScopeNode
        ? primaryFocus
        : FocusHelper.getFirstFocusCustomFocusScope() ??
            primaryFocus?.childrenCustomFocusNode.whereType<CustomFocusScopeNode>().firstOrNull;

    /// Проверка что выбранный элемент находится на активной странице
    /// Если нет, то поднимаемся по иерархии фокуса вверх, чтобы найти первый CustomFocusScopeNode на активной странице
    if (scope?.context != null && ModalRoute.of(scope!.context!)?.isCurrent == false) {
      CustomFocusScopeNode? node = primaryFocus?.parentCustomFocusScopeNode;
      while (node != null) {
        if (node.hasFocus &&
            node.hasFocusableCustomChildren &&
            node.context != null &&
            ModalRoute.of(node.context!)?.isCurrent == true) {
          scope = node;
          break;
        }
        node = node.parentCustomFocusScopeNode;
      }
    }

    if (scope == null) {
      if (primaryFocus is FocusScopeNode && primaryFocus is! CustomFocusScopeNode) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleFocusChange());
      }
      return;
    }

    if (scope.isRequireFirstFocus) {
      _applyRedirect(scope);
    } else {
      try {
        final customChildren = scope.customChildren;
        final focusableCustomChildren = customChildren.where((node) => node.canRequestFocus);
        if (focusableCustomChildren.length == 1) {
          final node = focusableCustomChildren.first;
          if (node is CustomFocusScopeNode) {
            _applyRedirect(node);
          } else {
            node.requestFocus();
          }
          return;
        }
        if (customChildren.length > scope.initialIndex) {
          final node = scope.customChildren.elementAt(scope.initialIndex);
          if (node is CustomFocusScopeNode) {
            _applyRedirect(node);
          } else {
            node.requestFocus();
          }
        } else {
          if (scope.customChildren.isEmpty) {
            return;
          }
          final allRequireFirstFocus = scope.customChildren.every((node) => node.isRequireFirstFocus);
          if (!allRequireFirstFocus) {
            return;
          }
          final node = scope.customChildren.firstWhere(
            (node) => node.isRequireFirstFocus,
            orElse: () => scope!.customChildren
                .firstWhere((node) => node.canRequestFocus, orElse: () => scope!.customChildren.first),
          );
          if (node is CustomFocusScopeNode) {
            _applyRedirect(node);
          } else {
            node.requestFocus();
          }
        }
      } catch (e) {
        debugPrint('handle focus change: no children require first focus in scope ${scope.label}');
      }
    }
  }

  void _scheduleFocusCheckAfterNavigation() {
    if (_navigationSettledCallbackScheduled) {
      return;
    }
    _navigationSettledCallbackScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.endOfFrame.then((_) {
        _navigationSettledCallbackScheduled = false;
        _handleFocusChange();
      });
    });
  }

  void _applyRedirect(CustomFocusScopeNode node) {
    node.requestScopeFocus();
    try {
      final target = node.isRequireFirstFocus
          ? node.customChildren.elementAtOrNull(node.initialIndex) ??
              node.customChildren.firstWhere(
                (n) => n.isRequireFirstFocus,
                orElse: () => node.customChildren.first,
              )
          : null;

      if (target == null) {
        node.requestFocus();
        return;
      }

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
      debugPrint('CustomFocusRedirector: redirect failed for ${node.label}: $e');
    }
  }
}

class _FocusNavigationObserver extends NavigatorObserver {
  _FocusNavigationObserver(this._onNavigationChanged);

  final VoidCallback _onNavigationChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onNavigationChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onNavigationChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _onNavigationChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onNavigationChanged();
  }

  @override
  void didStopUserGesture() {
    _onNavigationChanged();
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _onNavigationChanged();
  }
}
