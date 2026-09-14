import 'package:flutter/material.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// Collects a 1–5 star rating and an optional comment for a delivered
/// outstation parcel, then posts it to `POST /parcel/review`.
///
/// The endpoint and its guards (own parcel, DELIVERED only, one review each)
/// have always existed server-side; the app could read other customers'
/// reviews on the booking screen but never let anyone leave one.
class ParcelRatingSheet extends StatefulWidget {
  final String parcelId;
  final VoidCallback? onSubmitted;

  const ParcelRatingSheet({
    super.key,
    required this.parcelId,
    this.onSubmitted,
  });

  /// Returns true when a review was actually submitted.
  static Future<bool> show(
    BuildContext context, {
    required String parcelId,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParcelRatingSheet(parcelId: parcelId),
    );
    return result == true;
  }

  @override
  State<ParcelRatingSheet> createState() => _ParcelRatingSheetState();
}

class _ParcelRatingSheetState extends State<ParcelRatingSheet> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiClient.createDefault().post(
        ApiEndpoints.outstationParcelSubmitReview,
        data: {
          'parcelId': widget.parcelId,
          'rating': _rating,
          // Server truncates at 1000 characters.
          'comment': _commentCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop(true);
      AppSnackBar.showSuccess(context, 'Thanks for your feedback!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // 409 = not delivered yet, 400 = already reviewed, 403 = not your parcel.
      // Each of those is worth reading, so the server's own wording is shown.
      AppSnackBar.showError(
        context,
        (e is ApiException && e.message.isNotEmpty)
            ? e.message
            : "Couldn't save your rating",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              'How was this delivery?',
              style: AppTypography.headingLarge.copyWith(
                fontSize: 19.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Your rating helps other customers choose.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13.0,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                final filled = value <= _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = value),
                  iconSize: 36.0,
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFCBD5E1),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12.0),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Anything you want to add? (optional)',
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rating > 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: (_rating > 0 && !_isSubmitting) ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'SUBMIT RATING',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
