import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../core/network/api_client.dart';
import '../core/localization/app_locale_controller.dart';
import '../core/localization/fallback_localizations_delegate.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
import '../features/history/presentation/bloc/history_bloc.dart';
import '../features/parcel_home/presentation/bloc/parcel_home_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/tracking/presentation/bloc/tracking_bloc.dart';
import 'app_router.dart';

class SunGguardApp extends StatefulWidget {
  const SunGguardApp({super.key});

  @override
  State<SunGguardApp> createState() => _SunGguardAppState();
}

class _SunGguardAppState extends State<SunGguardApp> {
  late final AuthBloc _authBloc;
  late final ParcelHomeBloc _parcelHomeBloc;
  late final BookingBloc _bookingBloc;
  late final TrackingBloc _trackingBloc;
  late final HistoryBloc _historyBloc;
  late final ProfileBloc _profileBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Resolve BLoCs once from GetIt service locator
    _authBloc = sl<AuthBloc>()..add(AuthCheckRequested());
    _parcelHomeBloc = sl<ParcelHomeBloc>();
    _bookingBloc = sl<BookingBloc>();
    _trackingBloc = sl<TrackingBloc>();
    _historyBloc = sl<HistoryBloc>();
    _profileBloc = sl<ProfileBloc>();

    // A rejected token now ends the session instead of rendering as silently
    // empty screens. Datasources swallow errors and return empty lists, so
    // without this an expired JWT looked identical to "you have no parcels".
    ApiClient.onUnauthorized = () {
      if (!_authBloc.isClosed) _authBloc.add(AuthLogoutRequested());
    };

    // Create GoRouter connected to AuthBloc lifecycle
    _router = AppRouter.createRouter(_authBloc);
  }

  @override
  void dispose() {
    ApiClient.onUnauthorized = null;
    _authBloc.close();
    _parcelHomeBloc.close();
    _bookingBloc.close();
    _trackingBloc.close();
    _historyBloc.close();
    _profileBloc.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _parcelHomeBloc),
        BlocProvider.value(value: _bookingBloc),
        BlocProvider.value(value: _trackingBloc),
        BlocProvider.value(value: _historyBloc),
        BlocProvider.value(value: _profileBloc),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: sl<AppLocaleController>(),
        builder: (context, locale, child) {
          return MaterialApp.router(
            title: 'SunGguard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

