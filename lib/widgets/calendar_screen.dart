import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smartspend/services/theme_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ThemeService _themeService = ThemeService();
  final user = FirebaseAuth.instance.currentUser;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
                colors: [_themeService.bgTop, _themeService.bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _themeService.cardBg,
                              borderRadius: BorderRadius.circular(12),
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
                          "Calendar",
                          style: TextStyle(
                            color: _themeService.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('subscriptions')
                          .where('uid', isEqualTo: user!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        Map<int, List<Map<String, dynamic>>> eventsByDay = {};
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            int day = data['paymentDay'] ?? 1;
                            if (eventsByDay[day] == null) eventsByDay[day] = [];
                            eventsByDay[day]!.add(data);
                          }
                        }

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _themeService.cardBg,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                headerStyle: HeaderStyle(
                                  titleCentered: true,
                                  formatButtonVisible: false,
                                  titleTextStyle: TextStyle(
                                    color: _themeService.textMain,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: _themeService.primaryBlue,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: _themeService.primaryBlue,
                                  ),
                                ),
                                calendarStyle: CalendarStyle(
                                  defaultTextStyle: TextStyle(
                                    color: _themeService.textMain,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: _themeService.textMain,
                                  ),
                                  outsideTextStyle: TextStyle(
                                    color: _themeService.textSub.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: _themeService.primaryBlue
                                        .withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: _themeService.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                                eventLoader: (day) {
                                  return eventsByDay[day.day] ?? [];
                                },
                              ),
                            ),

                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: _themeService.sheetColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDay != null
                                          ? DateFormat(
                                              'MMMM d',
                                            ).format(_selectedDay!)
                                          : "Select a date",
                                      style: TextStyle(
                                        color: _themeService.textMain,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_selectedDay != null &&
                                        (eventsByDay[_selectedDay!.day] ?? [])
                                            .isNotEmpty)
                                      ...eventsByDay[_selectedDay!.day]!
                                          .map(
                                            (data) => Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: _themeService.bgBottom,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.payment,
                                                    color: _themeService
                                                        .primaryBlue,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    data['name'],
                                                    style: TextStyle(
                                                      color: _themeService
                                                          .textMain,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    _themeService
                                                        .formatCurrency(
                                                          (data['amount']
                                                                  as num)
                                                              .toDouble(),
                                                        ),
                                                    style: TextStyle(
                                                      color: _themeService
                                                          .textMain,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList()
                                    else
                                      Text(
                                        "No payments due.",
                                        style: TextStyle(
                                          color: _themeService.textSub,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
