import 'package:flutter/material.dart';

/// 社区论坛 · 设计系统（Apple / iOS 风格）
///
/// 遵循 Apple Human Interface Guidelines：
/// - 系统蓝 #007AFF 作为交互主色，品牌蓝 #2F6EE0 作为品牌基调
/// - 分组列表背景 #F2F2F7，卡片纯白，分隔线左缩进
/// - 圆角：卡片 14pt、单元格 10pt、控件 8pt
/// - 字体：SF Pro / PingFang SC，iOS 标准字号阶梯
/// - 动效：iOS 标准缓动曲线与时长
class AppColors {
  AppColors._();

  // ---------- 品牌色 ----------
  static const Color brand = Color(0xFF2F6EE0);
  static const Color brand2 = Color(0xFF5B8DEF);
  static const Color brandLight = Color(0xFFEAF1FE);

  /// iOS 系统蓝（交互主色：按钮、链接、选中态）
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosBlueDark = Color(0xFF0A84FF);
  /// iOS 系统灰蓝（次要交互图标）
  static const Color iosGrayBlue = Color(0xFF8E8E93);

  // ---------- iOS 背景层级 ----------
  /// iOS 分组列表背景（systemGroupedBackground）
  static const Color iosGroupedBg = Color(0xFFF2F2F7);
  /// iOS 次级分组背景
  static const Color iosGroupedBg2 = Color(0xFFEFEFF4);
  /// 卡片 / 单元格背景
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFFAFBFC);
  /// iOS 三级背景
  static const Color surface3 = Color(0xFFF7F7F9);

  /// 填充色（用于搜索框、分段控件底色）
  static const Color fill = Color(0xFFE5E5EA);
  static const Color fill2 = Color(0xFFEBEBF0);

  // ---------- 分隔线 ----------
  static const Color border = Color(0xFFE4E7EC);
  /// iOS 分隔线（更浅，且左缩进）
  static const Color separator = Color(0xFFC6C6C8);
  static const Color border2 = Color(0xFFEEF0F3);

  // ---------- 文本（iOS 系统标签色） ----------
  static const Color text = Color(0xFF000000);
  static const Color text2 = Color(0xFF3C3C43);
  static const Color text3 = Color(0xFF8E8E93);

  // ---------- iOS 系统语义色 ----------
  static const Color danger = Color(0xFFFF3B30); // systemRed
  static const Color dangerLight = Color(0xFFFFE5E5);
  static const Color success = Color(0xFF34C759); // systemGreen
  static const Color successLight = Color(0xFFE4F8EA);
  static const Color warn = Color(0xFFFF9500); // systemOrange
  static const Color warnLight = Color(0xFFFFF3E0);
  static const Color purple = Color(0xFFAF52DE); // systemPurple
  static const Color purpleLight = Color(0xFFF3E8FF);
  static const Color gold = Color(0xFFFFCC00); // systemYellow
  static const Color pink = Color(0xFFFF2D55); // systemPink
  static const Color teal = Color(0xFF5AC8FA); // systemTeal
  static const Color indigo = Color(0xFF5856D6); // systemIndigo

  /// 头像色板：低饱和柔和色（iOS 观感，避免列表花哨）
  static const List<Color> avatarPalette = [
    Color(0xFF8FA8C8), // 雾蓝
    Color(0xFFC4A08C), // 燕麦
    Color(0xFF8FBFA8), // 豆绿
    Color(0xFFA89CC4), // 藕紫
    Color(0xFFC4B48C), // 沙卡其
    Color(0xFFC4949C), // 藕粉
    Color(0xFF8FB8C0), // 雾青
    Color(0xFFB49CB0), // 灰梅
  ];

  /// 按用户 id 稳定取头像底色
  static Color avatarOf(int id) =>
      avatarPalette[id.abs() % avatarPalette.length];

  // ---------- 徽章配色（克制：浅底 + 语义色文字） ----------
  /// 中性徽章底（默认）
  static const Color badgeBg = Color(0xFFF0F0F4);
  /// 中性徽章文字
  static const Color badgeFg = Color(0xFF6E6E78);
  /// 等级徽章：统一中性（去渐变，避免列表花哨）
  static const Color levelBg = Color(0xFFEDEDF2);
  static const Color levelFg = Color(0xFF6E6E78);
}

/// iOS 圆角规范（Apple 连续圆角）
class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 8; // 输入框、按钮
  static const double md = 10; // iOS 单元格/列表项
  static const double lg = 14; // iOS 卡片（inset grouped）
  static const double xl = 20; // 弹窗
  static const double full = 999; // 胶囊

  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius cell = BorderRadius.circular(md);
  static final BorderRadius capsule = BorderRadius.circular(full);
}

/// iOS 动效规范（时长 + 曲线）
class AppMotion {
  AppMotion._();

  /// 页面转场
  static const Duration pageTransition = Duration(milliseconds: 400);
  /// 常规交互反馈
  static const Duration fast = Duration(milliseconds: 200);
  /// 列表项入场
  static const Duration itemIn = Duration(milliseconds: 320);
  /// 内容淡入
  static const Duration fade = Duration(milliseconds: 250);
  /// 骨架屏微光
  static const Duration shimmer = Duration(milliseconds: 1400);

  static const Curve ease = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// iOS 间距规范
class AppSpace {
  AppSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  /// iOS 分组列表标准左右边距
  static const double edge = 16;
  /// iOS 分隔线左缩进
  static const double separatorIndent = 16;
}

/// iOS 文本样式阶梯（SF Pro / PingFang SC）
class AppText {
  AppText._();

  static const String fontFamily = '.SF UI Text';

  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  /// 分组标题（iOS grouped section header）
  static const TextStyle groupHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.text3,
    letterSpacing: -0.1,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: false, // 保持 iOS 观感，避免 Material 3 配色重映射
      brightness: Brightness.light,
      primaryColor: AppColors.iosBlue,
      scaffoldBackgroundColor: AppColors.iosGroupedBg,
      highlightColor: Colors.transparent,
      fontFamily: AppText.fontFamily,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFamily: AppText.fontFamily,
        ),
        iconTheme: IconThemeData(color: AppColors.iosBlue, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.iosBlue, size: 22),
      ),
      cardTheme: const CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.iosBlue, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.iosBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.iosBlue,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.iosBlue,
          side: const BorderSide(color: AppColors.iosBlue, width: 1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1C1C1E),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.surface,
        iconColor: AppColors.iosGrayBlue,
        textColor: AppColors.text,
        titleTextStyle: TextStyle(fontSize: 17, letterSpacing: -0.2),
        subtitleTextStyle: TextStyle(fontSize: 13, color: AppColors.text3),
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.iosBlue,
        linearTrackColor: AppColors.fill,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.iosBlue,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
    );
  }
}
