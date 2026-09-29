import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.mealId});
  final String mealId;
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 5;
  final _comment = TextEditingController();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review meal')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'How was your meal?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => IconButton(
              onPressed: () => setState(() => _rating = index + 1.0),
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFF7A00),
                size: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _comment,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Share your thoughts'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () async {
            await ref
                .read(reviewProvider)
                .submit(
                  mealId: widget.mealId,
                  rating: _rating,
                  comment: _comment.text.trim(),
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Submit review'),
        ),
      ],
    ),
  );
}
