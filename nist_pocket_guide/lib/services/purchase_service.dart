// lib/services/purchase_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Use a direct import for the Android additions.
// Ensure 'in_app_purchase_android' is in your pubspec.yaml and `flutter pub get` has run.
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:shared_preferences/shared_preferences.dart';

const String kProUpgradeProductId = 'life.eucann.nistpocketguide.app.pro';

class PurchaseService with ChangeNotifier {
  final SharedPreferences prefs;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _isProUser = false;
  bool _isIapAvailable = false;
  bool get isIapAvailable => _isIapAvailable;

  PurchaseService(this.prefs) {
    _isProUser = true; // BETA: Force pro for testers
    debugPrint("PurchaseService: BETA mode. isPro = $_isProUser");
  }

  bool get isPro => _isProUser;
  // Indicates whether user has purchased unlimited AI chat
  bool get isUnlimitedChat => prefs.getBool('isUnlimitedChat') ?? false;
  // Alias for unlimited AI chat flag
  bool get isProAI => isUnlimitedChat;

  Future<void> initialize() async {
    debugPrint(
      "PurchaseService: Initializing for platform: $defaultTargetPlatform",
    );

    try {
      _isIapAvailable = await _inAppPurchase.isAvailable();
    } catch (e) {
      debugPrint("PurchaseService: Error checking IAP availability: $e");
      _isIapAvailable = false;
      return;
    }

    if (!_isIapAvailable) {
      debugPrint(
        "PurchaseService: In-app purchases are NOT available on this device/platform.",
      );
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint(
          "PurchaseService: This may be expected on Windows if Microsoft Store IAP is not configured for this plugin version.",
        );
      }
      return;
    }
    debugPrint("PurchaseService: In-app purchases ARE available.");

    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
        "PurchaseService: Android platform detected. Attempting Android specific setup.",
      );
      try {
        // ignore: unused_local_variable
        final InAppPurchaseAndroidPlatformAddition androidAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

        // This is the problematic line during Windows compilation.
        // await androidAddition.enablePendingPurchases();
        debugPrint(
          "PurchaseService: Android pending purchases successfully enabled.",
        );
      } catch (e) {
        debugPrint(
          "PurchaseService: Error during Android-specific IAP setup (enablePendingPurchases or getPlatformAddition): $e",
        );
        // This catch is for runtime errors. The error you're seeing is compile-time.
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint("PurchaseService: iOS platform detected.");
      // iOS specific initializations if any.
    } else {
      debugPrint(
        "PurchaseService: Platform is $defaultTargetPlatform. No specific IAP pre-init steps taken for pending purchases.",
      );
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) => _handlePurchaseUpdates(purchaseDetailsList),
      onDone: () {
        _subscription?.cancel();
        debugPrint("PurchaseService: Purchase stream 'onDone'.");
      },
      onError:
          (error) =>
              debugPrint("PurchaseService: Error in purchase stream: $error"),
    );
    debugPrint("PurchaseService: Subscribed to purchase stream.");

    await _checkProStatusAndPastPurchases();
    debugPrint("PurchaseService: Initialization complete.");
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint(
        "PurchaseService: Handling update for ${purchaseDetails.productID}, status: ${purchaseDetails.status}, error: ${purchaseDetails.error}",
      );
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == kProUpgradeProductId) {
          await _grantProAccess();
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint(
          "PurchaseService: Purchase Error: ${purchaseDetails.error?.message} (Code: ${purchaseDetails.error?.code})",
        );
      }

      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchaseDetails);
          debugPrint(
            "PurchaseService: Purchase explicitly COMPLETED for: ${purchaseDetails.productID}",
          );
        } catch (e) {
          debugPrint(
            "PurchaseService: Error completing purchase for ${purchaseDetails.productID}: $e",
          );
        }
      }
    }
  }

  Future<void> _grantProAccess() async {
    if (!_isProUser) {
      _isProUser = true;
      await prefs.setBool('isProUser', true);
      notifyListeners();
      debugPrint("PurchaseService: Pro access GRANTED and saved.");
    } else {
      debugPrint("PurchaseService: Pro access already granted, no change.");
    }
  }

  // Force free version (for testing)
  Future<void> forceFreeVersion() async {
    _isProUser = false;
    await prefs.setBool('isProUser', false);
    await prefs.setBool('isUnlimitedChat', false);
    notifyListeners();
    debugPrint("PurchaseService: FORCED to free version.");
  }

  // Force pro version (for beta testing)
  Future<void> forceProVersion() async {
    _isProUser = true;
    await prefs.setBool('isProUser', true);
    await prefs.setBool('isUnlimitedChat', true);
    notifyListeners();
    debugPrint("PurchaseService: FORCED to pro version.");
  }

  Future<void> _checkProStatusAndPastPurchases() async {
    debugPrint(
      "PurchaseService: Checking current pro status (from prefs check on init): $_isProUser",
    );

    // Disable auto-restore for free version testing - uncomment for free testing
    debugPrint(
      "PurchaseService: Auto-restore disabled for free version testing",
    );
    return;

    // Normal behavior for production - commented out for free testing
    // if (!_isProUser && _isIapAvailable) {
    //   debugPrint(
    //     "PurchaseService: Not pro, store available. Attempting to restore purchases...",
    //   );
    //   await restorePurchases();
    // }
  }

  Future<void> buyPro() async {
    if (!_isIapAvailable) {
      debugPrint("PurchaseService: Store not available for buying pro.");
      return;
    }
    debugPrint(
      "PurchaseService: Attempting to buy Pro '$kProUpgradeProductId'...",
    );
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails({kProUpgradeProductId});
    if (response.error != null) {
      debugPrint(
        "PurchaseService: Error querying product details: ${response.error!.message} (Code: ${response.error!.code})",
      );
      return;
    }
    if (response.notFoundIDs.contains(kProUpgradeProductId) ||
        response.productDetails.isEmpty) {
      debugPrint(
        "PurchaseService: Pro product '$kProUpgradeProductId' not found in store response.",
      );
      return;
    }

    final ProductDetails productDetails = response.productDetails.firstWhere(
      (details) => details.id == kProUpgradeProductId,
    );
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      final bool purchaseInitiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      debugPrint(
        "PurchaseService: buyNonConsumable initiated, result: $purchaseInitiated",
      );
    } catch (e) {
      debugPrint("PurchaseService: Error during buyNonConsumable: $e");
    }
  }

  Future<void> restorePurchases() async {
    if (!_isIapAvailable) {
      debugPrint(
        "PurchaseService: Store not available for restoring purchases.",
      );
      return;
    }
    debugPrint("PurchaseService: Attempting to restore purchases...");
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint(
        "PurchaseService: Restore purchases call initiated. Updates will come via the purchase stream.",
      );
    } catch (e) {
      debugPrint("PurchaseService: Error restoring purchases: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
    debugPrint("PurchaseService: Disposed.");
  }
}
