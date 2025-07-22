import 'package:flutter/material.dart';
import '../services/review_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String targetUserId;

  const WriteReviewScreen({super.key, required this.targetUserId});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 3.0;
  final TextEditingController _commentController = TextEditingController();
  bool isSubmitting = false;

  void _submitReview() async {
    setState(() => isSubmitting = true);

    try {
      await ReviewService.writeReview(
        targetUserId: widget.targetUserId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting review: $e")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Rating", style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.toString(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: "Comment"),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submitReview,
              child: const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }
}
