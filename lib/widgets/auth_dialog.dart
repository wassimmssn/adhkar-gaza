import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/streak_provider.dart';
import '../services/auth_service.dart';

/// Official 4-Color Google 'G' Vector Painter
class GooglePainter extends CustomPainter {
  const GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Red (Top)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Blue (Right & Bar)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20.0)
      ..lineTo(24, 20.0)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Yellow (Bottom Left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.56, 13.22)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24.0)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Green (Bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.56, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Google 'G' Logo Widget
class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: GooglePainter(),
      ),
    );
  }
}

/// Entry point: Launches official Google Auth (Popup on Web, Chooser Modal in-app)
Future<void> showGoogleSignInDialog(BuildContext context) async {
  final authService = Provider.of<AuthService>(context, listen: false);
  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  final streakProvider = Provider.of<StreakProvider>(context, listen: false);
  final lang = settingsProvider.language;

  // Set up auto-sync callback when auth succeeds
  authService.onUserSignedIn = (user) async {
    final cloudData = await authService.fetchFromCloud();
    if (cloudData != null) {
      if (cloudData['settings'] != null) {
        settingsProvider.loadFromJson(Map<String, dynamic>.from(cloudData['settings']));
      }
      if (cloudData['streakData'] != null) {
        await streakProvider.loadFromJson(Map<String, dynamic>.from(cloudData['streakData']));
      }
    } else {
      await authService.syncToCloud(
        settingsData: settingsProvider.toJson(),
        streakData: streakProvider.toJson(),
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('sync_success_toast', lang)),
          backgroundColor: const Color(0xFF0F9D58),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  };

  if (kIsWeb) {
    final opened = authService.openGoogleSignInPopup(lang: lang);
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const GoogleLogoWidget(size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.get('google_popup_opened', lang),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
  }

  // Fallback to pixel-perfect Google Account Chooser in-app
  await _showGoogleAccountChooserInApp(context);
}

/// Pixel-perfect Google Account Chooser modal dialog (accounts.google.com look & feel)
Future<void> _showGoogleAccountChooserInApp(BuildContext context) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final lang = Provider.of<SettingsProvider>(context, listen: false).language;
  final isAr = lang == 'ar';

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => _GoogleAccountChooserDialog(
      isDark: isDark,
      isAr: isAr,
      lang: lang,
    ),
  );
}

class _GoogleAccountChooserDialog extends StatefulWidget {
  final bool isDark;
  final bool isAr;
  final String lang;

  const _GoogleAccountChooserDialog({
    required this.isDark,
    required this.isAr,
    required this.lang,
  });

  @override
  State<_GoogleAccountChooserDialog> createState() => _GoogleAccountChooserDialogState();
}

class _GoogleAccountChooserDialogState extends State<_GoogleAccountChooserDialog> {
  bool _showForm = false;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController(text: 'Wassim Bousmaa');
  final TextEditingController _emailController = TextEditingController();

  Future<void> _handleSelect(String name, String email) async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 500));

    final success = await authService.signInWithGoogle(
      email: email,
      displayName: name,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (success && authService.currentUser != null && authService.onUserSignedIn != null) {
      authService.onUserSignedIn!(authService.currentUser!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgCard = widget.isDark ? const Color(0xFF202124) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF3C4043) : const Color(0xFFDADCE0);
    final textColor = widget.isDark ? const Color(0xFFE8EAED) : const Color(0xFF202124);
    final subtextColor = widget.isDark ? const Color(0xFF9AA0A6) : const Color(0xFF5F6368);
    final hoverColor = widget.isDark ? const Color(0xFF303134) : const Color(0xFFF8FAFD);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Linear Google Progress Bar
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Color(0xFFE8F0FE),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                  )
                else
                  const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Google Logo
                      const Center(
                        child: GoogleLogoWidget(size: 38),
                      ),
                      const SizedBox(height: 16),

                      if (!_showForm) ...[
                        // Title: Choisir un compte
                        Text(
                          AppStrings.get('dialog_google_title', widget.lang),
                          style: TextStyle(
                            fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.get('dialog_google_subtitle', widget.lang),
                          style: TextStyle(
                            fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                            fontSize: 14,
                            color: subtextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Account List
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: borderColor, width: 0.8),
                              bottom: BorderSide(color: borderColor, width: 0.8),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Default 1-Click Google Account
                              InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () => _handleSelect('Wassim Bousmaa', 'wassimbousmaa@gmail.com'),
                                hoverColor: hoverColor,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFF0B57D0),
                                        child: const Text(
                                          'W',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Wassim Bousmaa',
                                              style: TextStyle(
                                                fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'wassimbousmaa@gmail.com',
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 12,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F4EA),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Google',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF137333),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(height: 1, thickness: 0.8, color: borderColor),

                              // Use another account
                              InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () => setState(() => _showForm = true),
                                hoverColor: hoverColor,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: widget.isDark
                                            ? const Color(0xFF303134)
                                            : const Color(0xFFF1F3F4),
                                        child: Icon(
                                          Icons.person_add_alt_1_rounded,
                                          size: 20,
                                          color: subtextColor,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          AppStrings.get('google_use_another_account', widget.lang),
                                          style: TextStyle(
                                            fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        widget.isAr
                                            ? Icons.chevron_left_rounded
                                            : Icons.chevron_right_rounded,
                                        color: subtextColor,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Google Privacy Disclaimer
                        Text(
                          AppStrings.get('google_privacy_notice', widget.lang),
                          style: TextStyle(
                            fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                            fontSize: 11.5,
                            color: subtextColor,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ] else ...[
                        // Form View: Utiliser un autre compte
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                widget.isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                                color: subtextColor,
                              ),
                              onPressed: () => setState(() => _showForm = false),
                              tooltip: 'Retour',
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.get('google_use_another_account', widget.lang),
                              style: TextStyle(
                                fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('dialog_google_name_hint', widget.lang),
                            labelStyle: TextStyle(color: subtextColor, fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0B57D0), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('google_enter_email', widget.lang),
                            hintText: 'exemple@gmail.com',
                            labelStyle: TextStyle(color: subtextColor, fontSize: 13),
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0B57D0), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _showForm = false),
                              child: Text(
                                AppStrings.get('dialog_google_cancel', widget.lang),
                                style: TextStyle(
                                  color: subtextColor,
                                  fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B57D0),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: () {
                                final email = _emailController.text.trim();
                                var name = _nameController.text.trim();
                                if (email.isEmpty || !email.contains('@')) return;
                                if (name.isEmpty) name = email.split('@').first;
                                _handleSelect(name, email);
                              },
                              child: Text(
                                AppStrings.get('google_next', widget.lang),
                                style: TextStyle(
                                  fontFamily: widget.isAr ? 'Cairo' : 'Roboto',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

/// Profile management sheet when user is connected
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
                  padding: const EdgeInsets.all(4),
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
                    const Icon(
                      Icons.cloud_done_rounded,
                      color: Color(0xFF10B981),
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
