import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../utils/toast_utils.dart';

class RatingDialog extends StatefulWidget {
  final dynamic animeId;
  final String animeTitle;
  final double currentRating;

  const RatingDialog({
    Key? key,
    required this.animeId,
    required this.animeTitle,
    this.currentRating = 5.0,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.currentRating > 0 ? widget.currentRating : 5.0;
  }

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    final success = await ApiService().rateAnime(widget.animeId, _rating.toInt());
    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Bahoyingiz qabul qilindi!");
        Navigator.pop(context, true);
      } else {
        ToastUtils.showError(context, "Baholash uchun tizimga kiring!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.ratingGold, size: 48),
            const SizedBox(height: 12),
            const Text(
              "Animeni baholang",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.animeTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Yulduzchalar
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 10,
              itemSize: 26,
              unratedColor: AppTheme.surfaceBorder,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: AppTheme.ratingGold,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              "${_rating.toInt()} / 10 ball",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.ratingGold,
              ),
            ),
            const SizedBox(height: 24),

            // Tugmalar
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Bekor qilish", style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Baholash"),
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
