/// Constants for synchronization
class SyncConstants {
  // Oracle DB batch size limit (안정성을 위해 400으로 감소)
  static const int maxBatchSize = 400;
  
  // Timeout settings (안정성 강화: 더 긴 타임아웃)
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration requestTimeout = Duration(seconds: 60);
  static const Duration syncOperationTimeout = Duration(minutes: 10); // 전체 동기화 작업 타임아웃
  
  // Retry settings with exponential backoff (안정성 강화: 더 많은 재시도)
  static const int maxRetries = 5; // 3 → 5로 증가
  static const Duration baseRetryDelay = Duration(seconds: 2);
  static const double backoffMultiplier = 1.8; // 2.0 → 1.8로 감소 (더 빠른 재시도)
  
  // Sync settings (이벤트 기반 동기화)
  // 주기적 자동 동기화는 비활성화됨 - 이벤트 기반 동기화만 사용
  static const Duration autoSyncInterval = Duration(minutes: 30); // 사용하지 않음 (이벤트 기반만 사용)
  static const int maxQueueSize = 1000;
  
  // Progress update interval (milliseconds)
  static const int progressUpdateInterval = 100;
  
  // 이벤트 기반 동기화: 데이터 변경 시 debounce 시간 (너무 짧게 하면 서버 부하)
  static const Duration realtimeSyncDebounce = Duration(milliseconds: 500); // 0.5초 (적절한 debounce)
  
  // 이벤트 기반 동기화: 최소 동기화 간격 (너무 빠른 연속 동기화 방지, 서버 부하 최소화)
  static const Duration minSyncInterval = Duration(seconds: 5); // 최소 5초 간격 (적절한 간격)
  
  // 안정성 강화: 최대 재시도 지연 시간
  static const Duration maxRetryDelay = Duration(seconds: 30);
  
  // 안정성 강화: 데이터 검증 관련
  static const int maxDocumentSize = 1024 * 1024; // 1MB (문서 최대 크기)
  static const int maxBatchDocuments = 100; // 한 번에 처리할 최대 문서 수
}

/// Constants for recurring action generation
class RecurringActionConstants {
  // Maximum number of iterations (prevents infinite loop)
  static const int maxIterations = 365; // 1 year worth
}

/// Constants for Logbook
class LogbookConstants {
  // Number of items per Logbook page
  static const int pageLimit = 30;
  
  // Search debounce delay
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
  
  // Loading timeout
  static const Duration loadingTimeout = Duration(seconds: 10);
}
