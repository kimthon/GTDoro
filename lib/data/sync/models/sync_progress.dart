/// 동기화 진행률 모델
class SyncProgress {
  final int totalItems;
  final int processedItems;
  final String currentStep;
  final bool isUpload;
  final DateTime? startTime;

  SyncProgress({
    required this.totalItems,
    required this.processedItems,
    required this.currentStep,
    required this.isUpload,
    this.startTime,
  });

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;
  
  int get percentage => (progress * 100).round();
  
  bool get isComplete => processedItems >= totalItems;

  SyncProgress copyWith({
    int? totalItems,
    int? processedItems,
    String? currentStep,
    bool? isUpload,
    DateTime? startTime,
  }) {
    return SyncProgress(
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      currentStep: currentStep ?? this.currentStep,
      isUpload: isUpload ?? this.isUpload,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  String toString() {
    return 'SyncProgress(step: $currentStep, progress: $percentage%, items: $processedItems/$totalItems)';
  }
}
