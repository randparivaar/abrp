// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_language.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LanguageState)
final languageStateProvider = LanguageStateProvider._();

final class LanguageStateProvider
    extends $NotifierProvider<LanguageState, AppLanguage> {
  LanguageStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageStateHash();

  @$internal
  @override
  LanguageState create() => LanguageState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage>(value),
    );
  }
}

String _$languageStateHash() => r'd1ba994c9af879e6e0dbde06c814f8fccb1015af';

abstract class _$LanguageState extends $Notifier<AppLanguage> {
  AppLanguage build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppLanguage, AppLanguage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLanguage, AppLanguage>,
              AppLanguage,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
