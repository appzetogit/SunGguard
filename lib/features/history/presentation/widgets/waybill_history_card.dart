import 'package:flutter/material.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ink_barcode.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/waybill_item_entity.dart';

class WaybillHistoryCard extends StatelessWidget {
  final WaybillItemEntity item;
  final VoidCallback onTap;

  const WaybillHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _getStatusLabel(BuildContext context, ParcelStatus status) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return status.getLocalizedLabel(context);
    switch (status) {
      case ParcelStatus.requested:
      case ParcelStatus.searching:
        return l10n.statusPillFindingRider;
      case ParcelStatus.accepted:
      case ParcelStatus.riderAssigned:
      case ParcelStatus.pickupReached:
        return l10n.statusPillRiderAssigned;
      case ParcelStatus.pickedUp:
      case ParcelStatus.atWaypoint:
        return l10n.statusPillCollected;
      case ParcelStatus.outForDelivery:
      case ParcelStatus.dropReached:
        return l10n.statusPillOnTheWay;
      case ParcelStatus.delivered:
        return l10n.statusPillDelivered;
      case ParcelStatus.cancelled:
        return l10n.statusPillCancelled;
      case ParcelStatus.deliveryFailed:
      case ParcelStatus.returnInTransit:
      case ParcelStatus.returned:
        return l10n.statusPillFailed;
    }
  }

  Color _getStatusBg(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.requested:
      case ParcelStatus.searching:
        return const Color(0xFFFEF3C7); // soft amber
      case ParcelStatus.accepted:
      case ParcelStatus.riderAssigned:
      case ParcelStatus.pickupReached:
        return const Color(0xFFEFF6FF); // soft blue
      case ParcelStatus.pickedUp:
      case ParcelStatus.atWaypoint:
      case ParcelStatus.outForDelivery:
      case ParcelStatus.dropReached:
        return const Color(0xFFECFEFF); // soft teal
      case ParcelStatus.delivered:
        return const Color(0xFFECFDF5); // soft green
      case ParcelStatus.cancelled:
      case ParcelStatus.deliveryFailed:
      case ParcelStatus.returnInTransit:
      case ParcelStatus.returned:
        return const Color(0xFFF1F5F9); // soft grey
    }
  }

  Color _getStatusText(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.requested:
      case ParcelStatus.searching:
        return const Color(0xFFD97706); // amber 700
      case ParcelStatus.accepted:
      case ParcelStatus.riderAssigned:
      case ParcelStatus.pickupReached:
        return const Color(0xFF2563EB); // blue 600
      case ParcelStatus.pickedUp:
      case ParcelStatus.atWaypoint:
      case ParcelStatus.outForDelivery:
      case ParcelStatus.dropReached:
        return const Color(0xFF0D9488); // teal 700
      case ParcelStatus.delivered:
        return const Color(0xFF059669); // green 600
      case ParcelStatus.cancelled:
      case ParcelStatus.deliveryFailed:
      case ParcelStatus.returnInTransit:
      case ParcelStatus.returned:
        return const Color(0xFF64748B); // slate 500
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = item.status;
    final statusLabel = _getStatusLabel(context, status);
    final isLive = status.isLive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 16.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: WAYBILL ID + Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.waybillIdHeader,
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      item.referenceId,
                      style: AppTypography.monoData.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                // Status Badge & Outstation Badge
                Row(
                  children: [
                    if (item.kind == 'outstation') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        margin: const EdgeInsets.only(right: 6.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          l10n.homeOutstation.toUpperCase(),
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBg(status),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Icon(
                              Icons.two_wheeler,
                              size: 13.0,
                              color: _getStatusText(status),
                            ),
                            const SizedBox(width: 4.0),
                          ],
                          Text(
                            statusLabel,
                            style: AppTypography.monoLabel.copyWith(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              color: _getStatusText(status),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Route Section (From ● -> To ○)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    children: [
                      Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 1.0,
                        height: 18.0,
                        color: const Color(0xFFCBD5E1),
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.pickupAddress,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        item.dropAddress,
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Divider(color: const Color(0xFFE2E8F0), thickness: 0.5),

            const SizedBox(height: AppSpacing.md),

            // Footer: Timestamp + Ink Barcode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive ? l10n.estimatedHeader : l10n.completedHeader,
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13.0,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          item.formattedTime,
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 10.0),
                // Barcode graphic (Fitted & Responsive)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: InkBarcode(seed: item.referenceId, height: 24.0),
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
