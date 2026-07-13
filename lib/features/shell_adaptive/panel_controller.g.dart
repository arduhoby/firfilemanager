// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'panel_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$panelControllerHash() => r'f23fc5164372904c47b46aa8890a7805d3b29f30';

/// Controller that loads directory listings for panels.
///
/// Watches the panel's current path and loads entries from the
/// appropriate [StorageProvider] whenever the path changes.
///
/// Copied from [PanelController].
@ProviderFor(PanelController)
final panelControllerProvider =
    NotifierProvider<PanelController, void>.internal(
      PanelController.new,
      name: r'panelControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$panelControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PanelController = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
