import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message,
    this.color,
  });

  final String? message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: color ?? const Color(0xFFFF9800),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
            ),
          ],
        ],
      ),
    );
  }
}
