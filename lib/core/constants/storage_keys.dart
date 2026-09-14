abstract final class StorageKeys {
  static const String customerToken = 'auth_customer_token';
  static const String sellerToken = 'auth_seller_token';
  static const String adminToken = 'auth_admin_token';
  static const String deliveryToken = 'auth_delivery_token';
  static const String authLegacy = 'token';
  static const String activeRole = 'active_role';
  static const String userData = 'user_data';
  static const String savedAddresses = 'saved_addresses';

  // Language preference key
  static const String userLanguage = 'user_language';

  // Auth logged-in flag key
  static const String isLoggedIn = 'is_logged_in';

  // Aliases for compatibility
  static const String authCustomer = customerToken;
  static const String authSeller = sellerToken;
  static const String authAdmin = adminToken;
  static const String authDelivery = deliveryToken;
}
