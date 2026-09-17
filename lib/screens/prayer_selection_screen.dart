import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/adhkar_provider.dart';
import '../widgets/glass_widgets.dart';
import 'adhkar_screen.dart';

/// Data model for a prayer card
class _PrayerInfo {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final Color iconBgColor;

  const _PrayerInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.iconBgColor,
  });
}

class PrayerSelectionScreen extends StatefulWidget {
  const PrayerSelectionScreen({super.key});

  @override
  State<PrayerSelectionScreen> createState() => _PrayerSelectionScreenState();
}

class _PrayerSelectionScreenState extends State<PrayerSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  static const List<_PrayerInfo> _prayers = [
    _PrayerInfo(
      id: 'fajr',
      name: 'صلاة الفجر',
      subtitle: 'نور الشروق وبداية اليوم',
      icon: Icons.wb_twilight_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      glowColor: Color(0xFFF59E0B),
      iconBgColor: Color(0x33FBBF24),
    ),
    _PrayerInfo(
      id: 'dhuhr',
      name: 'صلاة الظهر',
      subtitle: 'وسط النهار وذروة الشمس',
      icon: Icons.wb_sunny_rounded,
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      glowColor: Color(0xFF0EA5E9),
      iconBgColor: Color(0x3338BDF8),
    ),
    _PrayerInfo(
      id: 'asr',
      name: 'صلاة العصر',
      subtitle: 'ميل الشمس وآخر النهار',
      icon: Icons.wb_shade_rounded,
      gradientColors: [Color(0xFFF97316), Color(0xFFEA580C)],
      glowColor: Color(0xFFF97316),
      iconBgColor: Color(0x33FB923C),
    ),
    _PrayerInfo(
      id: 'maghrib',
      name: 'صلاة المغرب',
      subtitle: 'لحظة غروب الشمس',
      icon: Icons.nights_stay_rounded,
      gradientColors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
      glowColor: Color(0xFFA855F7),
      iconBgColor: Color(0x33C084FC),
    ),
    _PrayerInfo(
      id: 'isha',
      name: 'صلاة العشاء',
      subtitle: 'سكون الليل وختام اليوم',
      icon: Icons.dark_mode_rounded,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF1E3A5F)],
      glowColor: Color(0xFF3B82F6),
      iconBgColor: Color(0x3360A5FA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPrayerTap(BuildContext context, _PrayerInfo prayer) {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final provider = Provider.of<AdhkarProvider>(context, listen: false);
    provider.loadAdhkar('after_${prayer.id}');

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            AdhkarScreen(title: 'أذكار بعد ${prayer.name}'),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Header animations
    final headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    final headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
          ),
        );

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'اختر الصلاة',
        scrollOffset: _scrollOffset,
      ),
      bottomNavigationBar: const FloatingGlassDock(activeIndex: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF090D16),
                    const Color(0xFF0F1729),
                    const Color(0xFF090D16),
                  ]
                : [
                    const Color(0xFFFAF8F5),
                    const Color(0xFFF0EBE4),
                    const Color(0xFFFAF8F5),
                  ],
          ),
        ),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            bottom: 100,
          ),
          children: [
            // ── Header ──
            SlideTransition(
              position: headerSlide,
              child: FadeTransition(
                opacity: headerFade,
                child: Column(
                  children: [
                    Icon(
                      Icons.mosque_rounded,
                      size: 48,
                      color: isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF115E54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'أذكار بعد الصلاة',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر الصلاة التي صليتها',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF5A6B6B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Prayer Cards ──
            ..._prayers.asMap().entries.map((entry) {
              final index = entry.key;
              final prayer = entry.value;

              final start = 0.15 + (index * 0.10);
              final end = (start + 0.35).clamp(0.0, 1.0);

              final cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start, end, curve: Curves.easeOut),
                ),
              );
              final cardSlide = Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                ),
              );

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: cardFade.value,
                    child: SlideTransition(position: cardSlide, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PrayerCard(
                    prayer: prayer,
                    isDark: isDark,
                    onTap: () => _onPrayerTap(context, prayer),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Prayer Card Widget
// ══════════════════════════════════════════════════════════════════════════════

class _PrayerCard extends StatefulWidget {
  final _PrayerInfo prayer;
  final bool isDark;
  final VoidCallback onTap;

  const _PrayerCard({
    required this.prayer,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnim.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      prayer.gradientColors[0].withValues(alpha: 0.15),
                      prayer.gradientColors[1].withValues(alpha: 0.08),
                    ]
                  : [
                      prayer.gradientColors[0].withValues(alpha: 0.10),
                      prayer.gradientColors[1].withValues(alpha: 0.05),
                    ],
            ),
            border: Border.all(
              color: prayer.gradientColors[0].withValues(
                alpha: isDark ? 0.25 : 0.20,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: prayer.glowColor.withValues(alpha: isDark ? 0.12 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // ── Subtle decorative gradient circle ──
                Positioned(
                  left: -30,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          prayer.glowColor.withValues(
                            alpha: isDark ? 0.10 : 0.07,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      // ── Icon container ──
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: prayer.gradientColors,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: prayer.glowColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(prayer.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),

                      // ── Text content ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer.name,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A2A2A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              prayer.subtitle,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF5A6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Arrow ──
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: prayer.gradientColors[0].withValues(
                            alpha: isDark ? 0.15 : 0.10,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: prayer.gradientColors[0],
                          size: 16,
                        ),
                      ),
                    ],
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
