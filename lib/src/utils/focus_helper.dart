import 'package:flutter/material.dart';
import 'package:tv_focus/src/utils/extension.dart';

import '../widgets/index.dart';

abstract class FocusHelper {
  ///Get parent CustorFocusScope with [label]
  static CustomFocusScopeNode getCustomFocusScope(String label) {
    try {
      return FocusManager.instance.primaryFocus!.labeledFocusScopeNode(label);
    } catch (e, stackTrace) {
      throw '$e $stackTrace';
    }
  }

  ///Move focus to first [FocusableWidget] on CustorFocusScope with [label]
  static bool moveToFirst(String label) {
    final node = getCustomFocusScope(label);

    // necessary for a situation where the condition for completing the transition of focus to the first child of FocusScope is not met
    int i = 1000;

    while (node.children.first != node.focusedChild && i > 0) {
      node.previousFocus();
      i--;
    }

    if (i != 0) {
      return true;
    } else {
      throw 'failed to move to first element';
    }
  }

  ///Move focus to last [FocusableWidget] on CustorFocusScope with [label]
  static bool moveToLast(String label) {
    final node = getCustomFocusScope(label);

    // necessary for a situation where the condition for completing the transition of focus to the last child of FocusScope is not met
    int i = 1000;

    while (node.children.last != node.focusedChild && i > 0) {
      node.nextFocus();
      i--;
    }

    if (i != 0) {
      return true;
    } else {
      throw 'failed to move to last element';
    }
  }

  ///Move focus to [node]
  static bool getFocus(FocusNode node) {
    //Get the node of current active [FocusScope]
    final scopeNode = FocusManager.instance.primaryFocus?.parentCustomFocusScopeNode;

    if (scopeNode == null) {
      throw 'Не удалось найти FocusScopeNode';
    }

    return _updateFocus(scopeNode, node);
  }

  ///Move focus from active [scopeNode] to [node].
  ///
  ///If moving between [CustomFocusScope] is not required, then get indices of current focus node and [node].
  ///Movement occurs along all intermediate nodes, so that during further navigation with remote control there is no obvious movement of focus
  ///
  ///If need to move focus from one [CustomFocusScope] to another, then create a path from [CustomFocusScopeNode]
  /// for the start and end focus nodes.
  static bool _updateFocus(CustomFocusScopeNode scopeNode, FocusNode node) {
    if (scopeNode.children.any((element) => element == node)) {
      final list = scopeNode.children.toList();
      final focusIndex = list.indexWhere((element) => element == scopeNode.focusedChild);
      final nodeIndex = list.indexOf(node);

      if (focusIndex > nodeIndex) {
        for (int i = focusIndex; i > nodeIndex; i--) {
          scopeNode.previousFocus();
        }
      } else if (focusIndex < nodeIndex) {
        for (int i = focusIndex; i < nodeIndex; i++) {
          scopeNode.nextFocus();
        }
      }

      return true;
    } else {
      final currentNodes = [...scopeNode.parentScopeNodes, scopeNode];
      final newNodes = node.parentScopeNodes;

      for (int i = 0; i < newNodes.length; i++) {
        if (currentNodes.length <= i || currentNodes[i] != newNodes[i]) {
          _updateScopeFocus(newNodes[i]);
        }
      }

      return _updateFocus(newNodes.last, node);
    }
  }


  ///Move focus to CustomFocusScopeNode from [node]
  static bool _updateScopeFocus(CustomFocusScopeNode node) {
    final scopeNode = node.parentCustomFocusScopeNode;

    final list = scopeNode!.children.toList();

    final focusIndex = list.indexWhere((element) => element.hasFocus);
    final nodeIndex = list.indexOf(node);

    if (focusIndex > nodeIndex) {
      for (int i = focusIndex; i > nodeIndex; i--) {
        scopeNode.previousFocus();
      }
    } else if (focusIndex < nodeIndex) {
      for (int i = focusIndex; i < nodeIndex; i++) {
        scopeNode.nextFocus();
      }
    }

    return true;
  }
}
