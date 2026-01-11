import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import 'package:gtdoro/core/constants/sync_constants.dart';
import 'package:gtdoro/core/utils/holiday_checker.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/repositories/recurring_action_repository.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';

extension RecurrenceTypeExtension on RecurrenceType {
  DateTime calculateNextDate(DateTime fromDate, int interval) {
    // interval이 0 이하이면 무한 루프 방지를 위해 최소 1로 설정
    final safeInterval = interval > 0 ? interval : 1;
    
    switch (this) {
      case RecurrenceType.daily:
        return fromDate.add(Duration(days: safeInterval));
      case RecurrenceType.weekly:
        return fromDate.add(Duration(days: 7 * safeInterval));
      case RecurrenceType.monthly:
        return DateTime(fromDate.year, fromDate.month + safeInterval, fromDate.day);
    }
  }
}

class RecurringActionGenerator {
  final ActionProvider _actionProvider;
  final RecurringActionRepository _recurringRepository;

  RecurringActionGenerator(this._actionProvider, this._recurringRepository);

  Future<bool> generateActions(List<RecurringAction> recurringActions) async {
    // 성능 최적화: where 대신 직접 필터링하여 불필요한 리스트 생성 방지
    final activeActions = <RecurringAction>[];
    for (final a in recurringActions) {
      if (!a.isDeleted) {
        activeActions.add(a);
      }
    }
    if (activeActions.isEmpty) return false;

    // 성능 최적화: 오늘 날짜를 한 번만 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isChanged = false;

    // 성능 최적화: 정렬은 필요할 때만 수행 (이미 정렬되어 있을 수 있음)
    if (activeActions.length > 1) {
      activeActions.sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));
    }

    for (int i = 0; i < activeActions.length; i++) {
      var currentAction = activeActions[i];
      
      bool getIsExpired(RecurringAction action) =>
          action.totalCount > 0 && action.currentCount >= action.totalCount;

      if (currentAction.isDeleted || getIsExpired(currentAction)) continue;

      // Skip one-time scheduled actions (totalCount == 1) - they are now handled by ScheduledActionGenerator
      if (currentAction.totalCount == 1) {
        dev.log('RecurringActionGenerator: Skipping one-time scheduled action "${currentAction.title}" - handled by ScheduledActionGenerator');
        continue;
      }

      var tempNextRunDate = currentAction.nextRunDate;
      var tempCurrentCount = currentAction.currentCount;
      bool actionWasUpdated = false;
      int iterationCount = 0;
      DateTime? previousNextRunDate; // 무한 루프 방지: 이전 날짜 추적

      while (!getIsExpired(currentAction.copyWith(currentCount: tempCurrentCount)) && 
             !tempNextRunDate.isAfter(today) &&
             iterationCount < RecurringActionConstants.maxIterations) {
        iterationCount++;
        
        // 무한 루프 방지: 날짜가 변경되지 않으면 루프 종료
        if (previousNextRunDate != null && tempNextRunDate == previousNextRunDate) {
          dev.log('RecurringActionGenerator: 날짜가 변경되지 않아 루프 종료 (무한 루프 방지)');
          dev.log('  - 제목: "${currentAction.title}"');
          dev.log('  - 날짜: ${tempNextRunDate.toString().split(' ')[0]}');
          dev.log('  - interval: ${currentAction.interval}');
          break;
        }
        previousNextRunDate = tempNextRunDate;
        
        var actionDate = tempNextRunDate; // 변수를 try 블록 밖으로 이동
        try {
          // Adjust date for holidays if skipHolidays is enabled
          if (currentAction.skipHolidays) {
            actionDate = HolidayChecker.adjustDateForHoliday(tempNextRunDate, true);
          }
          
          // 중복 생성 방지: 이미 해당 날짜에 Action이 존재하는지 확인
          final actionAlreadyExists = _actionProvider.hasActionWithTitleAndDueDate(
            currentAction.title,
            actionDate,
          );
          
          if (actionAlreadyExists) {
            dev.log('RecurringActionGenerator: 반복 작업 "${currentAction.title}" - 이미 해당 날짜에 Action이 존재함');
            dev.log('  - 실행 날짜: ${actionDate.toString().split(' ')[0]}');
            // 이미 존재하면 currentCount만 증가시키고 다음 날짜로 이동
            tempCurrentCount++;
            final oldNextRunDate = tempNextRunDate;
            tempNextRunDate = currentAction.type.calculateNextDate(
              tempNextRunDate,
              currentAction.interval,
            );
            
            // calculateNextDate가 같은 날짜를 반환하는 경우 체크 (무한 루프 방지)
            if (tempNextRunDate == oldNextRunDate) {
              dev.log('RecurringActionGenerator: calculateNextDate가 같은 날짜를 반환하여 루프 종료 (무한 루프 방지)');
              dev.log('  - 제목: "${currentAction.title}"');
              dev.log('  - 날짜: ${tempNextRunDate.toString().split(' ')[0]}');
              dev.log('  - interval: ${currentAction.interval}');
              break;
            }
            
            // If skipHolidays is enabled, adjust next run date to avoid holidays
            if (currentAction.skipHolidays) {
              tempNextRunDate = HolidayChecker.adjustDateForHoliday(tempNextRunDate, true);
            }
            
            actionWasUpdated = true;
            isChanged = true;
            continue; // 다음 반복으로 이동
          }
          
          await _actionProvider.addActionFromBlueprint(
            title: currentAction.title,
            description: currentAction.description,
            dueDate: actionDate,
            energyLevel: currentAction.energyLevel,
            duration: currentAction.duration,
            contextIds: currentAction.contextIds,
            triggerSync: false,
          );

          tempCurrentCount++;
          final oldNextRunDate = tempNextRunDate;
          tempNextRunDate = currentAction.type.calculateNextDate(
            tempNextRunDate,
            currentAction.interval,
          );
          
          // calculateNextDate가 같은 날짜를 반환하는 경우 체크 (무한 루프 방지)
          if (tempNextRunDate == oldNextRunDate) {
            dev.log('RecurringActionGenerator: calculateNextDate가 같은 날짜를 반환하여 루프 종료 (무한 루프 방지)');
            dev.log('  - 제목: "${currentAction.title}"');
            dev.log('  - 날짜: ${tempNextRunDate.toString().split(' ')[0]}');
            dev.log('  - interval: ${currentAction.interval}');
            break;
          }
          
          // If skipHolidays is enabled, adjust next run date to avoid holidays
          if (currentAction.skipHolidays) {
            tempNextRunDate = HolidayChecker.adjustDateForHoliday(tempNextRunDate, true);
          }
          
          actionWasUpdated = true;
          isChanged = true;
        } catch (e, stackTrace) {
          final actionDateStr = actionDate.toString().split(' ')[0];
          dev.log('RecurringActionGenerator: 반복 작업 생성 실패', error: e, stackTrace: stackTrace);
          dev.log('  - 제목: "${currentAction.title}"');
          dev.log('  - 실행 날짜: $actionDateStr');
          dev.log('  - 에러 타입: ${e.runtimeType}');
          dev.log('  - 에러 메시지: $e');
          break;
        }
      }

      if (iterationCount >= RecurringActionConstants.maxIterations) {
        dev.log('RecurringActionGenerator: Max iterations reached (ID: ${currentAction.id})');
      }

      if (actionWasUpdated) {
        final companion = RecurringActionsCompanion(
          id: Value(currentAction.id),
          currentCount: Value(tempCurrentCount),
          nextRunDate: Value(tempNextRunDate),
          updatedAt: Value(DateTime.now()),
        );
        await _recurringRepository.saveRecurringAction(companion);
      }
    }

    if (isChanged) {
      _actionProvider.triggerSync();
    }

    return isChanged;
  }
}
