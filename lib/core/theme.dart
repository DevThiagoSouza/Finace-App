import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta Tailwind usada no app web.
class SC {
  static const brand400 = Color(0xFF34D399);
  static const brand500 = Color(0xFF10B981);
  static const brand600 = Color(0xFF059669);
  static const brand700 = Color(0xFF047857);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const yellow500 = Color(0xFFEAB308);
  static const blue500 = Color(0xFF3B82F6);
  static const blue300 = Color(0xFF93C5FD);
  static const blue800 = Color(0xFF1E40AF);
  static const purple500 = Color(0xFFA855F7);
  static const indigo300 = Color(0xFFA5B4FC);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);
  static const pink500 = Color(0xFFEC4899);
  static const cyan500 = Color(0xFF06B6D4);
}

extension ColorOpacity on Color {
  Color o(double opacity) => withOpacity(opacity);
}

/// Cores dos membros (bgClass do app web).
const List<Color> kMemberColors = [
  SC.indigo500,
  SC.pink500,
  SC.brand500,
  SC.amber500,
  SC.cyan500,
];

/// Paleta que muda conforme tema claro/escuro.
class Pal {
  Pal(this.dark);
  final bool dark;

  static Pal of(BuildContext c) => Pal(Theme.of(c).brightness == Brightness.dark);

  Color get bg => dark ? SC.slate950 : SC.slate50;
  Color get header => dark ? SC.slate900 : SC.slate100;
  Color get surface => dark ? SC.slate900 : SC.slate100;
  Color get inner => dark ? SC.slate950 : SC.slate200.o(.5);
  Color get card2 => dark ? SC.slate900 : SC.slate200.o(.6);
  Color get border => dark ? SC.slate800 : SC.slate200;
  Color get border2 => dark ? SC.slate800 : SC.slate300;
  Color get text => dark ? SC.slate100 : SC.slate800;
  Color get strong => dark ? Colors.white : SC.slate900;
  Color get muted => dark ? SC.slate400 : SC.slate500;
  Color get soft => dark ? SC.slate300 : SC.slate600;
  Color get chip => dark ? SC.slate800 : SC.slate200;
  Color get chipBorder => dark ? SC.slate700 : SC.slate300;
  Color get brandText => dark ? SC.brand400 : SC.brand600;
  Color get redText => dark ? SC.red400 : SC.red500;
  Color get amberText => dark ? SC.amber400 : SC.amber600;
  Color get indigoText => dark ? SC.indigo400 : SC.indigo600;
  Color get bannerBg => dark ? SC.slate900.o(.9) : SC.slate200.o(.8);
  Color get overlay => SC.slate950.o(.7);
}

ThemeData buildTheme(bool dark) {
  final p = Pal(dark);
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: SC.brand500,
      secondary: SC.brand500,
      surface: p.surface,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: p.text,
      displayColor: p.text,
    ),
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: SC.brand500),
  );
}

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color? c, double? ls, double? h}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

const gradBrand = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [SC.brand600, SC.brand500],
);
