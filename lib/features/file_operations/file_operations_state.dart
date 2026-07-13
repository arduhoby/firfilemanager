import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/models/file_entry.dart';
import '../../core/storage/models/transfer_progress.dart';

part 'file_operations_state.g.dart';

/// Identifies which panel (A or B)
enum PanelSide { a, b }

/// Sort field for file listing
enum SortField { name, date, size, type }

/// Sort direction
enum SortDirection { ascending, descending }

/// State for a single file panel (A or B)
class TabState {
  const TabState({
    required this.id,
    required this.currentPath,
    this.providerId = 'local',
    this.entries = const [],
    this.selectedPaths = const {},
    this.sortField = SortField.name,
    this.sortDirection = SortDirection.ascending,
    this.showHidden = false,
    this.isLoading = false,
    this.searchQuery,
    this.error,
    this.history = const [],
    this.historyIndex = -1,
  });

  final String id;
  final String currentPath;
  final String providerId;
  final List<FileEntry> entries;
  final Set<String> selectedPaths;
  final SortField sortField;
  final SortDirection sortDirection;
  final bool showHidden;
  final bool isLoading;
  final String? searchQuery;
  final String? error;
  final List<String> history;
  final int historyIndex;

  /// Selected entries (filtered from entries by selectedPaths)
  List<FileEntry> get selectedEntries =>
      entries.where((e) => selectedPaths.contains(e.path)).toList();

  /// Whether any entries are selected
  bool get hasSelection => selectedPaths.isNotEmpty;

  /// Number of selected items
  int get selectionCount => selectedPaths.length;

  TabState copyWith({
    String? currentPath,
    String? providerId,
    List<FileEntry>? entries,
    Set<String>? selectedPaths,
    SortField? sortField,
    SortDirection? sortDirection,
    bool? showHidden,
    bool? isLoading,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? error,
    List<String>? history,
    int? historyIndex,
  }) {
    return TabState(
      id: this.id,
      currentPath: currentPath ?? this.currentPath,
      providerId: providerId ?? this.providerId,
      entries: entries ?? this.entries,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      showHidden: showHidden ?? this.showHidden,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      error: error,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }
}

class PanelState {
  const PanelState({required this.tabs, this.activeTabIndex = 0});

  final List<TabState> tabs;
  final int activeTabIndex;

  TabState get activeTab => tabs.isNotEmpty
      ? tabs[activeTabIndex]
      : const TabState(id: 'default', currentPath: '/');

