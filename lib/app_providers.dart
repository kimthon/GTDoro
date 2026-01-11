import 'package:flutter/material.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:provider/provider.dart';
import 'package:gtdoro/core/theme/theme_provider.dart';
import 'package:gtdoro/features/navigation/providers/navigation_provider.dart';
import 'package:gtdoro/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';
import 'package:gtdoro/features/todo/providers/recurring_provider.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';
import 'package:gtdoro/data/repositories/action_repository.dart';
import 'package:gtdoro/data/repositories/context_repository.dart';
import 'package:gtdoro/data/repositories/recurring_action_repository.dart';
import 'package:gtdoro/data/repositories/scheduled_action_repository.dart';
import 'package:gtdoro/features/todo/providers/scheduled_provider.dart';

class AppProviders extends StatefulWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late Future<Map<String, dynamic>> _initFuture;
  late AppDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    // Changed from Future to synchronous initialization
    final providers = _initializeAll();
    _initFuture = Future.value(providers);
  }

  Map<String, dynamic> _initializeAll() {
    final actionRepo = ActionRepository(_db);
    final contextRepo = ContextRepository(_db);
    final recurringRepo = RecurringActionRepository(_db);
    final scheduledRepo = ScheduledActionRepository(_db);

    final actionProvider = ActionProvider(
      repository: actionRepo,
    );

    final contextProvider = ContextProvider(
      actionProvider: actionProvider,
      repository: contextRepo,
    );

    final recurringProvider = RecurringProvider(
      actionProvider: actionProvider,
      repository: recurringRepo,
    );

    final scheduledProvider = ScheduledProvider(
      repository: scheduledRepo,
      actionProvider: actionProvider,
    );

    final syncProvider = SyncProvider(
      db: _db,
      actionRepo: actionRepo,
      contextRepo: contextRepo,
      recurringRepo: recurringRepo,
      scheduledRepo: scheduledRepo,
      actionProvider: actionProvider,
      contextProvider: contextProvider,
      recurringProvider: recurringProvider,
    );

    actionProvider.setSyncProvider(syncProvider);
    contextProvider.setSyncProvider(syncProvider);
    recurringProvider.setSyncProvider(syncProvider);
    scheduledProvider.setSyncProvider(syncProvider);
    actionProvider.setContextProvider(contextProvider);

    syncProvider.init();

    return {
      'action': actionProvider,
      'context': contextProvider,
      'recurring': recurringProvider,
      'scheduled': scheduledProvider,
      'sync': syncProvider,
    };
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: Text('데이터 로딩 실패: ${snapshot.error}')),
            ),
          );
        }

        final providers = snapshot.data!;

        final syncProvider = providers['sync'] as SyncProvider;
        
        return MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: _db),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) {
                final navProvider = NavigationProvider();
                navProvider.setSyncProvider(syncProvider); // 화면 전환 시 동기화를 위해 연결
                return navProvider;
              },
            ),
            ChangeNotifierProvider(create: (_) => PomodoroProvider()),
            ChangeNotifierProvider.value(value: providers['action'] as ActionProvider),
            ChangeNotifierProvider.value(value: providers['context'] as ContextProvider),
            ChangeNotifierProvider.value(value: providers['recurring'] as RecurringProvider),
            ChangeNotifierProvider.value(value: providers['scheduled'] as ScheduledProvider),
            ChangeNotifierProvider.value(value: syncProvider),
          ],
          child: widget.child,
        );
      },
    );
  }
}
