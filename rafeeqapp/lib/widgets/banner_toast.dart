import 'package:flutter/material.dart';

class BannerToast extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const BannerToast({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF3B2530),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFF3E4EE),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFFF3E4EE)),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
