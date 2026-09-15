import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_ks.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_sa.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('brx'),
    Locale('doi'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('kok'),
    Locale('ks'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('sa'),
    Locale('sat'),
    Locale('sd'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SunGguard'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @seeDetails.
  ///
  /// In en, this message translates to:
  /// **'See Details'**
  String get seeDetails;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get hindi;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navWaybills.
  ///
  /// In en, this message translates to:
  /// **'Waybills'**
  String get navWaybills;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Fast & Secure Logistics'**
  String get splashTagline;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delivering Trust Across Cities'**
  String get splashSubtitle;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to get started'**
  String get authLoginSubtitle;

  /// No description provided for @authEnterMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get authEnterMobile;

  /// No description provided for @authSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get authSendOtp;

  /// No description provided for @authEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get authEnterOtp;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to'**
  String get authOtpSentTo;

  /// No description provided for @authVerifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get authVerifyOtp;

  /// No description provided for @authResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get authResendOtp;

  /// No description provided for @authInvalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number'**
  String get authInvalidMobile;

  /// No description provided for @authInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete 6-digit OTP'**
  String get authInvalidOtp;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **' Please Enter your details to continue'**
  String get authRegisterSubtitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, Welcome!'**
  String get homeGreeting;

  /// No description provided for @homeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Reliable Parcel Delivery'**
  String get homeBannerTitle;

  /// No description provided for @homeBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book city or outstation delivery in minutes'**
  String get homeBannerSubtitle;

  /// No description provided for @homeStartShipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a Shipment'**
  String get homeStartShipmentTitle;

  /// No description provided for @homeLocalShipmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up from your door and hand it to someone across the city, verified at the doorstep.'**
  String get homeLocalShipmentSubtitle;

  /// No description provided for @homeOutstationShipmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We collect from you and hand it to your courier partner for the journey out of town.'**
  String get homeOutstationShipmentSubtitle;

  /// No description provided for @homeCreateNewBooking.
  ///
  /// In en, this message translates to:
  /// **'Create New Booking'**
  String get homeCreateNewBooking;

  /// No description provided for @homeLocalDelivery.
  ///
  /// In en, this message translates to:
  /// **'Local Delivery'**
  String get homeLocalDelivery;

  /// No description provided for @homeOutstation.
  ///
  /// In en, this message translates to:
  /// **'Outstation'**
  String get homeOutstation;

  /// No description provided for @homeCityParcel.
  ///
  /// In en, this message translates to:
  /// **'City Parcel'**
  String get homeCityParcel;

  /// No description provided for @homeCityDesc.
  ///
  /// In en, this message translates to:
  /// **'Same day intracity delivery'**
  String get homeCityDesc;

  /// No description provided for @homeOutstationParcel.
  ///
  /// In en, this message translates to:
  /// **'Outstation Parcel'**
  String get homeOutstationParcel;

  /// No description provided for @homeOutstationDesc.
  ///
  /// In en, this message translates to:
  /// **'Intercity & interstate shipping'**
  String get homeOutstationDesc;

  /// No description provided for @homeTrackParcel.
  ///
  /// In en, this message translates to:
  /// **'Track Your Parcel'**
  String get homeTrackParcel;

  /// No description provided for @homeParcelsInTransit.
  ///
  /// In en, this message translates to:
  /// **'Parcels in Transit'**
  String get homeParcelsInTransit;

  /// No description provided for @homeNothingOnTheMove.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the move'**
  String get homeNothingOnTheMove;

  /// No description provided for @homeEverythingOnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Everything on schedule'**
  String get homeEverythingOnSchedule;

  /// No description provided for @homeEnterWaybill.
  ///
  /// In en, this message translates to:
  /// **'Enter Waybill / Parcel ID'**
  String get homeEnterWaybill;

  /// No description provided for @homeTrackNow.
  ///
  /// In en, this message translates to:
  /// **'Track Now'**
  String get homeTrackNow;

  /// No description provided for @homeRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get homeRecentOrders;

  /// No description provided for @homeNoRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'No recent orders found'**
  String get homeNoRecentOrders;

  /// No description provided for @homeNoShipmentsMoving.
  ///
  /// In en, this message translates to:
  /// **'No shipments moving'**
  String get homeNoShipmentsMoving;

  /// No description provided for @homeLocalEmptyShipments.
  ///
  /// In en, this message translates to:
  /// **'Book a local delivery pickup and it will show up here.'**
  String get homeLocalEmptyShipments;

  /// No description provided for @homeOutstationEmptyShipments.
  ///
  /// In en, this message translates to:
  /// **'Book an outstation pickup and it will show up here.'**
  String get homeOutstationEmptyShipments;

  /// No description provided for @homeQuickServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get homeQuickServices;

  /// No description provided for @bookingCityTitle.
  ///
  /// In en, this message translates to:
  /// **'City Parcel Booking'**
  String get bookingCityTitle;

  /// No description provided for @bookingSenderInfo.
  ///
  /// In en, this message translates to:
  /// **'Sender Information'**
  String get bookingSenderInfo;

  /// No description provided for @bookingReceiverInfo.
  ///
  /// In en, this message translates to:
  /// **'Receiver Information'**
  String get bookingReceiverInfo;

  /// No description provided for @bookingPickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Pickup Address'**
  String get bookingPickupAddress;

  /// No description provided for @bookingDropAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get bookingDropAddress;

  /// No description provided for @bookingSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get bookingSelectVehicle;

  /// No description provided for @bookingParcelCategory.
  ///
  /// In en, this message translates to:
  /// **'Parcel Category'**
  String get bookingParcelCategory;

  /// No description provided for @bookingParcelWeight.
  ///
  /// In en, this message translates to:
  /// **'Approx Weight (kg)'**
  String get bookingParcelWeight;

  /// No description provided for @bookingEstimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated Fare'**
  String get bookingEstimatedPrice;

  /// No description provided for @bookingPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get bookingPaymentMethod;

  /// No description provided for @bookingPayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on Pickup/Delivery'**
  String get bookingPayCash;

  /// No description provided for @bookingPayOnline.
  ///
  /// In en, this message translates to:
  /// **'Online / Wallet'**
  String get bookingPayOnline;

  /// No description provided for @bookingConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get bookingConfirmOrder;

  /// No description provided for @bookingEnterSenderName.
  ///
  /// In en, this message translates to:
  /// **'Enter sender name'**
  String get bookingEnterSenderName;

  /// No description provided for @bookingEnterSenderPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter sender phone'**
  String get bookingEnterSenderPhone;

  /// No description provided for @bookingEnterReceiverName.
  ///
  /// In en, this message translates to:
  /// **'Enter receiver name'**
  String get bookingEnterReceiverName;

  /// No description provided for @bookingEnterReceiverPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter receiver phone'**
  String get bookingEnterReceiverPhone;

  /// No description provided for @bookingFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get bookingFillAllFields;

  /// No description provided for @outstationBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Outstation Parcel Shipping'**
  String get outstationBookingTitle;

  /// No description provided for @outstationPickupCity.
  ///
  /// In en, this message translates to:
  /// **'Pickup City'**
  String get outstationPickupCity;

  /// No description provided for @outstationDestinationCity.
  ///
  /// In en, this message translates to:
  /// **'Destination City'**
  String get outstationDestinationCity;

  /// No description provided for @outstationParcelDetails.
  ///
  /// In en, this message translates to:
  /// **'Parcel Details'**
  String get outstationParcelDetails;

  /// No description provided for @outstationRateCalc.
  ///
  /// In en, this message translates to:
  /// **'Calculate Rate'**
  String get outstationRateCalc;

  /// No description provided for @outstationBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Outstation Ship'**
  String get outstationBookNow;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Order & Waybill History'**
  String get historyTitle;

  /// No description provided for @historyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAll;

  /// No description provided for @historyActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get historyActive;

  /// No description provided for @historyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get historyCompleted;

  /// No description provided for @historyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get historyCancelled;

  /// No description provided for @historyWaybillNo.
  ///
  /// In en, this message translates to:
  /// **'Waybill #'**
  String get historyWaybillNo;

  /// No description provided for @historyNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No order history available'**
  String get historyNoOrders;

  /// No description provided for @waybillId.
  ///
  /// In en, this message translates to:
  /// **'WAYBILL ID'**
  String get waybillId;

  /// No description provided for @trackLive.
  ///
  /// In en, this message translates to:
  /// **'TRACK LIVE'**
  String get trackLive;

  /// No description provided for @etaTime.
  ///
  /// In en, this message translates to:
  /// **'ETA {time}'**
  String etaTime(String time);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKm(String distance);

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Parcel Tracking'**
  String get trackingTitle;

  /// No description provided for @trackingOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get trackingOrderStatus;

  /// No description provided for @trackingDriverInfo.
  ///
  /// In en, this message translates to:
  /// **'Driver Info'**
  String get trackingDriverInfo;

  /// No description provided for @trackingCallDriver.
  ///
  /// In en, this message translates to:
  /// **'Call Driver'**
  String get trackingCallDriver;

  /// No description provided for @trackingChatDriver.
  ///
  /// In en, this message translates to:
  /// **'Chat with Driver'**
  String get trackingChatDriver;

  /// No description provided for @trackingEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get trackingEstimatedTime;

  /// No description provided for @trackingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Delivery Timeline'**
  String get trackingTimeline;

  /// No description provided for @loadingTracking.
  ///
  /// In en, this message translates to:
  /// **'Loading tracking...'**
  String get loadingTracking;

  /// No description provided for @captainAssigned.
  ///
  /// In en, this message translates to:
  /// **'Captain assigned'**
  String get captainAssigned;

  /// No description provided for @captainOnWayToPickup.
  ///
  /// In en, this message translates to:
  /// **'Your delivery captain is on the way to pickup.'**
  String get captainOnWayToPickup;

  /// No description provided for @captainAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Captain at pickup'**
  String get captainAtPickup;

  /// No description provided for @riderReachedPickup.
  ///
  /// In en, this message translates to:
  /// **'Rider has reached the pickup point.'**
  String get riderReachedPickup;

  /// No description provided for @parcelCollected.
  ///
  /// In en, this message translates to:
  /// **'Parcel collected'**
  String get parcelCollected;

  /// No description provided for @captainCollectedParcel.
  ///
  /// In en, this message translates to:
  /// **'Captain collected your parcel. Live tracking has ended.'**
  String get captainCollectedParcel;

  /// No description provided for @parcelWithCaptain.
  ///
  /// In en, this message translates to:
  /// **'Your parcel is with the captain. Live tracking has ended.'**
  String get parcelWithCaptain;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @parcelRequestComplete.
  ///
  /// In en, this message translates to:
  /// **'Your parcel request is complete.'**
  String get parcelRequestComplete;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @parcelRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'This parcel request was cancelled.'**
  String get parcelRequestCancelled;

  /// No description provided for @findingDeliveryCaptain.
  ///
  /// In en, this message translates to:
  /// **'Finding your delivery captain'**
  String get findingDeliveryCaptain;

  /// No description provided for @bookingCreatedNotifying.
  ///
  /// In en, this message translates to:
  /// **'Booking created. Notifying nearby captains...'**
  String get bookingCreatedNotifying;

  /// No description provided for @nearestRidersGetting.
  ///
  /// In en, this message translates to:
  /// **'Nearest riders are getting this request now...'**
  String get nearestRidersGetting;

  /// No description provided for @firstRiderToAccept.
  ///
  /// In en, this message translates to:
  /// **'First rider to accept will be assigned to you.'**
  String get firstRiderToAccept;

  /// No description provided for @broadcastedToNearby.
  ///
  /// In en, this message translates to:
  /// **'Broadcasted to nearby captains...'**
  String get broadcastedToNearby;

  /// No description provided for @expectedPrice.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED PRICE'**
  String get expectedPrice;

  /// No description provided for @estimatedForDistance.
  ///
  /// In en, this message translates to:
  /// **'Estimated for about {distance} km.'**
  String estimatedForDistance(String distance);

  /// No description provided for @fastDispatch.
  ///
  /// In en, this message translates to:
  /// **'FAST DISPATCH'**
  String get fastDispatch;

  /// No description provided for @parcelSafety.
  ///
  /// In en, this message translates to:
  /// **'PARCEL SAFETY'**
  String get parcelSafety;

  /// No description provided for @cancelSearch.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelSearch;

  /// No description provided for @fare.
  ///
  /// In en, this message translates to:
  /// **'FARE'**
  String get fare;

  /// No description provided for @captainDistance.
  ///
  /// In en, this message translates to:
  /// **'CAPTAIN DISTANCE'**
  String get captainDistance;

  /// No description provided for @tripDistance.
  ///
  /// In en, this message translates to:
  /// **'TRIP DISTANCE'**
  String get tripDistance;

  /// No description provided for @deliveryCaptain.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY CAPTAIN'**
  String get deliveryCaptain;

  /// No description provided for @comingToYouDistance.
  ///
  /// In en, this message translates to:
  /// **'Coming to you · {distance}'**
  String comingToYouDistance(String distance);

  /// No description provided for @pickupOtp.
  ///
  /// In en, this message translates to:
  /// **'PICKUP OTP'**
  String get pickupOtp;

  /// No description provided for @shareOtpNotice.
  ///
  /// In en, this message translates to:
  /// **'Share this OTP only with your delivery captain when they collect the parcel.'**
  String get shareOtpNotice;

  /// No description provided for @latePickupTitle.
  ///
  /// In en, this message translates to:
  /// **'LATE PICKUP (NORMAL 30 MIN)'**
  String get latePickupTitle;

  /// No description provided for @refundRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Refund request is pending admin review. COD / fare collection stays unchanged until then.'**
  String get refundRequestPending;

  /// No description provided for @adminCreditedWallet.
  ///
  /// In en, this message translates to:
  /// **'Admin credited ₹{amount} to your wallet.'**
  String adminCreditedWallet(String amount);

  /// No description provided for @lateRefundRejected.
  ///
  /// In en, this message translates to:
  /// **'Late refund request was rejected.'**
  String get lateRefundRejected;

  /// No description provided for @captainTookLonger.
  ///
  /// In en, this message translates to:
  /// **'Captain took longer than 30 minutes. You can ask admin for a wallet refund.'**
  String get captainTookLonger;

  /// No description provided for @requestLateRefund.
  ///
  /// In en, this message translates to:
  /// **'REQUEST LATE REFUND'**
  String get requestLateRefund;

  /// No description provided for @openParcelHistory.
  ///
  /// In en, this message translates to:
  /// **'OPEN PARCEL HISTORY'**
  String get openParcelHistory;

  /// No description provided for @backToParcel.
  ///
  /// In en, this message translates to:
  /// **'BACK TO PARCEL'**
  String get backToParcel;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @failedToLoadParcel.
  ///
  /// In en, this message translates to:
  /// **'Failed to load parcel details'**
  String get failedToLoadParcel;

  /// No description provided for @searchCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Search cancelled successfully'**
  String get searchCancelledSuccess;

  /// No description provided for @unableToCancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Unable to cancel search'**
  String get unableToCancelSearch;

  /// No description provided for @lateRefundRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Late refund request sent to admin'**
  String get lateRefundRequestSent;

  /// No description provided for @unableToRequestRefund.
  ///
  /// In en, this message translates to:
  /// **'Unable to request refund'**
  String get unableToRequestRefund;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get profileSavedAddresses;

  /// No description provided for @profileWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get profileWallet;

  /// No description provided for @profileSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileSupport;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get profileAbout;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get profileTerms;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacy;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileLogoutConfirm;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSave;

  /// No description provided for @editProfileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get editProfileSuccess;

  /// No description provided for @addressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get addressesTitle;

  /// No description provided for @addressesAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addressesAddNew;

  /// No description provided for @addressesNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get addressesNoSaved;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get walletBalance;

  /// No description provided for @walletAddMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get walletAddMoney;

  /// No description provided for @walletRecentTxns.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get walletRecentTxns;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get supportTitle;

  /// No description provided for @supportFaq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get supportFaq;

  /// No description provided for @supportRaiseTicket.
  ///
  /// In en, this message translates to:
  /// **'Raise a Complaint'**
  String get supportRaiseTicket;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Chat'**
  String get chatTitle;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get chatTypeMessage;

  /// No description provided for @supportHeroTag.
  ///
  /// In en, this message translates to:
  /// **'FILE A COMPLAINT'**
  String get supportHeroTag;

  /// No description provided for @supportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell admin what went wrong'**
  String get supportHeroTitle;

  /// No description provided for @supportHeroSub.
  ///
  /// In en, this message translates to:
  /// **'Order, parcel, payment, delivery — anything. Admin will reply.'**
  String get supportHeroSub;

  /// No description provided for @supportComplaintType.
  ///
  /// In en, this message translates to:
  /// **'Complaint type'**
  String get supportComplaintType;

  /// No description provided for @supportCatOrder.
  ///
  /// In en, this message translates to:
  /// **'Order issue'**
  String get supportCatOrder;

  /// No description provided for @supportCatParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel delivery'**
  String get supportCatParcel;

  /// No description provided for @supportCatPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment / refund'**
  String get supportCatPayment;

  /// No description provided for @supportCatDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery partner'**
  String get supportCatDelivery;

  /// No description provided for @supportCatProduct.
  ///
  /// In en, this message translates to:
  /// **'Product quality'**
  String get supportCatProduct;

  /// No description provided for @supportCatRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund request'**
  String get supportCatRefund;

  /// No description provided for @supportCatApp.
  ///
  /// In en, this message translates to:
  /// **'App / technical'**
  String get supportCatApp;

  /// No description provided for @supportCatOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get supportCatOther;

  /// No description provided for @supportChatUs.
  ///
  /// In en, this message translates to:
  /// **'Chat Us'**
  String get supportChatUs;

  /// No description provided for @supportChatSub.
  ///
  /// In en, this message translates to:
  /// **'Live support'**
  String get supportChatSub;

  /// No description provided for @supportNewComplaint.
  ///
  /// In en, this message translates to:
  /// **'New Complaint'**
  String get supportNewComplaint;

  /// No description provided for @supportWriteDetails.
  ///
  /// In en, this message translates to:
  /// **'Write details'**
  String get supportWriteDetails;

  /// No description provided for @supportCallUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get supportCallUs;

  /// No description provided for @supportEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get supportEmailUs;

  /// No description provided for @supportMyComplaints.
  ///
  /// In en, this message translates to:
  /// **'My complaints'**
  String get supportMyComplaints;

  /// No description provided for @supportNoComplaints.
  ///
  /// In en, this message translates to:
  /// **'No complaints yet'**
  String get supportNoComplaints;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Delivering happiness to your doorstep in minutes.'**
  String get aboutTagline;

  /// No description provided for @aboutMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get aboutMissionTitle;

  /// No description provided for @aboutMissionDesc.
  ///
  /// In en, this message translates to:
  /// **'To revolutionize quick commerce by providing the fastest, most reliable delivery of daily essentials, ensuring quality and convenience for every household.'**
  String get aboutMissionDesc;

  /// No description provided for @aboutValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Values'**
  String get aboutValuesTitle;

  /// No description provided for @aboutVal1Title.
  ///
  /// In en, this message translates to:
  /// **'Customer First:'**
  String get aboutVal1Title;

  /// No description provided for @aboutVal1Desc.
  ///
  /// In en, this message translates to:
  /// **' Your satisfaction is our top priority.'**
  String get aboutVal1Desc;

  /// No description provided for @aboutVal2Title.
  ///
  /// In en, this message translates to:
  /// **'Quality Assurance:'**
  String get aboutVal2Title;

  /// No description provided for @aboutVal2Desc.
  ///
  /// In en, this message translates to:
  /// **' We deliver only the freshest and best products.'**
  String get aboutVal2Desc;

  /// No description provided for @aboutVal3Title.
  ///
  /// In en, this message translates to:
  /// **'Speed with Safety:'**
  String get aboutVal3Title;

  /// No description provided for @aboutVal3Desc.
  ///
  /// In en, this message translates to:
  /// **' Fast delivery without compromising on safety standards.'**
  String get aboutVal3Desc;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 SunGguard. All rights reserved.'**
  String get aboutCopyright;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: Oct 2025'**
  String get privacyUpdated;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'At SunGguard, we take your privacy seriously. This Privacy Policy explains how we collect, use, and protect your personal information.'**
  String get privacyIntro;

  /// No description provided for @privacyS1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get privacyS1Title;

  /// No description provided for @privacyS1Desc.
  ///
  /// In en, this message translates to:
  /// **'We collect information you provide directly, such as your name, address, phone number, and payment details. We also collect usage data automatically.'**
  String get privacyS1Desc;

  /// No description provided for @privacyS2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Information'**
  String get privacyS2Title;

  /// No description provided for @privacyS2Desc.
  ///
  /// In en, this message translates to:
  /// **'We use your data to process orders, improve our services, and communicate with you about promotions and updates.'**
  String get privacyS2Desc;

  /// No description provided for @privacyS3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Security'**
  String get privacyS3Title;

  /// No description provided for @privacyS3Desc.
  ///
  /// In en, this message translates to:
  /// **'We implement industry-standard security measures to protect your data. However, no method of transmission is 100% secure.'**
  String get privacyS3Desc;

  /// No description provided for @privacyS4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Sharing of Information'**
  String get privacyS4Title;

  /// No description provided for @privacyS4Desc.
  ///
  /// In en, this message translates to:
  /// **'We do not sell your personal data. We may share data with service providers (e.g., delivery partners) as necessary to fulfill your orders.'**
  String get privacyS4Desc;

  /// No description provided for @privacyS5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Rights'**
  String get privacyS5Title;

  /// No description provided for @privacyS5Desc.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access, correct, or delete your personal data. Contact our support team for assistance.'**
  String get privacyS5Desc;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsTitle;

  /// No description provided for @termsUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsUseTitle;

  /// No description provided for @termsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: Oct 2025'**
  String get termsUpdated;

  /// No description provided for @termsIntro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SunGguard. By accessing or using our mobile application and services, you agree to be bound by these Terms and Conditions.'**
  String get termsIntro;

  /// No description provided for @termsS1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsS1Title;

  /// No description provided for @termsS1Desc.
  ///
  /// In en, this message translates to:
  /// **'By creating an account or using our services, you agree to comply with these terms. If you do not agree, you may not use our services.'**
  String get termsS1Desc;

  /// No description provided for @termsS2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Use of Service'**
  String get termsS2Title;

  /// No description provided for @termsS2Desc.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to use our services. You agree to provide accurate information during registration and to keep your account secure.'**
  String get termsS2Desc;

  /// No description provided for @termsS3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Orders and Payments'**
  String get termsS3Title;

  /// No description provided for @termsS3Desc.
  ///
  /// In en, this message translates to:
  /// **'All orders are subject to availability. Prices are subject to change without notice. We reserve the right to cancel orders at our discretion.'**
  String get termsS3Desc;

  /// No description provided for @termsS4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Intellectual Property'**
  String get termsS4Title;

  /// No description provided for @termsS4Desc.
  ///
  /// In en, this message translates to:
  /// **'All content, trademarks, and data on this app are the property of SunGguard and are protected by law.'**
  String get termsS4Desc;

  /// No description provided for @termsS5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Termination'**
  String get termsS5Title;

  /// No description provided for @termsS5Desc.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to end or suspend your account at any time for violation of these terms.'**
  String get termsS5Desc;

  /// No description provided for @addrEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get addrEditTitle;

  /// No description provided for @addrAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addrAddTitle;

  /// No description provided for @addrEditSub.
  ///
  /// In en, this message translates to:
  /// **'Update your delivery details.'**
  String get addrEditSub;

  /// No description provided for @addrAddSub.
  ///
  /// In en, this message translates to:
  /// **'Enter your delivery details below.'**
  String get addrAddSub;

  /// No description provided for @addrType.
  ///
  /// In en, this message translates to:
  /// **'Address Type'**
  String get addrType;

  /// No description provided for @addrTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addrTypeHome;

  /// No description provided for @addrTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addrTypeWork;

  /// No description provided for @addrTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addrTypeOther;

  /// No description provided for @addrLandmarkOpt.
  ///
  /// In en, this message translates to:
  /// **'Nearest Landmark (optional)'**
  String get addrLandmarkOpt;

  /// No description provided for @addrCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addrCity;

  /// No description provided for @addrState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get addrState;

  /// No description provided for @addrPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get addrPincode;

  /// No description provided for @addrUpdateBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Address'**
  String get addrUpdateBtn;

  /// No description provided for @addrSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get addrSaveBtn;

  /// No description provided for @addrDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Address?'**
  String get addrDeleteTitle;

  /// No description provided for @addrDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address? This action cannot be undone.'**
  String get addrDeleteConfirm;

  /// No description provided for @editPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get editPhotoTitle;

  /// No description provided for @editPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get editPhotoCamera;

  /// No description provided for @editPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get editPhotoGallery;

  /// No description provided for @complaintFileTitle.
  ///
  /// In en, this message translates to:
  /// **'File a complaint'**
  String get complaintFileTitle;

  /// No description provided for @complaintFileSub.
  ///
  /// In en, this message translates to:
  /// **'Admin will see this and can reply'**
  String get complaintFileSub;

  /// No description provided for @complaintCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get complaintCategoryLabel;

  /// No description provided for @complaintSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'SUBJECT'**
  String get complaintSubjectLabel;

  /// No description provided for @complaintSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of your complaint'**
  String get complaintSubjectHint;

  /// No description provided for @complaintPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get complaintPriorityLabel;

  /// No description provided for @complaintHappenedLabel.
  ///
  /// In en, this message translates to:
  /// **'WHAT HAPPENED?'**
  String get complaintHappenedLabel;

  /// No description provided for @complaintHappenedHint.
  ///
  /// In en, this message translates to:
  /// **'Explain your complaint clearly. Include order/parcel details if useful.'**
  String get complaintHappenedHint;

  /// No description provided for @complaintSubmitBtn.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT TO ADMIN'**
  String get complaintSubmitBtn;

  /// No description provided for @statusRequested.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get statusRequested;

  /// No description provided for @statusSearching.
  ///
  /// In en, this message translates to:
  /// **'Finding Rider'**
  String get statusSearching;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Rider Assigned'**
  String get statusAccepted;

  /// No description provided for @statusRiderAssigned.
  ///
  /// In en, this message translates to:
  /// **'On The Way'**
  String get statusRiderAssigned;

  /// No description provided for @statusPickupReached.
  ///
  /// In en, this message translates to:
  /// **'At Your Door'**
  String get statusPickupReached;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get statusPickedUp;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusOutForDelivery;

  /// No description provided for @statusDropReached.
  ///
  /// In en, this message translates to:
  /// **'At The Drop'**
  String get statusDropReached;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t Deliver'**
  String get statusDeliveryFailed;

  /// No description provided for @statusReturnInTransit.
  ///
  /// In en, this message translates to:
  /// **'Coming Back'**
  String get statusReturnInTransit;

  /// No description provided for @statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned To You'**
  String get statusReturned;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @milestoneBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get milestoneBooked;

  /// No description provided for @milestoneRiderAssigned.
  ///
  /// In en, this message translates to:
  /// **'Rider assigned'**
  String get milestoneRiderAssigned;

  /// No description provided for @milestoneCollectedFromYou.
  ///
  /// In en, this message translates to:
  /// **'Collected from you'**
  String get milestoneCollectedFromYou;

  /// No description provided for @milestoneOnWayToDrop.
  ///
  /// In en, this message translates to:
  /// **'On the way to drop'**
  String get milestoneOnWayToDrop;

  /// No description provided for @milestoneHandedToReceiver.
  ///
  /// In en, this message translates to:
  /// **'Handed to receiver'**
  String get milestoneHandedToReceiver;

  /// No description provided for @consignmentNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Consignment Note'**
  String get consignmentNoteTitle;

  /// No description provided for @copyOne.
  ///
  /// In en, this message translates to:
  /// **'Copy 1'**
  String get copyOne;

  /// No description provided for @yourNumber.
  ///
  /// In en, this message translates to:
  /// **'Your Number'**
  String get yourNumber;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @codeForRider.
  ///
  /// In en, this message translates to:
  /// **'Code for the rider'**
  String get codeForRider;

  /// No description provided for @codeToTakeBack.
  ///
  /// In en, this message translates to:
  /// **'Code to take it back'**
  String get codeToTakeBack;

  /// No description provided for @sendMeCode.
  ///
  /// In en, this message translates to:
  /// **'Send me the code'**
  String get sendMeCode;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @awaitingPickupVerification.
  ///
  /// In en, this message translates to:
  /// **'Awaiting pickup verification'**
  String get awaitingPickupVerification;

  /// No description provided for @returningToSender.
  ///
  /// In en, this message translates to:
  /// **'Returning to sender · awaiting verification'**
  String get returningToSender;

  /// No description provided for @tapCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap below and we\'ll text you a code. Read it out to the rider — never send it to anyone else.'**
  String get tapCodeInstructions;

  /// No description provided for @weCouldNotHandOver.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t hand it over'**
  String get weCouldNotHandOver;

  /// No description provided for @deliveryFailedPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'The delivery didn\'t go through. The rider still has your parcel — tell us what to do.'**
  String get deliveryFailedPromptDesc;

  /// No description provided for @failOptionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get failOptionTryAgain;

  /// No description provided for @failOptionTryAgainHint.
  ///
  /// In en, this message translates to:
  /// **'Same address, one more attempt'**
  String get failOptionTryAgainHint;

  /// No description provided for @failOptionRelease.
  ///
  /// In en, this message translates to:
  /// **'Let anyone collect'**
  String get failOptionRelease;

  /// No description provided for @failOptionReleaseHint.
  ///
  /// In en, this message translates to:
  /// **'Whoever is at the address can take it'**
  String get failOptionReleaseHint;

  /// No description provided for @failOptionReturn.
  ///
  /// In en, this message translates to:
  /// **'Bring it back to me'**
  String get failOptionReturn;

  /// No description provided for @failOptionReturnHint.
  ///
  /// In en, this message translates to:
  /// **'Returns to your pickup address'**
  String get failOptionReturnHint;

  /// No description provided for @routeTitle.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeTitle;

  /// No description provided for @routeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get routeFrom;

  /// No description provided for @routeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get routeTo;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @cancelThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking'**
  String get cancelThisBooking;

  /// No description provided for @couldNotLoadParcel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this parcel'**
  String get couldNotLoadParcel;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'LIVE TRACKING'**
  String get liveTracking;

  /// No description provided for @trackingEnded.
  ///
  /// In en, this message translates to:
  /// **'TRACKING ENDED'**
  String get trackingEnded;

  /// No description provided for @parcelPickup.
  ///
  /// In en, this message translates to:
  /// **'PARCEL PICKUP'**
  String get parcelPickup;

  /// No description provided for @captainIsDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'Captain is {distance}'**
  String captainIsDistanceAway(String distance);

  /// No description provided for @captainIsOnWay.
  ///
  /// In en, this message translates to:
  /// **'Captain is on the way'**
  String get captainIsOnWay;

  /// No description provided for @parcelHandedToCaptain.
  ///
  /// In en, this message translates to:
  /// **'Parcel handed to captain'**
  String get parcelHandedToCaptain;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @statusPillFindingRider.
  ///
  /// In en, this message translates to:
  /// **'FINDING RIDER'**
  String get statusPillFindingRider;

  /// No description provided for @statusPillRiderAssigned.
  ///
  /// In en, this message translates to:
  /// **'RIDER ASSIGNED'**
  String get statusPillRiderAssigned;

  /// No description provided for @statusPillCollected.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get statusPillCollected;

  /// No description provided for @statusPillOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'ON THE WAY'**
  String get statusPillOnTheWay;

  /// No description provided for @statusPillDelivered.
  ///
  /// In en, this message translates to:
  /// **'DELIVERED'**
  String get statusPillDelivered;

  /// No description provided for @statusPillCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get statusPillCancelled;

  /// No description provided for @statusPillFailed.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get statusPillFailed;

  /// No description provided for @waybillIdHeader.
  ///
  /// In en, this message translates to:
  /// **'WAYBILL ID'**
  String get waybillIdHeader;

  /// No description provided for @estimatedHeader.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED'**
  String get estimatedHeader;

  /// No description provided for @completedHeader.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedHeader;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportWaybillData.
  ///
  /// In en, this message translates to:
  /// **'Export Waybill Data'**
  String get exportWaybillData;

  /// No description provided for @exportFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Export & Filter Waybills'**
  String get exportFilterTitle;

  /// No description provided for @selectStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'SELECT STATUS FILTER'**
  String get selectStatusFilter;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'ALL STATUSES'**
  String get allStatuses;

  /// No description provided for @quickSelect.
  ///
  /// In en, this message translates to:
  /// **'QUICK SELECT'**
  String get quickSelect;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'FROM DATE'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'TO DATE'**
  String get toDate;

  /// No description provided for @waybillsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} Waybills Found'**
  String waybillsFound(int count);

  /// No description provided for @noWaybillsFound.
  ///
  /// In en, this message translates to:
  /// **'No Records Found'**
  String get noWaybillsFound;

  /// No description provided for @matchingDateFilters.
  ///
  /// In en, this message translates to:
  /// **'Matching selected date range & filters'**
  String get matchingDateFilters;

  /// No description provided for @tryWiderDateRange.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a wider date range'**
  String get tryWiderDateRange;

  /// No description provided for @downloadExcel.
  ///
  /// In en, this message translates to:
  /// **'Download Excel'**
  String get downloadExcel;

  /// No description provided for @excel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get excel;

  /// No description provided for @filteredWaybills.
  ///
  /// In en, this message translates to:
  /// **'FILTERED WAYBILLS ({count})'**
  String filteredWaybills(int count);

  /// No description provided for @showingLiveResults.
  ///
  /// In en, this message translates to:
  /// **'Showing Live Results'**
  String get showingLiveResults;

  /// No description provided for @noMatchingWaybills.
  ///
  /// In en, this message translates to:
  /// **'No matching waybills'**
  String get noMatchingWaybills;

  /// No description provided for @tryWiderOrAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a wider date range or switch to \"All Statuses\".'**
  String get tryWiderOrAllStatuses;

  /// No description provided for @excelSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excel file saved successfully!'**
  String get excelSavedSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @fromDateAfterToDate.
  ///
  /// In en, this message translates to:
  /// **'From Date cannot be after To Date'**
  String get fromDateAfterToDate;

  /// No description provided for @draftWaybill.
  ///
  /// In en, this message translates to:
  /// **'DRAFT WAYBILL'**
  String get draftWaybill;

  /// No description provided for @estimate.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATE'**
  String get estimate;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'PRICING...'**
  String get pricing;

  /// No description provided for @stepFrom.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get stepFrom;

  /// No description provided for @stepTo.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get stepTo;

  /// No description provided for @stepWhat.
  ///
  /// In en, this message translates to:
  /// **'WHAT'**
  String get stepWhat;

  /// No description provided for @stepPay.
  ///
  /// In en, this message translates to:
  /// **'PAY'**
  String get stepPay;

  /// No description provided for @stepQuestionCollect.
  ///
  /// In en, this message translates to:
  /// **'Where do we collect it?'**
  String get stepQuestionCollect;

  /// No description provided for @stepQuestionGoing.
  ///
  /// In en, this message translates to:
  /// **'Where is it going?'**
  String get stepQuestionGoing;

  /// No description provided for @stepQuestionCarrying.
  ///
  /// In en, this message translates to:
  /// **'What are we carrying?'**
  String get stepQuestionCarrying;

  /// No description provided for @stepQuestionPay.
  ///
  /// In en, this message translates to:
  /// **'How would you like to pay?'**
  String get stepQuestionPay;

  /// No description provided for @searchAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Search for an area, building or landmark'**
  String get searchAddressHint;

  /// No description provided for @senderLabel.
  ///
  /// In en, this message translates to:
  /// **'SENDER'**
  String get senderLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get phoneLabel;

  /// No description provided for @houseFlatFloor.
  ///
  /// In en, this message translates to:
  /// **'HOUSE / FLAT / FLOOR'**
  String get houseFlatFloor;

  /// No description provided for @houseFlatHint.
  ///
  /// In en, this message translates to:
  /// **'House or Flat number'**
  String get houseFlatHint;

  /// No description provided for @houseHelperText.
  ///
  /// In en, this message translates to:
  /// **'The map gets us to the building; this gets us to the door.'**
  String get houseHelperText;

  /// No description provided for @landmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'LANDMARK'**
  String get landmarkLabel;

  /// No description provided for @landmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby landmark'**
  String get landmarkHint;

  /// No description provided for @landmarkHelperText.
  ///
  /// In en, this message translates to:
  /// **'Optional, but riders find you faster with one.'**
  String get landmarkHelperText;

  /// No description provided for @receiverLabel.
  ///
  /// In en, this message translates to:
  /// **'RECEIVER'**
  String get receiverLabel;

  /// No description provided for @recipientPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'RECIPIENT PHONE'**
  String get recipientPhoneLabel;

  /// No description provided for @packageCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'PACKAGE CATEGORY'**
  String get packageCategoryLabel;

  /// No description provided for @packageWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT (KG)'**
  String get packageWeightLabel;

  /// No description provided for @weightHint.
  ///
  /// In en, this message translates to:
  /// **'0.5'**
  String get weightHint;

  /// No description provided for @weightHelperText.
  ///
  /// In en, this message translates to:
  /// **'Max 20kg for city deliveries.'**
  String get weightHelperText;

  /// No description provided for @itemDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'ITEM DESCRIPTION'**
  String get itemDescriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Important office documents, house keys'**
  String get descriptionHint;

  /// No description provided for @anyoneCanCollect.
  ///
  /// In en, this message translates to:
  /// **'Anyone at delivery address can collect'**
  String get anyoneCanCollect;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get paymentMethodLabel;

  /// No description provided for @upiPayment.
  ///
  /// In en, this message translates to:
  /// **'UPI / QR Code'**
  String get upiPayment;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get cardPayment;

  /// No description provided for @codPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery (COD)'**
  String get codPayment;

  /// No description provided for @nextRecipient.
  ///
  /// In en, this message translates to:
  /// **'NEXT: RECIPIENT'**
  String get nextRecipient;

  /// No description provided for @nextPackageDetails.
  ///
  /// In en, this message translates to:
  /// **'NEXT: PACKAGE DETAILS'**
  String get nextPackageDetails;

  /// No description provided for @reviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'REVIEW & PAY'**
  String get reviewAndPay;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM & PAY {amount}'**
  String confirmAndPay(String amount);

  /// No description provided for @catDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get catDocuments;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get catClothes;

  /// No description provided for @catElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get catElectronics;

  /// No description provided for @catMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get catMedicine;

  /// No description provided for @catSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get catSomethingElse;

  /// No description provided for @outstationMastheadTag.
  ///
  /// In en, this message translates to:
  /// **'COURIER DROP-OFF · UP TO 1 KG'**
  String get outstationMastheadTag;

  /// No description provided for @outstationMastheadTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the courier\ncounter queue.'**
  String get outstationMastheadTitle;

  /// No description provided for @outstationMastheadSub.
  ///
  /// In en, this message translates to:
  /// **'A rider collects your parcel from your door and hands it to the courier company you choose. You fill this waybill once.'**
  String get outstationMastheadSub;

  /// No description provided for @outstationStep0Title.
  ///
  /// In en, this message translates to:
  /// **'Pickup location & sender details'**
  String get outstationStep0Title;

  /// No description provided for @outstationStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Courier company & destination'**
  String get outstationStep1Title;

  /// No description provided for @outstationStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Package details & weight'**
  String get outstationStep2Title;

  /// No description provided for @outstationStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Review charges & pay'**
  String get outstationStep3Title;

  /// No description provided for @selectPackageCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Package Category'**
  String get selectPackageCategoryTitle;

  /// No description provided for @nextCourier.
  ///
  /// In en, this message translates to:
  /// **'NEXT: COURIER & DESTINATION'**
  String get nextCourier;

  /// No description provided for @nextPackage.
  ///
  /// In en, this message translates to:
  /// **'NEXT: PACKAGE DETAILS'**
  String get nextPackage;

  /// No description provided for @nextReviewPay.
  ///
  /// In en, this message translates to:
  /// **'NEXT: REVIEW & PAY'**
  String get nextReviewPay;

  /// No description provided for @payAndShipNow.
  ///
  /// In en, this message translates to:
  /// **'PAY & SHIP NOW'**
  String get payAndShipNow;

  /// No description provided for @personalParcel.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL PARCEL'**
  String get personalParcel;

  /// No description provided for @businessShipment.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS SHIPMENT'**
  String get businessShipment;

  /// No description provided for @pickupAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'PICKUP HOUSE / STREET ADDRESS'**
  String get pickupAddressLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get cityLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'STATE'**
  String get stateLabel;

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'PINCODE'**
  String get pincodeLabel;

  /// No description provided for @destinationCityLabel.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION CITY'**
  String get destinationCityLabel;

  /// No description provided for @courierPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'COURIER PARTNER'**
  String get courierPartnerLabel;

  /// No description provided for @expressDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPRESS DELIVERY'**
  String get expressDeliveryLabel;

  /// No description provided for @standardDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'STANDARD DELIVERY'**
  String get standardDeliveryLabel;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred app language. The app will update immediately.'**
  String get selectLanguageSubtitle;

  /// No description provided for @selectLanguageItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select {language} language'**
  String selectLanguageItemSubtitle(String language);

  /// No description provided for @switchLanguageNotice.
  ///
  /// In en, this message translates to:
  /// **'You can switch back your preferred language anytime from Profile Settings.'**
  String get switchLanguageNotice;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'You will see updates about your bookings, deliveries, and account here.'**
  String get noNotificationsDesc;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'as',
    'bn',
    'brx',
    'doi',
    'en',
    'gu',
    'hi',
    'kn',
    'kok',
    'ks',
    'mai',
    'ml',
    'mni',
    'mr',
    'ne',
    'or',
    'pa',
    'sa',
    'sat',
    'sd',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'brx':
      return AppLocalizationsBrx();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'kok':
      return AppLocalizationsKok();
    case 'ks':
      return AppLocalizationsKs();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'sa':
      return AppLocalizationsSa();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
