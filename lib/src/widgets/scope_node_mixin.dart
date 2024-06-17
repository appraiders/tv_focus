mixin CustomScopeMixin {
  bool firstFocused = true;

  bool get isFirstFocused {
    if (firstFocused) {
      firstFocused = false;
      return true;
    }
    return false;
  }
}
