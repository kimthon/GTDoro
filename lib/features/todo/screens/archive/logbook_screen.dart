import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/widgets/tiles/action_item_tile.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch initial data when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Ensure search is cleared and initial data is fetched
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      }
      final provider = context.read<ActionProvider>();
      provider.searchLogbook('');
      provider.fetchInitialLogbook();
    });

    // Add listener to scroll controller to detect when user reaches the end
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only fetch more if not searching and has more data
    final provider = context.read<ActionProvider>();
    if (provider.logbookSearchQuery.isEmpty &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      provider.fetchMoreLogbookEntries();
    }
  }

  void _onSearchChanged(String query) {
    context.read<ActionProvider>().searchLogbook(query);
  }

  Widget _buildBody(ActionProvider provider) {
    // 로딩 중이면 로딩 인디케이터 표시
    if (provider.isFetchingLogbook && provider.logbookActions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.isSearchingLogbook) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedActions = provider.groupedLogbookActions;
    final sortedKeys = groupedActions.keys.toList()..sort((a, b) => b.compareTo(a));
    final query = provider.logbookSearchQuery;

    if (groupedActions.isEmpty) {
      return _buildEmptyState(query.isNotEmpty);
    }

    // If searching, don't use infinite scroll.
    if (query.isNotEmpty) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView.builder(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final date = sortedKeys[index];
            final actions = groupedActions[date]!;
            return _buildDateGroup(date, actions);
          },
        ),
      );
    }

    // Default paginated list view
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: sortedKeys.length + (provider.hasMoreLogbook ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == sortedKeys.length) {
            return provider.isFetchingLogbook
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          final date = sortedKeys[index];
          final actions = groupedActions[date]!;
          return _buildDateGroup(date, actions);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionProvider = context.watch<ActionProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildBody(actionProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logbook',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '완료된 작업 기록',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.55).round()),
              letterSpacing: 0.1,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '검색...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.5).round()),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.6).round()),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 15),
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.3).round()),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No results found' : 'Logbook is empty',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String dateKey, List<ActionWithContexts> actions) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text(
                dateKey,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${actions.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.6).round()),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        ...actions.map((actionWithContexts) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: ActionItemTile(
              actionWithContexts: actionWithContexts,
              isLogbook: true,
            ),
          );
        }),
      ],
    );
  }
}
