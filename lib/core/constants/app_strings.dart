class AppStrings {
  static const String appName = 'GTDoro';
  static const String inbox = 'Inbox';
  static const String nextActions = 'Next Actions';
  static const String scheduled = 'Scheduled';
  static const String someday = 'Someday';
  static const String logbook = 'Logbook';
  static const String settings = 'Settings';
  static const String noTitle = '(제목 없음)';
  static const String fabAddActionHeroTag = 'add_action_fab';
  
  // Action messages
  static const String overdueLabel = '마감일 지남';
  static const String actionDeleted = '삭제됨';
  static const String nextActionAssigned = 'Next Action으로 지정되었습니다.';
  
  // Error messages
  static const String errorScheduledCannotChangeStatus = 'Scheduled 항목은 다른 상태로 변경할 수 없습니다.';
  static const String errorCannotChangeToScheduled = '다른 상태의 항목을 Scheduled로 변경할 수 없습니다.';
  static const String errorWaitingForRequired = 'Waiting For 필드를 입력해주세요.';
  static const String errorStatusChangeFailed = '상태를 변경할 수 없습니다';
  static const String errorActionUpdateFailed = '항목을 업데이트할 수 없습니다';
  static const String errorActionDeleteFailed = '항목을 삭제할 수 없습니다';
  static const String errorActionNotFound = 'Action with id %s not found';
  
  // Sync error messages
  static const String errorConfigSaveFailed = '설정 저장 중 오류가 발생했습니다.';
  static const String errorServerConnectionFailed = '서버 연결 실패 (네트워크 또는 인증 오류)';
  static const String errorAuthFailed = '인증 실패 또는 서버 응답 없음';
  static const String errorUnsupportedProtocol = '지원되지 않는 프로토콜입니다. HTTP 또는 HTTPS를 사용해주세요.';
  static const String errorNetworkConnectionFailed = '네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.';
  static const String errorAuthFailedCheck = '인증에 실패했습니다. 사용자 이름과 비밀번호를 확인해주세요.';
  static const String errorServerTimeout = '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
  static const String errorDatabaseNotFound = '데이터베이스를 찾을 수 없습니다. 데이터베이스 이름을 확인해주세요.';
  static const String errorAccessDenied = '접근 권한이 없습니다. 인증 정보를 확인해주세요.';
  static const String errorSyncFailed = '동기화 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  
  // Context type names
  static const String contextTypeLocation = '장소';
  static const String contextTypeTool = '도구';
  static const String contextTypePerson = '관계';
  static const String contextTypeOther = '기타';
}
