/// Extension for List to provide null-safe firstWhere
extension ListExtensions<T> on List<T> {
  /// Returns the first element that satisfies the given predicate [test].
  /// Returns null if no element satisfies [test].
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
