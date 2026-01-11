import 'dart:developer' as dev;

/// Oracle 동기화 성능 모니터링
class OraclePerformanceMonitor {
  static final OraclePerformanceMonitor _instance = OraclePerformanceMonitor._internal();
  factory OraclePerformanceMonitor() => _instance;
  OraclePerformanceMonitor._internal();

  // 성능 메트릭 저장
  final List<SyncMetric> _metrics = [];
  static const int _maxMetrics = 100; // 최대 저장 메트릭 수

  /// 동기화 시작
  DateTime? startSync(String operation) {
    final startTime = DateTime.now();
    dev.log('OraclePerformanceMonitor: Started $operation at $startTime');
    return startTime;
  }

  /// 동기화 완료 및 메트릭 기록
  void endSync(String operation, DateTime startTime, {
    int? itemsProcessed,
    int? itemsUploaded,
    int? itemsDownloaded,
    String? error,
  }) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    final metric = SyncMetric(
      operation: operation,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      itemsProcessed: itemsProcessed,
      itemsUploaded: itemsUploaded,
      itemsDownloaded: itemsDownloaded,
      error: error,
    );
    
    _addMetric(metric);
    
    dev.log('OraclePerformanceMonitor: Completed $operation in ${duration.inMilliseconds}ms');
    if (itemsProcessed != null) {
      dev.log('OraclePerformanceMonitor: Processed $itemsProcessed items');
    }
    if (error != null) {
      dev.log('OraclePerformanceMonitor: Error: $error');
    }
  }

  /// 네트워크 요청 기록
  void recordRequest(String operation, Duration duration, {
    bool success = true,
    int? statusCode,
    int? responseSize,
    String? error,
  }) {
    final metric = SyncMetric(
      operation: 'request_$operation',
      startTime: DateTime.now().subtract(duration),
      endTime: DateTime.now(),
      duration: duration,
      statusCode: statusCode,
      responseSize: responseSize,
      error: error ?? (success ? null : 'Request failed'),
    );
    
    _addMetric(metric);
  }

  /// 메트릭 추가
  void _addMetric(SyncMetric metric) {
    _metrics.add(metric);
    
    // 최대 개수 초과 시 오래된 메트릭 제거
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  /// 최근 메트릭 가져오기
  List<SyncMetric> getRecentMetrics({int? limit}) {
    final sorted = List<SyncMetric>.from(_metrics)
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
    
    if (limit != null && limit > 0) {
      return sorted.take(limit).toList();
    }
    return sorted;
  }

  /// 평균 동기화 시간 계산
  Duration? getAverageSyncDuration(String operation) {
    final operationMetrics = _metrics
        .where((m) => m.operation == operation && m.error == null)
        .toList();
    
    if (operationMetrics.isEmpty) return null;
    
    final totalMs = operationMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ operationMetrics.length);
  }

  /// 성공률 계산
  double getSuccessRate(String operation) {
    final operationMetrics = _metrics
        .where((m) => m.operation == operation)
        .toList();
    
    if (operationMetrics.isEmpty) return 0.0;
    
    final successCount = operationMetrics
        .where((m) => m.error == null)
        .length;
    
    return successCount / operationMetrics.length;
  }

  /// 처리량 계산 (items/second)
  double? getThroughput(String operation) {
    final operationMetrics = _metrics
        .where((m) => m.operation == operation && 
                     m.error == null && 
                     m.itemsProcessed != null)
        .toList();
    
    if (operationMetrics.isEmpty) return null;
    
    int totalItems = 0;
    int totalMs = 0;
    
    for (final metric in operationMetrics) {
      totalItems += metric.itemsProcessed ?? 0;
      totalMs += metric.duration.inMilliseconds;
    }
    
    if (totalMs == 0) return null;
    
    return (totalItems * 1000) / totalMs;
  }

  /// 통계 요약
  Map<String, dynamic> getStatistics() {
    final allMetrics = _metrics.where((m) => m.error == null).toList();
    
    if (allMetrics.isEmpty) {
      return {
        'total_operations': 0,
        'average_duration_ms': 0,
        'total_items_processed': 0,
      };
    }
    
    final totalDuration = allMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    final totalItems = allMetrics
        .map((m) => m.itemsProcessed ?? 0)
        .reduce((a, b) => a + b);
    
    return {
      'total_operations': allMetrics.length,
      'average_duration_ms': totalDuration ~/ allMetrics.length,
      'total_items_processed': totalItems,
      'upload_operations': _metrics.where((m) => m.operation.contains('upload')).length,
      'download_operations': _metrics.where((m) => m.operation.contains('download')).length,
      'average_upload_duration_ms': getAverageSyncDuration('upload')?.inMilliseconds,
      'average_download_duration_ms': getAverageSyncDuration('download')?.inMilliseconds,
      'upload_throughput': getThroughput('upload'),
      'download_throughput': getThroughput('download'),
    };
  }

  /// 메트릭 초기화
  void clearMetrics() {
    _metrics.clear();
    dev.log('OraclePerformanceMonitor: Cleared all metrics');
  }

  /// 특정 작업의 메트릭만 초기화
  void clearMetricsForOperation(String operation) {
    _metrics.removeWhere((m) => m.operation == operation);
    dev.log('OraclePerformanceMonitor: Cleared metrics for $operation');
  }
}

/// 동기화 메트릭 데이터 클래스
class SyncMetric {
  final String operation;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int? itemsProcessed;
  final int? itemsUploaded;
  final int? itemsDownloaded;
  final String? error;
  final int? statusCode;
  final int? responseSize;

  SyncMetric({
    required this.operation,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.itemsProcessed,
    this.itemsUploaded,
    this.itemsDownloaded,
    this.error,
    this.statusCode,
    this.responseSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration_ms': duration.inMilliseconds,
      'itemsProcessed': itemsProcessed,
      'itemsUploaded': itemsUploaded,
      'itemsDownloaded': itemsDownloaded,
      'error': error,
      'statusCode': statusCode,
      'responseSize': responseSize,
    };
  }
}
