import 'package:flutter/material.dart';

class Brand {
  static ThemeData theme({bool dark = false}) {
    final background = dark ? const Color(0xFF212121) : Colors.white;
    final foreground = dark ? const Color(0xFFECECEC) : const Color(0xFF171717);
    final outline = dark ? const Color(0xFF424242) : const Color(0xFFE5E5E5);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF777777),
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: foreground,
      onPrimary: background,
      surface: background,
      onSurface: foreground,
      onSurfaceVariant:
          dark ? const Color(0xFFB4B4B4) : const Color(0xFF676767),
      surfaceContainerLow:
          dark ? const Color(0xFF2F2F2F) : const Color(0xFFF4F4F4),
      surfaceContainerHighest:
          dark ? const Color(0xFF373737) : const Color(0xFFEEEEEE),
      outlineVariant: outline,
      secondaryContainer:
          dark ? const Color(0xFF333333) : const Color(0xFFEAEAEA),
      onSecondaryContainer: foreground,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        titleTextStyle: TextStyle(
            color: foreground, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor:
            dark ? const Color(0xFF171717) : const Color(0xFFF9F9F9),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: foreground,
        selectedColor: foreground,
        selectedTileColor: scheme.secondaryContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: foreground)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: foreground,
        foregroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const StadiumBorder(),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const StadiumBorder(),
      )),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.all(8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 0.5),
    );
  }
}
