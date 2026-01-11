/// 동기화 통계 모델
class SyncStatistics {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastFailedSync;
  final String? lastError;
  final int totalItemsUploaded;
  final int totalItemsDownloaded;
  final Duration? averageSyncDuration;

  SyncStatistics({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.failedSyncs,
    this.lastSuccessfulSync,
    this.lastFailedSync,
    this.lastError,
    this.totalItemsUploaded = 0,
    this.totalItemsDownloaded = 0,
    this.averageSyncDuration,
  });

  double get successRate => totalSyncs > 0 ? successfulSyncs / totalSyncs : 0.0;

  SyncStatistics copyWith({
    int? totalSyncs,
    int? successfulSyncs,
    int? failedSyncs,
    DateTime? lastSuccessfulSync,
    DateTime? lastFailedSync,
    String? lastError,
    int? totalItemsUploaded,
    int? totalItemsDownloaded,
    Duration? averageSyncDuration,
  }) {
    return SyncStatistics(
      totalSyncs: totalSyncs ?? this.totalSyncs,
      successfulSyncs: successfulSyncs ?? this.successfulSyncs,
      failedSyncs: failedSyncs ?? this.failedSyncs,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      lastFailedSync: lastFailedSync ?? this.lastFailedSync,
      lastError: lastError ?? this.lastError,
      totalItemsUploaded: totalItemsUploaded ?? this.totalItemsUploaded,
      totalItemsDownloaded: totalItemsDownloaded ?? this.totalItemsDownloaded,
      averageSyncDuration: averageSyncDuration ?? this.averageSyncDuration,
    );
  }
}
