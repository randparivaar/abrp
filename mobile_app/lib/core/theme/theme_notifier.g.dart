// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeNotifier)
final themeProvider = ThemeNotifierProvider._();

final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, ThemeConfig> {
  ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeConfig>(value),
    );
  }
}

String _$themeNotifierHash() => r'437998001c3222b64c7f84afd903eac45c44bdea';

abstract class _$ThemeNotifier extends $Notifier<ThemeConfig> {
  ThemeConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeConfig, ThemeConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeConfig, ThemeConfig>,
              ThemeConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
