import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';

/// Show the “Upgrade to Pro” dialog and kick off the IAP flow.
void showUpgradeDialog(BuildContext context, PurchaseService purchaseService) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    builder:
        (dialogCtx) => AlertDialog(
          title: const Text('Upgrade to Pro'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock powerful Pro features for \$9.99:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.search, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Advanced search across all controls'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Favorites system to save important controls',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.grid_view, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Grid view for visual family browsing'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.filter_list, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Advanced filtering: baseline, implementation level & complete control list',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.psychology_alt, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(child: Text('AI RMF Playbook access')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.folder_shared, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(child: Text('SSP Generator (Experimental)')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.tune, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(child: Text('Custom Baseline & Overlay Builder')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.note, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Personal notes and enhanced navigation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // First row with Cancel and Restore Purchase
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // close the dialog first
                    Navigator.of(dialogCtx).pop();

                    // attempt to restore purchases
                    try {
                      await purchaseService.restorePurchases();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Purchases restored successfully.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Restore failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Restore Purchase'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Full-width Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // close the dialog first
                  Navigator.of(dialogCtx).pop();

                  // attempt the purchase
                  try {
                    await purchaseService.buyPro();
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Purchase failed: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
  );
}