  PanelState copyWith({List<TabState>? tabs, int? activeTabIndex}) {
    return PanelState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

/// State for panel A
@Riverpod(keepAlive: true)
class PanelA extends _$PanelA {
  @override
  PanelState build() {
    return const PanelState(
      tabs: [TabState(id: 'tab_0', currentPath: '/')],
    );
  }

  void _updateActiveTab(TabState Function(TabState tab) updater) {
    if (state.tabs.isEmpty) return;
    final newTabs = List<TabState>.from(state.tabs);
    newTabs[state.activeTabIndex] = updater(state.activeTab);
    state = state.copyWith(tabs: newTabs);
  }

  void setPath(String path) {
    _updateActiveTab((t) {
      if (t.currentPath == path) return t;
      final newHistory = t.historyIndex >= 0 
          ? t.history.sublist(0, t.historyIndex + 1) 
          : <String>[t.currentPath];
      newHistory.add(path);
      return t.copyWith(
        currentPath: path,
        selectedPaths: {},
        error: null,
        history: newHistory,
        historyIndex: newHistory.length - 1,
      );
    });
  }

  void setProviderAndPath(String providerId, String path) {
    _updateActiveTab((t) {
      if (t.currentPath == path && t.providerId == providerId) return t;
      final newHistory = t.historyIndex >= 0 
          ? t.history.sublist(0, t.historyIndex + 1) 
          : <String>[t.currentPath];
      newHistory.add(path);
      return t.copyWith(
        providerId: providerId,
        currentPath: path,
        selectedPaths: {},
        error: null,
        history: newHistory,
        historyIndex: newHistory.length - 1,
      );
    });
  }

  void goBack() {
    _updateActiveTab((t) {
      if (t.historyIndex > 0) {
        final newIndex = t.historyIndex - 1;
        return t.copyWith(
          currentPath: t.history[newIndex],
          selectedPaths: {},
          error: null,
          historyIndex: newIndex,
        );
      }
      return t;
    });
  }

  void goForward() {
    _updateActiveTab((t) {
      if (t.historyIndex >= 0 && t.historyIndex < t.history.length - 1) {
        final newIndex = t.historyIndex + 1;
        return t.copyWith(
          currentPath: t.history[newIndex],
          selectedPaths: {},
          error: null,
          historyIndex: newIndex,
        );
      }
      return t;
    });
  }

  void setEntries(List<FileEntry> entries) {
    final sorted = _sortEntries(
      entries,
      state.activeTab.sortField,
      state.activeTab.sortDirection,
    );
    _updateActiveTab((t) => t.copyWith(entries: sorted, isLoading: false));
  }

  void setLoading(bool loading) {
    _updateActiveTab((t) => t.copyWith(isLoading: loading));
  }

  void setSearchQuery(String? query) {
    if (state.tabs.isEmpty) return;
    final tabs = List<TabState>.from(state.tabs);
    tabs[state.activeTabIndex] = tabs[state.activeTabIndex].copyWith(
      searchQuery: query,
      clearSearchQuery: query == null,
    );
    state = state.copyWith(tabs: tabs);
  }

  void setError(String? error) {
    _updateActiveTab((t) => t.copyWith(error: error, isLoading: false));
  }

  void selectEntry(String path) {
    _updateActiveTab((t) => t.copyWith(selectedPaths: {path}));
  }

  void toggleSelection(String path) {
    final newSelection = Set<String>.from(state.activeTab.selectedPaths);
    if (newSelection.contains(path)) {
      newSelection.remove(path);
    } else {
      newSelection.add(path);
    }
    _updateActiveTab((t) => t.copyWith(selectedPaths: newSelection));
  }

  void selectRange(String from, String to) {
    final entries = state.activeTab.entries;
    final fromIndex = entries.indexWhere((e) => e.path == from);
    final toIndex = entries.indexWhere((e) => e.path == to);
    if (fromIndex == -1 || toIndex == -1) return;

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    final newSelection = <String>{};
    for (var i = start; i <= end; i++) {
      newSelection.add(entries[i].path);
    }
    _updateActiveTab((t) => t.copyWith(selectedPaths: newSelection));
  }

  void clearSelection() {
    _updateActiveTab((t) => t.copyWith(selectedPaths: {}));
  }

  void selectAll() {
    final allPaths = state.activeTab.entries.map((e) => e.path).toSet();
    _updateActiveTab((t) => t.copyWith(selectedPaths: allPaths));
  }

  void toggleSort(SortField field) {
    SortDirection dir = SortDirection.ascending;
    if (state.activeTab.sortField == field) {
      dir = state.activeTab.sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    }

    final sorted = _sortEntries(state.activeTab.entries, field, dir);
    _updateActiveTab(
      (t) => t.copyWith(sortField: field, sortDirection: dir, entries: sorted),
    );
  }

  void toggleHidden() {
    _updateActiveTab((t) => t.copyWith(showHidden: !t.showHidden));
  }

  List<FileEntry> _sortEntries(
    List<FileEntry> entries,
    SortField field,
    SortDirection direction,
  ) {
    final sorted = List<FileEntry>.from(entries);
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int cmp = 0;
      switch (field) {
        case SortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.date:
          cmp = (a.modified ?? DateTime(1970)).compareTo(b.modified ?? DateTime(1970));
        case SortField.size:
          cmp = a.size.compareTo(b.size);
        case SortField.type:
          final extA = a.name.split('.').last.toLowerCase();
          final extB = b.name.split('.').last.toLowerCase();
          cmp = extA.compareTo(extB);
      }

      return direction == SortDirection.ascending ? cmp : -cmp;
    });
    return sorted;
  }

  // --- Tab Management ---
  void addTab(String path, {String providerId = 'local'}) {
    if (state.tabs.length >= 10) return; // limit

    final newTabId = 'tab_${DateTime.now().millisecondsSinceEpoch}';
    final newTab = TabState(
      id: newTabId,
      currentPath: path,
      providerId: providerId,
    );

    final newTabs = List<TabState>.from(state.tabs)..add(newTab);
    state = state.copyWith(tabs: newTabs, activeTabIndex: newTabs.length - 1);
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) return; // Cannot close the last tab

