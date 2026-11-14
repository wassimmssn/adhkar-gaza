import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/streak_provider.dart';
import '../services/auth_service.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: size * 0.75,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

Future<void> showGoogleSignInDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primaryColor = theme.colorScheme.primary;
  final lang = Provider.of<SettingsProvider>(context, listen: false).language;
  final authService = Provider.of<AuthService>(context, listen: false);
  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  final streakProvider = Provider.of<StreakProvider>(context, listen: false);

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Google Icon Header
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('dialog_google_title', lang),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.get('dialog_google_subtitle', lang),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6B6B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('dialog_google_name_hint', lang),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Email field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('dialog_google_email_hint', lang),
                    hintText: 'user@gmail.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const GoogleLogoWidget(size: 20),
                    label: Text(
                      AppStrings.get('dialog_google_confirm', lang),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final name = nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : (email.isNotEmpty ? email.split('@').first : 'Utilisateur');

                      if (email.isEmpty || !email.contains('@')) {
                        return;
                      }

                      Navigator.of(dialogCtx).pop();

                      final success = await authService.signInWithGoogle(
                        email: email,
                        displayName: name,
                      );

                      if (success) {
                        // Attempt cloud restore first
                        final cloudData = await authService.fetchFromCloud();
                        if (cloudData != null) {
                          if (cloudData['settings'] != null) {
                            settingsProvider.loadFromJson(Map<String, dynamic>.from(cloudData['settings']));
                          }
                          if (cloudData['streakData'] != null) {
                            await streakProvider.loadFromJson(Map<String, dynamic>.from(cloudData['streakData']));
                          }
                        } else {
                          // Or sync local data up to cloud
                          await authService.syncToCloud(
                            settingsData: settingsProvider.toJson(),
                            streakData: streakProvider.toJson(),
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.get('sync_success_toast', lang)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    AppStrings.get('dialog_google_cancel', lang),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

Future<void> showUserProfileSheet(BuildContext context) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primaryColor = theme.colorScheme.primary;
  final lang = Provider.of<SettingsProvider>(context, listen: false).language;
  final authService = Provider.of<AuthService>(context, listen: false);
  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  final streakProvider = Provider.of<StreakProvider>(context, listen: false);
  final user = authService.currentUser;

  if (user == null) {
    await showGoogleSignInDialog(context);
    return;
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0x24115E54),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar with Google ring
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const GoogleLogoWidget(size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              user.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),

            // Cloud Sync Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authService.lastSyncTime != null
                          ? AppStrings.get('sync_status_synced', lang, {'time': AppStrings.get('sync_just_now', lang)})
                          : AppStrings.get('sync_status_synced', lang, {'time': 'OK'}),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    await authService.syncToCloud(
                      settingsData: settingsProvider.toJson(),
                      streakData: streakProvider.toJson(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.get('sync_success_toast', lang)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    AppStrings.get('btn_sync_now', lang),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sign out button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  AppStrings.get('btn_signout', lang),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  Navigator.of(sheetCtx).pop();
                  await authService.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.get('signout_confirm_toast', lang)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
