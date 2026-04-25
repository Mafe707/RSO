import 'package:flutter/material.dart';

class AppConfig {
  static const Color azulOscuro = Color(0xFF002244);
  static const Color azulClaro = Color(0xFF3399CC);
  static const Color rojo = Color(0xFFCC3333);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF5F5F5);
  static const Color grisMedio = Color(0xFFDDDDDD);
  static const Color grisOscuro = Color(0xFF666666);
  static const Color verde = Color(0xFF28A745);
  static const Color naranja = Color(0xFFFD7E14);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: azulOscuro),
    scaffoldBackgroundColor: grisClaro,
    appBarTheme: const AppBarTheme(
      backgroundColor: azulOscuro,
      foregroundColor: blanco,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: blanco,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: azulOscuro,
        foregroundColor: blanco,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}