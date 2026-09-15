import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/customer_auth_page.dart';
import '../features/booking/presentation/pages/city_parcel_booking_page.dart';
import '../features/booking/presentation/pages/outstation_parcel_booking_page.dart';
import '../features/history/presentation/pages/waybill_export_page.dart';
import '../features/history/presentation/pages/waybill_history_page.dart';
import '../features/parcel_home/presentation/pages/parcel_home_page.dart';
import '../features/profile/presentation/pages/about_us_page.dart';
import '../features/profile/presentation/pages/addresses_page.dart';
import '../features/profile/presentation/pages/chat_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/language_selection_page.dart';
import '../features/profile/presentation/pages/notification_preferences_page.dart';
import '../features/profile/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/privacy_policy_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/support_page.dart';
import '../features/profile/presentation/pages/terms_page.dart';
import '../features/profile/presentation/pages/wallet_page.dart';
import '../features/tracking/presentation/pages/city_parcel_tracking_page.dart';
import '../features/tracking/presentation/pages/parcel_search_tracking_page.dart';
import '../shared/layout/customer_shell_page.dart';
import '../shared/pages/splash_page.dart';
import 'app_routes.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'homeTab');
  static final GlobalKey<NavigatorState> _historyNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'historyTab');
  static final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profileTab');

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final isAuthRoute = state.matchedLocation == AppRoutes.auth;
        final isSplashRoute = state.matchedLocation == AppRoutes.splash;

        // While initializing token check on cold app start
        if (authState.isLoading && authState.user == null && !isAuthRoute) {
          return isSplashRoute ? null : AppRoutes.splash;
        }

        if (!authState.isAuthenticated) {
          return isAuthRoute ? null : AppRoutes.auth;
        }

        if (isAuthRoute || isSplashRoute) {
          return AppRoutes.initial;
        }

        return null;
      },
      routes: [
        // Full screen Splash Page
        GoRoute(
          path: AppRoutes.splash,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SplashPage(),
        ),

        // Full screen Auth Page
        GoRoute(
          path: AppRoutes.auth,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CustomerAuthPage(),
        ),

        // Stateful Shell with 4 core bottom navigation tabs
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              CustomerShellPage(navigationShell: navigationShell),
          branches: [
            // Branch 0: Home
            StatefulShellBranch(
              navigatorKey: _homeNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.initial,
                  builder: (context, state) => const ParcelHomePage(),
                ),
              ],
            ),

            // Branch 2: Waybill History
            StatefulShellBranch(
              navigatorKey: _historyNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.history,
                  builder: (context, state) => const WaybillHistoryPage(),
                ),
                // Route alias for parcel history
                GoRoute(
                  path: '/profile/parcel-history',
                  redirect: (_, __) => AppRoutes.history,
                ),
              ],
            ),

            // Branch 3: Profile
            StatefulShellBranch(
              navigatorKey: _profileNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),

        // Full Screen Sub-routes (no bottom nav)
        GoRoute(
          path: AppRoutes.cityParcelBooking,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CityParcelBookingPage(),
        ),
        GoRoute(
          path: AppRoutes.outstationBooking,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const OutstationParcelBookingPage(),
        ),
        GoRoute(
          path: '${AppRoutes.cityParcelTracking}/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final parcelId = state.pathParameters['id'] ?? '';
            return CityParcelTrackingPage(parcelId: parcelId);
          },
        ),
        GoRoute(
          path: '${AppRoutes.outstationTracking}/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final parcelId = state.pathParameters['id'] ?? '';
            return ParcelSearchTrackingPage(parcelId: parcelId);
          },
        ),
        GoRoute(
          path: '${AppRoutes.parcelSearch}/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final parcelId = state.pathParameters['id'] ?? '';
            return ParcelSearchTrackingPage(parcelId: parcelId);
          },
        ),
        GoRoute(
          path: AppRoutes.historyExport,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const WaybillExportPage(),
        ),
        GoRoute(
          path: AppRoutes.addresses,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AddressesPage(),
        ),
        GoRoute(
          path: AppRoutes.wallet,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: AppRoutes.support,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final complaint = state.uri.queryParameters['complaint'] ??
                state.uri.queryParameters['raise'];
            final category = state.uri.queryParameters['category'];
            final orderId = state.uri.queryParameters['orderId'];
            final parcelId = state.uri.queryParameters['parcelId'];
            final subject = state.uri.queryParameters['subject'];
            final description = state.uri.queryParameters['description'];
            return SupportPage(
              autoOpenComplaint: complaint != null && complaint.isNotEmpty,
              initialCategory: category,
              initialOrderId: orderId,
              initialParcelId: parcelId,
              initialSubject: subject,
              initialDescription: description,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.privacy,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const PrivacyPolicyPage(),
        ),
        GoRoute(
          path: AppRoutes.terms,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const TermsPage(),
        ),
        GoRoute(
          path: AppRoutes.about,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AboutUsPage(),
        ),
        GoRoute(
          path: AppRoutes.language,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LanguageSelectionPage(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const NotificationPreferencesPage(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final ticketId = state.uri.queryParameters['ticketId'];
            return ChatPage(
              initialTicketId: ticketId,
              relatedParcelId: state.uri.queryParameters['parcelId'],
              relatedOrderId: state.uri.queryParameters['orderId'],
            );
          },
        ),
      ],
    );
  }
}
