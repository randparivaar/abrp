import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final String minRequiredVersion;
  final int minRequiredBuild;
  final bool isForceUpdate;
  final bool isUpdateAvailable;
  final String updateUrl;
  final String titleEn;
  final String titleHi;
  final String messageEn;
  final String messageHi;
  final String releaseNotes;

  const VersionInfo({
    this.currentVersion = '1.0.0',
    this.currentBuild = 1,
    this.latestVersion = '1.0.0',
    this.latestBuild = 1,
    this.minRequiredVersion = '1.0.0',
    this.minRequiredBuild = 1,
    this.isForceUpdate = false,
    this.isUpdateAvailable = false,
    this.updateUrl = 'https://play.google.com/store/apps/details?id=com.abrp.mobile',
    this.titleEn = 'App Update Required',
    this.titleHi = 'ऐप अपडेट आवश्यक है',
    this.messageEn = 'A critical update is required to continue using the ABRP app. Please update to the latest version.',
    this.messageHi = 'ABRP ऐप का उपयोग जारी रखने के लिए ऐप अपडेट करना आवश्यक है। कृपया नए संस्करण में अपडेट करें।',
    this.releaseNotes = '',
  });

  factory VersionInfo.fromJson({
    required Map<String, dynamic> json,
    required String currentVersion,
    required int currentBuild,
  }) {
    final titleMap = json['title'] as Map<String, dynamic>?;
    final messageMap = json['message'] as Map<String, dynamic>?;

    final latestBuildNum = (json['latestBuild'] as num?)?.toInt() ?? currentBuild;
    final minRequiredBuildNum = (json['minRequiredBuild'] as num?)?.toInt() ?? 1;

    // A force update is triggered either if the backend explicitly flagged forceUpdate: true,
    // OR if client build number is less than minRequiredBuild.
    final bool force = json['forceUpdate'] == true || currentBuild < minRequiredBuildNum;
    final bool available = json['updateAvailable'] == true || currentBuild < latestBuildNum;

    return VersionInfo(
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: (json['latestVersion'] as String?) ?? currentVersion,
      latestBuild: latestBuildNum,
      minRequiredVersion: (json['minRequiredVersion'] as String?) ?? '1.0.0',
      minRequiredBuild: minRequiredBuildNum,
      isForceUpdate: force,
      isUpdateAvailable: available,
      updateUrl: (json['updateUrl'] as String?) ?? 'https://play.google.com/store/apps/details?id=com.abrp.mobile',
      titleEn: titleMap?['en'] ?? (json['title'] is String ? json['title'] : 'App Update Required'),
      titleHi: titleMap?['hi'] ?? 'ऐप अपडेट आवश्यक है',
      messageEn: messageMap?['en'] ?? (json['message'] is String ? json['message'] : 'A critical update is required.'),
      messageHi: messageMap?['hi'] ?? 'ABRP ऐप का उपयोग जारी रखने के लिए ऐप अपडेट करना आवश्यक है।',
      releaseNotes: (json['releaseNotes'] as String?) ?? '',
    );
  }
}

class VersionService {
  static String currentVersion = '1.0.0';
  static int currentBuildNumber = 1;
  static bool _initialized = false;

  /// Loads package info once at app startup
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
      _initialized = true;
      debugPrint('[VersionService] App Version: $currentVersion, Build: $currentBuildNumber');
    } catch (e) {
      debugPrint('[VersionService] Failed to get package info: $e');
    }
  }

  /// Calls backend to verify version requirements
  static Future<VersionInfo?> checkAppVersion(Dio dio) async {
    try {
      await initialize();
      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await dio.get(
        '/app-config/version',
        queryParameters: {
          'platform': platform,
          'build': currentBuildNumber,
          'version': currentVersion,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return VersionInfo.fromJson(
          json: response.data as Map<String, dynamic>,
          currentVersion: currentVersion,
          currentBuild: currentBuildNumber,
        );
      }
    } catch (e) {
      debugPrint('[VersionService] Version check failed (network/offline): $e');
    }
    return null;
  }
}
