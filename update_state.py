import re

with open('lib/features/file_operations/file_operations_state.dart', 'r') as f:
    content = f.read()

# Replace PanelState definition with TabState
content = content.replace("class PanelState {", "class TabState {")
content = content.replace("const PanelState({", "const TabState({")
content = content.replace("  PanelState copyWith({", "  TabState copyWith({")
content = content.replace("    return PanelState(", "    return TabState(")
content = content.replace("    required this.currentPath,", "    required this.id,\n    required this.currentPath,")
content = content.replace("  final String currentPath;", "  final String id;\n  final String currentPath;")
content = content.replace("      currentPath: currentPath ?? this.currentPath,", "      id: this.id,\n      currentPath: currentPath ?? this.currentPath,")

# Add new PanelState
new_panel_state = """
class PanelState {
  const PanelState({
    required this.tabs,
    this.activeTabIndex = 0,
  });

  final List<TabState> tabs;
  final int activeTabIndex;

  TabState get activeTab => tabs.isNotEmpty ? tabs[activeTabIndex] : const TabState(id: 'default', currentPath: '/');

  PanelState copyWith({
    List<TabState>? tabs,
    int? activeTabIndex,
  }) {
    return PanelState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}
"""

content = content.replace("/// State for panel A", new_panel_state + "\n/// State for panel A")

# Update PanelA and PanelB
for panel_name in ['PanelA', 'PanelB']:
    content = content.replace(f"class {panel_name} extends _${panel_name} {{", f"class {panel_name} extends _${panel_name} {{")
    
    # build method
    build_pattern = f"  @override\n  PanelState build() {{\n    // Will be initialized with home path by the shell\n    return const PanelState(currentPath: '/');\n  }}"
    new_build = f"  @override\n  PanelState build() {{\n    return const PanelState(tabs: [TabState(id: 'tab_0', currentPath: '/')]);\n  }}"
    content = content.replace(build_pattern, new_build)

    # replace `state = state.copyWith(...)` with active tab update
    methods = [
        "setPath", "setProviderAndPath", "setEntries", "setLoading", 
        "setError", "selectEntry", "toggleSelection", "selectRange", 
        "clearSelection", "selectAll", "toggleSort", "toggleHidden"
    ]
    
    # It's better to dynamically replace the internal logic for PanelA and PanelB in a second script or manually, because regex might get tricky here.
    # Actually, we can just replace the whole PanelA and PanelB class implementations.

panel_a_b = """
/// State for panel A
@Riverpod(keepAlive: true)
class PanelA extends _$PanelA {
  @override
  PanelState build() {
    return const PanelState(tabs: [TabState(id: 'tab_0', currentPath: '/')]);
  }

  void _updateActiveTab(TabState Function(TabState tab) updater) {
    if (state.tabs.isEmpty) return;
    final newTabs = List<TabState>.from(state.tabs);
    newTabs[state.activeTabIndex] = updater(state.activeTab);
    state = state.copyWith(tabs: newTabs);
  }

  void setPath(String path) {
    _updateActiveTab((t) => t.copyWith(currentPath: path, selectedPaths: {}, error: null));
  }

  void setProviderAndPath(String providerId, String path) {
    _updateActiveTab((t) => t.copyWith(
      providerId: providerId,
      currentPath: path,
      selectedPaths: {},
      error: null,
    ));
  }

  void setEntries(List<FileEntry> entries) {
    final sorted = _sortEntries(entries, state.activeTab.sortField, state.activeTab.sortDirection);
    _updateActiveTab((t) => t.copyWith(entries: sorted, isLoading: false));
  }

  void setLoading(bool loading) {
    _updateActiveTab((t) => t.copyWith(isLoading: loading));
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
    _updateActiveTab((t) => t.copyWith(
      sortField: field,
      sortDirection: dir,
      entries: sorted,
    ));
  }

  void toggleHidden() {
    _updateActiveTab((t) => t.copyWith(showHidden: !t.showHidden));
  }

  List<FileEntry> _sortEntries(List<FileEntry> entries, SortField field, SortDirection direction) {
    final sorted = List<FileEntry>.from(entries);
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int cmp = 0;
      switch (field) {
        case SortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.date:
          cmp = a.modified.compareTo(b.modified);
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
    final newTab = TabState(id: newTabId, currentPath: path, providerId: providerId);
    
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
    return const PanelState(tabs: [TabState(id: 'tab_0', currentPath: '/')]);
  }

  void _updateActiveTab(TabState Function(TabState tab) updater) {
    if (state.tabs.isEmpty) return;
    final newTabs = List<TabState>.from(state.tabs);
    newTabs[state.activeTabIndex] = updater(state.activeTab);
    state = state.copyWith(tabs: newTabs);
  }

  void setPath(String path) {
    _updateActiveTab((t) => t.copyWith(currentPath: path, selectedPaths: {}, error: null));
  }

  void setProviderAndPath(String providerId, String path) {
    _updateActiveTab((t) => t.copyWith(
      providerId: providerId,
      currentPath: path,
      selectedPaths: {},
      error: null,
    ));
  }

  void setEntries(List<FileEntry> entries) {
    final sorted = _sortEntries(entries, state.activeTab.sortField, state.activeTab.sortDirection);
    _updateActiveTab((t) => t.copyWith(entries: sorted, isLoading: false));
  }

  void setLoading(bool loading) {
    _updateActiveTab((t) => t.copyWith(isLoading: loading));
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
    _updateActiveTab((t) => t.copyWith(
      sortField: field,
      sortDirection: dir,
      entries: sorted,
    ));
  }

  void toggleHidden() {
    _updateActiveTab((t) => t.copyWith(showHidden: !t.showHidden));
  }

  List<FileEntry> _sortEntries(List<FileEntry> entries, SortField field, SortDirection direction) {
    final sorted = List<FileEntry>.from(entries);
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int cmp = 0;
      switch (field) {
        case SortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.date:
          cmp = a.modified.compareTo(b.modified);
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
    final newTab = TabState(id: newTabId, currentPath: path, providerId: providerId);
    
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
"""

start_idx = content.find("/// State for panel A")
if start_idx != -1:
    content = content[:start_idx] + panel_a_b
    with open('lib/features/file_operations/file_operations_state.dart', 'w') as f:
        f.write(content)
    print("Replaced PanelA and PanelB!")
else:
    print("Not found")

