import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_input.dart';

/// Port of components/blocklist-ui.tsx + components/BlockListRow.tsx —
/// small presentational pieces shared by the block-list sub-screens
/// (websites, keywords, whitelist).

class LimitBadge extends StatelessWidget {
  final int count;
  final num max; // may be double.infinity, matching lib/models/limits.dart
  const LimitBadge({super.key, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final atLimit = max.isFinite && count >= max;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: atLimit ? colors.primary.withOpacity(0.1) : colors.card,
        border: Border.all(color: atLimit ? colors.primary.withOpacity(0.25) : colors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        max.isFinite ? '$count/${max.toInt()}' : '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: atLimit ? colors.primary : colors.foreground,
        ),
      ),
    );
  }
}

class BlocklistEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const BlocklistEmptyState({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: colors.mutedForeground),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
        ],
      ),
    );
  }
}

class AddRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final String placeholder;
  final bool disabled;

  const AddRow({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.placeholder,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: IgnorePointer(
              ignoring: disabled,
              child: Opacity(
                opacity: disabled ? 0.5 : 1,
                child: AppInput(
                  icon: Icons.add_rounded,
                  placeholder: placeholder,
                  controller: controller,
                  textCapitalization: TextCapitalization.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: disabled ? null : onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class BlockListRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onRemove;

  const BlockListRow({super.key, required this.icon, required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: colors.foreground)),
          ),
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF43F5E)),
              ),
            ),
        ],
      ),
    );
  }
}
