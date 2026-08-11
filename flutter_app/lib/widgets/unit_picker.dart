import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A bounded 0..max dropdown for picking a single time unit (hours,
/// minutes, seconds…) — extracted from strict_mode_screen.dart's duration
/// picker so profile creation/editing can reuse the same select-based
/// input instead of free-text fields.
class UnitPicker extends StatelessWidget {
  final int value;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;
  final bool enabled;
  const UnitPicker({super.key, required this.value, required this.max, required this.suffix, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            isDense: true,
            dropdownColor: colors.card,
            style: TextStyle(fontSize: 13, color: colors.foreground),
            items: [
              for (int i = 0; i <= max; i++)
                DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}$suffix')),
            ],
            onChanged: enabled
                ? (v) {
                    if (v != null) onChanged(v);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
