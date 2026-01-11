import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import 'package:gtdoro/core/constants/sync_constants.dart';
import 'package:gtdoro/core/utils/action_grouping_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/repositories/action_repository.dart';

/// Mixin for Logbook functionality in ActionProvider
mixin ActionProviderLogbookMixin on ChangeNotifier {
  // These fields must be provided by the implementing class
  ActionRepository get repository;
  List<ActionWithContexts> get allActions;
  
  // Logbook state fields
  List<ActionWithContexts> _logbookItems = [];
  bool _isFetchingLogbook = false;
  bool _hasMoreLogbook = true;

  // Search state for Logbook
  List<ActionWithContexts> _logbookSearchResults = [];
  bool _isSearchingLogbook = false;
  String _logbookSearchQuery = '';
  Timer? _debounce;

  // Logbook Getters
  List<ActionWithContexts> get logbookActions => _logbookItems;
  bool get isFetchingLogbook => _isFetchingLogbook;
  bool get hasMoreLogbook => _hasMoreLogbook;
  bool get isSearchingLogbook => _isSearchingLogbook;
  String get logbookSearchQuery => _logbookSearchQuery;
  
  Map<String, List<ActionWithContexts>> get groupedLogbookActions => _groupLogbookActions();

  void cancelLogbookDebounce() {
    _debounce?.cancel();
  }

  Map<String, List<ActionWithContexts>> _groupLogbookActions() {
    final source =
        _logbookSearchQuery.isEmpty ? logbookActions : _logbookSearchResults;
    dev.log('ActionProviderLogbookMixin: _groupLogbookActions - source length: ${source.length}, searchQuery: "$_logbookSearchQuery"');
    final grouped = ActionGroupingHelper.groupActionsByDate(
      source,
      (actionWithContexts) => actionWithContexts.action.completedAt,
      '날짜 정보 없음',
    );
    dev.log('ActionProviderLogbookMixin: _groupLogbookActions - grouped keys: ${grouped.keys.toList()}');
    return grouped;
  }

  Future<void> fetchInitialLogbook() async {
    dev.log('ActionProviderLogbookMixin: fetchInitialLogbook called');
    _logbookItems = [];
    _hasMoreLogbook = true;
    await fetchMoreLogbookEntries();
    dev.log('ActionProviderLogbookMixin: fetchInitialLogbook completed, ${_logbookItems.length} items loaded');
  }

  Future<void> fetchMoreLogbookEntries() async {
    if (_isFetchingLogbook || !_hasMoreLogbook) {
      dev.log('ActionProviderLogbookMixin: fetchMoreLogbookEntries skipped (isFetching: $_isFetchingLogbook, hasMore: $_hasMoreLogbook)');
      return;
    }

    _isFetchingLogbook = true;
    notifyListeners();

    try {
      final offset = _logbookItems.length;
      dev.log('ActionProviderLogbookMixin: fetchMoreLogbookEntries - offset: $offset, current items: ${_logbookItems.length}');
      
      final newItems = await repository.getCompletedActions(
        limit: LogbookConstants.pageLimit,
        offset: offset,
      ).timeout(
        LogbookConstants.loadingTimeout,
        onTimeout: () {
          dev.log('ActionProviderLogbookMixin: Logbook loading timeout');
          return <ActionWithContexts>[];
        },
      );

      dev.log('ActionProviderLogbookMixin: fetchMoreLogbookEntries - received ${newItems.length} new items');

      // Check if we have more items
      if (newItems.length < LogbookConstants.pageLimit) {
        _hasMoreLogbook = false;
        dev.log('ActionProviderLogbookMixin: No more logbook entries available');
      }

      // Add new items (no duplicates possible with proper pagination)
      _logbookItems.addAll(newItems);
      dev.log('ActionProviderLogbookMixin: Total logbook items: ${_logbookItems.length}');
    } catch (e, stackTrace) {
      dev.log('ActionProviderLogbookMixin: Failed to load more logbook entries', error: e, stackTrace: stackTrace);
      dev.log('  - 에러 타입: ${e.runtimeType}');
      dev.log('  - 에러 메시지: $e');
      _hasMoreLogbook = false; // Stop loading on error
    } finally {
      _isFetchingLogbook = false;
      notifyListeners();
    }
  }

  Future<void> searchLogbook(String query) async {
    _logbookSearchQuery = query;
    _debounce?.cancel();

    if (query.isEmpty) {
      _logbookSearchResults = [];
      _isSearchingLogbook = false;
      notifyListeners();
      return;
    }

    _isSearchingLogbook = true;
    notifyListeners();

    _debounce = Timer(LogbookConstants.searchDebounceDelay, () async {
      try {
        _logbookSearchResults = await repository.searchCompletedActions(query);
      } catch (e, stackTrace) {
        dev.log('ActionProviderLogbookMixin: Logbook search failed', error: e, stackTrace: stackTrace);
        _logbookSearchResults = []; // Set empty list on error
      } finally {
        _isSearchingLogbook = false;
        notifyListeners();
      }
    });
  }
}
