import 'dart:developer' as dev;
import 'package:gtdoro/features/todo/providers/sync_provider.dart'; // SyncProvider는 features에 남김 (다른 provider들과의 의존성 때문)

/// Common mixin for sync trigger functionality
mixin SyncTriggerMixin {
  SyncProvider? get syncProvider;

  /// Trigger sync if syncProvider is set and sync is available
  /// 실시간 동기화: 데이터 변경 시 즉시 동기화 트리거 (0.5초 debounce)
  void triggerSyncIfAvailable() {
    final sync = syncProvider;
    if (sync != null && sync.canSync) {
      dev.log('$runtimeType: Data change detected, requesting realtime sync...');
      sync.triggerImmediateSync(); // 실시간 동기화 (0.5초 debounce)
    }
  }
}
