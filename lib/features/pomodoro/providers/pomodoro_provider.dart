import 'package:flutter/material.dart' hide Action;
import 'package:gtdoro/data/local/app_database.dart';

class PomodoroProvider with ChangeNotifier {
  bool _showTimer = false;
  Action? _selectedAction;

  bool get showTimer => _showTimer;
  Action? get selectedAction => _selectedAction;

  void toggleTimer(bool isVisible) {
    _showTimer = isVisible;
    if (!_showTimer) {
      _selectedAction = null; // Reset selected action when timer is hidden
    }
    notifyListeners();
  }

  void selectAction(Action? action) {
    if (_selectedAction != action) {
      _selectedAction = action;
      notifyListeners();
    }
  }
}
