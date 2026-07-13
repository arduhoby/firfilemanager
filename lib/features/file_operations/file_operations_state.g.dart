// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_operations_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$panelAHash() => r'd9f65732bbffee915861f69e9535c5f69f11b041';

/// State for panel A
///
/// Copied from [PanelA].
@ProviderFor(PanelA)
final panelAProvider = NotifierProvider<PanelA, PanelState>.internal(
  PanelA.new,
  name: r'panelAProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$panelAHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PanelA = Notifier<PanelState>;
String _$panelBHash() => r'728322a4201883589da100663d89605e1b1d39d4';

/// State for panel B
///
/// Copied from [PanelB].
@ProviderFor(PanelB)
final panelBProvider = NotifierProvider<PanelB, PanelState>.internal(
  PanelB.new,
  name: r'panelBProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$panelBHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PanelB = Notifier<PanelState>;
String _$activePanelHash() => r'b23e3c65cb66128d5a8bc40ecaa9ad6bb12e9a74';

/// Which panel is currently active (has keyboard focus)
///
/// Copied from [ActivePanel].
@ProviderFor(ActivePanel)
final activePanelProvider = NotifierProvider<ActivePanel, PanelSide>.internal(
  ActivePanel.new,
  name: r'activePanelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activePanelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActivePanel = Notifier<PanelSide>;
String _$fileClipboardHash() => r'027891d9616d3fd366e2bf8c8d562396536c1a09';

/// Clipboard for copy/cut operations
///
/// Copied from [FileClipboard].
@ProviderFor(FileClipboard)
final fileClipboardProvider =
    NotifierProvider<FileClipboard, ClipboardState?>.internal(
      FileClipboard.new,
      name: r'fileClipboardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fileClipboardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FileClipboard = Notifier<ClipboardState?>;
String _$operationProgressHash() => r'd7727b5acbfcda4f7dcdce5d9f7cd807069bc587';

/// Current transfer/operation progress state
///
/// Copied from [OperationProgress].
@ProviderFor(OperationProgress)
final operationProgressProvider =
    NotifierProvider<OperationProgress, TransferProgress?>.internal(
      OperationProgress.new,
      name: r'operationProgressProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$operationProgressHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OperationProgress = Notifier<TransferProgress?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
