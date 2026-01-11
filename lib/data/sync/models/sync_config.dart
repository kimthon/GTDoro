/// 동기화 설정 모델
class SyncConfig {
  final String url;
  final String username;
  final String password;
  final String dbName;
  final bool isEnabled;
  final String? lastSeq;

  SyncConfig({
    this.url = '',
    this.username = '',
    this.password = '',
    this.dbName = 'gtdoro',
    this.isEnabled = false,
    this.lastSeq,
  });

  SyncConfig copyWith({
    String? url,
    String? username,
    String? password,
    String? dbName,
    bool? isEnabled,
    String? lastSeq,
  }) {
    return SyncConfig(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      dbName: dbName ?? this.dbName,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSeq: lastSeq ?? this.lastSeq,
    );
  }
}
