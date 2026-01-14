// lib/services/iap_fallback.dart

// This file provides stubs for types from 'package:in_app_purchase_android'
// when compiling for non-Android platforms where the real package isn't used.

// Stub for InAppPurchaseAndroidPlatformAddition
import 'package:flutter/foundation.dart';

class InAppPurchaseAndroidPlatformAddition {
  // Provide a no-op (empty) version of any method that your main code
  // might try to call on this type when the fallback is active.
  Future<void> enablePendingPurchases() async {
    // This is a no-op because on non-Android platforms,
    // this specific Android feature doesn't apply.
    if (kDebugMode) {
      print("Stub InAppPurchaseAndroidPlatformAddition: enablePendingPurchases() called on non-Android.");
    }
  }

  // Add other methods if your main code calls them and they would cause errors.
  // For example, if you called androidAddition.someOtherMethod(), add:
  // Future<void> someOtherMethod() async {}
}

// You might also need to stub out other specific classes or top-level functions
// if your purchase_service.dart imports and uses them directly from
// 'package:in_app_purchase_android/in_app_purchase_android.dart'.
// For now, InAppPurchaseAndroidPlatformAddition is the main one causing issues.