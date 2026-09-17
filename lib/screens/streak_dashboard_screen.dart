import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_tracker.dart';
import '../providers/streak_provider.dart';
import '../services/streak_service.dart';
import '../widgets/glass_widgets.dart';

class StreakDashboardScreen extends StatefulWidget {
  const StreakDashboardScreen({super.key});

  @override
  State<StreakDashboardScreen> createState() => _StreakDashboardScreenState();
}

class _StreakDashboardScreenState extends State<StreakDashboardScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final currentMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    if (!next.isAfter(currentMonthStart)) {
      setState(() {
        _selectedMonth = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'سجل الالتزام',
        showBackButton: true,
        scrollOffset: 50,
      ),
      body: Consumer<StreakProvider>(
        builder: (context, streakProvider, _) {
          final todayData = streakProvider.todayData;
          final currentStreak = streakProvider.currentStreak;
          final bestStreak = streakProvider.bestStreak;
          final totalSessions = streakProvider.totalSessions;

          return ListView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              bottom: 60,
            ),
            children: [
              // ═════════════════════════════════════════
              //  HERO BANNER
              // ═════════════════════════════════════════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B).withValues(alpha: 0.8),
                            const Color(0xFF0F172A).withValues(alpha: 0.9),
                          ]
                        : [
                            const Color(0xFFFFFFFF),
                            const Color(0xFFF0FDF4),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_graph_rounded,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'سجل المداومة على الأذكار',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ»',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ═════════════════════════════════════════
              //  3 KPI HERO CARDS
              // ═════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF97316),
                      value: '$currentStreak',
                      unit: 'أيام',
                      title: 'السلسلة الحالية',
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFEAB308),
                      value: '$bestStreak',
                      unit: 'أيام',
                      title: 'أفضل التزام',
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF10B981),
                      value: '$totalSessions',
                      unit: 'وِردًا',
                      title: 'إجمالي الأوراد',
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ═════════════════════════════════════════
              //  TODAY'S COMMITMENT CHECKLIST
              // ═════════════════════════════════════════
              Text(
                'أوراد اليوم',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _TodayChecklistCard(
                todayData: todayData,
                isDark: isDark,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),

              const SizedBox(height: 28),

              // ═════════════════════════════════════════
              //  INTERACTIVE MONTHLY CALENDAR
              // ═════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تقويم الالتزام',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _prevMonth,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_getArabicMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _isCurrentMonth(_selectedMonth) ? null : _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MonthCalendarCard(
                month: _selectedMonth,
                data: streakProvider.data,
                isDark: isDark,
                primaryColor: primaryColor,
                onDayTapped: (date, entry) => _showDayDetails(context, date, entry),
              ),

              const SizedBox(height: 28),

              // ═════════════════════════════════════════
              //  BENEFIT CARD
              // ═════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: secondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'فضل المداومة على الذكر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'قال الإمام النووي رحمه الله: ينبغي لمن كان له وظيفة من الذكر في وقت من ليل أو نهار أو عقب صلاة أو حال من الأحوال ففاتته، أن يتداركها ويأتي بها إذا تمكن منها ولا يهملها، فإنه إذا اعتاد ملازمتها لم يعرضها للتفويت.',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 15,
                              height: 1.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  String _getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  void _showDayDetails(BuildContext context, DateTime date, DayCompletion? entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تفاصيل يوم ${date.day} ${_getArabicMonthName(date.month)} ${date.year}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (entry == null || !entry.hasAnyActivity)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'لم يتم تسجيل أوراد في هذا اليوم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                )
              else ...[
                _DayDetailRow(
                  title: 'أذكار الصباح',
                  isCompleted: entry.morning,
                  icon: Icons.wb_sunny_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 10),
                _DayDetailRow(
                  title: 'أذكار المساء',
                  isCompleted: entry.evening,
                  icon: Icons.nightlight_round,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 10),
                _DayDetailRow(
                  title: 'أذكار الصلوات (${entry.prayers.length}/5)',
                  isCompleted: entry.prayers.isNotEmpty,
                  subtitle: entry.prayers.isEmpty
                      ? 'لم تسجل'
                      : entry.prayers
                          .map((p) => _getPrayerArabicName(p))
                          .join('، '),
                  icon: Icons.mosque_rounded,
                  color: const Color(0xFF10B981),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _getPrayerArabicName(String id) {
    switch (id) {
      case 'fajr':
        return 'الفجر';
      case 'dhuhr':
        return 'الظهر';
      case 'asr':
        return 'العصر';
      case 'maghrib':
        return 'المغرب';
      case 'isha':
        return 'العشاء';
      default:
        return id;
    }
  }
}

// ══════════════════════════════════════════════════════
//  KPI HERO CARD
// ══════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String title;
  final bool isDark;
  final Color primaryColor;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.title,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TODAY'S CHECKLIST CARD
// ══════════════════════════════════════════════════════
class _TodayChecklistCard extends StatelessWidget {
  final DayCompletion todayData;
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;

  const _TodayChecklistCard({
    required this.todayData,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ChecklistItem(
            title: 'أذكار الصباح',
            isDone: todayData.morning,
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const Divider(height: 20),
          _ChecklistItem(
            title: 'أذكار المساء',
            isDone: todayData.evening,
            icon: Icons.nightlight_round,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          const Divider(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.mosque_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'أذكار بعد الصلوات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${todayData.prayers.length}/5 صلوات',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PrayerChip(name: 'الفجر', isDone: todayData.prayers.contains('fajr'), isDark: isDark),
                  _PrayerChip(name: 'الظهر', isDone: todayData.prayers.contains('dhuhr'), isDark: isDark),
                  _PrayerChip(name: 'العصر', isDone: todayData.prayers.contains('asr'), isDark: isDark),
                  _PrayerChip(name: 'المغرب', isDone: todayData.prayers.contains('maghrib'), isDark: isDark),
                  _PrayerChip(name: 'العشاء', isDone: todayData.prayers.contains('isha'), isDark: isDark),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final bool isDone;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _ChecklistItem({
    required this.title,
    required this.isDone,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: isDone
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
              const SizedBox(width: 5),
              Text(
                isDone ? 'تم بحمد الله' : 'في الانتظار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrayerChip extends StatelessWidget {
  final String name;
  final bool isDone;
  final bool isDark;

  const _PrayerChip({
    required this.name,
    required this.isDone,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDone)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.check_rounded,
                size: 12,
                color: Color(0xFF10B981),
              ),
            ),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
              color: isDone
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  MONTHLY CALENDAR CARD
// ══════════════════════════════════════════════════════
class _MonthCalendarCard extends StatelessWidget {
  final DateTime month;
  final Map<String, DayCompletion> data;
  final bool isDark;
  final Color primaryColor;
  final Function(DateTime, DayCompletion?) onDayTapped;

  const _MonthCalendarCard({
    required this.month,
    required this.data,
    required this.isDark,
    required this.primaryColor,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    const weekDays = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday is 7 in Dart DateTime (weekday), let's map Sunday=0 .. Saturday=6
    final startWeekday = firstDayOfMonth.weekday % 7;

    final now = DateTime.now();
    final todayKey = StreakService.formatDateKey(now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox.shrink();
              }

              final dayNum = index - startWeekday + 1;
              final cellDate = DateTime(month.year, month.month, dayNum);
              final cellKey = StreakService.formatDateKey(cellDate);
              final entry = data[cellKey];
              final isToday = cellKey == todayKey;
              final isFuture = cellDate.isAfter(now);

              return _CalendarDayCell(
                dayNumber: dayNum,
                isToday: isToday,
                isFuture: isFuture,
                entry: entry,
                isDark: isDark,
                primaryColor: primaryColor,
                onTap: isFuture ? null : () => onDayTapped(cellDate, entry),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int dayNumber;
  final bool isToday;
  final bool isFuture;
  final DayCompletion? entry;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback? onTap;

  const _CalendarDayCell({
    required this.dayNumber,
    required this.isToday,
    required this.isFuture,
    required this.entry,
    required this.isDark,
    required this.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity = entry != null && entry!.hasAnyActivity;
    final isPerfect = entry != null && entry!.isPerfectDay;

    Color bgColor;
    Color textColor;
    Border? border;

    if (isFuture) {
      bgColor = Colors.transparent;
      textColor = isDark ? Colors.white24 : Colors.black26;
    } else if (isPerfect) {
      bgColor = const Color(0xFF10B981);
      textColor = Colors.white;
    } else if (hasActivity) {
      bgColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.2);
      textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    } else {
      bgColor = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC);
      textColor = isDark ? Colors.white70 : const Color(0xFF475569);
    }

    if (isToday) {
      border = Border.all(
        color: const Color(0xFFF59E0B),
        width: 2,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  fontWeight: (hasActivity || isToday) ? FontWeight.w800 : FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (hasActivity && !isPerfect)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetailRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final IconData icon;
  final Color color;

  const _DayDetailRow({
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: isCompleted ? const Color(0xFF10B981) : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}
