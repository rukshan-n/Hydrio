import 'package:flutter/material.dart';

class HydrioTheme {
  // Light Palette
  static const Color lightPrimary = Color(0xff2A8FE0);
  static const Color lightPrimaryTint = Color(0xffD6ECFB);
  static const Color lightSuccess = Color(0xff34B27B);
  static const Color lightInk = Color(0xff1F2933);
  static const Color lightMuted = Color(0xff7B8794);
  static const Color lightSurface = Color(0xffFFFFFF);
  static const Color lightPanel = Color(0xffF2F5F8);
  static const Color lightDanger = Color(0xffC5221F);

  // Dark Palette
  static const Color darkPrimary = Color(0xff4FA8E8);
  static const Color darkPrimaryTint = Color(0xff173448);
  static const Color darkSuccess = Color(0xff3FBF86);
  static const Color darkInk = Color(0xffE8EDF2);
  static const Color darkMuted = Color(0xff9AA5B1);
  static const Color darkSurface = Color(0xff121821);
  static const Color darkPanel = Color(0xff1B2430);
  static const Color darkDanger = Color(0xffF08A86);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightSurface,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        primaryContainer: lightPrimaryTint,
        secondary: lightSuccess,
        surface: lightSurface,
        error: lightDanger,
        onPrimary: Colors.white,
        onSurface: lightInk,
        onSurfaceVariant: lightMuted,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: lightInk,
          fontSize: 18.0,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: lightInk,
          fontSize: 16.0,
        ),
        labelLarge: TextStyle(
          color: lightInk,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
        displayLarge: TextStyle(
          color: lightInk,
          fontSize: 34.0,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: lightInk,
          fontSize: 28.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        minWidth: 48.0,
        height: 52.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52.0),
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        primaryContainer: darkPrimaryTint,
        secondary: darkSuccess,
        surface: darkSurface,
        error: darkDanger,
        onPrimary: Colors.black,
        onSurface: darkInk,
        onSurfaceVariant: darkMuted,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: darkInk,
          fontSize: 18.0,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: darkInk,
          fontSize: 16.0,
        ),
        labelLarge: TextStyle(
          color: darkInk,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
        displayLarge: TextStyle(
          color: darkInk,
          fontSize: 34.0,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: darkInk,
          fontSize: 28.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        minWidth: 48.0,
        height: 52.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52.0),
          backgroundColor: darkPrimary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
