import 'package:flutter/widgets.dart';

import '../widgets/custom_focus_scope_node.dart';

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
  CustomFocusScopeNode? get parentCustomFocusScopeNode {
    try {
      return parent is CustomFocusScopeNode ? parent as CustomFocusScopeNode : parent!.parentCustomFocusScopeNode;
    } catch (e) {
      return null;
    }
  }

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

  ///Getting list of parents [FocusScopeNode]
  List<CustomFocusScopeNode> get parentScopeNodes {
    if (parentCustomFocusScopeNode != null) {
      return [...parent!.parentScopeNodes, parentCustomFocusScopeNode!];
    } else {
      return [];
    }
  }
}
