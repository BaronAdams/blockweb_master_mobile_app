import 'package:flutter/material.dart';

/// Port of components/DangerButton.tsx.
class DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const DangerButton({super.key, required this.label, required this.icon, this.onPressed});

  static const _red = Color(0xFFF43F5E);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: _red),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _red)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        side: const BorderSide(color: Color(0x4DF43F5E)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
