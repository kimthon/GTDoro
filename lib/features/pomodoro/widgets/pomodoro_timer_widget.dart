import 'dart:async';
import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart'; // Import Provider
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart'; // Import ActionProvider

class PomodoroTimerWidget extends StatefulWidget {
  final Action? currentAction; // Optional current action
  const PomodoroTimerWidget({super.key, this.currentAction});

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget> {
  // Default durations
  static const int _defaultWorkDurationMinutes = 25;
  static const int _defaultShortBreakDurationMinutes = 5;
  static const int _defaultLongBreakDurationMinutes = 15;

  // Configurable durations
  late int _currentWorkDurationMinutes;
  late int _currentShortBreakDurationMinutes;
  late int _currentLongBreakDurationMinutes;

  Duration _duration = const Duration(minutes: _defaultWorkDurationMinutes);
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isWorkTime = true;
  int _pomodoroCount = 0; // To track for long breaks
  Duration _totalTimeSpent = Duration.zero; // Track total time spent on current action
  bool _isDisposed = false; // Track dispose state

  @override
  void initState() {
    super.initState();
    _currentWorkDurationMinutes = _defaultWorkDurationMinutes;
    _currentShortBreakDurationMinutes = _defaultShortBreakDurationMinutes;
    _currentLongBreakDurationMinutes = _defaultLongBreakDurationMinutes;
    _resetTimer();
  }

  @override
  void didUpdateWidget(covariant PomodoroTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAction != oldWidget.currentAction) {
      // If the associated action changes, reset the timer
      _resetTimer();
    }
  }

  void _startTimer() {
    if (_isDisposed) return;
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (!mounted) return; // Return if widget is not mounted
      setState(() {
        if (_duration.inSeconds > 0) {
          _duration = _duration - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isPaused = false;
          _handleTimerCompletion();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _duration = Duration(minutes: _currentWorkDurationMinutes);
      _isRunning = false;
      _isPaused = false;
      _isWorkTime = true;
      _pomodoroCount = 0;
      _totalTimeSpent = Duration.zero;
    });
  }

  void _handleTimerCompletion() {
    if (_isWorkTime) {
      _pomodoroCount++;
      _totalTimeSpent += Duration(minutes: _currentWorkDurationMinutes); // Add completed work duration

      if (widget.currentAction != null) {
        // Update ActionModel with pomodoro count and total time spent
        context.read<ActionProvider>().updatePomodoroData(
              widget.currentAction!.id,
              _pomodoroCount,
              _totalTimeSpent,
            );
      }

      if (_pomodoroCount % 4 == 0) {
        // Long break after 4 pomodoros
        _duration = Duration(minutes: _currentLongBreakDurationMinutes);
        _isWorkTime = false;
        _showCompletionDialog('Work time finished! Take a long break.');
      } else {
        // Short break
        _duration = Duration(minutes: _currentShortBreakDurationMinutes);
        _isWorkTime = false;
        _showCompletionDialog('Work time finished! Take a short break.');
      }
    } else {
      // Break finished, go back to work time
      _duration = Duration(minutes: _currentWorkDurationMinutes);
      _isWorkTime = true;
      _showCompletionDialog('Break finished! Time to work.');
    }
    _startTimer(); // Automatically start the next phase
  }

  void _showCompletionDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pomodoro'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PomodoroSettingsDialog(
          initialWorkDuration: _currentWorkDurationMinutes,
          initialShortBreakDuration: _currentShortBreakDurationMinutes,
          initialLongBreakDuration: _currentLongBreakDurationMinutes,
          onSave: (work, shortBreak, longBreak) {
            setState(() {
              _currentWorkDurationMinutes = work;
              _currentShortBreakDurationMinutes = shortBreak;
              _currentLongBreakDurationMinutes = longBreak;
              _resetTimer(); // Reset timer with new durations
            });
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsDialog,
          ),
        ),
        if (widget.currentAction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Working on: ${widget.currentAction!.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        Text(
          _formatDuration(_duration),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(
          _isWorkTime ? 'Work Time' : 'Break Time',
          style: TextStyle(
            fontSize: 20,
            color: _isWorkTime ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startTimer,
              child: const Text('Start'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isRunning ? _pauseTimer : null,
              child: const Text('Pause'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isRunning || _isPaused ? _resetTimer : null,
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}

// Placeholder for PomodoroSettingsDialog
class PomodoroSettingsDialog extends StatefulWidget {
  final int initialWorkDuration;
  final int initialShortBreakDuration;
  final int initialLongBreakDuration;
  final Function(int work, int shortBreak, int longBreak) onSave;

  const PomodoroSettingsDialog({
    super.key,
    required this.initialWorkDuration,
    required this.initialShortBreakDuration,
    required this.initialLongBreakDuration,
    required this.onSave,
  });

  @override
  State<PomodoroSettingsDialog> createState() => _PomodoroSettingsDialogState();
}

class _PomodoroSettingsDialogState extends State<PomodoroSettingsDialog> {
  late TextEditingController _workController;
  late TextEditingController _shortBreakController;
  late TextEditingController _longBreakController;

  @override
  void initState() {
    super.initState();
    _workController = TextEditingController(text: widget.initialWorkDuration.toString());
    _shortBreakController = TextEditingController(text: widget.initialShortBreakDuration.toString());
    _longBreakController = TextEditingController(text: widget.initialLongBreakDuration.toString());
  }

  @override
  void dispose() {
    _workController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pomodoro Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _workController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Work Duration (minutes)'),
          ),
          TextField(
            controller: _shortBreakController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Short Break Duration (minutes)'),
          ),
          TextField(
            controller: _longBreakController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Long Break Duration (minutes)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final work = int.tryParse(_workController.text) ?? 25;
            final shortBreak = int.tryParse(_shortBreakController.text) ?? 5;
            final longBreak = int.tryParse(_longBreakController.text) ?? 15;
            widget.onSave(work, shortBreak, longBreak);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
