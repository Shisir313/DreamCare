// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_tracking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WaterTrackingNotifier)
final waterTrackingProvider = WaterTrackingNotifierProvider._();

final class WaterTrackingNotifierProvider
    extends $AsyncNotifierProvider<WaterTrackingNotifier, WaterTracking> {
  WaterTrackingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waterTrackingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waterTrackingNotifierHash();

  @$internal
  @override
  WaterTrackingNotifier create() => WaterTrackingNotifier();
}

String _$waterTrackingNotifierHash() =>
    r'a8e1cd63635eaa0e358cafbba63b3f9a8ae42a19';

abstract class _$WaterTrackingNotifier extends $AsyncNotifier<WaterTracking> {
  FutureOr<WaterTracking> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WaterTracking>, WaterTracking>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WaterTracking>, WaterTracking>,
              AsyncValue<WaterTracking>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
