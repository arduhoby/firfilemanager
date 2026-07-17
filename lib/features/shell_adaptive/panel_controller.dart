import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/storage_provider.dart';
import '../../core/storage/storage_provider_service.dart';
import '../../core/settings/recent_service.dart';
import '../file_operations/file_operations_state.dart';

part 'panel_controller.g.dart';

/// Controller that loads directory listings for panels.
///
/// Watches the panel's current path and loads entries from the
/// appropriate [StorageProvider] whenever the path changes.
@Riverpod(keepAlive: true)
class PanelController extends _$PanelController {
  StreamSubscription<FileSystemEvent>? _watchSubscriptionA;
  StreamSubscription<FileSystemEvent>? _watchSubscriptionB;
  @override
  void build() {
    // Listen to both panels and auto-load when path or provider changes
    ref.listen(panelAProvider, (previous, next) {
      if (previous?.activeTab.currentPath != next.activeTab.currentPath || previous?.activeTab.providerId != next.activeTab.providerId) {
        _loadDirectory(PanelSide.a, next.activeTab.currentPath, next.activeTab.showHidden);
      }
    });

    ref.listen(panelBProvider, (previous, next) {
      if (previous?.activeTab.currentPath != next.activeTab.currentPath || previous?.activeTab.providerId != next.activeTab.providerId) {
        _loadDirectory(PanelSide.b, next.activeTab.currentPath, next.activeTab.showHidden);
      }
    });
  }

  /// Get the appropriate provider for a panel side.
  StorageProvider _getProviderForPath(PanelSide side, String path) {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    if (panelState.activeTab.providerId == 'local') {
      return ref.read(localStorageProviderProvider);
    }

    final provider = ref.read(storageProviderRegistryProvider)[panelState.activeTab.providerId];
    if (provider == null) {
      throw Exception('Connection is not active or disconnected.');
    }
    return provider;
  }

  Future<void> _loadDirectory(PanelSide side, String path, bool showHidden) async {
    print('PANEL_CONTROLLER: _loadDirectory started for side=$side, path="$path"');
    if (side == PanelSide.a) {
      ref.read(panelAProvider.notifier).setLoading(true);
    } else {
      ref.read(panelBProvider.notifier).setLoading(true);
    }

    try {
      final provider = _getProviderForPath(side, path);
      final entries = await provider.list(
        path,
        ListOptions(showHidden: showHidden),
      );
      print('PANEL_CONTROLLER: _loadDirectory loaded ${entries.length} entries for side=$side');
      if (side == PanelSide.a) {
        ref.read(panelAProvider.notifier).setEntries(entries);
      } else {
        ref.read(panelBProvider.notifier).setEntries(entries);
      }

      // Add to recent folders if it's local
      final home = Platform.environment['HOME'];
      if (provider.displayName == 'Local' && (home == null || !path.startsWith('$home/Library/'))) {
        ref.read(recentServiceProvider.notifier).addRecentFolder(path);
      }

      // Setup file watcher for local directories to auto-refresh on external changes
      if (provider.displayName == 'Local') {
        _setupWatcher(side, path, showHidden);
      } else {
        _cancelWatcher(side);
      }

    } catch (e, stack) {
      print('PANEL_CONTROLLER: _loadDirectory failed for side=$side. Error: $e\n$stack');
      if (side == PanelSide.a) {
        ref.read(panelAProvider.notifier).setError(e.toString());
      } else {
        ref.read(panelBProvider.notifier).setError(e.toString());
      }
    }
  }

  void _cancelWatcher(PanelSide side) {
    if (side == PanelSide.a) {
      _watchSubscriptionA?.cancel();
      _watchSubscriptionA = null;
    } else {
      _watchSubscriptionB?.cancel();
      _watchSubscriptionB = null;
    }
  }

  void _setupWatcher(PanelSide side, String path, bool showHidden) {
    _cancelWatcher(side);
    try {
      final dir = Directory(path);
      if (dir.existsSync()) {
        final sub = dir.watch(events: FileSystemEvent.all, recursive: false).listen((event) {
          // Add a small delay to debounce multiple rapid events
          Future.delayed(const Duration(milliseconds: 100), () {
            if (side == PanelSide.a) {
              final activePath = ref.read(panelAProvider).activeTab.currentPath;
              if (activePath == path) refresh(side);
            } else {
              final activePath = ref.read(panelBProvider).activeTab.currentPath;
              if (activePath == path) refresh(side);
            }
          });
        });
        if (side == PanelSide.a) {
          _watchSubscriptionA = sub;
        } else {
          _watchSubscriptionB = sub;
        }
      }
    } catch (e) {
      print('PANEL_CONTROLLER: Failed to setup watcher for $path: $e');
    }
  }

