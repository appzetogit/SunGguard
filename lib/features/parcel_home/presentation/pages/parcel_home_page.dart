import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/parcel_home_bloc.dart';
import '../bloc/parcel_home_event.dart';
import '../bloc/parcel_home_state.dart';
import '../widgets/shipment_progress_card.dart';

class ParcelHomePage extends StatefulWidget {
  final Function(String route)? onNavigate;

  const ParcelHomePage({super.key, this.onNavigate});

  @override
  State<ParcelHomePage> createState() => _ParcelHomePageState();
}

class _ParcelHomePageState extends State<ParcelHomePage> {
  void _nav(String route) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
    } else {
      context.push(route);
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ParcelHomeBloc>().add(ParcelHomeFetchRequested());
    MapsService().fetchCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => !previous.isAuthenticated && current.isAuthenticated,
      listener: (context, state) {
        context.read<ParcelHomeBloc>().add(ParcelHomeFetchRequested());
        MapsService().fetchCurrentLocation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: BlocBuilder<ParcelHomeBloc, ParcelHomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ParcelHomeBloc>().add(ParcelHomeFetchRequested());
                },
                color: const Color(0xFF059669),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Segmented Switcher (LOCAL DELIVERY vs OUTSTATION)
                      _buildTopSwitcher(state),

                      const SizedBox(height: AppSpacing.md),

                      // 2. Start a Shipment Hero Card
                      _buildStartShipmentCard(state),

                      const SizedBox(height: AppSpacing.lg),

                      // 3. Parcels in Transit Metric Card
                      _buildParcelsInTransitCard(state),

                      const SizedBox(height: AppSpacing.xl),

                      // 4. Active Shipments Header & Section
                      _buildActiveShipmentsSection(state),

                      const SizedBox(height: 90.0), // Spacing for bottom floating navigation
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopSwitcher(ParcelHomeState state) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8.0, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<ParcelHomeBloc>().add(const ParcelHomeServiceSwitched('local')),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: state.isLocal ? const Color(0xFF0F172A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.homeLocalDelivery.toUpperCase(),
                  style: AppTypography.monoLabel.copyWith(
                    color: state.isLocal ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.0,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<ParcelHomeBloc>().add(const ParcelHomeServiceSwitched('outstation')),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: !state.isLocal ? const Color(0xFF0F172A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.homeOutstation.toUpperCase(),
                  style: AppTypography.monoLabel.copyWith(
                    color: !state.isLocal ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.0,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartShipmentCard(ParcelHomeState state) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 16.0, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12.0)),
            child: const Icon(Icons.add, color: Color(0xFF0F172A), size: 22.0),
          ),
          const SizedBox(height: 16.0),
          Text(
            l10n.homeStartShipmentTitle,
            style: AppTypography.headingLarge.copyWith(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            state.isLocal ? l10n.homeLocalShipmentSubtitle : l10n.homeOutstationShipmentSubtitle,
            style: AppTypography.bodyRegular.copyWith(fontSize: 13.5, color: const Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 20.0),
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () {
                if (state.isLocal) {
                  _nav('/parcel/local');
                } else {
                  _nav('/parcel/outstation');
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.homeCreateNewBooking.toUpperCase(),
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(Icons.arrow_forward, size: 16.0, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelsInTransitCard(ParcelHomeState state) {
    final count = state.currentCount;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 16.0, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.homeParcelsInTransit.toUpperCase(),
                style: AppTypography.monoLabel.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.shield_outlined, color: Color(0xFF94A3B8), size: 18.0),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            count == 0 ? '00' : count.toString().padLeft(2, '0'),
            style: AppTypography.monoData.copyWith(
              fontSize: 34.0,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF059669), size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                count == 0 ? l10n.homeNothingOnTheMove : l10n.homeEverythingOnSchedule,
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF059669),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShipmentsSection(ParcelHomeState state) {
    final shipments = state.currentShipments;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.homeRecentOrders,
              style: AppTypography.headingLarge.copyWith(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => _nav('/profile/parcel-history'),
              child: Text(
                l10n.viewAll.toUpperCase(),
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 10.5,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),
        if (state.isLoading)
          const HomeShipmentCardSkeleton()
        else if (shipments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 42.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.homeNoShipmentsMoving,
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  state.isLocal ? l10n.homeLocalEmptyShipments : l10n.homeOutstationEmptyShipments,
                  style: AppTypography.bodySmall.copyWith(fontSize: 12.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ...shipments.map(
            (shipment) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ShipmentProgressCard(
                parcel: shipment,
                onTrack: () {
                  if (shipment.kind == 'outstation') {
                    _nav('/parcel/outstation/track/${shipment.id}');
                  } else {
                    _nav('/parcel/local/track/${shipment.id}');
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}
