import 'package:flutter/material.dart';

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final Border? border;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.border,
  });

  /// Extracts 1 or 2 uppercase initials from a name or username
  static String getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    } else {
      return trimmed.substring(0, 1).toUpperCase();
    }
  }

  /// Deterministic pleasant color based on the name hash
  static Color getColorForName(String name) {
    final colors = [
      const Color(0xFF8B4513), // Saddle Brown (app primary)
      const Color(0xFF704214), // Dark Brown
      const Color(0xFF2E5A88), // Slate Blue
      const Color(0xFF386641), // Hunter Green
      const Color(0xFF7B2D26), // Rustic Red
      const Color(0xFF5E503F), // Warm Umber
      const Color(0xFF4A5859), // Steel Teal
      const Color(0xFF6B4226), // Coffee
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);
    final bgColor = backgroundColor ?? getColorForName(name);
    final computedFontSize = fontSize ?? (size * 0.4);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: computedFontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
