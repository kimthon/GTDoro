import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import 'package:gtdoro/core/utils/holiday_checker.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/repositories/scheduled_action_repository.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';

/// Generates Next Actions from ScheduledAction templates
class ScheduledActionGenerator {
  final ActionProvider _actionProvider;
  final ScheduledActionRepository _scheduledRepository;

  ScheduledActionGenerator(this._actionProvider, this._scheduledRepository);

  Future<bool> generateActions(List<ScheduledAction> scheduledActions) async {
    try {
      // 성능 최적화: where 대신 직접 필터링하여 불필요한 리스트 생성 방지
      final activeActions = <ScheduledAction>[];
      for (final a in scheduledActions) {
        if (!a.isDeleted && !a.isCreated) {
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
        activeActions.sort((a, b) => a.startDate.compareTo(b.startDate));
      }

      for (int i = 0; i < activeActions.length; i++) {
        var currentAction = activeActions[i];

        if (currentAction.isDeleted || currentAction.isCreated) continue;

        try {
          var startDate = currentAction.startDate;

          // Adjust start date if skipHolidays is enabled
          if (currentAction.skipHolidays) {
            startDate = HolidayChecker.adjustDateForHoliday(startDate, true);

            // If date was adjusted, update the scheduled action
            if (startDate != currentAction.startDate) {
              dev.log('ScheduledActionGenerator: Scheduled action "${currentAction.title}" - 날짜가 휴일이어서 ${startDate.toString().split(' ')[0]}로 조정됨');
              final companion = ScheduledActionsCompanion(
                id: Value(currentAction.id),
                startDate: Value(startDate),
                updatedAt: Value(DateTime.now()),
              );
              await _scheduledRepository.saveScheduledAction(companion);
              isChanged = true;
              continue; // Skip action creation this time, will be processed next time
            }
          }

          // Calculate when to create the action
          DateTime createDate;
          if (currentAction.advanceDays > 0) {
            // If advanceDays is set, create action in advance
            createDate = startDate.subtract(Duration(days: currentAction.advanceDays));
          } else {
            // If advanceDays is 0, create action when start date arrives
            createDate = startDate;
          }
          final createDateOnly = DateTime(createDate.year, createDate.month, createDate.day);
          final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);

          // Check if action already exists for this date (중복 생성 방지)
          final actionAlreadyExists = _actionProvider.hasActionWithTitleAndDueDate(
            currentAction.title,
            startDate,
          );

          if (actionAlreadyExists) {
            dev.log('ScheduledActionGenerator: Scheduled action "${currentAction.title}" - 이미 해당 날짜에 Action이 존재함');
            dev.log('  - 시작일: ${startDateOnly.toString().split(' ')[0]}');
            // isCreated를 업데이트하여 더 이상 생성하지 않도록 함
            final companion = ScheduledActionsCompanion(
              id: Value(currentAction.id),
              isCreated: const Value(true),
              updatedAt: Value(DateTime.now()),
            );
            await _scheduledRepository.saveScheduledAction(companion);
            isChanged = true;
            dev.log('ScheduledActionGenerator: isCreated 업데이트 완료 (Action 존재 확인)');
            continue;
          }

          // Check why action is not being created and log detailed information
          if (createDateOnly.isAfter(today)) {
            final daysUntilCreate = createDateOnly.difference(today).inDays;
            final todayStr = today.toString().split(' ')[0];
            final createDateStr = createDateOnly.toString().split(' ')[0];
            final startDateStr = startDateOnly.toString().split(' ')[0];
            dev.log('ScheduledActionGenerator: Scheduled action "${currentAction.title}" - 아직 생성 시점이 아님');
            dev.log('  - 오늘: $todayStr');
            dev.log('  - 생성 예정일: $createDateStr ($daysUntilCreate일 후)');
            dev.log('  - 시작일: $startDateStr');
            dev.log('  - advanceDays: ${currentAction.advanceDays}');
            continue;
          }

          if (createDateOnly.isBefore(today)) {
            // 이미 지난 날짜는 생성하지 않음
            final todayStr = today.toString().split(' ')[0];
            final createDateStr = createDateOnly.toString().split(' ')[0];
            dev.log('ScheduledActionGenerator: Scheduled action "${currentAction.title}" - 생성 시점이 이미 지남');
            dev.log('  - 오늘: $todayStr');
            dev.log('  - 생성 예정일: $createDateStr (이미 지남)');
            dev.log('  - 시작일: ${startDateOnly.toString().split(' ')[0]}');
            // isCreated를 업데이트하여 더 이상 생성하지 않도록 함
            final companion = ScheduledActionsCompanion(
              id: Value(currentAction.id),
              isCreated: const Value(true), // Mark as expired/created
              updatedAt: Value(DateTime.now()),
            );
            await _scheduledRepository.saveScheduledAction(companion);
            isChanged = true;
            dev.log('ScheduledActionGenerator: isCreated 업데이트 완료 (생성 시점 지남)');
            continue;
          }

          // Create the action
          dev.log('ScheduledActionGenerator: Scheduled action "${currentAction.title}" - Action 생성 시작');
          dev.log('  - 생성일: ${createDateOnly.toString().split(' ')[0]}');
          dev.log('  - 시작일: ${startDateOnly.toString().split(' ')[0]}');
          dev.log('  - advanceDays: ${currentAction.advanceDays}');

          // Update isCreated BEFORE creating action to prevent race conditions
          final updateCompanion = ScheduledActionsCompanion(
            id: Value(currentAction.id),
            isCreated: const Value(true), // Mark as created
            updatedAt: Value(DateTime.now()),
          );
          await _scheduledRepository.saveScheduledAction(updateCompanion);
          isChanged = true;

          // Create the Next Action with dueDate set to startDate
          await _actionProvider.addActionFromBlueprint(
            title: currentAction.title,
            description: currentAction.description,
            status: GTDStatus.next, // Scheduled creates Next Actions
            dueDate: startDate,
            energyLevel: currentAction.energyLevel,
            duration: currentAction.duration,
            contextIds: currentAction.contextIds,
          );

          dev.log('ScheduledActionGenerator: Scheduled action "${currentAction.title}" - Action 생성 완료');
        } catch (e, stackTrace) {
          dev.log('ScheduledActionGenerator: Error processing scheduled action "${currentAction.title}"', error: e, stackTrace: stackTrace);
          // Continue processing other actions even if one fails
        }
      }

      return isChanged;
    } catch (e, stackTrace) {
      dev.log('ScheduledActionGenerator: Error in generateActions', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
