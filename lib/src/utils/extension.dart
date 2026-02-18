import 'package:flutter/widgets.dart';

import '../widgets/custom_node.dart';

extension FocusScopeNodeAdapter on FocusNode {
  ///Getting parent [FocusScopeNode]
  FocusScopeNode get parentFocusScopeNode {
    try {
      return parent is FocusScopeNode ? parent as FocusScopeNode : parent!.parentFocusScopeNode;
    } catch (e) {
      throw 'Parent focus scope not found';
    }
  }

  ///Getting parent [CustomFocusScopeNode]
  CustomFocusScopeNode? get parentCustomFocusScopeNode =>
      parent is CustomFocusScopeNode ? parent as CustomFocusScopeNode : parent?.parentCustomFocusScopeNode;

  ///Getting parent [CustomFocusScopeNode] with [label]
  CustomFocusScopeNode labeledFocusScopeNode(String label) {
    try {
      return (parent is CustomFocusScopeNode && (parent as CustomFocusScopeNode).label == label)
          ? parent as CustomFocusScopeNode
          : parent!.labeledFocusScopeNode(label);
    } catch (e) {
      throw 'Label «$label» not found on parents of current focus node\nUse «hasLabeledFocusScopeNode» before call «labeledFocusScopeNode»';
    }
  }

  bool hasLabeledFocusScopeNode(String label) {
    try {
      return (parent is CustomFocusScopeNode && (parent as CustomFocusScopeNode).label == label)
          ? true
          : parent!.hasLabeledFocusScopeNode(label);
    } catch (e) {
      return false;
    }
  }

  ///Finding [CustomFocusScopeNode] with [label] in all focus tree
  CustomFocusScopeNode? findCustomFocusScopeNode(String label) {
    if (this is CustomFocusScopeNode && (this as CustomFocusScopeNode).label == label) {
      return this as CustomFocusScopeNode;
    }

    for (final child in children) {
      final node = child.findCustomFocusScopeNode(label);
      if (node != null) {
        return node;
      }
    }
    return null;
  }

  ///Getting list of parents [FocusScopeNode]
  List<CustomFocusScopeNode> get parentScopeNodes {
    if (parentCustomFocusScopeNode != null) {
      return [...parent!.parentScopeNodes, parentCustomFocusScopeNode!];
    } else {
      return [];
    }
  }

  ///Getting child [FocusScopeNode]
  List<CustomNode> get childrenCustomFocusNode {
    try {
      if (this is CustomNode) {
        return [this as CustomNode];
      }
      if (children.isEmpty) {
        return [];
      }
      return children.map((child) => child.childrenCustomFocusNode).expand((element) => element).toList();
    } catch (e) {
      throw 'Child CustomFocusNode not found';
    }
  }
}
