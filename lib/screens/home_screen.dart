import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/adhkar_provider.dart';
import '../providers/streak_provider.dart';
import '../services/pwa_install_service.dart';
import 'adhkar_screen.dart';
import 'prayer_selection_screen.dart';
import 'streak_dashboard_screen.dart';
import '../widgets/glass_widgets.dart';
import 'package:web/web.dart' as web;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

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

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleUrlParameters();
    });
  }

  void _handleUrlParameters() {
    try {
      final uri = Uri.parse(web.window.location.href);
      final category = uri.queryParameters['category'];
      if (category == 'morning' || category == 'evening') {
        _navigateToAdhkar(context, category!);
        _clearUrlParameters();
      }
    } catch (_) {}
  }

  void _clearUrlParameters() {
    try {
      web.window.history.replaceState(null, '', '/');
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pwaService = Provider.of<PwaInstallService>(context);

    // Staggered Animations
    final fadeHeader = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    final scaleHeader = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    final fadeBasmala = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    final slideBasmala = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    final fadeToggle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );
    final slideToggle = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    final fadeCard1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );
    final scaleCard1 = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutBack),
      ),
    );

    final fadeCard2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 0.95, curve: Curves.easeOut),
      ),
    );
    final scaleCard2 = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 0.95, curve: Curves.easeOutBack),
      ),
    );

    final fadeCard3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    final scaleCard3 = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutBack),
      ),
    );

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: 'أذكار غزة', scrollOffset: _scrollOffset),
      bottomNavigationBar: const FloatingGlassDock(activeIndex: 0),
      body: Stack(
        children: [
          // Subtle Islamic Geometric Pattern Background
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: theme.brightness == Brightness.light
                      ? theme.colorScheme.primary.withValues(alpha: 0.025)
                      : theme.colorScheme.primary.withValues(alpha: 0.012),
                ),
              ),
            ),
          ),
          // Main Body Column
          Column(
            children: [
              // ── PWA Install Ribbon ────────────────────
              if (pwaService.shouldShowPrompt)
                _InstallRibbon(
                  onTap: () => _handleInstall(context, pwaService),
                  onDismiss: () => pwaService.dismissPrompt(),
                ),

              // ── Main Content ──────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top:
                        MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        16,
                    bottom: 110,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Header ───────────────────────
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeHeader.value,
                            child: Transform.scale(
                              scale: scaleHeader.value,
                              child: child,
                            ),
                          );
                        },
                        child: const _HeaderHero(),
                      ),
                      const SizedBox(height: 16),

                      // ── Glass Gaza Dedication Banner (Immediately Visible) ──
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeHeader.value,
                            child: child,
                          );
                        },
                        child: GlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          borderColor: isDark
                              ? const Color(0x33EF4444)
                              : const Color(0x33EF4444),
                          glowColor: const Color(0x14EF4444),
                          gradientColors: isDark
                              ? [
                                  const Color(0x28EF4444),
                                  const Color(0x10EF4444),
                                ]
                              : [
                                  const Color(0x18EF4444),
                                  const Color(0x0AEF4444),
                                ],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'صدقة جارية لأهلنا في غزة — نسألكم الدعاء',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A2A2A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '🇵🇸',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeBasmala.value,
                            child: Transform.translate(
                              offset: Offset(0.0, slideBasmala.value),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            ShimmerText(
                              text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اختر الأذكار',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Quick Mode Toggle ────────────
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeToggle.value,
                            child: Transform.translate(
                              offset: Offset(0.0, slideToggle.value),
                              child: child,
                            ),
                          );
                        },
                        child: Consumer<AdhkarProvider>(
                          builder: (context, provider, _) {
                            final isDark = theme.brightness == Brightness.dark;
                            return GestureDetector(
                              onTap: () =>
                                  provider.setQuickMode(!provider.quickMode),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: provider.quickMode
                                        ? theme.colorScheme.primary.withValues(
                                            alpha: isDark ? 0.15 : 0.08,
                                          )
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.04,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.7,
                                                )),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: provider.quickMode
                                          ? theme.colorScheme.primary
                                                .withValues(
                                                  alpha: isDark ? 0.4 : 0.25,
                                                )
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.06,
                                                  )
                                                : theme.colorScheme.primary
                                                      .withValues(alpha: 0.06)),
                                      width: 1.5,
                                    ),
                                    boxShadow: provider.quickMode
                                        ? [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: isDark
                                                  ? Colors.black.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : theme.colorScheme.primary
                                                        .withValues(
                                                          alpha: 0.03,
                                                        ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Bolt icon with animated container
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: provider.quickMode
                                              ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.2)
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.bolt_rounded,
                                          size: 20,
                                          color: provider.quickMode
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'النسخة السريعة (دقيقتان)',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: provider.quickMode
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        height: 20,
                                        width: 36,
                                        child: Transform.scale(
                                          scale: 0.85,
                                          child: Switch.adaptive(
                                            value: provider.quickMode,
                                            onChanged: (v) =>
                                                provider.setQuickMode(v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Category Cards ───────────────
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeCard1.value,
                            child: Transform.scale(
                              scale: scaleCard1.value,
                              child: child,
                            ),
                          );
                        },
                        child: _CategoryCard(
                          title: 'أذكار الصباح',
                          subtitle: 'ابدأ يومك بذكر الله',
                          icon: Icons.wb_sunny_rounded,
                          gradientColors: const [
                            Color(0xFFFCD34D),
                            Color(0xFFF97316),
                          ],
                          glowColor: const Color(0xFFF97316),
                          onTap: () => _navigateToAdhkar(context, 'morning'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeCard2.value,
                            child: Transform.scale(
                              scale: scaleCard2.value,
                              child: child,
                            ),
                          );
                        },
                        child: _CategoryCard(
                          title: 'أذكار المساء',
                          subtitle: 'أمسِ على ذكر الله',
                          icon: Icons.nightlight_round,
                          gradientColors: const [
                            Color(0xFF818CF8),
                            Color(0xFF6D28D9),
                          ],
                          glowColor: const Color(0xFF6D28D9),
                          onTap: () => _navigateToAdhkar(context, 'evening'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: fadeCard3.value,
                            child: Transform.scale(
                              scale: scaleCard3.value,
                              child: child,
                            ),
                          );
                        },
                        child: _CategoryCard(
                          title: 'أذكار بعد الصلاة',
                          subtitle: 'الأذكار بعد السلام من الصلاة المفروضة',
                          icon: Icons.mosque_rounded,
                          gradientColors: const [
                            Color(0xFF38BDF8),
                            Color(0xFF1D4ED8),
                          ],
                          glowColor: const Color(0xFF1D4ED8),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrayerSelectionScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Daily Commitment / Streak Summary Card ──
                      const _StreakSummaryCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToAdhkar(BuildContext context, String category) {
    final provider = Provider.of<AdhkarProvider>(context, listen: false);
    provider.loadAdhkar(category);
    final String title = category == 'morning'
        ? 'أذكار الصباح'
        : (category == 'evening' ? 'أذكار المساء' : 'أذكار بعد الصلاة');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdhkarScreen(title: title)),
    );
  }

  Future<void> _handleInstall(
    BuildContext context,
    PwaInstallService pwa,
  ) async {
    if (pwa.isIos) {
      _showManualInstallDialog(context, isIos: true);
    } else {
      final success = await pwa.promptInstall();
      if (!success && context.mounted) {
        _showManualInstallDialog(context, isIos: false);
      }
    }
  }

  void _showManualInstallDialog(BuildContext context, {required bool isIos}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تثبيت التطبيق'),
        content: Text(
          isIos
              ? 'للتثبيت على جهازك (iPhone/iPad):\n\n'
                    '١. اضغط على أيقونة المشاركة (↥) في المتصفح\n'
                    '٢. اختر "إضافة إلى الشاشة الرئيسية"\n'
                    '٣. اضغط "إضافة"'
              : 'لم نتمكن من إظهار نافذة التثبيت التلقائية.\n\n'
                    'للتثبيت يدوياً:\n'
                    'ابحث عن أيقونة التثبيت 🖥️ أو (Install App) في شريط عنوان المتصفح (URL) أو في قائمة الخيارات (⋮).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Header Hero Widget with radial glow and star pulse
// ═══════════════════════════════════════════════════════
class _HeaderHero extends StatefulWidget {
  const _HeaderHero();

  @override
  State<_HeaderHero> createState() => _HeaderHeroState();
}

class _HeaderHeroState extends State<_HeaderHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.85,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer radial glow ──
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 100 * _glowAnimation.value,
                height: 100 * _glowAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.15,
                      ),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          ),
          // ── Decorative outer ring ──
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    theme.colorScheme.primary.withValues(
                      alpha: isDark ? 0.08 : 0.03,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.mosque_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Shimmer Text Widget
// ═══════════════════════════════════════════════════════
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ShimmerText({super.key, required this.text, required this.style});

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.style.color ?? Colors.black,
                Theme.of(context).colorScheme.secondary,
                widget.style.color ?? Colors.black,
              ],
              stops: const [0.3, 0.5, 0.7],
              begin: Alignment(-1.5 + (_controller.value * 3.0), -0.2),
              end: Alignment(-0.5 + (_controller.value * 3.0), 0.2),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Install Ribbon Widget with slide down animation
// ═══════════════════════════════════════════════════════
class _InstallRibbon extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InstallRibbon({required this.onTap, required this.onDismiss});

  @override
  State<_InstallRibbon> createState() => _InstallRibbonState();
}

