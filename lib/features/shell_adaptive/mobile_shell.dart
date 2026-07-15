import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../file_operations/file_operations_state.dart';
import 'file_panel.dart';
import 'panel_controller.dart';
import 'file_operations_actions.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  int _currentIndex = 0;
  bool _isDualPaneLandscape = true; // Toggle for landscape dual pane

  @override
  void initState() {
    super.initState();
    // In mobile, we might want to sync active panel with bottom nav
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activePanelProvider.notifier).state =
          _currentIndex == 0 ? PanelSide.a : PanelSide.b;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      ref.read(activePanelProvider.notifier).state =
          index == 0 ? PanelSide.a : PanelSide.b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final isLandscape = orientation == Orientation.landscape;

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    EdgeInsetsGeometry getPlatformPadding() {
      if (Platform.isIOS) {
        return const EdgeInsets.only(left: 3.0, bottom: 1.0);
      } else if (Platform.isAndroid) {
        return const EdgeInsets.only(bottom: 3.0);
      }
      return EdgeInsets.zero;
    }

    // If landscape and dual pane is enabled
    if (isLandscape && _isDualPaneLandscape) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fir File Manager'),
          actions: [
            IconButton(
              icon: const Icon(Icons.splitscreen),
              tooltip: 'Tek panele geç',
              onPressed: () {
                setState(() {
                  _isDualPaneLandscape = false;
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: getPlatformPadding(),
          child: Row(
            children: [
              const Expanded(child: FilePanel(side: PanelSide.a)),
              Container(
                width: 1,
                color: theme.dividerColor,
              ),
              const Expanded(child: FilePanel(side: PanelSide.b)),
            ],
          ),
        ),
      );
    }

    // Portrait or single pane landscape
    final activeSide = _currentIndex == 0 ? PanelSide.a : PanelSide.b;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fir File Manager'),
        actions: [
          if (isLandscape)
            IconButton(
              icon: const Icon(Icons.vertical_split),
              tooltip: 'Çift panele geç',
              onPressed: () {
                setState(() {
                  _isDualPaneLandscape = true;
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: getPlatformPadding(),
        child: FilePanel(side: activeSide),
      ),
      bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.folder_open),
              selectedIcon: Icon(Icons.folder),
              label: 'Panel A',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder_copy),
              label: 'Panel B',
            ),
          ],
        ),
    );
  }
}
