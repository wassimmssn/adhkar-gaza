import 'package:flutter/material.dart';

/// Predefined Spiritual Avatars
class SpiritualAvatarPreset {
  final String id;
  final String labelFr;
  final String labelAr;
  final IconData icon;
  final List<Color> gradientColors;

  const SpiritualAvatarPreset({
    required this.id,
    required this.labelFr,
    required this.labelAr,
    required this.icon,
    required this.gradientColors,
  });
}

const List<SpiritualAvatarPreset> kSpiritualPresets = [
  SpiritualAvatarPreset(
    id: 'preset:mosque',
    labelFr: 'Mosquée Al-Aqsa',
    labelAr: 'المسجد المبارك',
    icon: Icons.mosque_rounded,
    gradientColors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:crescent',
    labelFr: 'Croissant de Lune',
    labelAr: 'هلال رمضان',
    icon: Icons.nightlight_round,
    gradientColors: [Color(0xFF1E3A8A), Color(0xFF38BDF8)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:kaaba',
    labelFr: 'Kaaba Sacrée',
    labelAr: 'الكعبة المشرفة',
    icon: Icons.account_balance_rounded,
    gradientColors: [Color(0xFF18181B), Color(0xFFD97706)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:quran',
    labelFr: 'Saint Coran',
    labelAr: 'المصحف الشريف',
    icon: Icons.menu_book_rounded,
    gradientColors: [Color(0xFF047857), Color(0xFF34D399)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:lantern',
    labelFr: 'Lanterne Fanous',
    labelAr: 'فانوس الإيمان',
    icon: Icons.light_mode_rounded,
    gradientColors: [Color(0xFFB45309), Color(0xFFFBBF24)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:peace',
    labelFr: 'Rameau de Paix',
    labelAr: 'غصن الزيتون',
    icon: Icons.spa_rounded,
    gradientColors: [Color(0xFF15803D), Color(0xFF86EFAC)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:tasbih',
    labelFr: 'Tasbih & Dhikr',
    labelAr: 'تسبيح وذكر',
    icon: Icons.adjust_rounded,
    gradientColors: [Color(0xFF4338CA), Color(0xFF818CF8)],
  ),
  SpiritualAvatarPreset(
    id: 'preset:star',
    labelFr: 'Étoile Céleste',
    labelAr: 'نجمة ساطعة',
    icon: Icons.star_rate_rounded,
    gradientColors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
  ),
];

const List<List<Color>> kInitialGradients = [
  [Color(0xFF065F46), Color(0xFF10B981)], // Emerald
  [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Deep Blue
  [Color(0xFF7C2D12), Color(0xFFF59E0B)], // Amber Gold
  [Color(0xFF581C87), Color(0xFFA855F7)], // Royal Purple
];

/// Reusable User Avatar Component
class UserAvatar extends StatelessWidget {
  final double size;
  final String? photoUrl;
  final String displayName;
  final bool isLoggedIn;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.size = 40,
    this.photoUrl,
    this.displayName = '',
    this.isLoggedIn = false,
    this.showEditBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : (isLoggedIn ? 'U' : '');

    Widget avatarContent;

    if (photoUrl != null && photoUrl!.startsWith('preset:')) {
      final preset = kSpiritualPresets.firstWhere(
        (p) => p.id == photoUrl,
        orElse: () => kSpiritualPresets.first,
      );
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: preset.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: preset.gradientColors.first.withValues(alpha: 0.35),
              blurRadius: size * 0.25,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            preset.icon,
            size: size * 0.52,
            color: Colors.white,
          ),
        ),
      );
    } else if (photoUrl != null && photoUrl!.startsWith('initial:')) {
      final parts = photoUrl!.split(':');
      final gradIndex = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final colors = kInitialGradients[gradIndex % kInitialGradients.length];

      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: size * 0.25,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initial.isNotEmpty ? initial : 'G',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: size * 0.48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (photoUrl != null && photoUrl!.startsWith('http')) {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: size * 0.2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            photoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackInitial(size, initial),
          ),
        ),
      );
    } else {
      if (isLoggedIn && initial.isNotEmpty) {
        avatarContent = _buildFallbackInitial(size, initial);
      } else {
        avatarContent = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: size * 0.55,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
    }

    if (!showEditBadge && onTap == null) {
      return avatarContent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          avatarContent,
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(size * 0.08),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: size * 0.28,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(double size, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial.isNotEmpty ? initial : 'A',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: size * 0.48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
