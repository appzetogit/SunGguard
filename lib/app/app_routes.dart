abstract final class AppRoutes {
  // Splash & Authentication
  static const String splash = '/splash';
  static const String auth = '/auth';

  // Customer Core Tabs (Stateful Shell Branches)
  static const String initial = '/';
  static const String home = '/home';
  static const String cityParcelBooking = '/parcel/local';
  static const String outstationBooking = '/parcel/outstation';
  static const String history = '/history';
  static const String historyExport = '/history/export';
  static const String profile = '/profile';

  // Sub-routes & Detail Pages
  static const String cityParcelTracking = '/parcel/local/track';
  static const String outstationTracking = '/parcel/outstation/track';
  static const String parcelSearch = '/parcel/search';
  static const String addresses = '/addresses';
  static const String wallet = '/wallet';
  static const String support = '/support';
  static const String editProfile = '/profile/edit';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String about = '/about';
  static const String language = '/language';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String chat = '/chat';
  static const String paymentStatus = '/payment/status';

  // Route builder helpers
  static String trackingPath(String id) => '$cityParcelTracking/$id';
  static String outstationTrackingPath(String id) => '$outstationTracking/$id';
  static String parcelSearchPath(String id) => '$parcelSearch/$id';
}
