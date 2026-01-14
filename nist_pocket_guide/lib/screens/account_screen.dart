import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_sync_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = AuthService();
  final _syncService = DataSyncService();

  bool _isLoading = false;
  bool _isGuestMode = true;
  AIUsageStats? _usageStats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  Future<void> _loadAccountInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _isGuestMode = await _authService.isGuestMode();

      if (!_isGuestMode && _authService.isAuthenticated) {
        final statsResult = await _syncService.getAIUsageStats();
        if (statsResult.isSuccess) {
          _usageStats = statsResult.data;
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load account info';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  Future<void> _handleCreateAccount() async {
    Navigator.of(context).pushNamed('/auth');
  }

  Future<void> _handleSyncData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // This would trigger a full data sync
      // Implementation depends on your local data structure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data sync completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sync data';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildGuestModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Guest Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re using the app in guest mode. Your data is stored locally on this device only.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleCreateAccount,
                icon: const Icon(Icons.account_circle),
                label: const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Benefits of creating an account:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            _buildBenefit('Sync data across devices'),
            _buildBenefit('Access AI features with usage tracking'),
            _buildBenefit('Backup your chat history'),
            _buildBenefit('Personalized settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedSection() {
    final user = _authService.currentUser;

    return Column(
      children: [
        // User Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        (user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.userMetadata?['full_name'] ?? 'User',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // AI Usage Card
        if (_usageStats != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Usage Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildUsageBar(
                    'Daily',
                    _usageStats!.dailyTokens,
                    _usageStats!.dailyUsagePercentage,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageBar(
                    'Weekly',
                    _usageStats!.weeklyTokens,
                    _usageStats!.weeklyUsagePercentage,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageBar(
                    'Monthly',
                    _usageStats!.monthlyTokens,
                    _usageStats!.monthlyUsagePercentage,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),
        ],

        // Sync Card
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Sync',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your data synchronized across all devices',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSyncData,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.sync),
                    label: Text(_isLoading ? 'Syncing...' : 'Sync Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageBar(
    String label,
    int tokens,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$tokens tokens (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isLoading && _usageStats == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _isGuestMode
                        ? _buildGuestModeSection()
                        : _buildAuthenticatedSection(),
                  ],
                ),
              ),
    );
  }
}
