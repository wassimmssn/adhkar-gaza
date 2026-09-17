import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/pwa_install_service.dart';
import '../screens/settings_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  1. GLASS CONTAINER (Universal Frosted Glass Box)
// ══════════════════════════════════════════════════════════════════════════════

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 16.0,
    this.padding,
    this.margin,
    this.gradientColors,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = isDark
        ? [const Color(0x2B131B2E), const Color(0x1A090D16)]
        : [const Color(0xCCFFFFFF), const Color(0x99FAF8F5)];

    final defaultBorderColor = isDark
        ? const Color(0x332DD4BF)
        : const Color(0x22115E54);

    final defaultGlowColor = isDark
        ? const Color(0x1A2DD4BF)
        : const Color(0x0C115E54);

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor ?? defaultGlowColor,
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? defaultGradient,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? defaultBorderColor,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return _GlassTapWrapper(onTap: onTap!, child: content);
    }

    return content;
  }
}

class _GlassTapWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassTapWrapper({required this.child, required this.onTap});

  @override
  State<_GlassTapWrapper> createState() => _GlassTapWrapperState();
}

class _GlassTapWrapperState extends State<_GlassTapWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          try {
            HapticFeedback.lightImpact();
          } catch (_) {}
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  2. GLASS APP BAR (Dynamic Scroll Blur Header)
// ══════════════════════════════════════════════════════════════════════════════

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final double scrollOffset;
  final Widget? bottom;
  final double bottomHeight;

  const GlassAppBar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.scrollOffset = 0.0,
    this.bottom,
    this.bottomHeight = 0.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + bottomHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate dynamic opacity based on scroll (fully opaque blur at 40px scroll)
    final scrollRatio = (scrollOffset / 40.0).clamp(0.0, 1.0);

    final bgAlpha = (scrollRatio * (isDark ? 0.78 : 0.85)).clamp(0.0, 0.85);
    final borderAlpha = (scrollRatio * (isDark ? 0.25 : 0.18)).clamp(0.0, 0.25);
    final blurAmount = scrollRatio * 16.0;

    final bgColor = isDark
        ? Color.fromRGBO(9, 13, 22, bgAlpha)
        : Color.fromRGBO(250, 248, 245, bgAlpha);

    final borderColor = isDark
        ? Color.fromRGBO(45, 212, 191, borderAlpha)
        : Color.fromRGBO(17, 94, 84, borderAlpha);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: NavigationToolbar(
                    leading:
                        leading ??
                        (showBackButton && Navigator.canPop(context)
                            ? IconButton(
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: () => Navigator.pop(context),
                              )
                            : null),
                    middle:
                        titleWidget ??
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A2A2A),
                          ),
                        ),
                    trailing: actions != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          )
                        : null,
                  ),
                ),
                ?bottom,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  3. FLOATING GLASS DOCK (iOS Style Floating Glass Dock)
// ══════════════════════════════════════════════════════════════════════════════

class FloatingGlassDock extends StatelessWidget {
  final int activeIndex;
  final Function(int)? onItemTapped;

  const FloatingGlassDock({super.key, this.activeIndex = 0, this.onItemTapped});

  void _shareApp(BuildContext context) {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ShareGlassSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pwa = Provider.of<PwaInstallService>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final dockBg = isDark ? const Color(0xD9131B2E) : const Color(0xEEFFFFFF);

    final borderColor = isDark
        ? const Color(0x382DD4BF)
        : const Color(0x22115E54);

    final shadowColor = isDark
        ? const Color(0x40000000)
        : const Color(0x1F115E54);

    return Container(
      margin: EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding + 14),
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF115E54))
                .withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: dockBg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home Button
                _DockItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: activeIndex == 0,
                  isDark: isDark,
                  onTap: () {
                    if (onItemTapped != null) onItemTapped!(0);
                    if (ModalRoute.of(context)?.settings.name != '/') {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                ),

                // 2. Share Button
                _DockItem(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  isActive: activeIndex == 1,
                  isDark: isDark,
                  onTap: () => _shareApp(context),
                ),

                // 3. PWA Install (if applicable) or Quick Info
                if (pwa.shouldShowPrompt)
                  _DockItem(
                    icon: Icons.download_rounded,
                    label: 'تثبيت',
                    isActive: false,
                    isDark: isDark,
                    badgeColor: isDark
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFD97706),
                    onTap: () async {
                      try {
                        HapticFeedback.mediumImpact();
                      } catch (_) {}
                      await pwa.promptInstall();
                    },
                  ),

                // 4. Settings Button
                _DockItem(
                  icon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  isActive: activeIndex == 3,
                  isDark: isDark,
                  onTap: () {
                    try {
                      HapticFeedback.lightImpact();
                    } catch (_) {}
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF115E54);
    final inactiveColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.18 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
                if (badgeColor != null)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  4. SHARE GLASS BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _ShareGlassSheet extends StatelessWidget {
  const _ShareGlassSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF115E54);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0x24115E54),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.share_rounded, size: 32, color: primaryColor),
          ),
          const SizedBox(height: 14),
          Text(
            'مشاركة تطبيق أذكار غزة 🤲',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF115E54),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ساهم في نشر الأذكار والدعاء لأهلنا في غزة والعالم الإسلامي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            label: const Text(
              'نسخ رابط التطبيق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'https://adhkar-gaza.pages.dev'),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رابط التطبيق بنجاح 📋'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
