import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedLifeAdService {
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-8274979068153688/5276714699';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;

  bool get isReady => _rewardedAd != null;

  void load() {
    if (!Platform.isIOS) return;
    if (_isLoading || _rewardedAd != null) return;

    _isLoading = true;

    RewardedAd.load(
      adUnitId: _iosRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('Rewarded life ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('Rewarded life ad failed to load: $error');
        },
      ),
    );
  }

  Future<bool> showAndWaitForReward() async {
    if (_isShowing) return false;

    final ad = _rewardedAd;
    if (ad == null) {
      load();
      return false;
    }

    _rewardedAd = null;
    _isShowing = true;

    final completer = Completer<bool>();
    var rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        load();

        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded life ad failed to show: $error');
        ad.dispose();
        _isShowing = false;
        load();

        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;

        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
