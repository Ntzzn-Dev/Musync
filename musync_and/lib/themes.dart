import 'package:flutter/material.dart';

final baseElementDark = Color.fromARGB(255, 38, 38, 39);
final baseFundoDark = Color.fromARGB(255, 23, 23, 24);
final baseFundoDarkDark = Color.fromARGB(255, 8, 8, 10);
final baseAppColor = Color.fromARGB(255, 243, 160, 34);
ThemeData lighttheme() {
  return ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.orange,
    scaffoldBackgroundColor: Color.fromARGB(255, 242, 242, 242),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 237, 237, 237),
      foregroundColor: baseAppColor,
      surfaceTintColor: Color.fromARGB(255, 242, 242, 242),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 242, 242, 242),
        foregroundColor: baseAppColor,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color.fromARGB(255, 255, 255, 255),
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Color.fromARGB(255, 242, 242, 242),
      textStyle: TextStyle(color: baseAppColor, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: baseAppColor,
      inactiveTrackColor: Color.fromARGB(77, 243, 160, 34),
      trackHeight: 4,
      thumbColor: baseAppColor,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
      overlayColor: Color.fromARGB(51, 243, 160, 34),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
      valueIndicatorColor: baseAppColor,
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Color.fromARGB(255, 242, 242, 242),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Color.fromARGB(255, 0, 0, 0),
      displayColor: Color.fromARGB(255, 0, 0, 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      floatingLabelStyle: TextStyle(
        color: baseAppColor,
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
        borderSide: BorderSide(color: baseAppColor, width: 2.0),
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
          borderSide: BorderSide(color: baseAppColor, width: 2),
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
        side: BorderSide(color: baseAppColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: baseAppColor.withAlpha(60),
      cursorColor: Color.fromARGB(255, 0, 0, 0),
      selectionHandleColor: baseAppColor,
    ),
    focusColor: baseAppColor,
    highlightColor: baseAppColor,
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
    fontFamily: "Default-Medium",
    useMaterial3: true,
    primarySwatch: Colors.orange,
    scaffoldBackgroundColor: baseElementDark,
    appBarTheme: AppBarTheme(
      backgroundColor: baseFundoDark,
      foregroundColor: baseAppColor,
      surfaceTintColor: baseFundoDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: baseElementDark,
        foregroundColor: baseAppColor,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color.fromARGB(255, 36, 36, 36),
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: baseFundoDark,
      textStyle: TextStyle(color: baseAppColor, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: baseAppColor,
      inactiveTrackColor: Color.fromARGB(77, 243, 160, 34),
      trackHeight: 4,
      thumbColor: baseAppColor,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
      overlayColor: Color.fromARGB(51, 243, 160, 34),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
      valueIndicatorColor: baseAppColor,
      valueIndicatorTextStyle: TextStyle(
        color: baseElementDark,
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: baseElementDark,
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
        color: baseAppColor,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      hintStyle: TextStyle(color: Colors.grey),
      outlineBorder: BorderSide(color: Colors.red),

      filled: true,
      fillColor: Color.fromRGBO(60, 60, 60, 0.5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: baseElementDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: baseAppColor, width: 2.0),
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
          borderSide: BorderSide(color: baseElementDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseAppColor, width: 2),
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
        backgroundColor: MaterialStateProperty.all(baseFundoDark),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: baseAppColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: baseAppColor.withAlpha(60),
      cursorColor: Color.fromARGB(255, 0, 0, 0),
      selectionHandleColor: baseAppColor,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(baseFundoDark),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(baseFundoDarkDark),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    focusColor: baseAppColor,
    highlightColor: baseAppColor,
    extensions: <ThemeExtension<dynamic>>[
      CustomColors(
        textForce: Color.fromARGB(255, 214, 214, 214),
        subtextForce: Color.fromARGB(255, 160, 160, 160),
        disabledText: Color.fromARGB(255, 179, 151, 109),
        disabledBack: Color.fromARGB(255, 83, 83, 83),
        backgroundForce: baseElementDark,
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
