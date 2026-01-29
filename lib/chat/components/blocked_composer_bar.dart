import 'package:flutter/material.dart';

class BlockedComposerBar extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final bool showUnblock;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;

  const BlockedComposerBar({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.showUnblock,
    required this.onUnblock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black : Colors.white;
    final text1 = isDark ? Colors.white : Colors.black;
    final text2 = isDark ? Colors.white70 : Colors.black54;
    final divider = isDark ? Colors.white12 : Colors.black12;

    return SafeArea(
      top: false,
      child: Container(
        color: bg,
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: text2, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: divider),

            // actions row (like Instagram)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: showUnblock ? onUnblock : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Text(
                        showUnblock ? "Unblock" : "Blocked",
                        style: TextStyle(
                          color: showUnblock ? text1 : text2,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 44, color: divider),
                Expanded(
                  child: InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}