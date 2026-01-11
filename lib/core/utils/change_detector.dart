/// 변경 감지 유틸리티
/// 리스트의 변경사항을 효율적으로 감지하는 헬퍼 함수들
class ChangeDetector {
  /// Action 리스트 변경 감지
  /// Action의 id, updatedAt, isDeleted, isDone 필드를 비교
  static bool hasActionListChanged<T>(
    List<T> oldList,
    List<T> newList,
    String Function(T) getId,
    DateTime? Function(T) getUpdatedAt,
    bool Function(T) getIsDeleted,
    {bool Function(T)? getIsDone,}
  ) {
    if (oldList.length != newList.length) {
      return true;
    }

    if (oldList.isEmpty) {
      return false;
    }

    // 빠른 비교: 첫 번째와 마지막 항목만 확인 (대부분의 경우 충분)
    final firstChanged = getId(oldList.first) != getId(newList.first) ||
        getUpdatedAt(oldList.first)?.millisecondsSinceEpoch !=
            getUpdatedAt(newList.first)?.millisecondsSinceEpoch ||
        getIsDeleted(oldList.first) != getIsDeleted(newList.first) ||
        (getIsDone != null && getIsDone(oldList.first) != getIsDone(newList.first));

    final lastChanged = getId(oldList.last) != getId(newList.last) ||
        getUpdatedAt(oldList.last)?.millisecondsSinceEpoch !=
            getUpdatedAt(newList.last)?.millisecondsSinceEpoch ||
        getIsDeleted(oldList.last) != getIsDeleted(newList.last) ||
        (getIsDone != null && getIsDone(oldList.last) != getIsDone(newList.last));

    if (firstChanged || lastChanged) {
      return true;
    }

    // 전체 비교 (드물게만 실행)
    for (int i = 0; i < oldList.length; i++) {
      final old = oldList[i];
      final new_ = newList[i];
      if (getId(old) != getId(new_) ||
          getUpdatedAt(old)?.millisecondsSinceEpoch !=
              getUpdatedAt(new_)?.millisecondsSinceEpoch ||
          getIsDeleted(old) != getIsDeleted(new_) ||
          (getIsDone != null && getIsDone(old) != getIsDone(new_))) {
        return true;
      }
    }

    return false;
  }

  /// Context 리스트 변경 감지
  /// Context의 id, updatedAt 필드를 비교
  static bool hasContextListChanged<T>(
    List<T> oldList,
    List<T> newList,
    String Function(T) getId,
    DateTime? Function(T) getUpdatedAt,
  ) {
    if (oldList.length != newList.length) {
      return true;
    }

    if (oldList.isEmpty) {
      return false;
    }

    // 빠른 비교: 첫 번째와 마지막 항목만 확인
    final firstChanged = getId(oldList.first) != getId(newList.first) ||
        getUpdatedAt(oldList.first)?.millisecondsSinceEpoch !=
            getUpdatedAt(newList.first)?.millisecondsSinceEpoch;

    final lastChanged = getId(oldList.last) != getId(newList.last) ||
        getUpdatedAt(oldList.last)?.millisecondsSinceEpoch !=
            getUpdatedAt(newList.last)?.millisecondsSinceEpoch;

    if (firstChanged || lastChanged) {
      return true;
    }

    // 전체 비교 (드물게만 실행)
    for (int i = 0; i < oldList.length; i++) {
      final old = oldList[i];
      final new_ = newList[i];
      if (getId(old) != getId(new_) ||
          getUpdatedAt(old)?.millisecondsSinceEpoch !=
              getUpdatedAt(new_)?.millisecondsSinceEpoch) {
        return true;
      }
    }

    return false;
  }

  /// RecurringAction 리스트 변경 감지
  /// RecurringAction의 id, updatedAt, currentCount, nextRunDate 필드를 비교
  static bool hasRecurringActionListChanged<T>(
    List<T> oldList,
    List<T> newList,
    String Function(T) getId,
    DateTime? Function(T) getUpdatedAt,
    int Function(T) getCurrentCount,
    DateTime Function(T) getNextRunDate,
  ) {
    if (oldList.length != newList.length) {
      return true;
    }

    if (oldList.isEmpty) {
      return false;
    }

    // 빠른 비교: 첫 번째와 마지막 항목만 확인
    final firstChanged = getId(oldList.first) != getId(newList.first) ||
        getUpdatedAt(oldList.first)?.millisecondsSinceEpoch !=
            getUpdatedAt(newList.first)?.millisecondsSinceEpoch ||
        getCurrentCount(oldList.first) != getCurrentCount(newList.first) ||
        getNextRunDate(oldList.first).millisecondsSinceEpoch !=
            getNextRunDate(newList.first).millisecondsSinceEpoch;

    final lastChanged = getId(oldList.last) != getId(newList.last) ||
        getUpdatedAt(oldList.last)?.millisecondsSinceEpoch !=
            getUpdatedAt(newList.last)?.millisecondsSinceEpoch ||
        getCurrentCount(oldList.last) != getCurrentCount(newList.last) ||
        getNextRunDate(oldList.last).millisecondsSinceEpoch !=
            getNextRunDate(newList.last).millisecondsSinceEpoch;

    if (firstChanged || lastChanged) {
      return true;
    }

    // 전체 비교 (드물게만 실행)
    for (int i = 0; i < oldList.length; i++) {
      final old = oldList[i];
      final new_ = newList[i];
      if (getId(old) != getId(new_) ||
          getUpdatedAt(old)?.millisecondsSinceEpoch !=
              getUpdatedAt(new_)?.millisecondsSinceEpoch ||
          getCurrentCount(old) != getCurrentCount(new_) ||
          getNextRunDate(old).millisecondsSinceEpoch !=
              getNextRunDate(new_).millisecondsSinceEpoch) {
        return true;
      }
    }

    return false;
  }
}
