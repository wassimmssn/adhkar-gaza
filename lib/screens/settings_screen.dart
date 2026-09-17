import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../widgets/glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'الإعدادات',
        scrollOffset: 50,
        showBackButton: false,
      ),
      bottomNavigationBar: const FloatingGlassDock(activeIndex: 3),
      body: ListView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          bottom: 100,
        ),
        children: [
          // ═════════════════════════════════════════════
          //  APPEARANCE SECTION
          // ═════════════════════════════════════════════
          _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'المظهر',
            theme: theme,
          ),
          const SizedBox(height: 12),

          // ── Sliding Segmented Theme Selector ──
          _GlassCard(
            theme: theme,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'وضع المظهر',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _SlidingThemeSelector(
                  currentMode: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode),
                  theme: theme,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ═════════════════════════════════════════════
          //  INTERACTION SECTION
          // ═════════════════════════════════════════════
          _SectionHeader(
            icon: Icons.touch_app_outlined,
            title: 'التفاعل',
            theme: theme,
          ),
          const SizedBox(height: 12),

          _GlassCard(
            theme: theme,
            isDark: isDark,
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.touch_app_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تأكيد بلمس الشاشة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اضغط في أي مكان على الشاشة لتأكيد الذكر',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Switch
                Switch.adaptive(
                  value: settingsProvider.tapToConfirm,
                  onChanged: (value) => settingsProvider.setTapToConfirm(value),
                ),
              ],
            ),
          ),

          // ═════════════════════════════════════════════
          //  NOTIFICATIONS SECTION
          // ═════════════════════════════════════════════
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.notifications_active_outlined,
            title: 'التبليغات والذكر',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _GlassCard(
            theme: theme,
            isDark: isDark,
            child: Consumer<NotificationService>(
              builder: (context, notifService, _) {
                final hasPermission = notifService.hasPermission;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Permission status / request ---
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            hasPermission ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفعيل التنبيهات اليومية',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasPermission ? 'التنبيهات مفعلة وستصلك في أوقاتها' : 'احصل على تذكير لقراءة الأذكار اليومية',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (!hasPermission)
                          ElevatedButton(
                            onPressed: () async {
                              final granted = await notifService.requestPermission();
                              if (granted) {
                                await notifService.syncWithWorker();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text(
                              'تفعيل',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                        else ...[
                          TextButton.icon(
                            onPressed: () async {
                              final success = await notifService.sendTestNotification();
                              if (context.mounted) {
                                final errorDetail = notifService.lastTestError;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'تم إرسال التنبيه التجريبي بنجاح ✅'
                                          : 'فشل إرسال التنبيه${errorDetail != null ? ': $errorDetail' : '. تأكد من تفعيل أحد التذكيرات أولاً.'}',
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.play_arrow_rounded, size: 16, color: theme.colorScheme.primary),
                            label: Text(
                              'تجربة التنبيه',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
                        ],
                      ],
                    ),

                    if (hasPermission) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),

                      // --- Morning reminder switch ---
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تنبيه أذكار الصباح',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تذكير لقراءة أذكار الصباح بعد الفجر',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: notifService.morningEnabled,
                            onChanged: (val) => notifService.setMorningEnabled(val),
                          ),
                        ],
                      ),

                      if (notifService.morningEnabled) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'وقت التذكير (بعد الفجر):',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            DropdownButton<int>(
                              value: notifService.morningOffset,
                              dropdownColor: theme.colorScheme.surface,
                              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('في وقت الفجر')),
                                DropdownMenuItem(value: 15, child: Text('بعد الفجر بـ 15 دقيقة')),
                                DropdownMenuItem(value: 30, child: Text('بعد الفجر بـ 30 دقيقة')),
                              ],
                              onChanged: (val) {
                                if (val != null) notifService.setMorningOffset(val);
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),

                      // --- Evening reminder switch ---
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تنبيه أذكار المساء',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تذكير لقراءة أذكار المساء بعد العصر أو قرب المغرب',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: notifService.eveningEnabled,
                            onChanged: (val) => notifService.setEveningEnabled(val),
                          ),
                        ],
                      ),

                      if (notifService.eveningEnabled) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'وقت التذكير:',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            DropdownButton<String>(
                              value: notifService.eveningType,
                              dropdownColor: theme.colorScheme.surface,
                              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'asr_0', child: Text('في وقت العصر')),
                                DropdownMenuItem(value: 'asr_15', child: Text('بعد العصر بـ 15 دقيقة')),
                                DropdownMenuItem(value: 'asr_30', child: Text('بعد العصر بـ 30 دقيقة')),
                                DropdownMenuItem(value: 'maghrib_before_30', child: Text('قبل المغرب بـ 30 دقيقة')),
                                DropdownMenuItem(value: 'maghrib_after_15', child: Text('بعد المغرب بـ 15 دقيقة')),
                              ],
                              onChanged: (val) {
                                if (val != null) notifService.setEveningType(val);
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),

                      // --- Location display & refresh ---
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'موقع الحساب والصلوات',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'المدينة الحالية: ${notifService.city}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (notifService.isLoadingLocation)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: Icon(Icons.my_location_rounded, color: theme.colorScheme.primary),
                              tooltip: 'تحديث الموقع تلقائياً',
                              onPressed: () => notifService.detectIpLocation(),
                            ),
                        ],
                      ),

                      // Sync status indicator
                      if (notifService.isSyncing) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(
                              'جاري مزامنة الإعدادات...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ] else if (notifService.isSubscribed && (notifService.morningEnabled || notifService.eveningEnabled)) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_done_rounded, color: theme.colorScheme.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'التنبيهات مفعلة ✅ ستصلك حتى لو كان المتصفح مغلقاً.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!notifService.isSubscribed && (notifService.morningEnabled || notifService.eveningEnabled) && notifService.lastSyncError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'خطأ في المزامنة: ${notifService.lastSyncError}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // ── Version footer ──
          Center(
            child: Text(
              'أذكار غزة — الإصدار 1.0',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeData theme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  GLASS CARD
// ═══════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final Widget child;

  const _GlassCard({
    required this.theme,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : theme.colorScheme.primary.withValues(alpha: 0.06),
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
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SLIDING SEGMENTED THEME SELECTOR
// ═══════════════════════════════════════════════════════
class _SlidingThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  final ThemeData theme;
  final bool isDark;

  const _SlidingThemeSelector({
    required this.currentMode,
    required this.onChanged,
    required this.theme,
    required this.isDark,
  });

  static const _modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _modes.indexOf(currentMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 3;
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : theme.colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                // ── Sliding pill indicator ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * segmentWidth + 4,
                  top: 4,
                  bottom: 4,
                  width: segmentWidth - 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.12),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                  ),
                ),
                // ── Tap targets ──
                Row(
                  children: [
                    _buildSegment(0, Icons.brightness_auto_outlined, 'النظام', segmentWidth),
                    _buildSegment(1, Icons.wb_sunny_outlined, 'فاتح', segmentWidth),
                    _buildSegment(2, Icons.nightlight_outlined, 'داكن', segmentWidth),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegment(int index, IconData icon, String label, double width) {
    final isSelected = _modes[index] == currentMode;

    return GestureDetector(
      onTap: () => onChanged(_modes[index]),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 52,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