    final newTabs = List<TabState>.from(state.tabs)..removeAt(index);
    int newIndex = state.activeTabIndex;
    if (index < newIndex) {
      newIndex--;
    } else if (index == newIndex && newIndex >= newTabs.length) {
      newIndex = newTabs.length - 1;
    }
    state = state.copyWith(tabs: newTabs, activeTabIndex: newIndex);
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }
}

/// State for panel B
@Riverpod(keepAlive: true)
class PanelB extends _$PanelB {
  @override
  PanelState build() {
    return const PanelState(
      tabs: [TabState(id: 'tab_0', currentPath: '/')],
    );
  }

  void _updateActiveTab(TabState Function(TabState tab) updater) {
    if (state.tabs.isEmpty) return;
    final newTabs = List<TabState>.from(state.tabs);
    newTabs[state.activeTabIndex] = updater(state.activeTab);
    state = state.copyWith(tabs: newTabs);
  }

  void setPath(String path) {
    _updateActiveTab((t) {
      if (t.currentPath == path) return t;
      final newHistory = t.historyIndex >= 0 
          ? t.history.sublist(0, t.historyIndex + 1) 
          : <String>[t.currentPath];
      newHistory.add(path);
      return t.copyWith(
        currentPath: path,
        selectedPaths: {},
        error: null,
        history: newHistory,
        historyIndex: newHistory.length - 1,
      );
    });
  }

  void setProviderAndPath(String providerId, String path) {
    _updateActiveTab((t) {
      if (t.currentPath == path && t.providerId == providerId) return t;
      final newHistory = t.historyIndex >= 0 
          ? t.history.sublist(0, t.historyIndex + 1) 
          : <String>[t.currentPath];
      newHistory.add(path);
      return t.copyWith(
        providerId: providerId,
        currentPath: path,
        selectedPaths: {},
        error: null,
        history: newHistory,
        historyIndex: newHistory.length - 1,
      );
    });
  }

  void goBack() {
    _updateActiveTab((t) {
      if (t.historyIndex > 0) {
        final newIndex = t.historyIndex - 1;
        return t.copyWith(
          currentPath: t.history[newIndex],
          selectedPaths: {},
          error: null,
          historyIndex: newIndex,
        );
      }
      return t;
    });
  }

  void goForward() {
    _updateActiveTab((t) {
      if (t.historyIndex >= 0 && t.historyIndex < t.history.length - 1) {
        final newIndex = t.historyIndex + 1;
        return t.copyWith(
          currentPath: t.history[newIndex],
          selectedPaths: {},
          error: null,
          historyIndex: newIndex,
        );
      }
      return t;
    });
  }

  void setEntries(List<FileEntry> entries) {
    final sorted = _sortEntries(
      entries,
      state.activeTab.sortField,
      state.activeTab.sortDirection,
    );
    _updateActiveTab((t) => t.copyWith(entries: sorted, isLoading: false));
  }

  void setLoading(bool loading) {
    _updateActiveTab((t) => t.copyWith(isLoading: loading));
  }

  void setSearchQuery(String? query) {
    if (state.tabs.isEmpty) return;
    final tabs = List<TabState>.from(state.tabs);
    tabs[state.activeTabIndex] = tabs[state.activeTabIndex].copyWith(
      searchQuery: query,
      clearSearchQuery: query == null,
    );
    state = state.copyWith(tabs: tabs);
  }

  void setError(String? error) {
    _updateActiveTab((t) => t.copyWith(error: error, isLoading: false));
  }

  void selectEntry(String path) {
    _updateActiveTab((t) => t.copyWith(selectedPaths: {path}));
  }

  void toggleSelection(String path) {
    final newSelection = Set<String>.from(state.activeTab.selectedPaths);
    if (newSelection.contains(path)) {
      newSelection.remove(path);
    } else {
      newSelection.add(path);
    }
    _updateActiveTab((t) => t.copyWith(selectedPaths: newSelection));
  }

  void selectRange(String from, String to) {
    final entries = state.activeTab.entries;
    final fromIndex = entries.indexWhere((e) => e.path == from);
    final toIndex = entries.indexWhere((e) => e.path == to);
    if (fromIndex == -1 || toIndex == -1) return;

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    final newSelection = <String>{};
    for (var i = start; i <= end; i++) {
      newSelection.add(entries[i].path);
    }
    _updateActiveTab((t) => t.copyWith(selectedPaths: newSelection));
  }

