import 'package:flutter/material.dart';
import 'package:smartspend/services/auth_service.dart';
import 'package:smartspend/services/theme_service.dart';

class DeleteResetScreen extends StatefulWidget {
  const DeleteResetScreen({super.key});

  @override
  State<DeleteResetScreen> createState() => _DeleteResetScreenState();
}

class _DeleteResetScreenState extends State<DeleteResetScreen> {
  final ThemeService _themeService = ThemeService();
  final AuthService _authService = AuthService();

  bool _isDeleting = false;

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.redAccent,
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _themeService.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account & Data',
          style: TextStyle(color: _themeService.textMain),
        ),
        content: Text(
          'This will permanently delete your SmartSpend account, all saved data, '
          'and sign you out. This action cannot be undone. Continue?',
          style: TextStyle(color: _themeService.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      await _authService.deleteAccountAndData();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _themeService.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Account deleted',
            style: TextStyle(color: _themeService.textMain),
          ),
          content: Text(
            'Your account and data have been removed successfully.',
            style: TextStyle(color: _themeService.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: TextStyle(color: _themeService.primaryBlue),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Failed to delete account. Please try again later.');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_themeService.bgTop, _themeService.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: _themeService.textMain),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delete & Reset',
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Permanently remove your SmartSpend account and data.',
                  style: TextStyle(color: _themeService.textSub, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    color: _themeService.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha:0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_forever,
                                    color: Colors.red, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Deleting your account will remove all transactions, budgets, '
                                  'and backups associated with you.',
                                  style: TextStyle(color: _themeService.textSub),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isDeleting ? null : _confirmAndDelete,
                              icon: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.warning_amber_rounded),
                              label: Text(
                                _isDeleting
                                    ? 'Deleting account...'
                                    : 'Delete account & data',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

