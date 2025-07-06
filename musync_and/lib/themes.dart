import 'package:flutter/material.dart';

ThemeData lighttheme() {
  return ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Color.fromARGB(255, 242, 242, 242),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 237, 237, 237),
      foregroundColor: Color.fromARGB(255, 243, 160, 34),
      surfaceTintColor: Color.fromARGB(255, 242, 242, 242),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 242, 242, 242),
        foregroundColor: Color.fromARGB(255, 243, 160, 34),
      ),
    ),
    cardTheme: CardTheme(
      color: Color.fromARGB(255, 237, 237, 237),
      surfaceTintColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Color.fromARGB(255, 243, 160, 34),
      inactiveTrackColor: Color.fromARGB(77, 243, 160, 34),
      trackHeight: 4,
      thumbColor: Color.fromARGB(255, 243, 160, 34),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
      overlayColor: Color.fromARGB(51, 243, 160, 34),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
      valueIndicatorColor: Color.fromARGB(255, 243, 160, 34),
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Color.fromARGB(255, 242, 242, 242),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      floatingLabelStyle: TextStyle(
        color: Color.fromARGB(255, 243, 160, 34),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      hintStyle: TextStyle(color: Colors.grey),

      filled: true,
      fillColor: Color.fromRGBO(228, 228, 228, 0.5),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 243, 160, 34),
          width: 2.0,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Color.fromARGB(255, 243, 160, 34).withAlpha(60),
      cursorColor: Color.fromARGB(255, 0, 0, 0),
      selectionHandleColor: Color.fromARGB(255, 243, 160, 34),
    ),
  );
}

ThemeData darkTheme(Color corPrimaria) {
  return ThemeData(
    primarySwatch: Colors.orange,
    scaffoldBackgroundColor: Color.fromARGB(255, 64, 64, 64),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 37, 37, 37),
      foregroundColor: corPrimaria,
      surfaceTintColor: Color.fromARGB(255, 37, 37, 37),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 64, 64, 64),
        foregroundColor: corPrimaria,
      ),
    ),
    cardTheme: CardTheme(color: Color.fromARGB(255, 64, 64, 64)),
    dialogTheme: DialogTheme(backgroundColor: Color.fromARGB(255, 64, 64, 64)),

    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Color.fromARGB(255, 242, 242, 242),
      displayColor: Color.fromARGB(255, 242, 242, 242),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(
        fontSize: 18,
        color: Color.fromARGB(255, 242, 242, 242),
        fontWeight: FontWeight.w900,
      ),
      floatingLabelStyle: TextStyle(
        color: corPrimaria,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      hintStyle: TextStyle(color: Colors.grey),

      filled: true,
      fillColor: Color.fromRGBO(60, 60, 60, 0.5),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: corPrimaria, width: 2.0),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: corPrimaria.withAlpha(60),
      cursorColor: Color.fromARGB(255, 0, 0, 0),
      selectionHandleColor: corPrimaria,
    ),
  );
}
