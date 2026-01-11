import 'dart:async';
import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/local/oracle_serialization.dart';
import 'package:gtdoro/data/sync/oracle/data/document_helper.dart';
import 'package:gtdoro/data/repositories/action_repository.dart';
import 'package:gtdoro/data/repositories/context_repository.dart';
import 'package:gtdoro/data/repositories/recurring_action_repository.dart';
import 'package:gtdoro/data/repositories/scheduled_action_repository.dart';
import 'package:gtdoro/core/config/app_config.dart';
import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/constants/sync_constants.dart';
import 'package:gtdoro/data/sync/oracle/cache/manager.dart';
import 'package:gtdoro/data/sync/oracle/error/handler.dart';
import 'package:gtdoro/data/sync/oracle/network/network_monitor.dart'
    show OracleNetworkMonitor, NetworkStatusListener;
import 'package:gtdoro/data/sync/models/connection_test_result.dart';
import 'package:gtdoro/data/sync/models/sync_config.dart' as model;
import 'package:gtdoro/data/sync/models/sync_progress.dart';
import 'package:gtdoro/data/sync/models/sync_statistics.dart';
import 'package:gtdoro/data/sync/oracle/core/sync_service.dart';
import 'package:gtdoro/data/sync/oracle/core/metadata_extractor.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';
import 'package:gtdoro/data/sync/providers/sync_data_merger.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';
import 'package:gtdoro/features/todo/providers/recurring_provider.dart';

class SyncProvider with ChangeNotifier {
  final AppDatabase _db;
  final OracleSyncService _oracleSyncService = OracleSyncService();
  final ActionRepository _actionRepo;
  final ContextRepository _contextRepo;
  final RecurringActionRepository _recurringRepo;
  final ScheduledActionRepository _scheduledRepo;
  late SyncDataMerger _dataMerger;

  // Kept for potential future use (e.g., manual refresh, direct provider access)
  // ignore: unused_field
  final ActionProvider _actionProvider;
  // ignore: unused_field
  final ContextProvider _contextProvider;
  // ignore: unused_field
  final RecurringProvider _recurringProvider;

  model.SyncConfig _config = model.SyncConfig();
  bool _isSyncing = false;
  DateTime? _lastSyncDisplayTime;
  DateTime? _lastSyncTimestamp;
  String? _errorMessage;
  SyncProgress? _currentProgress;
  SyncStatistics _statistics = SyncStatistics(
    totalSyncs: 0,
    successfulSyncs: 0,
    failedSyncs: 0,
  );

  model.SyncConfig get config => _config;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncDisplayTime => _lastSyncDisplayTime;
  String? get errorMessage => _errorMessage;
  SyncProgress? get currentProgress => _currentProgress;
  SyncStatistics get statistics => _statistics;
  
  bool get canSync => AppConfig.oracleDbApiUrl.isNotEmpty;
      // 동기화는 항상 활성화됨 (자동 동기화)
      // URL은 AppConfig에서 관리
  
  /// 네트워크 연결 상태
  bool get isNetworkOnline => OracleNetworkMonitor().isOnline;
  
  /// Oracle DB 연결 상태 (null: 확인 안함, true: 연결됨, false: 연결 안됨)
  bool? get isOracleConnected => _isOracleConnected;
  
  /// 연결 상태 확인 여부
  bool get isConnectionChecked => _isConnectionChecked;
  
  /// 마지막 연결 확인 시간
  DateTime? get lastConnectionCheckTime => _lastConnectionCheckTime;
  
  /// 연결 상태 텍스트
  String get connectionStatusText {
    if (!isConnectionChecked) {
      return '연결 상태 확인 중...';
    }
    if (!isNetworkOnline) {
      return '네트워크 오프라인';
    }
    if (_isOracleConnected == null) {
      return '연결 상태 확인 불가';
    }
    if (_isOracleConnected ?? false) {
      return '연결됨';
    }
    return '연결 안됨';
  }

  SyncProvider({
    required AppDatabase db,
    required ActionRepository actionRepo,
    required ContextRepository contextRepo,
    required RecurringActionRepository recurringRepo,
    required ScheduledActionRepository scheduledRepo,
    required ActionProvider actionProvider,
    required ContextProvider contextProvider,
    required RecurringProvider recurringProvider,
  })  : _db = db,
        _actionRepo = actionRepo,
        _contextRepo = contextRepo,
        _recurringRepo = recurringRepo,
        _scheduledRepo = scheduledRepo,
        _actionProvider = actionProvider,
        _contextProvider = contextProvider,
        _recurringProvider = recurringProvider {
    _dataMerger = SyncDataMerger(_actionRepo, _contextRepo, _recurringRepo, _scheduledRepo);
  }

  Timer? _autoSyncTimer;
  Timer? _debounceSyncTimer; // 실시간 동기화 debounce 타이머
  DateTime? _lastSyncAttemptTime; // 마지막 동기화 시도 시간 (너무 빠른 연속 동기화 방지)
  NetworkStatusListener? _networkStatusListener; // 네트워크 상태 리스너 (메모리 누수 방지)
  bool _isConnectionChecked = false; // 연결 상태 확인 여부
  bool? _isOracleConnected; // Oracle DB 연결 상태 (null: 확인 안함, true: 연결됨, false: 연결 안됨)
  DateTime? _lastConnectionCheckTime; // 마지막 연결 확인 시간

  Future<void> init() async {
    try {
      await _loadConfig();
      notifyListeners();

      // 이벤트 기반 동기화 설정 (화면 전환 및 데이터 변경 시)
      if (canSync) {
        debugPrint('SyncProvider: Event-based sync enabled (triggers: app start, screen change, data modification)');
        dev.log('SyncProvider: Event-based sync enabled');
        
        _checkConnectionStatus();
        _startPeriodicConnectionCheck();
        
        // 앱 시작 시 초기 동기화 (2초 후)
        Future.delayed(const Duration(seconds: 2), () {
          if (canSync && !_isSyncing) {
            startSync(retryOnFailure: true);
          }
        });
      }
    } catch (e, stackTrace) {
      dev.log('SyncProvider Init Error', error: e, stackTrace: stackTrace);
    }
  }

  /// 화면 전환 시 동기화 트리거 (NavigationProvider에서 호출)
  void triggerSyncOnScreenChange() {
    if (!canSync || _isSyncing) return;
    
    // 최소 간격 체크
    if (_lastSyncAttemptTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncAttemptTime!);
      if (timeSinceLastSync < SyncConstants.minSyncInterval) {
        return; // 너무 빠른 연속 동기화 방지
      }
    }
    
