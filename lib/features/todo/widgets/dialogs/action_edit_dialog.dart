import 'dart:developer' as dev;

import 'package:flutter/material.dart' hide Action;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/core/utils/error_handler.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';
import 'package:gtdoro/features/todo/providers/recurring_provider.dart';
import 'package:gtdoro/features/todo/providers/scheduled_provider.dart';
import 'package:gtdoro/features/todo/widgets/action_form_fields.dart';

class ActionEditDialog extends StatefulWidget {
  final ActionWithContexts? actionWithContexts;
  final bool isRoutineMode;
  final GTDStatus? prefilledStatus;
  final String? routineActionId; // For recurring actions (deprecated for scheduled)
  final ScheduledAction? scheduledAction; // For scheduled actions

  const ActionEditDialog({
    super.key,
    this.actionWithContexts,
    this.isRoutineMode = false,
    this.prefilledStatus,
    this.routineActionId,
    this.scheduledAction,
  });

  @override
  State<ActionEditDialog> createState() => _ActionEditDialogState();
}

class _ActionEditDialogState extends State<ActionEditDialog> {
  // 성능 최적화: DateFormat 캐싱 (반복 생성 방지)
  static final _dateFormatter = DateFormat('yyyy-MM-dd');
  
  final ButtonStyle _buttonStyle = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
  );

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _waitingController;
  late TextEditingController _intervalController;
  late TextEditingController _totalCountController;
  late TextEditingController _advanceDaysController;
  late GTDStatus _status;
  DateTime? _dueDate;
  late int _energy;
  late int _duration;
  late List<String> _selectedContextIds;
  RecurrenceType _recurType = RecurrenceType.daily;
  int _interval = 1;
  int _totalCount = 1; // Scheduled는 기본적으로 한 번만 실행 (totalCount == 1)
  int _advanceDays = 0; // Days before start date to create action
  bool _skipHolidays = false; // Skip holidays when scheduling

  bool get _isEditMode => widget.actionWithContexts != null || widget.routineActionId != null || widget.scheduledAction != null;

  bool get _isValid {
    final title = _titleController.text.trim();
    if (title.isEmpty) return false;
    
    // Waiting For 화면에서는 waitingFor 필드가 필수
    if (_status == GTDStatus.waiting) {
      final waitingFor = _waitingController.text.trim();
      if (waitingFor.isEmpty) return false;
    }
    
    // Routine mode (Scheduled)에서는 시작 날짜가 필수
    // 단, 편집 모드에서는 기존 날짜가 있으므로 체크하지 않음
    if (widget.isRoutineMode && _dueDate == null && !_isEditMode) {
      return false;
    }
    
    return true;
  }

  @override
  void initState() {
    super.initState();
    final actionWithContexts = widget.actionWithContexts;
    final action = actionWithContexts?.action;

    // Initialize from ScheduledAction if provided
    if (widget.scheduledAction != null) {
      final scheduled = widget.scheduledAction!;
      _titleController = TextEditingController(text: scheduled.title);
      _descController = TextEditingController(text: scheduled.description ?? '');
      _waitingController = TextEditingController(text: '');
      _dueDate = scheduled.startDate;
      _energy = scheduled.energyLevel;
      _duration = scheduled.duration;
      _advanceDays = scheduled.advanceDays;
      _skipHolidays = scheduled.skipHolidays;
      _selectedContextIds = List<String>.from(scheduled.contextIds);
      _status = GTDStatus.scheduled;
      _totalCount = 1; // Scheduled는 항상 1
    } else {
      // Initialize from regular action
      _titleController = TextEditingController(text: action?.title ?? '');
      _descController = TextEditingController(text: action?.description ?? '');
      _waitingController = TextEditingController(text: action?.waitingFor ?? '');
      
      // Status 초기화 - Scheduled는 독립적으로 관리
      final initialStatus = widget.prefilledStatus ??
          (widget.isRoutineMode
              ? GTDStatus.scheduled
              : action?.status ?? GTDStatus.inbox);
      
      _status = initialStatus;
      _dueDate = action?.dueDate;
      _energy = action?.energyLevel ?? 3;
      _duration = action?.duration ?? 10;
      // 성능 최적화: 불필요한 List.from() 제거 (이미 List이므로)
      _selectedContextIds =
          actionWithContexts != null ? [...actionWithContexts.contextIds] : [];
    }

    // Initialize recurring action controllers
    // Scheduled (routine mode)는 기본적으로 totalCount = 1 (한 번만 실행)
    if (widget.isRoutineMode && !_isEditMode && widget.routineActionId == null && widget.scheduledAction == null) {
      _totalCount = 1; // 새로 생성하는 Scheduled는 기본값 1
    }
    
    _intervalController = TextEditingController(text: _interval.toString());
    _totalCountController = TextEditingController(text: _totalCount.toString());
    _advanceDaysController = TextEditingController(text: _advanceDays.toString());

    if (widget.isRoutineMode && widget.scheduledAction == null) {
      if (_isEditMode || widget.routineActionId != null) {
        try {
          // Since this is a routine, the action ID corresponds to a recurring action
          final actionId = widget.routineActionId ?? action?.id;
          if (actionId != null) {
          final recurringAction = context
              .read<RecurringProvider>()
              .actions
                .firstWhere(
                  (a) => a.id == actionId,
                  orElse: () => throw StateError('Recurring action not found: $actionId'),
                );
          _recurType = recurringAction.type;
          _interval = recurringAction.interval;
          _totalCount = recurringAction.totalCount;
          _advanceDays = recurringAction.advanceDays;
          _skipHolidays = recurringAction.skipHolidays;
          
          // Update controllers with values from recurring action
          _intervalController.text = _interval.toString();
          _totalCountController.text = _totalCount.toString();
          _advanceDaysController.text = _advanceDays.toString();
          
            // Initialize fields from recurring action if actionWithContexts is null
            if (action == null) {
              _titleController.text = recurringAction.title;
              _descController.text = recurringAction.description ?? '';
              _energy = recurringAction.energyLevel;
              _duration = recurringAction.duration;
              _selectedContextIds = List<String>.from(recurringAction.contextIds);
            }
          }
        } catch (e) {
          dev.log('Error initializing recurring action in dialog: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _waitingController.dispose();
    _intervalController.dispose();
    _totalCountController.dispose();
    _advanceDaysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }

    // Waiting For 화면에서는 waitingFor 필드가 필수
    if (_status == GTDStatus.waiting) {
      final waitingFor = _waitingController.text.trim();
      if (waitingFor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting For 필드를 입력해주세요.')),
        );
        return;
      }
    }

    final actionProvider = context.read<ActionProvider>();

    // 성능 최적화: 중복 제거 후 리스트로 변환 (필요한 작업)
    // Set으로 변환하여 중복 제거 후 다시 리스트로 (순서 유지)
    final uniqueContextIds = _selectedContextIds.toSet().toList();

    if (widget.isRoutineMode) {
      try {
        // Scheduled action (new structure)
        if (widget.scheduledAction != null) {
          final scheduledProvider = context.read<ScheduledProvider>();
          // 편집 모드에서는 시작 날짜가 없어도 기존 날짜 유지
          final startDate = _dueDate ?? widget.scheduledAction!.startDate;
          await scheduledProvider.updateAction(
            id: widget.scheduledAction!.id,
            title: title,
            description: _descController.text,
            startDate: startDate,
            energyLevel: _energy,
            duration: _duration,
            advanceDays: _advanceDays,
            skipHolidays: _skipHolidays,
            contextIds: uniqueContextIds,
          );
        }
        // Recurring action (legacy - for backward compatibility)
        else if (_isEditMode || widget.routineActionId != null) {
          final recurringProvider = context.read<RecurringProvider>();
          final actionId = widget.routineActionId ?? widget.actionWithContexts?.action.id;
          if (actionId != null) {
            await recurringProvider.updateAction(
              actionId,
              title: title,
              description: _descController.text,
              type: _recurType,
              interval: _interval,
              totalCount: _totalCount,
              energyLevel: _energy,
              duration: _duration,
              advanceDays: _advanceDays,
              skipHolidays: _skipHolidays,
              contextIds: uniqueContextIds,
            );
          }
        } else {
          // Add new scheduled action
          if (_dueDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('시작 날짜를 선택해주세요.')),
            );
            return;
          }
          final scheduledProvider = context.read<ScheduledProvider>();
          await scheduledProvider.addAction(
            title: title,
            description: _descController.text,
            startDate: _dueDate!,
            energyLevel: _energy,
            duration: _duration,
            advanceDays: _advanceDays,
            skipHolidays: _skipHolidays,
            contextIds: uniqueContextIds,
          );
        }
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e, stackTrace) {
        dev.log('ActionEditDialog: Error saving scheduled/recurring action', error: e, stackTrace: stackTrace);
        if (!mounted) return;
        ErrorHandler.showError(context, e);
      }
    } else {
      try {
        if (_isEditMode && widget.actionWithContexts != null) {
          // Update existing regular action
          await actionProvider.updateAction(
            widget.actionWithContexts!.action.id,
            title: title,
            description: _descController.text,
            waitingFor: _waitingController.text,
            status: _status,
            dueDate: _dueDate,
            energyLevel: _energy,
            duration: _duration,
            contextIds: uniqueContextIds,
          );
        } else {
          // Add new regular action
          await actionProvider.addAction(
            title: title,
            status: _status,
            dueDate: _dueDate,
            energyLevel: _energy,
            duration: _duration,
            contextIds: uniqueContextIds,
            description: _descController.text,
            waitingFor: _waitingController.text,
          );
        }
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e, stackTrace) {
        dev.log('ActionEditDialog: Error saving action', error: e, stackTrace: stackTrace);
        if (!mounted) return;
        ErrorHandler.showError(context, e);
      }
    }
  }

  void _cancel() {
    // Analytics tracking removed
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final Widget contentWidget = _buildContentWidget(context);

    if (isMobile) {
      return _buildMobileLayout(theme, contentWidget);
    } else {
      return _buildDesktopLayout(theme, contentWidget);
    }
  }

  Widget _buildContentWidget(BuildContext context) {
    final contextProvider = context.watch<ContextProvider>();
    final availableContexts = contextProvider.availableContexts;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActionFormFields.buildTitle(
          _titleController,
          onChanged: () => setState(() {}), // 제목 변경 시 상태 업데이트하여 저장 버튼 활성화
        ),
        const SizedBox(height: 16),
        ActionFormFields.buildDescription(_descController),
        if (!widget.isRoutineMode && _status == GTDStatus.waiting) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _waitingController,
            decoration: InputDecoration(
              labelText: 'Waiting For *',
              hintText: '누구에게 기다리고 있는지...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}), // 실시간 검증을 위한 상태 업데이트
          ),
        ],
        const SizedBox(height: 16),
        // Scheduled는 독립적으로 관리 - 상태 변경 불가
        Builder(
          builder: (context) {
            final isScheduled = widget.actionWithContexts?.action.status == GTDStatus.scheduled || 
                              widget.prefilledStatus == GTDStatus.scheduled ||
                              widget.isRoutineMode;
            
            if (isScheduled) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  'Scheduled',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              );
            }
            
            // Filter out Scheduled from available statuses
            final availableStatuses = GTDStatus.values.where((status) {
              return status != GTDStatus.scheduled;
            }).toList();
            
            // Ensure we have at least one available status
            if (availableStatuses.isEmpty) {
              return const SizedBox.shrink();
            }
            
            // Ensure current status is in available list, otherwise use first available
            final currentStatus = availableStatuses.contains(_status) 
                ? _status 
                : availableStatuses.first;
            
            return DropdownButtonFormField<GTDStatus>(
              initialValue: currentStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: availableStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null && v != GTDStatus.scheduled) {
                  setState(() => _status = v);
                  // Status가 변경되면 유효성 검사 업데이트
                }
              },
            );
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _dueDate = picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.isRoutineMode ? '시작 날짜 *' : 'Due Date',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _dueDate != null 
                  ? _dateFormatter.format(_dueDate!) 
                  : (widget.isRoutineMode ? '시작 날짜를 선택하세요' : 'No date'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Level: $_energy',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              value: _energy.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_energy',
              onChanged: (value) {
                setState(() => _energy = value.round());
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration: $_duration분',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_duration분',
              onChanged: (value) {
                setState(() => _duration = value.round());
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Contexts', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableContexts.map((ctx) {
            final isSelected = _selectedContextIds.contains(ctx.id);
            return FilterChip(
              label: Text('#${ContextProvider.formatContextName(ctx)}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedContextIds.add(ctx.id);
                  } else {
                    _selectedContextIds.remove(ctx.id);
                  }
                });
              },
              backgroundColor: Color(ctx.colorValue).withAlpha((255 * 0.1).round()),
              selectedColor: Color(ctx.colorValue).withAlpha((255 * 0.3).round()),
              checkmarkColor: Color(ctx.colorValue),
            );
          }).toList(),
        ),
        if (widget.isRoutineMode) ...[
          const SizedBox(height: 20),
          Divider(color: theme.colorScheme.outline.withAlpha((255 * 0.1).round())),
          const SizedBox(height: 12),
          Text(
            '반복 설정',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
            ),
          ),
          const SizedBox(height: 12),
          // Recurrence Type과 Interval을 한 줄에
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<RecurrenceType>(
                  initialValue: _recurType,
                  decoration: InputDecoration(
                    labelText: '반복',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
                  ),
                  items: RecurrenceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name == 'daily' ? '매일' : 
                        type.name == 'weekly' ? '매주' :
                        type.name == 'monthly' ? '매월' : type.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _recurType = v!),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _intervalController,
                  decoration: InputDecoration(
                    labelText: '간격',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      setState(() => _interval = parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total Count와 Advance Days를 한 줄에
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _totalCountController,
                  decoration: InputDecoration(
                    labelText: '횟수',
                    hintText: '0=무한',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      setState(() => _totalCount = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _advanceDaysController,
                  decoration: InputDecoration(
                    labelText: '미리 생성',
                    hintText: '일수',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      setState(() => _advanceDays = parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Skip Holidays를 간단한 Switch로
          SwitchListTile(
            title: const Text('휴일 건너뛰기', style: TextStyle(fontSize: 14)),
            value: _skipHolidays,
            onChanged: (v) => setState(() => _skipHolidays = v),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, Widget contentWidget) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditMode ? '편집' : (widget.isRoutineMode ? '루틴 추가' : '할 일 추가'),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cancel,
          tooltip: '취소',
        ),
        actions: [
          TextButton(
            onPressed: _isValid ? _save : null,
            child: const Text(
              '저장',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: contentWidget,
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Widget contentWidget) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r28)),
      title: Text(widget.isRoutineMode ? 'Routine Factory' : 'Clarify Task'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(child: contentWidget),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: Text('Cancel', style: TextStyle(color: theme.colorScheme.outline))),
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.p8, bottom: AppSizes.p8),
          child: FilledButton.icon(
            onPressed: _isValid ? _save : null,
            icon: Icon(widget.isRoutineMode ? Icons.bolt : Icons.check),
            label: Text(widget.isRoutineMode ? 'Start Routine' : 'Confirm'),
            style: _buttonStyle,
          ),
        ),
      ],
    );
  }
}
