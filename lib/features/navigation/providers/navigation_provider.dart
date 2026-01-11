import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:gtdoro/features/navigation/models/nav_tab.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';

class NavigationProvider extends ChangeNotifier {
  NavTab _currentTab = NavTab.inbox;
  SyncProvider? _syncProvider;

  NavTab get currentTab => _currentTab;
  int get currentIndex => _currentTab.index;

  /// SyncProvider 설정 (화면 전환 시 동기화 트리거를 위해)
  void setSyncProvider(SyncProvider? syncProvider) {
    _syncProvider = syncProvider;
  }

  void setTab(NavTab tab) {
    if (_currentTab != tab) {
      final previousTab = _currentTab;
      _currentTab = tab;
      notifyListeners();
      
      // 화면 전환 시 동기화 트리거 (이벤트 기반 동기화)
      if (_syncProvider != null && _syncProvider!.canSync) {
        dev.log('NavigationProvider: Tab changed from ${previousTab.name} to ${tab.name}, triggering sync');
        _syncProvider!.triggerSyncOnScreenChange();
      }
    }
  }

  void setIndex(int index) {
    setTab(NavTab.values[index]);
  }
}
