// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameControllerHash() => r'ee52f90e364ac36e6166e2a16a8802403b8a4b7a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$GameController extends BuildlessNotifier<GameState> {
  late final PlayerClassType selectedClass;

  GameState build(PlayerClassType selectedClass);
}

/// See also [GameController].
@ProviderFor(GameController)
const gameControllerProvider = GameControllerFamily();

/// See also [GameController].
class GameControllerFamily extends Family<GameState> {
  /// See also [GameController].
  const GameControllerFamily();

  /// See also [GameController].
  GameControllerProvider call(PlayerClassType selectedClass) {
    return GameControllerProvider(selectedClass);
  }

  @override
  GameControllerProvider getProviderOverride(
    covariant GameControllerProvider provider,
  ) {
    return call(provider.selectedClass);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gameControllerProvider';
}

/// See also [GameController].
class GameControllerProvider
    extends NotifierProviderImpl<GameController, GameState> {
  /// See also [GameController].
  GameControllerProvider(PlayerClassType selectedClass)
    : this._internal(
        () => GameController()..selectedClass = selectedClass,
        from: gameControllerProvider,
        name: r'gameControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$gameControllerHash,
        dependencies: GameControllerFamily._dependencies,
        allTransitiveDependencies:
            GameControllerFamily._allTransitiveDependencies,
        selectedClass: selectedClass,
      );

  GameControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.selectedClass,
  }) : super.internal();

  final PlayerClassType selectedClass;

  @override
  GameState runNotifierBuild(covariant GameController notifier) {
    return notifier.build(selectedClass);
  }

  @override
  Override overrideWith(GameController Function() create) {
    return ProviderOverride(
      origin: this,
      override: GameControllerProvider._internal(
        () => create()..selectedClass = selectedClass,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        selectedClass: selectedClass,
      ),
    );
  }

  @override
  NotifierProviderElement<GameController, GameState> createElement() {
    return _GameControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameControllerProvider &&
        other.selectedClass == selectedClass;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, selectedClass.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GameControllerRef on NotifierProviderRef<GameState> {
  /// The parameter `selectedClass` of this provider.
  PlayerClassType get selectedClass;
}

class _GameControllerProviderElement
    extends NotifierProviderElement<GameController, GameState>
    with GameControllerRef {
  _GameControllerProviderElement(super.provider);

  @override
  PlayerClassType get selectedClass =>
      (origin as GameControllerProvider).selectedClass;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
