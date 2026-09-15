import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/consignment_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/parcel_summary_entity.dart';

class ShipmentProgressCard extends StatelessWidget {
  final ParcelSummaryEntity parcel;
  final VoidCallback onTrack;

  const ShipmentProgressCard({super.key, required this.parcel, required this.onTrack});

  String _formatTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return '--:--';
    }
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('hh:mm a').format(dt).toLowerCase();
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = parcel.status;
    final moving = status.isMoving;
    final l10n = AppLocalizations.of(context)!;

    final pickupTimeFormatted = _formatTime(parcel.pickedUpAt);
    final etaTimeFormatted = _formatTime(parcel.deliveryEta);

    return ConsignmentCard(
      onTap: onTrack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Waybill ID + Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.waybillId,
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    parcel.referenceId,
                    style: AppTypography.monoData.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              StatusChip(label: status.label, tone: status.tone, icon: moving ? Icons.directions_bike : null),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Route Progress Bar (From -> To with Truck/Package icon)
          Row(
            children: [
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: moving ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: moving ? AppColors.primary : AppColors.borderStrong, width: 2.0),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(height: 2.0, color: AppColors.borderStrong),
                    if (moving)
                      Positioned(
                        left: 0,
                        right: 0,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          alignment: Alignment.centerLeft,
                          child: Container(height: 2.0, color: AppColors.primary),
                        ),
                      ),
                    Container(
                      width: 24.0,
                      height: 24.0,
                      decoration: BoxDecoration(
                        color: moving ? AppColors.primary : AppColors.counter,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        moving ? Icons.local_shipping : Icons.inventory_2_outlined,
                        size: 13.0,
                        color: moving ? Colors.white : AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderStrong, width: 2.0),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Pickup & Drop Titles + Times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.pickupAddress,
                      style: AppTypography.bodyBold.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      pickupTimeFormatted,
                      style: AppTypography.monoDataSmall.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      parcel.dropAddress,
                      style: AppTypography.bodyRegular.copyWith(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      etaTimeFormatted != '--:--' ? l10n.etaTime(etaTimeFormatted) : '--:--',
                      style: AppTypography.monoDataSmall.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1.0),
          const SizedBox(height: AppSpacing.sm),

          // Footer: Distance + Track CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14.0, color: AppColors.inkTertiary),
                  const SizedBox(width: 4.0),
                  Text(
                    '${parcel.distanceKm > 0 ? parcel.distanceKm.toStringAsFixed(1) : "3.5"} km',
                    style: AppTypography.monoDataSmall.copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    l10n.trackLive,
                    style: AppTypography.monoLabel.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(Icons.arrow_forward, size: 14.0, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
