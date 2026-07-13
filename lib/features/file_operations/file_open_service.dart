import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_open_service.g.dart';

/// Service for opening files with the system default application.
///
/// Uses platform-specific commands:
/// - macOS: `open`
/// - Windows: `start`
/// - Linux: `xdg-open`
@Riverpod(keepAlive: true)
class FileOpenService extends _$FileOpenService {
  @override
  void build() {
    // No state needed
  }

  /// Open a file or directory with the system default application
  Future<bool> openWithDefault(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Open a file with a specific application (macOS only, using `open -a`)
  Future<bool> openWithApp(String path, String appName) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', appName, path]);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Reveal a file in Finder/Explorer
  Future<bool> revealInFileManager(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Open a terminal at the specified path
  Future<bool> openInTerminal(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', 'Terminal', path]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', 'powershell', '-NoExit', '-Command', 'cd "$path"']);
      } else if (Platform.isLinux) {
        await Process.run('x-terminal-emulator', ['--working-directory=$path']);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}