    triggerImmediateSync();
  }
  
  Timer? _connectionCheckTimer;
  
  /// 주기적 연결 상태 확인 시작
  void _startPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (canSync) {
        _checkConnectionStatus();
      }
    });
  }
  
  /// 주기적 연결 상태 확인 중지
  void _stopPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }
  
  /// 연결 상태 확인 (비동기, UI 블로킹 없음)
  Future<void> _checkConnectionStatus() async {
    if (!canSync) return;
    
    try {
      // 네트워크 상태 확인
      final networkMonitor = OracleNetworkMonitor();
      if (networkMonitor.isStatusStale) {
        await networkMonitor.checkNetworkStatus();
      }
      
          // Oracle DB 연결 확인 (네트워크가 온라인일 때만)
          bool? oracleConnected;
          if (networkMonitor.isOnline) {
            try {
              final tempConfig = _createTempConfig();
              final isConnected = await _oracleSyncService.checkConnection(tempConfig);
              oracleConnected = isConnected;
              _lastConnectionCheckTime = DateTime.now();
            } catch (e) {
              dev.log('SyncProvider: Connection check failed', error: e);
              oracleConnected = false;
            }
          } else {
            oracleConnected = false;
          }
      
      _isOracleConnected = oracleConnected;
      _isConnectionChecked = true;
      _lastConnectionCheckTime = DateTime.now();
      notifyListeners();
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Error checking connection status', error: e, stackTrace: stackTrace);
      _isConnectionChecked = true;
      _isOracleConnected = false;
      _lastConnectionCheckTime = DateTime.now();
      notifyListeners();
    }
  }
  
  /// 수동 연결 상태 확인 (UI에서 호출 가능)
  Future<void> checkConnectionStatus() async {
    _isConnectionChecked = false;
    _isOracleConnected = null;
    notifyListeners();
    await _checkConnectionStatus();
  }

  /// 이벤트 기반 동기화 트리거 (debounce 적용)
  /// 데이터 변경 시 호출되며, 최소 간격과 debounce를 통해 과도한 동기화 방지
  void triggerImmediateSync() {
    if (!canSync || _isSyncing) {
      return;
    }
    
    // 최소 간격 체크
    if (_lastSyncAttemptTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncAttemptTime!);
      if (timeSinceLastSync < SyncConstants.minSyncInterval) {
        final remainingTime = SyncConstants.minSyncInterval - timeSinceLastSync;
        _debounceSyncTimer?.cancel();
        _debounceSyncTimer = Timer(remainingTime, () {
          if (canSync && !_isSyncing) {
            startSync(retryOnFailure: true);
          }
        });
        return;
      }
    }
    
    // Debounce 적용
    _debounceSyncTimer?.cancel();
    _debounceSyncTimer = Timer(SyncConstants.realtimeSyncDebounce, () {
      if (canSync && !_isSyncing) {
        startSync(retryOnFailure: true);
      }
    });
  }
  
  /// 로컬 데이터 변경 시 동기화 트리거 (하위 호환성 유지)
  /// triggerSyncIfAvailable를 통해 호출됨
  void triggerSync() {
    triggerImmediateSync();
  }

  @override
  void dispose() {
    // 주기적 자동 동기화는 비활성화되어 타이머가 없음 (이벤트 기반 동기화만 사용)
    _autoSyncTimer?.cancel(); // 혹시 모를 경우를 대비해 안전하게 처리
    _autoSyncTimer = null;
    _stopPeriodicConnectionCheck();
    _debounceSyncTimer?.cancel();
    _debounceSyncTimer = null;
    // 네트워크 리스너 제거 (메모리 누수 방지)
    if (_networkStatusListener != null) {
      OracleNetworkMonitor().removeListener(_networkStatusListener!);
      _networkStatusListener = null;
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final configData = await (_db.select(_db.syncConfigs)).getSingleOrNull();
    if (configData != null) {
      // 기존 설정이 있으면 lastSeq만 사용 (URL은 AppConfig에서 관리)
      _config = model.SyncConfig(
        url: AppConfig.oracleDbApiUrl, // 항상 AppConfig에서 가져옴
        username: '', // 사용하지 않음
        password: '', // 사용하지 않음
        dbName: 'gtdoro', // 사용하지 않음 (게이트웨이에서 이미 매핑됨)
        isEnabled: true, // 항상 활성화
        lastSeq: configData.lastSeq,
      );
      if (_config.lastSeq != null) {
        _lastSyncDisplayTime = DateTime.now();
        _lastSyncTimestamp = DateTime.now();
      }
    } else {
      // 새로운 설정 생성 시 lastSeq만 초기화
      _config = model.SyncConfig(
        url: AppConfig.oracleDbApiUrl, // 항상 AppConfig에서 가져옴
        username: '', // 사용하지 않음
        password: '', // 사용하지 않음
        dbName: 'gtdoro', // 사용하지 않음
        isEnabled: true, // 항상 활성화
        lastSeq: null,
      );
      
      // DB에 저장 (lastSeq만 저장)
      final companion = SyncConfigsCompanion(
        url: Value(AppConfig.oracleDbApiUrl), // 참고용으로만 저장
        username: const Value(''),
        password: const Value(''),
        dbName: const Value('gtdoro'),
        isEnabled: const Value(true),
        lastSeq: const Value.absent(),
        dbType: const Value('oracle'),
      );
      await _db.into(_db.syncConfigs).insert(companion);
    }
    notifyListeners();
  }

  Future<void> updateConfig(model.SyncConfig newConfig, {bool autoSync = true}) async {
    final lastSeqChanged = _config.lastSeq != newConfig.lastSeq;
    
    if (lastSeqChanged) {
      // lastSeq만 업데이트 (URL은 AppConfig에서 관리)
      _config = model.SyncConfig(
        url: AppConfig.oracleDbApiUrl, // 항상 AppConfig에서 가져옴
        username: '',
        password: '',
        dbName: 'gtdoro',
        isEnabled: true,
        lastSeq: newConfig.lastSeq,
      );
      _errorMessage = null;
      try {
        final companion = SyncConfigsCompanion(
          url: Value(AppConfig.oracleDbApiUrl), // 참고용
          username: const Value(''),
          password: const Value(''),
          dbName: const Value('gtdoro'),
          isEnabled: const Value(true),
          lastSeq: Value(_config.lastSeq),
          dbType: const Value('oracle'),
        );
        await (_db.update(_db.syncConfigs)).write(companion);
        notifyListeners();
        
        // 설정 변경 시 즉시 동기화 (실시간 동기화)
        if (autoSync && canSync && !_isSyncing) {
          dev.log('SyncProvider: Config changed, triggering immediate sync');
          Future.delayed(const Duration(milliseconds: 300), () {
            _lastSyncAttemptTime = DateTime.now();
            startSync(retryOnFailure: true);
          });
        }
      } catch (e, stackTrace) {
        dev.log('SyncProvider: Update config error', error: e, stackTrace: stackTrace);
        _errorMessage = AppStrings.errorConfigSaveFailed;
        notifyListeners();
      }
    }
  }

  Future<void> startSync({bool retryOnFailure = true, int retryCount = 0}) async {
    if (_isSyncing) {
      debugPrint('SyncProvider: ⏸️ Sync already in progress, skipping');
      dev.log('SyncProvider: Sync already in progress, skipping');
      return;
    }
    
    if (!canSync) {
      debugPrint('SyncProvider: ❌ Cannot sync (canSync: false)');
      dev.log('SyncProvider: Cannot sync (canSync: false)');
      return;
    }
    
    // 최소 간격 체크 (너무 빠른 연속 동기화 방지 - 실시간 동기화 최적화)
    // 단, 재시도(retryCount > 0)인 경우는 최소 간격 체크를 건너뜀
    if (_lastSyncAttemptTime != null && retryCount == 0) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncAttemptTime!);
      if (timeSinceLastSync < SyncConstants.minSyncInterval) {
        final remainingSeconds = (SyncConstants.minSyncInterval - timeSinceLastSync).inSeconds;
        debugPrint('SyncProvider: ⏱️ Sync request too soon (${timeSinceLastSync.inSeconds}s < ${SyncConstants.minSyncInterval.inSeconds}s), scheduling in ${remainingSeconds}s...');
        dev.log('SyncProvider: Sync request too soon (${timeSinceLastSync.inSeconds}s < ${SyncConstants.minSyncInterval.inSeconds}s), scheduling for later...');
        // 최소 간격이 지나면 동기화하도록 타이머 설정
        _debounceSyncTimer?.cancel();
        final remainingTime = SyncConstants.minSyncInterval - timeSinceLastSync;
        _debounceSyncTimer = Timer(remainingTime, () {
          if (canSync && !_isSyncing) {
            debugPrint('SyncProvider: ⏰ Scheduled sync triggered after min interval - proceeding with sync');
            dev.log('SyncProvider: Scheduled sync triggered after min interval');
            // 여기서는 _lastSyncAttemptTime을 업데이트하지 않음 - 실제 동기화 시작 시 업데이트됨
            startSync(retryOnFailure: retryOnFailure, retryCount: 0);
          }
        });
        return;
      }
    }
    
    // 실제 동기화 시작 - _lastSyncAttemptTime 업데이트
    _lastSyncAttemptTime = DateTime.now();
    
    // 네트워크 상태 확인 (오프라인 시 동기화 큐에 추가)
    final networkMonitor = OracleNetworkMonitor();
    if (networkMonitor.isStatusStale) {
      debugPrint('SyncProvider: Checking network status...');
      await networkMonitor.checkNetworkStatus();
    }
    
    if (networkMonitor.isOffline) {
      debugPrint('SyncProvider: ❌ Network is offline, sync will be queued for when online');
      dev.log('SyncProvider: Network is offline, sync will be queued for when online');
      _errorMessage = '네트워크 연결이 없습니다. 연결 후 즉시 동기화됩니다.';
      notifyListeners();
      // 네트워크 복구 시 즉시 동기화 (실시간 동기화) - 리스너 중복 등록 방지
      if (_networkStatusListener != null) {
        networkMonitor.removeListener(_networkStatusListener!);
      }
      _networkStatusListener = (isOnline) {
        if (isOnline && canSync && !_isSyncing) {
          debugPrint('SyncProvider: 🌐 Network recovered, triggering immediate sync');
          dev.log('SyncProvider: Network recovered, triggering immediate sync');
          // 네트워크 복구 시 즉시 동기화 (debounce 없음)
          Future.delayed(const Duration(milliseconds: 300), () => startSync(retryOnFailure: true));
        }
      };
      networkMonitor.addListener(_networkStatusListener!);
      return;
    }
    
    _isSyncing = true;
    _errorMessage = null;
    _currentProgress = null;
    final syncStartTime = DateTime.now();
    int itemsUploaded = 0;
    int itemsDownloaded = 0;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('SyncProvider: 🚀 Starting sync (attempt ${retryCount + 1})...');
    debugPrint('═══════════════════════════════════════════════════════');
    
    notifyListeners();

    try {
      // 전체 동기화 작업 타임아웃 적용 (안정성 강화)
      final syncResult = await Future.any([
        _performSync(syncStartTime),
        Future.delayed(SyncConstants.syncOperationTimeout, () {
          throw TimeoutException(
            'Sync operation timeout after ${SyncConstants.syncOperationTimeout.inMinutes} minutes',
            SyncConstants.syncOperationTimeout,
          );
        }),
      ]);
      
      itemsUploaded = syncResult['uploaded'] ?? 0;
      itemsDownloaded = syncResult['downloaded'] ?? 0;
      
      // 성공 시 재시도 카운터 리셋
      retryCount = 0;
    } catch (e, stackTrace) {
      if (e is TimeoutException) {
        dev.log('SyncProvider: Sync timeout', error: e, stackTrace: stackTrace);
        _errorMessage = '동기화 작업 시간이 초과되었습니다. 다시 시도해주세요.';
      } else {
        dev.log('SyncProvider Error: $e', error: e, stackTrace: stackTrace);
        _errorMessage = _formatErrorMessage(e);
      }
      
      // 자동 재시도 로직 (지수 백오프) - 재시도 가능한 에러만
      if (retryOnFailure && 
          retryCount < SyncConstants.maxRetries && 
          OracleErrorHandler.isRetryableError(e)) {
        final delaySeconds = (SyncConstants.baseRetryDelay.inSeconds * 
                              (SyncConstants.backoffMultiplier * (retryCount + 1))).round();
        final actualDelay = delaySeconds > SyncConstants.maxRetryDelay.inSeconds
            ? SyncConstants.maxRetryDelay.inSeconds
            : delaySeconds;
        dev.log('SyncProvider: Retrying sync in ${actualDelay}s (attempt ${retryCount + 1}/${SyncConstants.maxRetries})');
        
        await Future.delayed(Duration(seconds: actualDelay));
        
        // 재시도 (현재 상태 유지)
        _isSyncing = false;
        notifyListeners();
        
        return startSync(retryOnFailure: true, retryCount: retryCount + 1);
      }
      
      // 실패 통계 업데이트
      _updateStatistics(
        success: false,
        itemsUploaded: itemsUploaded,
        itemsDownloaded: itemsDownloaded,
        error: _errorMessage,
      );
    } finally {
      _isSyncing = false;
      _currentProgress = null;
      notifyListeners();
    }
  }
  
  /// 실제 동기화 작업 수행
  Future<Map<String, int>> _performSync(DateTime syncStartTime) async {
    // 1. 서버 연결 확인
    await _checkServerConnection();
    
    // 2. 서버 메타데이터 및 원격 문서 다운로드
    final serverData = await _fetchServerMetadataAndDocs();
    final serverMetadata = serverData['metadata'] as Map<String, String>;
    final remoteDocs = serverData['docs'] as List<Map<String, dynamic>>;
    final downloadResult = serverData['result'] as Map<String, dynamic>;
    
    // 3. 로컬 데이터 수집 및 비교하여 업로드/다운로드 목록 결정
    final comparisonResult = await _compareAndFilterDocuments(serverMetadata, remoteDocs);
    final uploadList = comparisonResult['upload'] as List<Map<String, dynamic>>;
    final downloadList = comparisonResult['download'] as List<Map<String, dynamic>>;
    final conflictIds = comparisonResult['conflicts'] as Set<String>;
    
    if (conflictIds.isNotEmpty) {
      dev.log('SyncProvider: Conflicts detected - ${conflictIds.length} items need conflict resolution');
    }
    
    // 4. 업로드 실행
    final itemsUploaded = await _uploadDocuments(uploadList);
    
    // 5. 다운로드 및 병합 실행
    final mergeResult = await _downloadAndMergeDocuments(downloadList, uploadList);
    final itemsDownloaded = downloadList.length;
    final successCount = mergeResult['success'] ?? 0;
    final conflictCount = mergeResult['conflicts'] ?? 0;
    final failedCount = mergeResult['failed'] ?? 0;
    
    // 6. 후처리 (삭제된 데이터 정리, 설정 업데이트)
    await _postSyncCleanup(downloadResult['last_seq'] as String?);
    
    // 7. 통계 업데이트 및 최종 로깅
    _finalizeSync(syncStartTime, itemsUploaded, itemsDownloaded, successCount, conflictCount, failedCount);
    
    return {
      'uploaded': itemsUploaded,
      'downloaded': itemsDownloaded,
    };
  }
  
  /// SyncConfig 헬퍼 - 중복 코드 제거
  model.SyncConfig _createTempConfig({String? lastSeq}) {
    return model.SyncConfig(
      url: AppConfig.oracleDbApiUrl,
      lastSeq: lastSeq ?? _config.lastSeq,
    );
  }
  
  /// 서버 연결 확인
  Future<void> _checkServerConnection() async {
    _updateProgress(0, 0, '연결 확인 중...', isUpload: false);
    debugPrint('SyncProvider: Checking server connection...');
    
    final tempConfig = _createTempConfig();
    final isAlive = await _getSyncService().checkConnection(tempConfig);
    
    if (!isAlive) {
      debugPrint('SyncProvider: ❌ Server connection failed');
      throw Exception(AppStrings.errorServerConnectionFailed);
    }
    
    debugPrint('SyncProvider: ✅ Server connection successful');
  }
  
  /// 서버 메타데이터 및 원격 문서 다운로드
  /// 최적화된 동기화 플로우: max-rev 체크 → 동기화 필요 여부 판단 → metadata/delta 호출
  Future<Map<String, dynamic>> _fetchServerMetadataAndDocs() async {
    _updateProgress(0, 0, '서버 상태 확인 중...', isUpload: false);
    debugPrint('SyncProvider: Checking server status (max-rev)...');
    
    final syncService = _getSyncService();
    final tempConfig = _createTempConfig();
    
    Map<String, String> serverMetadata = {};
    List<Map<String, dynamic>> remoteDocs = [];
    Map<String, dynamic> downloadResult = {'docs': <Map<String, dynamic>>[], 'last_seq': null};
    
    try {
      // 1. High Water Mark 체크: max-rev를 먼저 확인하여 동기화 필요 여부 빠르게 판단
      try {
        debugPrint('SyncProvider: Checking server max-rev (High Water Mark)...');
        final serverMaxRev = await (syncService as OracleSyncService).getMaxRevBySql();
        
        if (serverMaxRev != null) {
          // 로컬 max-rev 조회
          final localMaxRev = await _getLocalMaxRev();
          
          debugPrint('SyncProvider: Server max-rev: $serverMaxRev, Local max-rev: $localMaxRev');
          
          // 로컬과 서버의 max-rev가 같으면 동기화 불필요 (퀵 체크)
          if (localMaxRev != null && localMaxRev == serverMaxRev) {
            debugPrint('SyncProvider: ✅ Max-rev match! No sync needed (local: $localMaxRev, server: $serverMaxRev)');
            // 메타데이터는 빈 맵, 문서도 빈 리스트 반환
            return {
              'metadata': <String, String>{},
              'docs': <Map<String, dynamic>>[],
              'result': {'docs': <Map<String, dynamic>>[], 'last_seq': _config.lastSeq},
            };
          } else {
            debugPrint('SyncProvider: Max-rev mismatch! Sync needed (local: $localMaxRev, server: $serverMaxRev)');
          }
        }
      } catch (e) {
        // max-rev 체크 실패해도 계속 진행 (폴백)
        debugPrint('SyncProvider: ⚠️ Max-rev check failed, continuing with normal sync: $e');
        dev.log('SyncProvider: Max-rev check failed', error: e);
      }
      // 서버 API 표준 1.0: /metadata 엔드포인트로 메타데이터만 먼저 가져오기
      try {
        debugPrint('SyncProvider: Downloading metadata from server...');
        serverMetadata = await syncService.downloadMetadataOnly(tempConfig);
        debugPrint('SyncProvider: ✅ Downloaded metadata for ${serverMetadata.length} documents');
        
        // 메타데이터로 비교하여 필요한 문서 ID 목록 결정
        final allLocalData = await _collectLocalDataForComparison();
        final localDataMap = _buildLocalDataMap(allLocalData);
        final downloadIds = _filterDownloadIdsByMetadata(serverMetadata, localDataMap);
        
        debugPrint('SyncProvider: Identified ${downloadIds.length} documents that need download (based on metadata comparison) out of ${serverMetadata.length} total');
        
        // 필요한 문서가 없으면 다운로드 스킵 (최적화!)
        if (downloadIds.isEmpty) {
          debugPrint('SyncProvider: ✅ No documents need download, skipping document download (saving bandwidth)');
          remoteDocs = [];
          downloadResult = {'docs': remoteDocs, 'last_seq': null};
        } else {
          // 필요한 문서만 다운로드: 델타 동기화 우선 사용
          final localMaxRev = await _getLocalMaxRev();
          if (localMaxRev != null) {
            // 델타 동기화 사용 (서버 API 표준 1.0: /delta 엔드포인트)
            debugPrint('SyncProvider: Using delta sync for ${downloadIds.length} needed documents (local max-rev: $localMaxRev)...');
            downloadResult = await syncService.downloadChangedDocs(tempConfig, localMaxRev.toString());
            remoteDocs = (downloadResult['docs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
            
            // 필요한 문서만 필터링 (델타 동기화로 받은 문서 중에서)
            remoteDocs = remoteDocs.where((doc) {
              final id = doc['_id'] as String? ?? doc['id'] as String?;
              return id != null && downloadIds.contains(id);
            }).toList();
            
            debugPrint('SyncProvider: Downloaded ${remoteDocs.length} documents via delta sync (filtered from ${downloadIds.length} needed)');
          } else {
            // 첫 실행: 전체 다운로드 (서버 API 표준 1.0: /delta 엔드포인트, since_rev 없이 호출)
            debugPrint('SyncProvider: First sync - using full download for ${downloadIds.length} needed documents...');
            remoteDocs = await syncService.downloadAllDocs(tempConfig);
            // 필요한 문서만 필터링
            remoteDocs = remoteDocs.where((doc) {
              final id = doc['_id'] as String? ?? doc['id'] as String?;
              return id != null && downloadIds.contains(id);
            }).toList();
            downloadResult = {'docs': remoteDocs, 'last_seq': null};
            debugPrint('SyncProvider: Downloaded ${remoteDocs.length} documents for merge (filtered from ${downloadIds.length} needed)');
          }
        }
      } catch (e) {
        // 메타데이터 다운로드 실패 시 델타/전체 다운로드 사용
        debugPrint('SyncProvider: ⚠️ Metadata-only download failed, using delta/full download: $e');
        dev.log('SyncProvider: Metadata-only download failed, using delta/full download', error: e);
        
        // 로컬 max-rev 확인: 데이터가 있으면 델타 동기화, 없으면 전체 다운로드
        final localMaxRev = await _getLocalMaxRev();
        
        if (localMaxRev != null) {
          // 델타 동기화 사용
          debugPrint('SyncProvider: Using delta sync (local max-rev: $localMaxRev)');
          downloadResult = await syncService.downloadChangedDocs(tempConfig, localMaxRev.toString());
          remoteDocs = (downloadResult['docs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
          debugPrint('SyncProvider: Downloaded ${remoteDocs.length} documents via delta sync');
        } else {
          // 전체 다운로드 (첫 실행)
          debugPrint('SyncProvider: First sync - using full download');
          remoteDocs = await syncService.downloadAllDocs(tempConfig);
          downloadResult = {'docs': remoteDocs, 'last_seq': null};
          debugPrint('SyncProvider: Downloaded ${remoteDocs.length} total documents');
        }
        
        // 메타데이터 추출 (기존 방식)
        serverMetadata = OracleMetadataExtractor.extractMetadataFromDocs(remoteDocs);
        debugPrint('SyncProvider: Extracted ${serverMetadata.length} server metadata entries (for _rev comparison)');
      }
    } catch (e, stackTrace) {
      debugPrint('SyncProvider: ❌ Error fetching server metadata: $e');
      dev.log('SyncProvider: Error fetching server metadata', error: e, stackTrace: stackTrace);
      // 메타데이터 가져오기 실패해도 업로드는 시도 (부분 동기화)
      downloadResult = {'docs': <Map<String, dynamic>>[], 'last_seq': _config.lastSeq};
    }
    
    return {
      'metadata': serverMetadata,
      'docs': remoteDocs,
      'result': downloadResult,
    };
  }
  
  /// 로컬 데이터베이스에서 최대 rev 값 조회 (High Water Mark)
  /// 모든 테이블(Actions, Contexts, RecurringActions, ScheduledActions)에서 최대 rev 값 반환
  Future<int?> _getLocalMaxRev() async {
    try {
      int? maxRev;
      
      // 각 테이블에서 최대 rev 값 조회
      final actions = await (_db.select(_db.actions)
            ..orderBy([(t) => OrderingTerm.desc(t.rev)])
            ..limit(1))
          .get();
      
      if (actions.isNotEmpty && actions.first.rev != null) {
        final rev = int.tryParse(actions.first.rev!);
        if (rev != null && (maxRev == null || rev > maxRev)) {
          maxRev = rev;
        }
      }
      
      final contexts = await (_db.select(_db.contexts)
            ..orderBy([(t) => OrderingTerm.desc(t.rev)])
            ..limit(1))
          .get();
      
      if (contexts.isNotEmpty && contexts.first.rev != null) {
        final rev = int.tryParse(contexts.first.rev!);
        if (rev != null && (maxRev == null || rev > maxRev)) {
          maxRev = rev;
        }
      }
      
      final recurringActions = await (_db.select(_db.recurringActions)
            ..orderBy([(t) => OrderingTerm.desc(t.rev)])
            ..limit(1))
          .get();
      
      if (recurringActions.isNotEmpty && recurringActions.first.rev != null) {
        final rev = int.tryParse(recurringActions.first.rev!);
        if (rev != null && (maxRev == null || rev > maxRev)) {
          maxRev = rev;
        }
      }
      
      final scheduledActions = await (_db.select(_db.scheduledActions)
            ..orderBy([(t) => OrderingTerm.desc(t.rev)])
            ..limit(1))
          .get();
      
      if (scheduledActions.isNotEmpty && scheduledActions.first.rev != null) {
        final rev = int.tryParse(scheduledActions.first.rev!);
        if (rev != null && (maxRev == null || rev > maxRev)) {
          maxRev = rev;
        }
      }
      
      return maxRev;
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Error getting local max-rev', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// 로컬 데이터와 서버 메타데이터 비교하여 업로드/다운로드 목록 결정
  /// 최적화: 메타데이터만으로 비교 (이미 _fetchServerMetadataAndDocs에서 필요한 문서만 필터링됨)
  Future<Map<String, dynamic>> _compareAndFilterDocuments(
    Map<String, String> serverMetadata,
    List<Map<String, dynamic>> remoteDocs,
  ) async {
    _updateProgress(0, 0, '로컬 변경사항 확인 중...', isUpload: true);
    debugPrint('SyncProvider: Comparing local data with server metadata...');
    
    // 로컬 데이터 수집
    final allLocalData = await _collectLocalDataForComparison();
    debugPrint('SyncProvider: Collected ${allLocalData.length} local items');
    
    // 메타데이터만으로 업로드 목록 결정
    final uploadResult = _filterUploadItems(allLocalData, serverMetadata);
    final uploadList = uploadResult['list'] as List<Map<String, dynamic>>;
    
    // remoteDocs는 이미 _fetchServerMetadataAndDocs에서 필요한 문서만 필터링되었거나 빈 리스트
    // downloadIds가 비어있으면 remoteDocs도 비어있음 (전체 문서 다운로드 스킵됨)
    final downloadList = remoteDocs;
    final downloadResult = {
      'list': downloadList,
      'skipped': serverMetadata.length - downloadList.length,
    };
    
    debugPrint('SyncProvider: Using pre-filtered documents: ${downloadList.length} documents (from ${serverMetadata.length} total metadata, skipped: ${downloadResult['skipped']})');
    
    // 충돌 감지
    final conflictIds = _detectConflicts(uploadList, downloadList);
    
    // 데이터 검증
    final validatedUploadList = _validateDocuments(uploadList);
    final validatedDownloadList = _validateDocuments(downloadList);
    
    debugPrint('SyncProvider: Comparison - Upload: ${validatedUploadList.length} (skipped: ${uploadResult['skipped']}), Download: ${validatedDownloadList.length} (skipped: ${downloadResult['skipped']})');
    if (conflictIds.isNotEmpty) {
      debugPrint('SyncProvider: ⚠️ Detected ${conflictIds.length} conflicts');
    }
    
    return {
      'upload': validatedUploadList,
      'download': validatedDownloadList,
      'conflicts': conflictIds,
    };
  }
  
  /// 비교를 위한 로컬 데이터 수집
  Future<List<Map<String, dynamic>>> _collectLocalDataForComparison() async {
    final lastSeq = _config.lastSeq;
    final lastSyncTimestamp = _lastSyncTimestamp?.millisecondsSinceEpoch ?? 0;
    
    return lastSeq == null
        ? await _collectAllLocalData()
        : await _collectModifiedLocalData(lastSyncTimestamp);
  }
  
  /// 로컬 데이터를 ID 맵으로 변환 (빠른 조회)
  Map<String, Map<String, dynamic>> _buildLocalDataMap(List<Map<String, dynamic>> localData) {
    final map = <String, Map<String, dynamic>>{};
    for (final doc in localData) {
      final id = doc['_id'] as String? ?? doc['id'] as String?;
      if (id != null) {
        map[id] = doc;
      }
    }
    return map;
  }
  
  /// 업로드가 필요한 항목 필터링 (_rev 기반)
  Map<String, dynamic> _filterUploadItems(
    List<Map<String, dynamic>> localData,
    Map<String, String> serverMetadata,
  ) {
    final uploadList = <Map<String, dynamic>>[];
    int skippedCount = 0;
    
    for (final localDoc in localData) {
      final id = localDoc['_id'] as String? ?? localDoc['id'] as String?;
      final localRev = localDoc['_rev'] as String? ?? localDoc['rev'] as String?;
      
      if (id == null) continue;
      
      final serverRev = serverMetadata[id];
      
      // 업로드 필요 여부 판단:
      // 1. 로컬에 rev가 없거나 비어있으면 업로드 (새로운 항목)
      // 2. 서버에 rev가 없거나 비어있으면 업로드 (서버에 없는 항목)
      // 3. 로컬 rev가 서버 rev보다 더 최신이면 업로드 (로컬이 변경됨)
      // 4. 로컬 rev가 서버 rev보다 낮거나 같으면 업로드하지 않음 (서버가 더 최신이거나 동기화됨)
      bool needsUpload = false;
      
      if (localRev == null || localRev.isEmpty) {
        // 로컬에 rev가 없으면 기존 데이터일 수 있음
        // 서버 메타데이터에 ID가 있는지 확인 (서버에 존재하는지)
        if (serverMetadata.containsKey(id)) {
          // 서버에 존재함: rev가 없는 기존 데이터이므로 서버 버전 사용 (다운로드됨)
          needsUpload = false;
          skippedCount++;
          debugPrint('SyncProvider: Skipping upload for $id (local has no rev but exists on server - will download)');
        } else {
          // 서버에 없음: 새로운 항목이므로 업로드 필요
          needsUpload = true;
          debugPrint('SyncProvider: Upload needed for $id (local has no rev and not on server - new item)');
        }
      } else if (serverRev == null || serverRev.isEmpty) {
        // 서버 메타데이터에 ID가 있지만 rev가 없거나 빈 문자열
        // extractMetadataFromDocs에서 rev가 없으면 빈 문자열('')로 저장되므로,
        // serverMetadata.containsKey(id)는 true이지만 serverRev는 빈 문자열
        if (serverMetadata.containsKey(id)) {
          // 서버에 존재하지만 rev가 없음: 기존 데이터
          // 로컬에 rev가 있으면 로컬이 더 최신일 가능성이 높지만,
          // 서버에 이미 존재하므로 업로드 시도하지 않고 다운로드로 처리 (서버 버전 사용)
          needsUpload = false;
          skippedCount++;
          debugPrint('SyncProvider: Skipping upload for $id (local has rev $localRev but server has no rev - existing data on server, will download)');
        } else {
          // 서버 메타데이터에 ID가 없음: 서버에 없는 항목이므로 업로드 필요
          needsUpload = true;
          debugPrint('SyncProvider: Upload needed for $id (local has rev $localRev but not on server - new item)');
        }
      } else {
        // rev 비교: 로컬이 더 최신인 경우만 업로드 필요
        final revComparison = RevHelper.compareRev(localRev, serverRev);
        if (revComparison > 0) {
          // 로컬이 더 최신: 업로드 필요
          needsUpload = true;
          debugPrint('SyncProvider: Upload needed for $id (local rev $localRev is newer than server rev $serverRev)');
        } else if (revComparison < 0) {
          // 서버가 더 최신: 업로드 불필요, 나중에 다운로드됨
          needsUpload = false;
          skippedCount++;
          debugPrint('SyncProvider: Skipping upload for $id (server rev $serverRev is newer than local rev $localRev)');
        } else {
          // rev가 같음: 동기화됨, 업로드 불필요
          needsUpload = false;
          skippedCount++;
        }
      }
      
      if (needsUpload) {
        uploadList.add(localDoc);
      }
    }
    
    return {'list': uploadList, 'skipped': skippedCount};
  }
  
  /// 메타데이터만으로 다운로드 필요한 문서 ID 목록 결정 (최적화)
  /// 전체 문서 객체를 만들지 않고 메타데이터만 비교하여 필요한 ID만 반환
  Set<String> _filterDownloadIdsByMetadata(
    Map<String, String> serverMetadata,
    Map<String, Map<String, dynamic>> localDataMap,
  ) {
    final downloadIds = <String>{};
    
    for (final entry in serverMetadata.entries) {
      final id = entry.key;
      final serverRev = entry.value;
      
      final localDoc = localDataMap[id];
      final localRev = localDoc?['_rev'] as String? ?? localDoc?['rev'] as String?;
      
      // 로컬에 없으면 다운로드 필요
      if (localRev == null || localRev.isEmpty) {
        downloadIds.add(id);
        continue;
      }
      
      // rev 비교를 통해 어느 쪽이 더 최신인지 확인 (오버플로우 안전 비교)
      final revComparison = RevHelper.compareRev(localRev, serverRev);
      
      if (revComparison < 0) {
        // 원격이 더 최신: 다운로드 필요
        downloadIds.add(id);
      } else if (revComparison > 0) {
        // 로컬이 더 최신: 다운로드 불필요, 스킵
        debugPrint('SyncProvider: Skipping download for $id (local rev $localRev is newer than server rev $serverRev)');
      }
      // rev가 같으면 동기화됨, 스킵 (아무것도 하지 않음)
    }
    
    return downloadIds;
  }

  
  /// 충돌 감지 (양쪽에서 수정된 항목)
  Set<String> _detectConflicts(
    List<Map<String, dynamic>> uploadList,
    List<Map<String, dynamic>> downloadList,
  ) {
    final uploadIds = uploadList
        .map((doc) => doc['_id'] ?? doc['id'])
        .whereType<String>()
        .toSet();
    final downloadIds = downloadList
        .map((doc) => doc['_id'] ?? doc['id'])
        .whereType<String>()
        .toSet();
    
    return uploadIds.intersection(downloadIds);
  }
  
  /// 문서 업로드 실행
  Future<int> _uploadDocuments(List<Map<String, dynamic>> uploadList) async {
    if (uploadList.isEmpty) {
      debugPrint('SyncProvider: No items to upload (all already synced)');
      return 0;
    }
    
    _updateProgress(uploadList.length, 0, '업로드 중...', isUpload: true);
    debugPrint('SyncProvider: Uploading ${uploadList.length} items...');
    
    int itemsUploaded = 0;
    await _uploadWithProgress(_config, uploadList, (uploaded, total) {
      _updateProgress(total, uploaded, '업로드 중... ($uploaded/$total)', isUpload: true);
      itemsUploaded = uploaded;
    });
    
    debugPrint('SyncProvider: ✅ Upload completed - $itemsUploaded items');
    return itemsUploaded;
  }
  
  /// 문서 다운로드 및 병합 실행
  Future<Map<String, int>> _downloadAndMergeDocuments(
    List<Map<String, dynamic>> downloadList,
    List<Map<String, dynamic>> uploadList,
  ) async {
    if (downloadList.isEmpty) {
      debugPrint('SyncProvider: No items to download (all already synced)');
      _dataMerger.clearCache();
      return {'success': 0, 'conflicts': 0, 'failed': 0};
    }
    
    debugPrint('SyncProvider: Merging ${downloadList.length} remote documents...');
    
    // 로컬 문서 캐시 설정 (충돌 감지 최적화)
    if (uploadList.isNotEmpty) {
      final localDocsCache = <String, Map<String, dynamic>>{};
      for (final doc in uploadList) {
        final type = doc['type'] as String? ?? 'todo';
        final id = doc['_id'] as String? ?? doc['id'] as String?;
        if (id != null) {
          localDocsCache['$type:$id'] = doc;
        }
      }
      _dataMerger.setLocalDocsCache(localDocsCache);
    }
    
    // 데이터 병합
    _updateProgress(downloadList.length, 0, '데이터 병합 중...', isUpload: false);
    final mergeResult = await _dataMerger.mergeRemoteData(downloadList);
    
    final successCount = mergeResult['success'] ?? 0;
    final conflictCount = mergeResult['conflicts'] ?? 0;
    final failedCount = mergeResult['failed'] ?? 0;
    
    debugPrint('SyncProvider: Merge result - Success: $successCount, Conflicts: $conflictCount, Failed: $failedCount');
    
    if (failedCount > 0) {
      dev.log('SyncProvider: Warning - $failedCount documents failed to merge');
    }
    
    _dataMerger.clearCache();
    return mergeResult;
  }
  
  /// 동기화 후처리 (삭제된 데이터 정리, 설정 업데이트)
  Future<void> _postSyncCleanup(String? newLastSeq) async {
    _updateProgress(0, 0, '삭제된 데이터 정리 중...', isUpload: false);
    
    try {
      await _dataMerger.purgeDeletedLocalData();
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Error purging deleted data', error: e, stackTrace: stackTrace);
    }
    
    try {
      _config = _config.copyWith(lastSeq: newLastSeq ?? _config.lastSeq);
      await updateConfig(_config, autoSync: false);
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Error updating config', error: e, stackTrace: stackTrace);
    }
  }
  
  /// 동기화 완료 처리 (통계 업데이트, 로깅)
  void _finalizeSync(
    DateTime syncStartTime,
    int itemsUploaded,
    int itemsDownloaded,
    int successCount,
    int conflictCount,
    int failedCount,
  ) {
    final syncDuration = DateTime.now().difference(syncStartTime);
    _lastSyncDisplayTime = DateTime.now();
    _lastSyncTimestamp = DateTime.now();
    
    _updateStatistics(
      success: true,
      itemsUploaded: itemsUploaded,
      itemsDownloaded: itemsDownloaded,
      duration: syncDuration,
    );
    
    OracleCacheManager().cleanupExpiredCache();
    _updateProgress(0, 0, '완료', isUpload: false);
    
    // 동기화 완료 후 UI Provider 강제 새로고침 (데이터베이스 스트림이 변경사항을 감지하지 못할 수 있음)
    // 약간의 지연을 두어 데이터베이스 트랜잭션이 완전히 커밋된 후에 새로고침
    Future.delayed(const Duration(milliseconds: 100), () {
      _refreshProviders();
    });
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('SyncProvider: ✅ Sync completed successfully!');
    debugPrint('SyncProvider: Duration: ${syncDuration.inSeconds}s');
    debugPrint('SyncProvider: Uploaded: $itemsUploaded, Downloaded: $itemsDownloaded');
    if (successCount > 0 || conflictCount > 0 || failedCount > 0) {
      debugPrint('SyncProvider: Merged - Success: $successCount, Conflicts: $conflictCount, Failed: $failedCount');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    dev.log('SyncProvider: Sync completed in ${syncDuration.inSeconds}s');
  }
  
  /// UI Provider 강제 새로고침 (동기화 완료 후 데이터베이스 변경사항이 UI에 반영되도록)
  /// 데이터베이스 스트림이 변경사항을 감지하지 못하는 경우를 대비하여
  /// Provider에 직접 알림을 보내거나 데이터베이스 쿼리를 다시 실행하도록 유도
  void _refreshProviders() {
    try {
      // ActionProvider는 데이터베이스 스트림을 구독하고 있으므로,
      // 데이터베이스가 업데이트되면 자동으로 반응해야 함
      // 하지만 스트림이 변경사항을 감지하지 못하는 경우를 대비하여
      // 약간의 지연 후에 데이터베이스 쿼리를 다시 실행하도록 유도
      
      // 데이터베이스에 작은 변경을 트리거하여 스트림을 활성화
      // 하지만 이는 불필요한 데이터베이스 작업이므로, 대신 Provider에 직접 알림
      // ActionProvider는 스트림을 통해 자동으로 업데이트되므로,
      // 여기서는 명시적으로 새로고침할 필요가 없음
      // 대신 데이터베이스 변경사항이 제대로 감지되도록 보장
      
      // 실제로는 데이터베이스 스트림이 자동으로 업데이트되므로
      // 여기서는 로그만 남기고 실제 작업은 하지 않음
      // 만약 스트림이 업데이트되지 않는다면, ActionProvider의 스트림 구독 로직을 확인해야 함
      
      dev.log('SyncProvider: Sync completed, database streams should automatically update providers');
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Error refreshing providers', error: e, stackTrace: stackTrace);
    }
  }
  
  void _updateProgress(int total, int processed, String step, {required bool isUpload}) {
    _currentProgress = SyncProgress(
      totalItems: total,
      processedItems: processed,
      currentStep: step,
      isUpload: isUpload,
      startTime: _currentProgress?.startTime ?? DateTime.now(),
    );
    notifyListeners();
  }
  
  void _updateStatistics({
    required bool success,
    int itemsUploaded = 0,
    int itemsDownloaded = 0,
    Duration? duration,
    String? error,
  }) {
    _statistics = _statistics.copyWith(
      totalSyncs: _statistics.totalSyncs + 1,
      successfulSyncs: success ? _statistics.successfulSyncs + 1 : _statistics.successfulSyncs,
      failedSyncs: success ? _statistics.failedSyncs : _statistics.failedSyncs + 1,
      lastSuccessfulSync: success ? DateTime.now() : _statistics.lastSuccessfulSync,
      lastFailedSync: success ? _statistics.lastFailedSync : DateTime.now(),
      lastError: error,
      totalItemsUploaded: _statistics.totalItemsUploaded + itemsUploaded,
      totalItemsDownloaded: _statistics.totalItemsDownloaded + itemsDownloaded,
      averageSyncDuration: duration != null
          ? Duration(
              milliseconds: ((_statistics.averageSyncDuration?.inMilliseconds ?? 0) + duration.inMilliseconds) ~/ 2,
            )
          : _statistics.averageSyncDuration,
    );
  }
  
  Future<void> _uploadWithProgress(
    model.SyncConfig config,
    List<Map<String, dynamic>> docs,
    void Function(int processed, int total) onProgress,
  ) async {
    final batchSize = SyncConstants.maxBatchSize;
    int processed = 0;
    final tempConfig = _createTempConfig();
    
    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = docs.skip(i).take(batchSize).toList();
      await _getSyncService().uploadDocs(tempConfig, batch);
      processed += batch.length;
      onProgress(processed, docs.length);
    }
  }

  Future<bool> testConnection(model.SyncConfig testConfig) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isAlive = await _oracleSyncService.checkConnection(testConfig);
      if (isAlive) return true;
      throw Exception(AppStrings.errorAuthFailed);
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Test connection error', error: e, stackTrace: stackTrace);
      _errorMessage = _formatErrorMessage(e);
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 상세한 연결 테스트 수행
  Future<ConnectionTestResult> testConnectionDetailed() async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    final hasOAuth2 = AppConfig.oracleDbClientId != null && 
                     AppConfig.oracleDbClientSecret != null &&
                     AppConfig.oracleDbClientId!.isNotEmpty && 
                     AppConfig.oracleDbClientSecret!.isNotEmpty;
    
    // 1단계: 기본 네트워크 확인
    bool hasNetwork = false;
    String? networkError;
    try {
      final networkMonitor = OracleNetworkMonitor();
      hasNetwork = await networkMonitor.checkNetworkStatus();
      if (!hasNetwork) {
        networkError = '인터넷 연결이 없습니다';
      }
    } catch (e) {
      networkError = '네트워크 확인 실패: ${e.toString()}';
    }

    if (!hasNetwork) {
      return ConnectionTestResult(
        success: false,
        message: '네트워크 연결 실패',
        errorType: 'NetworkError',
        details: networkError ?? '인터넷에 연결할 수 없습니다',
        testTime: DateTime.now(),
        hasNetwork: false,
        hasOAuth2: hasOAuth2,
        apiUrl: apiUrl,
      );
    }

    // 2단계: Oracle DB 연결 확인
    try {
      final tempConfig = model.SyncConfig(
        url: apiUrl,
        lastSeq: _config.lastSeq,
      ); // testConnectionDetailed에서는 apiUrl을 직접 사용하므로 헬퍼 미사용
      
      final isConnected = await _oracleSyncService.checkConnection(tempConfig);
      
      if (isConnected) {
        return ConnectionTestResult(
          success: true,
          message: 'Oracle DB에 성공적으로 연결되었습니다',
          statusCode: 200,
          testTime: DateTime.now(),
          hasNetwork: true,
          hasOAuth2: hasOAuth2,
          apiUrl: apiUrl,
        );
      } else {
        return ConnectionTestResult(
          success: false,
          message: 'Oracle DB 연결 실패',
          errorType: 'ConnectionFailed',
          details: '서버에 연결할 수 없습니다. URL과 인증 정보를 확인하세요.',
          testTime: DateTime.now(),
          hasNetwork: true,
          hasOAuth2: hasOAuth2,
          apiUrl: apiUrl,
        );
      }
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Detailed connection test failed', error: e, stackTrace: stackTrace);
      
      String errorType = 'UnknownError';
      String errorDetails = e.toString();
      
      if (e.toString().contains('SocketException') || e.toString().contains('Network is unreachable')) {
        errorType = 'NetworkError';
        errorDetails = '네트워크 연결 문제: 서버에 도달할 수 없습니다';
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorType = 'TimeoutError';
        errorDetails = '연결 타임아웃: 서버가 응답하지 않습니다';
      } else if (e.toString().contains('Certificate') || e.toString().contains('SSL')) {
        errorType = 'SSLError';
        errorDetails = 'SSL 인증서 문제: 보안 연결을 설정할 수 없습니다';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorType = 'AuthError';
        errorDetails = '인증 실패: OAuth2 Client ID와 Secret을 확인하세요';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorType = 'PermissionError';
        errorDetails = '권한 없음: 인증 정보는 올바르지만 접근 권한이 없습니다';
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorType = 'NotFoundError';
        errorDetails = '엔드포인트를 찾을 수 없습니다: URL을 확인하세요';
      }
      
      return ConnectionTestResult(
        success: false,
        message: '연결 테스트 실패',
        errorType: errorType,
        details: errorDetails,
        testTime: DateTime.now(),
        hasNetwork: true,
        hasOAuth2: hasOAuth2,
        apiUrl: apiUrl,
      );
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Force sync from remote: Delete all local data and sync from remote only
  /// This is a destructive operation that will delete all local data
  Future<void> forceSyncFromRemote() async {
    // Prevent concurrent sync
    if (_isSyncing) {
      dev.log('SyncProvider: Sync already in progress');
      return;
    }
    
    if (!canSync) {
      dev.log('SyncProvider: Cannot sync (canSync: false)');
      throw Exception('동기화 설정이 완료되지 않았습니다.');
    }
    
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      dev.log('SyncProvider: Force sync from remote - deleting all local data...');
      
      final tempConfig = _createTempConfig();
      
      // Check connection first
      final isAlive = await _getSyncService().checkConnection(tempConfig);
      if (!isAlive) throw Exception(AppStrings.errorServerConnectionFailed);

      // Delete all local data (안정성 강화: 트랜잭션 에러 처리)
      try {
        await _db.transaction(() async {
          // Delete all actions and their contexts
          await (_db.delete(_db.actionContexts)).go();
          await (_db.delete(_db.actions)).go();
          
          // Delete all contexts
          await (_db.delete(_db.contexts)).go();
          
          // Delete all recurring actions
          await (_db.delete(_db.recurringActions)).go();
          
          // Delete all scheduled actions
          await (_db.delete(_db.scheduledActions)).go();
        });
      } catch (e, stackTrace) {
        dev.log('SyncProvider: Error deleting local data in transaction', error: e, stackTrace: stackTrace);
        throw Exception('로컬 데이터 삭제 실패: ${e.toString()}');
      }
      
      dev.log('SyncProvider: All local data deleted, downloading from remote...');
      
      // Download all data from remote (full sync)
      final syncService = _getSyncService();
      final downloadResult = {
        'docs': await syncService.downloadAllDocs(tempConfig),
        'last_seq': null,
      };

      final remoteDocs = (downloadResult['docs'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];
      final newLastSeq = downloadResult['last_seq'] as String?;

      // 데이터 검증 (안정성 강화)
      final validatedRemoteDocs = _validateDocuments(remoteDocs);

      // Merge remote data (which will be all data since local is empty)
      await _dataMerger.mergeRemoteData(validatedRemoteDocs);

      // Reset lastSeq to start fresh
      _config = _config.copyWith(lastSeq: newLastSeq);
      await updateConfig(_config, autoSync: false);

      _lastSyncDisplayTime = DateTime.now();
      _lastSyncTimestamp = DateTime.now();
      dev.log('SyncProvider: Force sync from remote completed');
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Force sync error', error: e, stackTrace: stackTrace);
      _errorMessage = _formatErrorMessage(e);
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Convert error to user-friendly message
  String _formatErrorMessage(dynamic error) {
    // Oracle 특화 에러 처리
    return OracleErrorHandler.formatOracleError(error);
  }

  /// Oracle 동기화 서비스 반환
  OracleSyncService _getSyncService() {
    return _oracleSyncService;
  }

  /// 개별 항목 즉시 업로드 (액션 추가/수정 시 호출)
  /// 변경된 항목만 원격 DB에 즉시 업로드하여 효율성 향상
  Future<void> uploadSingleItem(Map<String, dynamic> item) async {
    if (!canSync || _isSyncing) {
      dev.log('SyncProvider: uploadSingleItem skipped (canSync: $canSync, isSyncing: $_isSyncing)');
      return;
    }

    // 네트워크 상태 확인
    if (!isNetworkOnline) {
      dev.log('SyncProvider: uploadSingleItem skipped (network offline)');
      return;
    }

    try {
      final tempConfig = _createTempConfig();
      final docList = [item];
      
      dev.log('SyncProvider: Uploading single item immediately (type: ${item['type']}, id: ${item['_id'] ?? item['id']})');
      
      // 단일 문서 업로드
      await _getSyncService().uploadDocs(tempConfig, docList);
      
      dev.log('SyncProvider: ✅ Single item uploaded successfully (type: ${item['type']}, id: ${item['_id'] ?? item['id']})');
    } catch (e, stackTrace) {
      dev.log('SyncProvider: Error uploading single item', error: e, stackTrace: stackTrace);
      // 개별 업로드 실패는 전체 동기화에 영향주지 않음 (조용히 실패 처리)
      // 전체 동기화 시 다시 시도됨
    }
  }

  /// 모든 로컬 데이터 수집 및 Oracle 형식으로 변환
  Future<List<Map<String, dynamic>>> _collectAllLocalData() async {
    final List<Map<String, dynamic>> result = [];
    
    result.addAll((await _actionRepo.getAllActions())
        .map((e) => e.toOracleJson()));
    result.addAll((await _contextRepo.getAllContexts())
        .map((e) => e.toOracleJson()));
    result.addAll((await _recurringRepo.getAllRecurringActions())
        .map((e) => e.toOracleJson()));
    result.addAll((await _scheduledRepo.getAllScheduledActions())
        .map((e) => e.toOracleJson()));
    
    return result;
  }

  /// 수정된 로컬 데이터 수집 및 Oracle 형식으로 변환
  Future<List<Map<String, dynamic>>> _collectModifiedLocalData(int lastSyncTimestamp) async {
    final List<Map<String, dynamic>> result = [];
    
    result.addAll((await _actionRepo.getModifiedActions(lastSyncTimestamp))
        .map((e) => e.toOracleJson()));
    result.addAll((await _contextRepo.getModifiedContexts(lastSyncTimestamp))
        .map((e) => e.toOracleJson()));
    result.addAll((await _recurringRepo.getModifiedRecurringActions(lastSyncTimestamp))
        .map((e) => e.toOracleJson()));
    result.addAll((await _scheduledRepo.getModifiedScheduledActions(lastSyncTimestamp))
        .map((e) => e.toOracleJson()));
    
    return result;
  }
  
  
  /// 문서 검증 (리팩토링: OracleDocumentHelper 사용)
  List<Map<String, dynamic>> _validateDocuments(List<Map<String, dynamic>> docs) {
    final validated = <Map<String, dynamic>>[];
    
    for (final doc in docs) {
      try {
        // 필수 필드 검증 (리팩토링: 헬퍼 사용)
        if (!OracleDocumentHelper.isValidDocument(doc)) {
          dev.log('SyncProvider: Invalid document skipped: ${doc['_id'] ?? 'unknown'}');
          continue;
        }
        
        // 문서 크기 검증 (메모리 보호)
        final docSize = OracleDocumentHelper.estimateDocumentSize(doc);
        if (docSize > SyncConstants.maxDocumentSize) {
          dev.log('SyncProvider: Document too large ($docSize bytes), skipped: ${doc['_id'] ?? 'unknown'}');
          continue;
        }
        
        validated.add(doc);
      } catch (e) {
        dev.log('SyncProvider: Error validating document: $e');
        // 검증 실패한 문서는 제외하고 계속 진행
        continue;
      }
    }
    
    return validated;
  }
}
