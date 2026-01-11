import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_breakpoints.dart';
import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/sync/models/connection_test_result.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';
import 'package:gtdoro/features/todo/screens/settings/context_manage_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contextProvider = context.watch<ContextProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth > AppBreakpoints.settingsTablet ? 2 : 1;
    if (screenWidth > AppBreakpoints.settingsDesktop) crossAxisCount = 3;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.settingsMaxWidth),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.p32, AppSizes.p32, AppSizes.p32, AppSizes.p24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: AppSizes.settingsTitleFontSize,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: AppSizes.settingsTitleLetterSpacing,
                        ),
                      ),
                      Text(
                        'Configure your workspace and sync preferences',
                        style: TextStyle(
                          fontSize: AppSizes.settingsSubtitleFontSize,
                          color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context, 'Connectivity'),
                      AppSizes.gapH16,
                      _buildSyncCard(context, syncProvider),
                      AppSizes.gapH24,
                      _buildSectionLabel(context, 'Data Organization'),
                      AppSizes.gapH16,
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSizes.p16,
                    mainAxisSpacing: AppSizes.p16,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final type = ContextType.values[index];
                      final count = contextProvider.availableContexts
                          .where((c) => c.typeCategory == type)
                          .length;
                      return _buildContextCategoryCard(context, type, count);
                    },
                    childCount: ContextType.values.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSizes.p32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Row(
      children: [
        Container(
          width: AppSizes.settingsSectionIndicatorWidth,
          height: AppSizes.settingsSectionIndicatorHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(AppSizes.settingsSectionIndicatorBorderRadius),
          ),
        ),
        AppSizes.gapW12,
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: AppSizes.settingsSectionLabelFontSize,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: AppSizes.settingsSectionLabelLetterSpacing,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncCard(BuildContext context, SyncProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCloudMode = provider.canSync;
    final isSyncing = provider.isSyncing;
    final isNetworkOnline = provider.isNetworkOnline;
    final isOracleConnected = provider.isOracleConnected;
    final connectionStatusText = provider.connectionStatusText;
    final isChecking = !provider.isConnectionChecked;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.settingsCardBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCloudMode
              ? [colorScheme.primaryContainer.withAlpha((255 * 0.4).round()), colorScheme.primaryContainer.withAlpha((255 * 0.1).round())]
              : [colorScheme.surfaceContainerHighest.withAlpha((255 * 0.4).round()), colorScheme.surfaceContainerHighest.withAlpha((255 * 0.1).round())],
        ),
        border: Border.all(
          color: isCloudMode ? colorScheme.primary.withAlpha((255 * 0.2).round()) : colorScheme.outline.withAlpha((255 * 0.1).round()),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.settingsCardBorderRadius),
        child: Column(
          children: [
            InkWell(
              // 연결 상태 확인을 위해 탭 가능하게 변경
              onTap: isCloudMode ? () async {
                await provider.checkConnectionStatus();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('연결 상태를 확인했습니다: ${provider.connectionStatusText}'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } : null,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    _buildSyncIcon(isCloudMode, isSyncing, isNetworkOnline, isOracleConnected, isChecking, colorScheme),
                    AppSizes.gapW20,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '자동 동기화',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppSizes.settingsSyncCardTitleFontSize),
                              ),
                              AppSizes.gapW8,
                              _buildStatusBadge(isCloudMode, isOracleConnected, colorScheme),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            connectionStatusText,
                            style: TextStyle(
                              fontSize: AppSizes.settingsSyncCardSubtitleFontSize,
                              color: colorScheme.onSurface.withAlpha((255 * 0.5).round()),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isCloudMode && isChecking)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '연결 확인 중...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withAlpha((255 * 0.4).round()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // DB 접근 테스트 버튼
            if (isCloudMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withAlpha((255 * 0.1).round()),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isSyncing || isChecking
                        ? null
                        : () => _showConnectionTestDialog(context, provider),
                    icon: const Icon(Icons.network_check, size: 18),
                    label: const Text('DB 접근 테스트'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIcon(
    bool isCloud,
    bool isSyncing,
    bool isNetworkOnline,
    bool? isOracleConnected,
    bool isChecking,
    ColorScheme colorScheme,
  ) {
    if (isSyncing) {
      return Container(
        width: AppSizes.settingsSyncIconSize,
        height: AppSizes.settingsSyncIconSize,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha((255 * 0.3).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.settingsSyncIconInnerPadding),
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.settingsSyncIconStrokeWidth,
            color: colorScheme.onPrimary,
          ),
        ),
      );
    }

    IconData iconData;
    Color iconColor;
    Color backgroundColor;
    List<BoxShadow>? boxShadow;

    if (!isCloud) {
      iconData = Icons.cloud_off_rounded;
      iconColor = colorScheme.onSurface;
      backgroundColor = colorScheme.surfaceContainerHighest;
      boxShadow = null;
    } else if (isChecking) {
      iconData = Icons.cloud_queue_rounded;
      iconColor = colorScheme.onPrimary;
      backgroundColor = colorScheme.primary.withAlpha((255 * 0.7).round());
      boxShadow = [
        BoxShadow(
          color: colorScheme.primary.withAlpha((255 * 0.3).round()),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ];
    } else if ((isOracleConnected ?? false) && isNetworkOnline) {
      iconData = Icons.cloud_done_rounded;
      iconColor = colorScheme.onPrimary;
      backgroundColor = colorScheme.primary;
      boxShadow = [
        BoxShadow(
          color: colorScheme.primary.withAlpha((255 * 0.3).round()),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ];
    } else if (!isNetworkOnline) {
      iconData = Icons.wifi_off_rounded;
      iconColor = colorScheme.onPrimary;
      backgroundColor = Colors.orange.withAlpha((255 * 0.8).round());
      boxShadow = [
        BoxShadow(
          color: Colors.orange.withAlpha((255 * 0.3).round()),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ];
    } else {
      iconData = Icons.cloud_off_rounded;
      iconColor = colorScheme.onPrimary;
      backgroundColor = Colors.red.withAlpha((255 * 0.8).round());
      boxShadow = [
        BoxShadow(
          color: Colors.red.withAlpha((255 * 0.3).round()),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ];
    }

    return Container(
      width: AppSizes.settingsSyncIconSize,
      height: AppSizes.settingsSyncIconSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: boxShadow,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: AppSizes.settingsSyncIconIconSize,
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool? isOracleConnected, ColorScheme colorScheme) {
    String badgeText;
    Color badgeColor;
    Color backgroundColor;

    if (!isActive) {
      badgeText = 'LOCAL';
      badgeColor = colorScheme.outline;
      backgroundColor = colorScheme.outline.withAlpha((255 * 0.1).round());
    } else if (isOracleConnected == null) {
      badgeText = 'CHECKING';
      badgeColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withAlpha((255 * 0.1).round());
    } else if (isOracleConnected) { // null 체크 후이므로 non-nullable
      badgeText = 'CONNECTED';
      badgeColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withAlpha((255 * 0.1).round());
    } else {
      badgeText = 'DISCONNECTED';
      badgeColor = Colors.red;
      backgroundColor = Colors.red.withAlpha((255 * 0.1).round());
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.settingsStatusBadgeHorizontalPadding,
        vertical: AppSizes.settingsStatusBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.settingsStatusBadgeBorderRadius),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: AppSizes.settingsStatusBadgeFontSize,
          fontWeight: FontWeight.w900,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildContextCategoryCard(BuildContext context, ContextType type, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContextManagePage(category: type),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.settingsCardBorderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.settingsCardBorderRadius),
          border: Border.all(
            color: colorScheme.outline.withAlpha((255 * 0.1).round()),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type.name.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count items',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionTestDialog(BuildContext context, SyncProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ConnectionTestDialog(provider: provider),
    );
  }
}

/// 연결 테스트 다이얼로그
class _ConnectionTestDialog extends StatefulWidget {
  final SyncProvider provider;

  const _ConnectionTestDialog({required this.provider});

  @override
  State<_ConnectionTestDialog> createState() => _ConnectionTestDialogState();
}

class _ConnectionTestDialogState extends State<_ConnectionTestDialog> {
  ConnectionTestResult? _testResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final result = await widget.provider.testConnectionDetailed();
      if (mounted) {
        setState(() {
          _testResult = result;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = ConnectionTestResult(
            success: false,
            message: '테스트 중 오류 발생',
            errorType: 'TestError',
            details: e.toString(),
            testTime: DateTime.now(),
            hasNetwork: false,
            hasOAuth2: false,
            apiUrl: '',
          );
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = _testResult;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.network_check, size: 24),
          SizedBox(width: 8),
          Text('DB 접근 테스트'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: _isTesting
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '연결 테스트 중...',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              )
            : result != null
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 결과 요약
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: result.success
                                ? Colors.green.withAlpha((255 * 0.1).round())
                                : Colors.red.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: result.success ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                result.success ? Icons.check_circle : Icons.error,
                                color: result.success ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result.statusText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: result.success ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 상세 정보
                        Text(
                          '테스트 결과',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('메시지', result.message, colorScheme),
                        if (result.statusCode != null)
                          _buildInfoRow('HTTP 상태 코드', '${result.statusCode}', colorScheme),
                        if (result.errorType != null)
                          _buildInfoRow('에러 타입', result.errorType!, colorScheme),
                        _buildInfoRow('API URL', result.apiUrl, colorScheme),
                        _buildInfoRow('네트워크', result.hasNetwork ? '연결됨' : '오프라인', colorScheme),
                        _buildInfoRow('OAuth2 인증', result.hasOAuth2 ? '설정됨' : '미설정', colorScheme),
                        _buildInfoRow(
                          '테스트 시간',
                          result.testTime.toLocal().toString().split('.')[0],
                          colorScheme,
                        ),
                        if (result.details != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '상세 정보',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              result.details!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
      ),
      actions: [
        if (!_isTesting) ...[
          TextButton(
            onPressed: _runTest,
            child: const Text('다시 테스트'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
