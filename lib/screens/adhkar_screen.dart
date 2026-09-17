import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/adhkar_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/glass_widgets.dart';

class AdhkarScreen extends StatelessWidget {
  final String title;

  const AdhkarScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdhkarProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: title,
            scrollOffset: 50,
            actions: [
              // ── Undo button ──
              if (provider.canUndo && !provider.isCompleted)
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'تراجع',
                  onPressed: () {
                    provider.undo();
                    try {
                      HapticFeedback.mediumImpact();
                    } catch (_) {}
                  },
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.adhkarList.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد أذكار',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                );
              }

              if (provider.isCompleted) {
                return _CompletionView(provider: provider);
              }

              return _DhikrView(provider: provider);
            },
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
//  DHIKR READING VIEW
// ══════════════════════════════════════════════════════
class _DhikrView extends StatefulWidget {
  final AdhkarProvider provider;

  const _DhikrView({required this.provider});

  @override
  State<_DhikrView> createState() => _DhikrViewState();
}

class _DhikrViewState extends State<_DhikrView>
    with TickerProviderStateMixin {
  final List<_RippleEntry> _ripples = [];

  void _onCounterTap(AdhkarProvider provider, [Offset? tapPosition]) {
    final wasLastTap = provider.remainingCount == 1;
    final accepted = provider.decrementCounter();
    if (accepted) {
      try {
        if (wasLastTap) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      } catch (_) {}

      if (tapPosition != null && mounted) {
        _spawnRipple(tapPosition);
      }
    }
  }

  void _spawnRipple(Offset center) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final entry = _RippleEntry(
      center: center,
      controller: controller,
      animation: CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    setState(() => _ripples.add(entry));

    controller.forward().then((_) {
      if (mounted) {
        setState(() => _ripples.remove(entry));
      }
      controller.dispose();
    });
  }

  @override
  void dispose() {
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    _ripples.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final dhikr = provider.currentDhikr;
    if (dhikr == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (provider.currentIndex + 1) / provider.totalCount;
    final tapToConfirm =
        Provider.of<SettingsProvider>(context).tapToConfirm;

    final content = Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight - 24),
        // ══════════════════════════════════════════════
        //  PREMIUM PROGRESS SECTION (ultra-compact & top-aligned)
        // ══════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
          child: Column(
            children: [
              // ── Step indicator + Percentage ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step counter badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                          theme.colorScheme.primary.withValues(alpha: isDark ? 0.06 : 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'الذكر ${provider.currentIndex + 1} من ${provider.totalCount}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated percentage
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ── Premium gradient progress bar ──
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, _) => LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    final fillWidth = barWidth * value;
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── Track (thin & subtle) ──
                          Container(
                            height: 6,
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),

                          // ── Fill with gradient ──
                          if (fillWidth > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                height: 6,
                                width: fillWidth.clamp(6.0, barWidth),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withValues(alpha: 0.6),
                                      theme.colorScheme.primary,
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Glowing tip dot (double ring) ──
                          if (fillWidth > 4)
                            Positioned(
                              right: fillWidth.clamp(6.0, barWidth) - 7,
                              top: -4,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // ── Step dots indicator ──
              if (provider.totalCount <= 15)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(provider.totalCount, (i) {
                    final isCompleted = i < provider.currentIndex;
                    final isCurrent = i == provider.currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : isCurrent
                                ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                : theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.1),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 8),

              // ── Required count badge (golden pill) ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: isDark ? 0.15 : 0.1),
                      theme.colorScheme.secondary.withValues(alpha: isDark ? 0.06 : 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'العدد المطلوب: ${dhikr.count}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ══════════════════════════════════════════════
        //  DHIKR CONTENT
        // ══════════════════════════════════════════════
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: SingleChildScrollView(
              key: ValueKey<int>(provider.currentIndex),
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
              child: Column(
                children: [
                  // ── Reference (above the dhikr) ──
                  if (dhikr.reference.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      dhikr.reference,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6B6B),
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // ── Bienfaits / الفضل (golden ornamented box) ──
                  if (dhikr.bienfaits.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _BienfaitBox(text: dhikr.bienfaits, theme: theme, isDark: isDark),
                  ],

                  const SizedBox(height: 12),

                  // ── Main Arabic Dhikr Text ──────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : theme.colorScheme.primary.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── Decorative top ornament ──
                        _IslamicOrnament(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          dhikr.text,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 2.2,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 16),
                        // ── Decorative bottom ornament ──
                        _IslamicOrnament(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Floating counter badge in fullscreen-tap mode ──
                  if (tapToConfirm) ...[
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Container(
                        key: ValueKey<int>(provider.remainingCount),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                              theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 22,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${provider.remainingCount}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ══════════════════════════════════════════════
        //  TASBIH BEAD COUNTER (Non-fullscreen mode)
        // ══════════════════════════════════════════════
        if (!tapToConfirm)
          _TasbihButton(
            remainingCount: provider.remainingCount,
            theme: theme,
            onTap: () => _onCounterTap(provider),
          ),
      ],
    );

    // ── Fullscreen tap mode: wrap everything in a GestureDetector + ripple overlay ──
    if (tapToConfirm) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          _onCounterTap(provider, details.localPosition);
        },
        child: Stack(
          children: [
            content,
            // Ripple overlay
            ..._ripples.map((ripple) {
              return AnimatedBuilder(
                animation: ripple.animation,
                builder: (context, _) {
                  final size = MediaQuery.of(context).size;
                  final maxRadius = size.longestSide * 1.2;
                  final currentRadius = maxRadius * ripple.animation.value;
                  final opacity = (1.0 - ripple.animation.value) * 0.18;

                  return Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RipplePainter(
                          center: ripple.center,
                          radius: currentRadius,
                          color: theme.colorScheme.primary
                              .withValues(alpha: opacity),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    }

    return content;
  }
}

// ══════════════════════════════════════════════════════
//  BIENFAIT BOX (Golden ornamented)
// ══════════════════════════════════════════════════════
class _BienfaitBox extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final bool isDark;

  const _BienfaitBox({
    required this.text,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
    final textColor = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final bgColors = isDark
        ? [const Color(0x240D9488), const Color(0x0D14B8A6)]
        : [const Color(0x140D9488), const Color(0x050D9488)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_rounded,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.6,
              ),
              textAlign: TextAlign.start,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  ISLAMIC ORNAMENT (Thin decorative line)
// ══════════════════════════════════════════════════════
class _IslamicOrnament extends StatelessWidget {
  final Color color;

  const _IslamicOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 12,
      child: CustomPaint(
        painter: _OrnamentPainter(color: color),
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  final Color color;
  _OrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final midY = size.height / 2;
    final midX = size.width / 2;

    // Left line
    canvas.drawLine(Offset(0, midY), Offset(midX - 10, midY), paint);
    // Right line
    canvas.drawLine(Offset(midX + 10, midY), Offset(size.width, midY), paint);
    // Center diamond
    final diamondPath = Path()
      ..moveTo(midX, midY - 5)
      ..lineTo(midX + 6, midY)
      ..lineTo(midX, midY + 5)
      ..lineTo(midX - 6, midY)
      ..close();
    canvas.drawPath(diamondPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ══════════════════════════════════════════════════════
//  TASBIH BUTTON (Full-Width Bottom Quarter Zone)
// ══════════════════════════════════════════════════════
class _TasbihButton extends StatelessWidget {
  final int remainingCount;
  final ThemeData theme;
  final VoidCallback onTap;

  const _TasbihButton({
    required this.remainingCount,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.25,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.80),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$remainingCount',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اضغط',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  RIPPLE ANIMATION DATA
// ══════════════════════════════════════════════════════
class _RippleEntry {
  final Offset center;
  final AnimationController controller;
  final Animation<double> animation;

  _RippleEntry({
    required this.center,
    required this.controller,
    required this.animation,
  });
}

// ══════════════════════════════════════════════════════
//  CUSTOM PAINTER FOR RADIAL RIPPLE
// ══════════════════════════════════════════════════════
class _RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  _RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.radius != radius || old.color != color || old.center != center;
}

// ══════════════════════════════════════════════════════
//  COMPLETION VIEW
// ══════════════════════════════════════════════════════
class _CompletionView extends StatefulWidget {
  final AdhkarProvider provider;

  const _CompletionView({required this.provider});

  @override
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _rubController;
  late Animation<double> _rubRotation;
  late Animation<double> _rubScale;

  // Confetti particles
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );


    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Rub el Hizb rotation
    _rubController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _rubRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _rubController, curve: Curves.easeOutCubic),
    );

    _rubScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rubController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generate particles
    final rng = math.Random(42);
    for (int i = 0; i < 20; i++) {
      _particles.add(_ConfettiParticle(
        angle: rng.nextDouble() * 2 * math.pi,
        speed: 80 + rng.nextDouble() * 120,
        size: 3.0 + rng.nextDouble() * 4.0,
        color: [
          const Color(0xFFD4AF37),
          const Color(0xFFF59E0B),
          const Color(0xFF2DD4BF),
          const Color(0xFFFFD700),
        ][i % 4],
      ));
    }

    // Start animations
    _rubController.forward();
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.forward();
    });

    // Record streak & commitment completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final streakProvider =
            Provider.of<StreakProvider>(context, listen: false);
        streakProvider.recordCompletion(
          widget.provider.currentCategory,
          dhikrsCount: widget.provider.totalCount,
        );
      }
    });

    // Haptic
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rubController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final isAfterPrayer = widget.provider.currentCategory.startsWith('after_') ||
        widget.provider.currentCategory == 'after_prayer';

    final quoteAttribution = isAfterPrayer
        ? 'وصية النبي ﷺ لمعاذ بن جبل رضي الله عنه'
        : 'قال الإمام ابن القيم رحمه الله';

    final quoteText = isAfterPrayer
        ? '«يَا مُعَاذُ، وَاللَّهِ إِنِّي لَأُحِبُّكَ، فَلَا تَدَعَنَّ فِي دُبُرِ كُلِّ صَلَاةٍ أَنْ تَقُولَ: اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ»'
        : 'أذكار الصباح والمساء بمثابة الدرع، كلما زادت سماكته لم يتأثر صاحبه، بل تصل قوة الدرع أن يعود السهم فيصيب من أطلقه.';

    final completionSubtitle = isAfterPrayer
        ? 'تقبّل الله صلاتك وذكرك'
        : 'لقد أتممت جميع الأذكار';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ══════════════════════════════════════
                //  RUB EL HIZB Symbol
                // ══════════════════════════════════════
                AnimatedBuilder(
                  animation: _rubController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _rubScale.value,
                      child: Transform.rotate(
                        angle: _rubRotation.value * math.pi,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: _RubElHizbPainter(
                        color: primaryColor,
                        glowColor: primaryColor.withValues(alpha: 0.3),
                        isDark: isDark,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 44,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Main message ──
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ).createShader(bounds),
                        child: Text(
                          isAfterPrayer ? 'تقبّل الله طاعتكم!' : 'بارك الله فيك!',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          completionSubtitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ══════════════════════════════════
                      //  QUOTE CARD (Frosted glass style)
                      // ══════════════════════════════════
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── Main card ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues(alpha: isDark ? 0.1 : 0.04),
                                  primaryColor.withValues(alpha: isDark ? 0.03 : 0.01),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : primaryColor.withValues(alpha: 0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // ── Author attribution ──
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 1,
                                      width: 32,
                                      color: primaryColor.withValues(alpha: 0.25),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        quoteAttribution,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      height: 1,
                                      width: 32,
                                      color: primaryColor.withValues(alpha: 0.25),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // ── Quote text ──
                                Text(
                                  quoteText,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                    height: 1.9,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
                                  ),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),

                          // ── Top-Left corner quote badge ──
                          Positioned(
                            top: -18,
                            left: 24,
                            child: _QuoteBadge(
                              character: '\u201C',
                              primaryColor: primaryColor,
                              scaffoldColor: theme.scaffoldBackgroundColor,
                            ),
                          ),

                          // ── Bottom-Right corner quote badge ──
                          Positioned(
                            bottom: -18,
                            right: 24,
                            child: _QuoteBadge(
                              character: '\u201D',
                              primaryColor: primaryColor,
                              scaffoldColor: theme.scaffoldBackgroundColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ══════════════════════════════════
                      //  ACTION BUTTONS (Pill style)
                      // ══════════════════════════════════
                      Row(
                        children: [
                          // ── Home button ──
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.home_rounded,
                              label: 'الرئيسية',
                              isPrimary: false,
                              primaryColor: primaryColor,
                              isDark: isDark,
                              scaffoldColor: theme.scaffoldBackgroundColor,
                              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // ── Repeat button ──
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.refresh_rounded,
                              label: 'إعادة',
                              isPrimary: true,
                              primaryColor: primaryColor,
                              isDark: isDark,
                              scaffoldColor: theme.scaffoldBackgroundColor,
                              onTap: () => widget.provider.reset(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ══════════════════════════════════════
          //  CONFETTI OVERLAY
          // ══════════════════════════════════════
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return IgnorePointer(
                child: CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  QUOTE BADGE
// ══════════════════════════════════════════════════════
class _QuoteBadge extends StatelessWidget {
  final String character;
  final Color primaryColor;
  final Color scaffoldColor;

  const _QuoteBadge({
    required this.character,
    required this.primaryColor,
    required this.scaffoldColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: scaffoldColor,
          width: 3,
        ),
      ),
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 4),
          child: Text(
            character,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              height: 1.0,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  ACTION BUTTON (Pill-style)
// ══════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final Color primaryColor;
  final bool isDark;
  final Color scaffoldColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.primaryColor,
    required this.isDark,
    required this.scaffoldColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isPrimary ? null : scaffoldColor,
        border: isPrimary
            ? null
            : Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : primaryColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  RUB EL HIZB PAINTER
// ══════════════════════════════════════════════════════
class _RubElHizbPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final bool isDark;

  _RubElHizbPainter({
    required this.color,
    required this.glowColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Glow
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius * 0.7, glowPaint);

    // Draw two overlapping squares rotated to form an 8-pointed star
    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.25 : 0.15)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.5 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Square 1 (0°)
    _drawRotatedSquare(canvas, center, radius, 0, paint);
    _drawRotatedSquare(canvas, center, radius, 0, strokePaint);

    // Square 2 (45°)
    _drawRotatedSquare(canvas, center, radius, math.pi / 4, paint);
    _drawRotatedSquare(canvas, center, radius, math.pi / 4, strokePaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, innerPaint);

    final innerStrokePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.3 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.5, innerStrokePaint);
  }

  void _drawRotatedSquare(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RubElHizbPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}

// ══════════════════════════════════════════════════════
//  CONFETTI PARTICLE & PAINTER
// ══════════════════════════════════════════════════════
class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.15; // emanate from top area

    for (final particle in particles) {
      final distance = particle.speed * progress;
      final x = centerX + math.cos(particle.angle) * distance;
      final y = centerY + math.sin(particle.angle) * distance + (progress * progress * 100); // gravity
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final currentSize = particle.size * (1.0 - progress * 0.5);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      // Draw as a 4-pointed star
      final path = Path();
      path.moveTo(x, y - currentSize);
      path.quadraticBezierTo(x, y, x + currentSize, y);
      path.quadraticBezierTo(x, y, x, y + currentSize);
      path.quadraticBezierTo(x, y, x - currentSize, y);
      path.quadraticBezierTo(x, y, x, y - currentSize);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
