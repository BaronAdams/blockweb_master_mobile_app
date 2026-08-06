import 'package:flutter/material.dart';

enum EntryIconType { app, site }

/// Port of components/EntryIcon.tsx — sites get their real favicon
/// (Google's favicon service, same source the extension uses), falling
/// back to a generic globe glyph on error. Apps get a colored
/// initial-letter avatar — real package icons need the native
/// installed-apps bridge, not yet ported (see blocklists/apps.tsx in the
/// RN app, still a placeholder here).
class EntryIcon extends StatelessWidget {
  final String name;
  final EntryIconType type;
  final Color color;
  final double size;

  const EntryIcon({super.key, required this.name, required this.type, required this.color, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final badgeDecoration = BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(size * 0.28),
    );

    if (type == EntryIconType.site) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Container(
          width: size,
          height: size,
          decoration: badgeDecoration,
          alignment: Alignment.center,
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=$name&sz=64',
            width: size * 0.55,
            height: size * 0.55,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.public, size: size * 0.5, color: color),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: badgeDecoration,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
