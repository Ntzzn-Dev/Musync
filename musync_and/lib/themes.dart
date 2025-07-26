import 'package:flutter/material.dart';

ThemeData lighttheme() {
  return ThemeData(
    primarySwatch: Colors.orange,
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
      color: Color.fromARGB(255, 255, 255, 255),
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
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Color.fromARGB(255, 0, 0, 0),
      displayColor: Color.fromARGB(255, 0, 0, 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      floatingLabelStyle: TextStyle(
        color: Color.fromARGB(255, 243, 160, 34),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      hintStyle: TextStyle(color: Colors.grey),
      outlineBorder: BorderSide(color: Colors.red),

      filled: true,
      fillColor: Color.fromRGBO(228, 228, 228, 0.5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 243, 160, 34),
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2.0),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.fromRGBO(228, 228, 228, 0.5),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 243, 160, 34),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      textStyle: TextStyle(color: Colors.black87, fontSize: 16),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(
          Color.fromARGB(255, 237, 237, 237),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color.fromARGB(255, 243, 160, 34), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Color.fromARGB(255, 243, 160, 34).withAlpha(60),
      cursorColor: Color.fromARGB(255, 0, 0, 0),
      selectionHandleColor: Color.fromARGB(255, 243, 160, 34),
    ),
    focusColor: Color.fromARGB(255, 243, 160, 34),
    highlightColor: Color.fromARGB(255, 243, 160, 34),
    extensions: <ThemeExtension<dynamic>>[
      CustomColors(
        textForce: Color.fromARGB(255, 0, 0, 0),
        subtextForce: Color.fromARGB(255, 104, 104, 104),
        disabledText: Color.fromARGB(255, 179, 151, 109),
        disabledBack: Color.fromARGB(255, 214, 214, 214),
        backgroundForce: Color.fromARGB(255, 242, 242, 242),
      ),
    ],
  );
}

ThemeData darktheme() {
  return ThemeData(
    primarySwatch: Colors.orange,
    scaffoldBackgroundColor: Color.fromARGB(255, 48, 48, 48),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 37, 37, 37),
      foregroundColor: Color.fromARGB(255, 243, 160, 34),
      surfaceTintColor: Color.fromARGB(255, 37, 37, 37),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 48, 48, 48),
        foregroundColor: Color.fromARGB(255, 243, 160, 34),
      ),
    ),
    cardTheme: CardTheme(
      color: Color.fromARGB(255, 36, 36, 36),
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
        color: Color.fromARGB(255, 48, 48, 48),
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Color.fromARGB(255, 48, 48, 48),
      titleTextStyle: TextStyle(color: Colors.white),
    ),

    textTheme: TextTheme(
      titleMedium: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey.shade300),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(
        fontSize: 18,
        color: Color.fromARGB(255, 242, 242, 242),
        fontWeight: FontWeight.w900,
      ),
      floatingLabelStyle: TextStyle(
        color: Color.fromARGB(255, 243, 160, 34),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      hintStyle: TextStyle(color: Colors.grey),
      outlineBorder: BorderSide(color: Colors.red),

      filled: true,
      fillColor: Color.fromRGBO(60, 60, 60, 0.5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 48, 48, 48),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 243, 160, 34),
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2.0),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.fromRGBO(60, 60, 60, 0.5),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 48, 48, 48),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 243, 160, 34),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      textStyle: TextStyle(color: Colors.black87, fontSize: 16),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(
          Color.fromARGB(255, 37, 37, 37),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color.fromARGB(255, 243, 160, 34), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Color.fromARGB(255, 243, 160, 34).withAlpha(60),
      cursorColor: Color.fromARGB(255, 0, 0, 0),
      selectionHandleColor: Color.fromARGB(255, 243, 160, 34),
    ),
    focusColor: Color.fromARGB(255, 243, 160, 34),
    highlightColor: Color.fromARGB(255, 243, 160, 34),
    extensions: <ThemeExtension<dynamic>>[
      CustomColors(
        textForce: Color.fromARGB(255, 214, 214, 214),
        subtextForce: Color.fromARGB(255, 160, 160, 160),
        disabledText: Color.fromARGB(255, 179, 151, 109),
        disabledBack: Color.fromARGB(255, 83, 83, 83),
        backgroundForce: Color.fromARGB(255, 48, 48, 48),
      ),
    ],
  );
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color textForce;
  final Color subtextForce;
  final Color disabledText;
  final Color disabledBack;
  final Color backgroundForce;

  const CustomColors({
    required this.textForce,
    required this.subtextForce,
    required this.disabledText,
    required this.disabledBack,
    required this.backgroundForce,
  });

  @override
  CustomColors copyWith({
    Color? textForce,
    Color? subtextForce,
    Color? disabledText,
    Color? disabledBack,
    Color? backgroundForce,
  }) {
    return CustomColors(
      textForce: textForce ?? this.textForce,
      subtextForce: subtextForce ?? this.subtextForce,
      disabledText: disabledText ?? this.disabledText,
      disabledBack: disabledBack ?? this.disabledBack,
      backgroundForce: backgroundForce ?? this.backgroundForce,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      textForce: Color.lerp(textForce, other.textForce, t)!,
      subtextForce: Color.lerp(subtextForce, other.subtextForce, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
      disabledBack: Color.lerp(disabledBack, other.disabledBack, t)!,
      backgroundForce: Color.lerp(backgroundForce, other.backgroundForce, t)!,
    );
  }
}