  /// Navigate a panel to a new path
  Future<void> navigate(PanelSide side, String path, {String? providerId}) async {
    String? resolvedProviderId = providerId;
    
    // Auto-detect local paths if providerId is not specified
    if (resolvedProviderId == null) {
      bool isLocal = false;
      if (Platform.isWindows) {
        isLocal = RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(path) || path == '/';
      } else {
        isLocal = path.startsWith('/Users/') || path.startsWith('/home/') || path.startsWith('/tmp/') || Directory(path).existsSync() || path == '/';
      }
      if (isLocal) {
        resolvedProviderId = 'local';
      }
    }

    if (side == PanelSide.a) {
      if (resolvedProviderId != null) {
        ref.read(panelAProvider.notifier).setProviderAndPath(resolvedProviderId, path);
      } else {
        ref.read(panelAProvider.notifier).setPath(path);
      }
    } else {
      if (resolvedProviderId != null) {
        ref.read(panelBProvider.notifier).setProviderAndPath(resolvedProviderId, path);
      } else {
        ref.read(panelBProvider.notifier).setPath(path);
      }
    }
  }

  /// Navigate up one level
  Future<void> navigateUp(PanelSide side) async {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final provider = _getProviderForPath(side, panelState.activeTab.currentPath);
    final parent = provider.dirname(panelState.activeTab.currentPath);

    if (parent != panelState.activeTab.currentPath) {
      await navigate(side, parent);
    }
  }

  /// Navigate back in history
  Future<void> navigateBack(PanelSide side) async {
    if (side == PanelSide.a) {
      ref.read(panelAProvider.notifier).goBack();
    } else {
      ref.read(panelBProvider.notifier).goBack();
    }
  }

  /// Navigate to home path of current provider
  Future<void> navigateHome(PanelSide side) async {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    try {
      final provider = _getProviderForPath(side, panelState.activeTab.currentPath);
      final home = await provider.homePath;
      await navigate(side, home);
    } catch (e) {
      // Ignore if provider doesn't exist
    }
  }

  /// Navigate forward in history
  Future<void> navigateForward(PanelSide side) async {
    if (side == PanelSide.a) {
      ref.read(panelAProvider.notifier).goForward();
    } else {
      ref.read(panelBProvider.notifier).goForward();
    }
  }

  /// Refresh the current directory
  Future<void> refresh(PanelSide side) async {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    await _loadDirectory(side, panelState.activeTab.currentPath, panelState.activeTab.showHidden);
  }

  /// Search inside the current directory
  Future<void> search(PanelSide side, String query, {bool recursive = false}) async {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    if (query.trim().isEmpty) {
      await refresh(side);
      return;
    }

    if (side == PanelSide.a) {
      ref.read(panelAProvider.notifier).setLoading(true);
    } else {
      ref.read(panelBProvider.notifier).setLoading(true);
    }

    try {
      final provider = _getProviderForPath(side, panelState.activeTab.currentPath);
      final results = await provider.search(
        panelState.activeTab.currentPath,
        query,
        recursive: recursive,
      );

      if (side == PanelSide.a) {
        ref.read(panelAProvider.notifier).setEntries(results);
      } else {
        ref.read(panelBProvider.notifier).setEntries(results);
      }
    } catch (e) {
      if (side == PanelSide.a) {
        ref.read(panelAProvider.notifier).setError(e.toString());
      } else {
        ref.read(panelBProvider.notifier).setError(e.toString());
      }
    }
  }

  /// Initialize panels with home path
  Future<void> initialize() async {
    print('PANEL_CONTROLLER: initialize() started');
    try {
      final provider = ref.read(localStorageProviderProvider);
      final home = await provider.homePath;
      print('PANEL_CONTROLLER: initialize() resolved homePath="$home"');

      ref.read(panelAProvider.notifier).setPath(home);
      ref.read(panelBProvider.notifier).setPath(home);
      print('PANEL_CONTROLLER: initialize() completed successfully');
    } catch (e, stack) {
      print('PANEL_CONTROLLER: initialize() failed with error: $e\n$stack');
    }
  }
}