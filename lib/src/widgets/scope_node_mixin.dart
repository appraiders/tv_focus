mixin CustomScopeMixin {
  bool _firstFocus = true;

  bool get isFirstFocus {
    return _firstFocus;
  }

  void focused() {
    _firstFocus = false;
  }
}
