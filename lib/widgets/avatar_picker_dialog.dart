import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/streak_provider.dart';
import '../services/auth_service.dart';
import 'user_avatar.dart';

Future<void> showAvatarPickerDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final lang = Provider.of<SettingsProvider>(context, listen: false).language;
  final isAr = lang == 'ar';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) => _AvatarPickerSheet(
      isDark: isDark,
      isAr: isAr,
      lang: lang,
    ),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  final bool isDark;
  final bool isAr;
  final String lang;

  const _AvatarPickerSheet({
    required this.isDark,
    required this.isAr,
    required this.lang,
  });

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _applyAvatar(String avatarId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final streakProvider = Provider.of<StreakProvider>(context, listen: false);

    await authService.updateAvatar(avatarId);

    // Sync to cloud if user is logged in
    if (authService.isLoggedIn) {
      await authService.syncToCloud(
        settingsData: settingsProvider.toJson(),
        streakData: streakProvider.toJson(),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('avatar_updated_toast', widget.lang)),
          backgroundColor: const Color(0xFF0F9D58),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final currentAvatar = authService.effectivePhotoUrl;
    final displayName = user?.displayName ?? (widget.isAr ? 'زائر' : 'Invité');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withValues(alpha: widget.isDark ? 0.35 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Header with Avatar preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                UserAvatar(
                  size: 54,
                  photoUrl: currentAvatar,
                  displayName: displayName,
                  isLoggedIn: authService.isLoggedIn,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('avatar_picker_title', widget.lang),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.get('avatar_picker_subtitle', widget.lang),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                          fontSize: 11.5,
                          color: widget.isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: widget.isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: AppStrings.get('avatar_tab_gallery', widget.lang)),
              Tab(text: AppStrings.get('avatar_tab_initials', widget.lang)),
              Tab(text: AppStrings.get('avatar_tab_url', widget.lang)),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Spiritual Presets Gallery
                _buildGalleryTab(),

                // 2. Initial Gradients Tab
                _buildInitialsTab(displayName),

                // 3. Custom URL & Google Photo Tab
                _buildCustomUrlTab(authService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: kSpiritualPresets.length,
      itemBuilder: (context, index) {
        final preset = kSpiritualPresets[index];
        final label = widget.isAr ? preset.labelAr : preset.labelFr;

        return InkWell(
          onTap: () => _applyAvatar(preset.id),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                size: 52,
                photoUrl: preset.id,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialsTab(String displayName) {
    final themes = [
      {'id': 'initial:0', 'name': widget.isAr ? 'زمردي ذهبي' : 'Émeraude'},
      {'id': 'initial:1', 'name': widget.isAr ? 'أزرق ليلي' : 'Bleu Nuit'},
      {'id': 'initial:2', 'name': widget.isAr ? 'عنبر ملكي' : 'Ambre Doré'},
      {'id': 'initial:3', 'name': widget.isAr ? 'أرجواني' : 'Pourpre'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 1.4,
              ),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final item = themes[index];
                return InkWell(
                  onTap: () => _applyAvatar(item['id']!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        UserAvatar(
                          size: 46,
                          photoUrl: item['id'],
                          displayName: displayName,
                          isLoggedIn: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['name']!,
                            style: TextStyle(
                              fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomUrlTab(AuthService authService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: AppStrings.get('avatar_url_hint', widget.lang),
              prefixIcon: const Icon(Icons.link_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                AppStrings.get('avatar_url_apply', widget.lang),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.startsWith('http')) {
                  _applyAvatar(url);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          if (authService.isLoggedIn) ...[
            const Divider(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.account_circle_rounded, size: 20),
              label: Text(
                AppStrings.get('avatar_google_photo', widget.lang),
                style: TextStyle(
                  fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                _applyAvatar('initial:0');
              },
            ),
          ],
        ],
      ),
    );
  }
}