class _InstallRibbonState extends State<_InstallRibbon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(0.0, _slideAnimation.value),
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.12 : 0.06,
                ),
                theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.04 : 0.02,
                ),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.download_for_offline,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أضف التطبيق للشاشة الرئيسية',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'للوصول السريع وبدون إنترنت',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: widget.onDismiss,
                    color: theme.colorScheme.onSurfaceVariant,
                    tooltip: 'إخفاء',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Category Card Widget with pulsing particle overlay
// ═══════════════════════════════════════════════════════
class _CategoryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // ── Colored glow shadow ──
              BoxShadow(
                color: widget.glowColor.withValues(alpha: isDark ? 0.25 : 0.3),
                blurRadius: 28,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
              // ── Dark mode ambient shadow ──
              if (isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Star Particles Overlay
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: CardParticlesPainter(
                          animationValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Row(
                    children: [
                      // Glowing framed icon with double ring
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
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

// ═══════════════════════════════════════════════════════
//  Card Particles Painter
// ═══════════════════════════════════════════════════════
class CardParticlesPainter extends CustomPainter {
  final double animationValue;
  CardParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw 3 soft stars/particles that float or pulse
    final center1 = Offset(size.width * 0.15, size.height * 0.3);
    _drawStar(canvas, paint, center1, 7.0 + 3.0 * animationValue);

    final center2 = Offset(size.width * 0.85, size.height * 0.25);
    _drawStar(canvas, paint, center2, 5.0 + 2.0 * (1.0 - animationValue));

    final center3 = Offset(size.width * 0.75, size.height * 0.75);
    _drawStar(canvas, paint, center3, 4.0 + 1.5 * animationValue);
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CardParticlesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ═══════════════════════════════════════════════════════
//  Islamic Pattern Painter
// ═══════════════════════════════════════════════════════
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final double step = 52.0;
    for (double i = -step; i < size.width + step; i += step) {
      for (double j = -step; j < size.height + step; j += step) {
        canvas.drawRect(Rect.fromLTWH(i, j, step, step), paint);

        canvas.save();
        canvas.translate(i + step / 2, j + step / 2);
        canvas.rotate(0.785398); // 45 degrees in radians
        canvas.drawRect(
          Rect.fromLTRB(-step / 2, -step / 2, step / 2, step / 2),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════
//  Daily Commitment & Streak Summary Card
// ═══════════════════════════════════════════════════════
class _StreakSummaryCard extends StatelessWidget {
  const _StreakSummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Consumer<StreakProvider>(
      builder: (context, streakProvider, _) {
        final streak = streakProvider.currentStreak;
        final today = streakProvider.todayData;

        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          borderColor: primaryColor.withValues(alpha: isDark ? 0.22 : 0.15),
          glowColor: primaryColor.withValues(alpha: 0.08),
          gradientColors: isDark
              ? [
                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                  const Color(0xFF0F172A).withValues(alpha: 0.7),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF0FDF4),
                ],
          child: Column(
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
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'سجل الالتزام اليومي',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            streak > 0
                                ? 'سلسلة متتالية: $streak ${streak == 1 ? "يوم" : "أيام"}'
                                : 'ابدأ سلسلتك المباركة اليوم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StreakDashboardScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'التفاصيل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Today status pills
              Row(
                children: [
                  Expanded(
                    child: _MiniStatusPill(
                      label: 'الصباح',
                      isDone: today.morning,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatusPill(
                      label: 'المساء',
                      isDone: today.evening,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatusPill(
                      label: 'الصلوات (${today.prayers.length}/5)',
                      isDone: today.prayers.isNotEmpty,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isDark;

  const _MiniStatusPill({
    required this.label,
    required this.isDone,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF10B981).withValues(alpha: 0.14)
            : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: isDone
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                color: isDone
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
