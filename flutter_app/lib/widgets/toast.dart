import 'package:flutter/material.dart';

/// Port of components/ui/toast.tsx's `useToast().warning(...)` call sites —
/// a custom ToastProvider isn't needed in Flutter, ScaffoldMessenger's
/// SnackBar already does this job idiomatically.
void showWarningToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFF59E0B),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}
