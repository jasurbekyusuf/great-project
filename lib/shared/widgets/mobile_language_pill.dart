import 'package:flutter/material.dart';

class MobileLanguagePill extends StatelessWidget {
  const MobileLanguagePill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('UZ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFF101828)),
            ),
          ],
        ),
      ),
    );
  }
}
