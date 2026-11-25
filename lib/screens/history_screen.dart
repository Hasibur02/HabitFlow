import 'package:flutter/material.dart';

import 'package:habitflow/app_locale.dart';
import 'package:habitflow/app_theme.dart';

// ==================================================
// HISTORY SCREEN
// ==================================================

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> habits;
  final Map<String, IconData> habitIcons;

  const HistoryScreen({
    super.key,
    required this.habits,
    required this.habitIcons,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime selectedMonth = DateTime.now();
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get completedHabits {
    return widget.habits.where((habit) {
      final dates = List<String>.from(
        habit['completedDates'] ?? [],
      );
      return dates.contains(_dateKey(selectedDate));
    }).toList();
  }

  void _changeMonth(int amount) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + amount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final startingWeekday = firstDay.weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Tr(
          'Calendar History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.luxury(radius: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.gold,
                      ),
                    ),
                    Text(
                      '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ].map((day) {
                    return Expanded(
                      child: Center(
                        child: Tr(
                          day,
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: startingWeekday + daysInMonth,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    if (index < startingWeekday) {
                      return const SizedBox();
                    }

                    final day = index - startingWeekday + 1;
                    final date = DateTime(
                      selectedMonth.year,
                      selectedMonth.month,
                      day,
                    );

                    final key = _dateKey(date);
                    final isSelected =
                        _dateKey(selectedDate) == key;

                    final completed = widget.habits.any((habit) {
                      final dates = List<String>.from(
                        habit['completedDates'] ?? [],
                      );
                      return dates.contains(key);
                    });

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.gold
                              : completed
                                  ? const Color(0xFF2FB38F)
                                      .withValues(alpha: 0.35)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.deep
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (completedHabits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: Tr(
                  'No completed habits on this day.',
                ),
              ),
            )
          else
            ...completedHabits.map((habit) {
              final icon = widget.habitIcons[habit['icon']] ??
                  Icons.star_rounded;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.luxury(radius: 16),
                child: ListTile(
                  leading: Icon(
                    icon,
                    color: AppTheme.gold,
                  ),
                  title: Text(
                    AppLocale.tr(habit['name'].toString()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    AppLocale.tr(habit['category'].toString()),
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: AppTheme.gold,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return AppLocale.tr(months[month - 1]);
  }
}
