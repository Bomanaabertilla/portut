import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final TextStyle? textStyle;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = false,
    this.textStyle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF6D4C41),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'PT',
            style: TextStyle(
              color: const Color(0xFFF5F5DC),
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );

    if (!showText) {
      return imageWidget;
    }

    final effectiveTextColor = textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF424242));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        imageWidget,
        const SizedBox(width: 8),
        Text(
          'PorTuT',
          style: textStyle ??
              TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: effectiveTextColor,
              ),
        ),
      ],
    );
  }
}