  void clearSelection() {
    _updateActiveTab((t) => t.copyWith(selectedPaths: {}));
  }

  void selectAll() {
    final allPaths = state.activeTab.entries.map((e) => e.path).toSet();
    _updateActiveTab((t) => t.copyWith(selectedPaths: allPaths));
  }

  void toggleSort(SortField field) {
    SortDirection dir = SortDirection.ascending;
    if (state.activeTab.sortField == field) {
      dir = state.activeTab.sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    }

    final sorted = _sortEntries(state.activeTab.entries, field, dir);
    _updateActiveTab(
      (t) => t.copyWith(sortField: field, sortDirection: dir, entries: sorted),
    );
  }

  void toggleHidden() {
    _updateActiveTab((t) => t.copyWith(showHidden: !t.showHidden));
  }

  List<FileEntry> _sortEntries(
    List<FileEntry> entries,
    SortField field,
    SortDirection direction,
  ) {
    final sorted = List<FileEntry>.from(entries);
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int cmp = 0;
      switch (field) {
        case SortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.date:
          cmp = (a.modified ?? DateTime(1970)).compareTo(b.modified ?? DateTime(1970));
        case SortField.size:
          cmp = a.size.compareTo(b.size);
        case SortField.type:
          final extA = a.name.split('.').last.toLowerCase();
          final extB = b.name.split('.').last.toLowerCase();
          cmp = extA.compareTo(extB);
      }

      return direction == SortDirection.ascending ? cmp : -cmp;
    });
    return sorted;
  }

  // --- Tab Management ---
  void addTab(String path, {String providerId = 'local'}) {
    if (state.tabs.length >= 10) return; // limit

    final newTabId = 'tab_${DateTime.now().millisecondsSinceEpoch}';
    final newTab = TabState(
      id: newTabId,
      currentPath: path,
      providerId: providerId,
    );

    final newTabs = List<TabState>.from(state.tabs)..add(newTab);
    state = state.copyWith(tabs: newTabs, activeTabIndex: newTabs.length - 1);
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) return; // Cannot close the last tab

    final newTabs = List<TabState>.from(state.tabs)..removeAt(index);
    int newIndex = state.activeTabIndex;
    if (index < newIndex) {
      newIndex--;
    } else if (index == newIndex && newIndex >= newTabs.length) {
      newIndex = newTabs.length - 1;
    }
    state = state.copyWith(tabs: newTabs, activeTabIndex: newIndex);
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }
}

/// Which panel is currently active (has keyboard focus)
@Riverpod(keepAlive: true)
class ActivePanel extends _$ActivePanel {
  @override
  PanelSide build() => PanelSide.a;

  void setActive(PanelSide side) {
    state = side;
  }
}

enum ClipboardOperation { copy, cut }

class ClipboardState {
  const ClipboardState({
    required this.sourcePaths,
    required this.sourceSide,
    required this.sourceProviderId,
    required this.operation,
  });

  final List<String> sourcePaths;
  final PanelSide sourceSide;
  final String sourceProviderId;
  final ClipboardOperation operation;
}



/// Clipboard for copy/cut operations
@Riverpod(keepAlive: true)
class FileClipboard extends _$FileClipboard {
  @override
  ClipboardState? build() => null;

  void copy(List<String> paths, PanelSide side, String providerId) {
    state = ClipboardState(
      sourcePaths: paths,
      sourceSide: side,
      sourceProviderId: providerId,
      operation: ClipboardOperation.copy,
    );
  }

  void cut(List<String> paths, PanelSide side, String providerId) {
    state = ClipboardState(
      sourcePaths: paths,
      sourceSide: side,
      sourceProviderId: providerId,
      operation: ClipboardOperation.cut,
    );
  }

  void clear() {
    state = null;
  }
}

/// Current transfer/operation progress state
@Riverpod(keepAlive: true)
class OperationProgress extends _$OperationProgress {
  @override
  TransferProgress? build() => null;

  void setProgress(TransferProgress state) {
    this.state = state;
  }

  void clear() {
    state = null;
  }
}
