import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/ui/input.tsx's visual shape (icon + rounded field,
/// themed) — not a verbatim BNA UI port, since that library's source isn't
/// meaningfully portable to Flutter widgets; this matches the same look
/// with a plain Material TextField.
class AppInput extends StatelessWidget {
  final IconData icon;
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const AppInput({
    super.key,
    required this.icon,
    required this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(color: colors.foreground, fontSize: 15),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: colors.mutedForeground),
        prefixIcon: Icon(icon, color: colors.mutedForeground, size: 18),
        filled: true,
        fillColor: colors.input,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}
