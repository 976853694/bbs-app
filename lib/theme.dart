import 'package:flutter/material.dart';

/// 社区论坛 · 设计系统
/// 品牌延续自 Web / ui-app 设计稿：品牌蓝 #2f6ee0，圆角卡片，等级徽章，头像色板。
class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF2F6EE0);
  static const Color brand2 = Color(0xFF5B8DEF);
  static const Color brandLight = Color(0xFFEAF1FE);

  static const Color bg = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFFAFBFC);
  static const Color border = Color(0xFFE4E7EC);
  static const Color border2 = Color(0xFFEEF0F3);

  static const Color text = Color(0xFF1F2328);
  static const Color text2 = Color(0xFF57606A);
  static const Color text3 = Color(0xFF8B949E);

  static const Color danger = Color(0xFFD92D20);
  static const Color dangerLight = Color(0xFFFDECEB);
  static const Color success = Color(0xFF1A7F37);
  static const Color successLight = Color(0xFFE8F5EC);
  static const Color warn = Color(0xFFE8912A);
  static const Color warnLight = Color(0xFFFDF3E6);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color purpleLight = Color(0xFFF1ECFF);
  static const Color gold = Color(0xFFD4A017);

  /// 头像色板（延续 Web 端 av-1 ~ av-8）
  static const List<Color> avatarPalette = [
    Color(0xFF2F6EE0),
    Color(0xFFE0562F),
    Color(0xFF1A9E7F),
    Color(0xFF7C4DFF),
    Color(0xFFD4A017),
    Color(0xFFD92D20),
    Color(0xFF4A7C8C),
    Color(0xFFC2418F),
  ];

  /// 按用户 id 稳定取头像底色
  static Color avatarOf(int id) => avatarPalette[id.abs() % avatarPalette.length];

  /// 等级徽章渐变（延续 .level.l3/l5/l7/l9/l11）
  static List<Color> levelGradient(int level) {
    if (level >= 11) return const [Color(0xFFFF7A59), Color(0xFFD92D20)];
    if (level >= 9) return const [Color(0xFFF0B849), Color(0xFFD4A017)];
    if (level >= 7) return const [Color(0xFFB07DFF), Color(0xFF7C4DFF)];
    if (level >= 5) return const [Color(0xFF5B8DEF), Color(0xFF2F6EE0)];
    if (level >= 3) return const [Color(0xFF58B368), Color(0xFF1A7F37)];
    return const [Color(0xFF8B949E), Color(0xFF6E7781)];
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'PingFang SC',
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'PingFang SC',
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border2,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.brand),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
