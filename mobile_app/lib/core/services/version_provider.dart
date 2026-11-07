import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'version_service.dart';

class VersionStateNotifier extends Notifier<VersionInfo> {
  @override
  VersionInfo build() {
    return const VersionInfo();
  }

  /// Checks version with backend
  Future<void> checkForUpdates() async {
    try {
      final dio = ref.read(apiClientProvider);
      final info = await VersionService.checkAppVersion(dio);
      if (info != null) {
        state = info;
      }
    } catch (_) {
      // Keep existing state on transient network failures
    }
  }

  /// Triggered directly by Dio interceptor when backend returns HTTP 426 Upgrade Required
  void triggerForceUpdateFromBackend(dynamic data) {
    if (data is Map<String, dynamic>) {
      state = VersionInfo.fromJson(
        json: data,
        currentVersion: VersionService.currentVersion,
        currentBuild: VersionService.currentBuildNumber,
      );
    } else {
      state = VersionInfo(
        currentVersion: VersionService.currentVersion,
        currentBuild: VersionService.currentBuildNumber,
        isForceUpdate: true,
      );
    }
  }
}

final versionStateProvider =
    NotifierProvider<VersionStateNotifier, VersionInfo>(
  VersionStateNotifier.new,
);
