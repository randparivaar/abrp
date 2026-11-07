import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  AdmobService._();
  static final AdmobService instance = AdmobService._();

  // ── Ad Unit IDs ────────────────────────────────────────────────────────────
  // Production IDs
  static const String _prodBannerId = 'ca-app-pub-4387759468023618/7408557931';
  static const String _prodInterstitialId = 'ca-app-pub-4387759468023618/7600129629';
  static const String _prodRewardedId = 'ca-app-pub-4387759468023618/9960865394';

  // Google Test IDs (Used in debug mode to safeguard real account against invalid traffic)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static String get bannerAdUnitId => kDebugMode ? _testBannerId : _prodBannerId;
  static String get interstitialAdUnitId => kDebugMode ? _testInterstitialId : _prodInterstitialId;
  static String get rewardedAdUnitId => kDebugMode ? _testRewardedId : _prodRewardedId;

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownAt;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;
  DateTime? _lastRewardedShownAt;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdmobService: initialization error: $e');
    }
  }

  // ── Interstitial Ad ────────────────────────────────────────────────────────
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Shows the interstitial ad on app launch or resume with frequency throttling.
  void showInterstitialAd({Duration minInterval = const Duration(seconds: 60)}) {
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return;
    }

    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!) < minInterval) {
      return;
    }

    _lastInterstitialShownAt = now;
    _interstitialAd!.show();
  }

  // ── Rewarded Ad ────────────────────────────────────────────────────────────
  void loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  /// Shows the rewarded ad on app launch or resume with frequency throttling.
  void showRewardedAdOnLaunchOrResume({
    Duration minInterval = const Duration(seconds: 60),
    Function(RewardItem reward)? onUserEarnedReward,
  }) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }

    final now = DateTime.now();
    if (_lastRewardedShownAt != null &&
        now.difference(_lastRewardedShownAt!) < minInterval) {
      return;
    }

    _lastRewardedShownAt = now;
    _rewardedAd!.show(onUserEarnedReward: (adWithoutView, reward) {
      debugPrint('User earned reward on launch/resume: ${reward.amount} ${reward.type}');
      onUserEarnedReward?.call(reward);
    });
  }

  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
  }) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }

    _rewardedAd!.show(onUserEarnedReward: (adWithoutView, reward) {
      onUserEarnedReward(reward);
    });
  }
}

