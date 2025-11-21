import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartspend/services/theme_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final ThemeService _themeService = ThemeService();
  final user = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  String? _selectedDirectory;

  // ---------------- BACKUP LOGIC ----------------
  Future<void> _backupNow() async {
    if (user == null) return;

    if (_selectedDirectory == null) {
      await _pickDirectory();
      if (_selectedDirectory == null) return;
    }

    setState(() => _isLoading = true);

    try {
      final transactions = await _fetchCollection('transactions');
      final categories = await _fetchCollection('categories');
      final accounts = await _fetchCollection('accounts');
      final budgets = await _fetchCollection('budgets');

      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'uid': user!.uid,
        'transactions': transactions,
        'categories': categories,
        'accounts': accounts,
        'budgets': budgets,
      };

      final jsonString = jsonEncode(backupData);

      final fileName =
          "SmartSpend_Backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.mbak";

      final file = File('$_selectedDirectory/$fileName');
      await file.writeAsString(jsonString);

      if (mounted) {
        _showSuccessDialog(
          "Backup Successful",
          "Your backup file is saved at:\n${file.path}",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Backup Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCollection(String collection) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['uid'] == user!.uid ||
              data['userId'] == user!.uid ||
              data['owner'] == user!.uid;
        })
        .map((doc) => doc.data()..['docId'] = doc.id)
        .toList();
  }

  // ---------------- RESTORE LOGIC ----------------
  Future<void> _restore() async {
    if (user == null) return;

    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final backupData = jsonDecode(content);

        await _restoreCollection('transactions', backupData['transactions']);
        await _restoreCollection('categories', backupData['categories']);
        await _restoreCollection('accounts', backupData['accounts']);
        await _restoreCollection('budgets', backupData['budgets']);

        if (mounted) {
          _showSuccessDialog(
            "Restore Complete",
            "Your SmartSpend data has been successfully restored.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Restore Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreCollection(
    String collectionName,
    List<dynamic>? data,
  ) async {
    if (data == null || data.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (var item in data) {
      final docData = Map<String, dynamic>.from(item);
      final docId = docData['docId'];
      docData.remove('docId');

      // Ensure this user owns restored data
      docData['uid'] = user!.uid;
      if (collectionName == 'categories') {
        docData['owner'] = user!.uid;
      }

      // -------- FIX TIMESTAMPS --------
      docData.forEach((key, value) {
        if (value is String) {
          // Detect timestamp format using ISO
          final isPossibleDate = RegExp(r"^\d{4}-\d{2}-\d{2}").hasMatch(value);
          if (isPossibleDate) {
            try {
              docData[key] = Timestamp.fromDate(DateTime.parse(value)); // FIXED
            } catch (_) {}
          }
        }
      });

      final docRef = docId != null
          ? FirebaseFirestore.instance.collection(collectionName).doc(docId)
          : FirebaseFirestore.instance.collection(collectionName).doc();

      batch.set(docRef, docData, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ---------------- DIRECTORY PICKER ----------------
  Future<void> _pickDirectory() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() => _selectedDirectory = selectedDirectory);
    }
  }

  // ---------------- UI HELPERS ----------------
  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _themeService.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: _themeService.textMain)),
        content: Text(content, style: TextStyle(color: _themeService.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: TextStyle(
                color: _themeService.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
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
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- UI SECTIONS ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _themeService.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      _themeService.isDarkMode ? 0.3 : 0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: _themeService.textMain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Backup & Restore",
            style: TextStyle(
              color: _themeService.textMain,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_sync_outlined,
            size: 100,
            color: _themeService.primaryBlue.withOpacity(0.8),
          ),
          const SizedBox(height: 30),

          _buildInfoCard(),
          const SizedBox(height: 40),

          if (_selectedDirectory != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Selected: ...${_selectedDirectory!.split('/').last}",
                style: TextStyle(
                  color: _themeService.textSub,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          if (_isLoading)
            const CircularProgressIndicator()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActionButton(
                  "BACKUP NOW",
                  _themeService.primaryBlue,
                  Colors.white,
                  _backupNow,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  "RESTORE",
                  _themeService.cardBg,
                  _themeService.textMain,
                  _restore,
                  outlined: true,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  "SELECT/CHANGE DIRECTORY",
                  _themeService.cardBg,
                  _themeService.primaryBlue,
                  _pickDirectory,
                  outlined: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _themeService.primaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _themeService.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBullet(
            "Backup includes all transactions, categories, accounts & budgets.",
          ),
          const SizedBox(height: 12),
          _buildBullet("Choose a backup directory before saving files."),
          const SizedBox(height: 12),
          _buildBullet(".mbak files can be restored anytime."),
          const SizedBox(height: 12),
          _buildBullet(
            "Restore overwrites your current data for this account.",
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 8, color: _themeService.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _themeService.textSub,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color bg,
    Color text,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: outlined ? 0 : 5,
          shadowColor: outlined
              ? null
              : _themeService.primaryBlue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: outlined
                ? BorderSide(
                    color: _themeService.primaryBlue.withOpacity(0.5),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
