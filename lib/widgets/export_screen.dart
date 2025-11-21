import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/services/theme_service.dart'; // Import Theme Service

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ThemeService _themeService = ThemeService();
  final user = FirebaseAuth.instance.currentUser;

  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ); // First day of current month
  DateTime _endDate = DateTime.now(); // Today
  bool _isExporting = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // Custom theme for date picker to match app
        return Theme(
          data: _themeService.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportData() async {
    if (user == null) return;

    setState(() => _isExporting = true);

    try {
      // 1. Fetch Data from Firestore
      // Note: We need to fetch all and filter, or use a composite index for date range querying
      // For simplicity and robustness without index errors, we'll fetch by UID and filter in memory
      // (efficient enough for personal finance apps)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: user!.uid)
          .get();

      List<List<dynamic>> rows = [];

      // 2. Add Header Row
      rows.add(["Date", "Type", "Category", "Account", "Amount", "Note"]);

      // 3. Process Data
      // Ensure end date includes the whole day (up to 23:59:59)
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23,
        59,
        59,
      );

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final Timestamp? timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        final date = timestamp.toDate();

        // Filter by date range
        if (date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endDateTime)) {
          rows.add([
            DateFormat('yyyy-MM-dd HH:mm').format(date),
            data['type'] ?? '',
            data['category'] ?? '',
            data['account'] ?? '',
            data['amount']?.toString() ?? '0',
            data['name'] ?? '', // Note/Description
          ]);
        }
      }

      // 4. Convert to CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // 5. Save to File
      final directory = await getApplicationDocumentsDirectory();
      final path =
          "${directory.path}/smartspend_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // 6. Share/Export
      if (mounted) {
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Here are your transaction records.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        final Color bgTop = _themeService.bgTop;
        final Color bgBottom = _themeService.bgBottom;
        final Color primaryBlue = _themeService.primaryBlue;
        final Color textDark = _themeService.textMain;
        final Color cardBg = _themeService.cardBg;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Export Records",
                          style: TextStyle(
                            color: textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- Info Card ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.table_view_rounded,
                                  size: 48,
                                  color: primaryBlue,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Export as CSV",
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Records within the specified date range will be exported as a CSV file. You can open this file in Excel, Google Sheets, or any spreadsheet app.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _themeService.textSub,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // --- Date Selection ---
                          Text(
                            "From:",
                            style: TextStyle(
                              color: _themeService.textSub,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMMM dd, yyyy',
                                    ).format(_startDate),
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "To:",
                            style: TextStyle(
                              color: _themeService.textSub,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMMM dd, yyyy',
                                    ).format(_endDate),
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // --- Export Button ---
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isExporting ? null : _exportData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 5,
                                shadowColor: primaryBlue.withOpacity(0.4),
                              ),
                              child: _isExporting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "EXPORT NOW",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
