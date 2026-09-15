import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/maps_service.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/booking/presentation/bloc/booking_event.dart';
import '../../app/app_routes.dart';
import 'liquid_bottom_nav.dart';

class CustomerShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShellPage({super.key, required this.navigationShell});

  @override
  State<CustomerShellPage> createState() => _CustomerShellPageState();
}

class _CustomerShellPageState extends State<CustomerShellPage> {
  @override
  void initState() {
    super.initState();
    // Warm up and cache device location on app shell launch
    MapsService().fetchCurrentLocation();
  }

  /// Bottom nav:
  /// 0 = Home
  /// 1 = Parcel
  /// 2 = History
  /// 3 = Profile
  ///
  /// Shell:
  /// 0 = Home
  /// 1 = History
  /// 2 = Profile
  ///
  /// Parcel is a separate full-screen route.
  int _shellToNavIndex(int shellIndex) {
    switch (shellIndex) {
      case 0:
        return 0;

      case 1:
        return 2;

      case 2:
        return 3;

      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          // ======================================================
          // MAIN CONTENT
          // ======================================================

          Positioned.fill(child: widget.navigationShell),

          // ======================================================
          // FLOATING GLASS BOTTOM NAV
          // ======================================================
          LiquidBottomNav(
            currentIndex: _shellToNavIndex(widget.navigationShell.currentIndex),

            onTabSelected: (navIndex) {
              // ==================================================
              // PARCEL
              // ==================================================

              if (navIndex == 1) {
                context.read<BookingBloc>().add(BookingResetRequested());

                context.push(AppRoutes.cityParcelBooking);

                return;
              }

              // ==================================================
              // HOME / HISTORY / PROFILE
              // ==================================================

              final shellBranch = switch (navIndex) {
                0 => 0, // Home
                2 => 1, // History
                3 => 2, // Profile
                _ => 0,
              };

              widget.navigationShell.goBranch(
                shellBranch,
                initialLocation:
                    shellBranch == widget.navigationShell.currentIndex,
              );
            },
          ),
        ],
      ),
    );
  }
}
