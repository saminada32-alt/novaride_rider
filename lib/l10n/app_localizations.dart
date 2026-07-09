import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'NovaRide'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NovaRide Rider App'**
  String get splashSubtitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NovaRide'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your ride is just a tap away.'**
  String get welcomeSubtitle;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_title;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get otpSubtitle;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get otpHint;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resend;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend ({seconds})'**
  String resendIn(int seconds);

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @failedToSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code'**
  String get failedToSendOtp;

  /// No description provided for @invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid server response'**
  String get invalidResponse;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @otpError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete verification code'**
  String get otpError;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue'**
  String get loginSubtitle;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidOtp;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullName;

  /// No description provided for @registerEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get registerEmailOptional;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get registerPhone;

  /// No description provided for @registerAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to '**
  String get registerAgree;

  /// No description provided for @registerPolicies.
  ///
  /// In en, this message translates to:
  /// **'I agree to Privacy Policy & Terms of Use'**
  String get registerPolicies;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @policiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy & Terms of Use'**
  String get policiesTitle;

  /// No description provided for @policiesFullText.
  ///
  /// In en, this message translates to:
  /// **'Paste the full legal text here'**
  String get policiesFullText;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDate;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get termsAgreement;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @introTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NovaRide!'**
  String get introTitle;

  /// No description provided for @introSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re excited to have you onboard. Get ready for fast, safe and comfortable rides.'**
  String get introSubtitle;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @legalText.
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Terms and Privacy Policy.'**
  String get legalText;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let’s go places'**
  String get letsGo;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @rideNow.
  ///
  /// In en, this message translates to:
  /// **'Ride now'**
  String get rideNow;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @mall.
  ///
  /// In en, this message translates to:
  /// **'Mall'**
  String get mall;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @enterPromo.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterPromo;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @myRides.
  ///
  /// In en, this message translates to:
  /// **'My rides'**
  String get myRides;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get searchDestination;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @van.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get van;

  /// No description provided for @taxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get taxi;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @expenseYourRides.
  ///
  /// In en, this message translates to:
  /// **'Expense Your Rides'**
  String get expenseYourRides;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personalInfo;

  /// No description provided for @familyProfile.
  ///
  /// In en, this message translates to:
  /// **'Family profile'**
  String get familyProfile;

  /// No description provided for @loginSecurity.
  ///
  /// In en, this message translates to:
  /// **'Login & security'**
  String get loginSecurity;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlaces;

  /// No description provided for @addHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Add home address'**
  String get addHomeAddress;

  /// No description provided for @addWorkAddress.
  ///
  /// In en, this message translates to:
  /// **'Add work address'**
  String get addWorkAddress;

  /// No description provided for @addPlace.
  ///
  /// In en, this message translates to:
  /// **'+ Add a place'**
  String get addPlace;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @communicationPrefs.
  ///
  /// In en, this message translates to:
  /// **'Communication preferences'**
  String get communicationPrefs;

  /// No description provided for @calendars.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get calendars;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get wallet;

  /// No description provided for @shamCash.
  ///
  /// In en, this message translates to:
  /// **'Sham Cash'**
  String get shamCash;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterPromoCode;

  /// No description provided for @availablePromotions.
  ///
  /// In en, this message translates to:
  /// **'Available promotions'**
  String get availablePromotions;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @currencySYP.
  ///
  /// In en, this message translates to:
  /// **'SYP'**
  String get currencySYP;

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'0 SYP'**
  String get balanceAmount;

  /// No description provided for @whatIsBalance.
  ///
  /// In en, this message translates to:
  /// **'What is balance?'**
  String get whatIsBalance;

  /// No description provided for @balanceExplanation.
  ///
  /// In en, this message translates to:
  /// **'Balance is the amount available in your account to pay for rides.'**
  String get balanceExplanation;

  /// No description provided for @seeBalanceTransactions.
  ///
  /// In en, this message translates to:
  /// **'See balance transactions'**
  String get seeBalanceTransactions;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add debit/credit card'**
  String get addCard;

  /// No description provided for @workProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up work profile'**
  String get workProfile;

  /// No description provided for @workProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up a work profile to receive ride payments on your business account.'**
  String get workProfileDesc;

  /// No description provided for @balanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Balance is an in-app virtual payment method used to pay for products.'**
  String get balanceDesc;

  /// No description provided for @howToTopUp.
  ///
  /// In en, this message translates to:
  /// **'How do I top up my balance?'**
  String get howToTopUp;

  /// No description provided for @topUpExplanation.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, you can’t currently top up your balance in your location if you have a zero or positive balance. We’re working on it!\n\nIf you have a negative balance, you can use debit or credit cards (MasterCard, Visa, American Express), cash, Sham Cash, PayPal, Bancontact, iDeal, Diners Club, M-Pesa, and JCB to settle your balance.\n\nYour balance can also be topped up via refunds.'**
  String get topUpExplanation;

  /// No description provided for @howToUseBalance.
  ///
  /// In en, this message translates to:
  /// **'How do I use it?'**
  String get howToUseBalance;

  /// No description provided for @howToUseBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Your balance is automatically applied to your order. If your balance reaches zero, another payment method will be used to cover the remaining cost.'**
  String get howToUseBalanceDesc;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faq;

  /// No description provided for @whyNegativeBalance.
  ///
  /// In en, this message translates to:
  /// **'Why is my balance negative?'**
  String get whyNegativeBalance;

  /// No description provided for @whyNegativeBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Your balance may be negative if a previous payment failed. You can settle it by placing a new order or using an available payment method.'**
  String get whyNegativeBalanceDesc;

  /// No description provided for @someoneToppedUp.
  ///
  /// In en, this message translates to:
  /// **'Someone already topped up my balance'**
  String get someoneToppedUp;

  /// No description provided for @someoneToppedUpDesc.
  ///
  /// In en, this message translates to:
  /// **'Our support team may have issued you a refund for a previous order.'**
  String get someoneToppedUpDesc;

  /// No description provided for @balanceExpire.
  ///
  /// In en, this message translates to:
  /// **'Can my balance expire?'**
  String get balanceExpire;

  /// No description provided for @balanceExpireDesc.
  ///
  /// In en, this message translates to:
  /// **'Balance earned as cashback may expire. Balance added in other ways does not expire.'**
  String get balanceExpireDesc;

  /// No description provided for @withdrawBalance.
  ///
  /// In en, this message translates to:
  /// **'Can I withdraw my balance?'**
  String get withdrawBalance;

  /// No description provided for @withdrawBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'No. Balance can be used for payments but cannot be withdrawn.'**
  String get withdrawBalanceDesc;

  /// No description provided for @settleBalance.
  ///
  /// In en, this message translates to:
  /// **'Which payment methods can I use to settle my balance?'**
  String get settleBalance;

  /// No description provided for @settleBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'You can use bank cards or mobile wallets. More payment methods are coming soon.'**
  String get settleBalanceDesc;

  /// No description provided for @balanceCurrency.
  ///
  /// In en, this message translates to:
  /// **'Why did my balance change in another country?'**
  String get balanceCurrency;

  /// No description provided for @balanceCurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your balance uses the currency of the country you’re currently in. Balances in other currencies will be available when you return.'**
  String get balanceCurrencyDesc;

  /// No description provided for @onProgress.
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get onProgress;

  /// No description provided for @scheduledRidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Rides - made for your convenience'**
  String get scheduledRidesTitle;

  /// No description provided for @scheduledRidesDesc.
  ///
  /// In en, this message translates to:
  /// **'There\'s no need to stress whether you\'ll get a ride, plan ahead of time and enjoy the peace of mind.'**
  String get scheduledRidesDesc;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @noPastRides.
  ///
  /// In en, this message translates to:
  /// **'You don’t have any ride yet'**
  String get noPastRides;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @noUpcomingRides.
  ///
  /// In en, this message translates to:
  /// **'No upcoming rides'**
  String get noUpcomingRides;

  /// No description provided for @upcomingRidesDesc.
  ///
  /// In en, this message translates to:
  /// **'Whatever is on your schedule, a Scheduled Ride can get you there on time'**
  String get upcomingRidesDesc;

  /// No description provided for @learnHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Learn how it works'**
  String get learnHowItWorks;

  /// No description provided for @scheduleTitle1.
  ///
  /// In en, this message translates to:
  /// **'Ideal for any occasion'**
  String get scheduleTitle1;

  /// No description provided for @scheduleDesc1.
  ///
  /// In en, this message translates to:
  /// **'Dinner reservations? Doctor\'s appointment? Schedule a ride and arrive on time.'**
  String get scheduleDesc1;

  /// No description provided for @scheduleTitle2.
  ///
  /// In en, this message translates to:
  /// **'Peace of mind anywhere you go'**
  String get scheduleTitle2;

  /// No description provided for @scheduleDesc2.
  ///
  /// In en, this message translates to:
  /// **'Traveling abroad? Book rides up to 90 days in advance! Plan your trip stress-free!'**
  String get scheduleDesc2;

  /// No description provided for @scheduleTitle3.
  ///
  /// In en, this message translates to:
  /// **'Flexibility guaranteed'**
  String get scheduleTitle3;

  /// No description provided for @scheduleDesc3.
  ///
  /// In en, this message translates to:
  /// **'Cancel your ride free of charge up to 60 minutes before pickup.'**
  String get scheduleDesc3;

  /// No description provided for @scheduleTitle4.
  ///
  /// In en, this message translates to:
  /// **'Stress-free planning'**
  String get scheduleTitle4;

  /// No description provided for @scheduleDesc4.
  ///
  /// In en, this message translates to:
  /// **'No need to worry whether you\'ll find a ride in time. Just book ahead and we\'ll handle the rest.'**
  String get scheduleDesc4;

  /// No description provided for @scheduleRideButton.
  ///
  /// In en, this message translates to:
  /// **'Schedule a ride'**
  String get scheduleRideButton;

  /// No description provided for @idealForOccasion.
  ///
  /// In en, this message translates to:
  /// **'Ideal for any occasion'**
  String get idealForOccasion;

  /// No description provided for @idealForOccasionDesc.
  ///
  /// In en, this message translates to:
  /// **'Dinner reservations? Doctor\'s appointment?\nSchedule a ride and arrive on time.'**
  String get idealForOccasionDesc;

  /// No description provided for @peaceOfMind.
  ///
  /// In en, this message translates to:
  /// **'Peace of mind anywhere you go'**
  String get peaceOfMind;

  /// No description provided for @peaceOfMindDesc.
  ///
  /// In en, this message translates to:
  /// **'Traveling abroad? Book rides up to 90 days in advance!'**
  String get peaceOfMindDesc;

  /// No description provided for @planStressFree.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip stress-free!'**
  String get planStressFree;

  /// No description provided for @planStressFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'No need to worry whether you\'ll find a ride in time.\nJust book ahead and we\'ll handle the rest.'**
  String get planStressFreeDesc;

  /// No description provided for @flexibilityGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'Flexibility guaranteed'**
  String get flexibilityGuaranteed;

  /// No description provided for @flexibilityGuaranteedDesc.
  ///
  /// In en, this message translates to:
  /// **'Cancel your ride free of charge up to 60 minutes before pickup.'**
  String get flexibilityGuaranteedDesc;

  /// No description provided for @scheduleRide.
  ///
  /// In en, this message translates to:
  /// **'Schedule a ride'**
  String get scheduleRide;

  /// No description provided for @scheduleRideComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Scheduling rides feature coming soon!'**
  String get scheduleRideComingSoon;

  /// No description provided for @driverVerification.
  ///
  /// In en, this message translates to:
  /// **'Driver verification'**
  String get driverVerification;

  /// No description provided for @driverVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'All drivers are verified and identity-matched.'**
  String get driverVerificationDesc;

  /// No description provided for @emergencyAssistance.
  ///
  /// In en, this message translates to:
  /// **'Emergency assistance'**
  String get emergencyAssistance;

  /// No description provided for @emergencyAssistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'In-app emergency button for quick contact with authorities.'**
  String get emergencyAssistanceDesc;

  /// No description provided for @rideSafety.
  ///
  /// In en, this message translates to:
  /// **'Ride safety'**
  String get rideSafety;

  /// No description provided for @rideSafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Ensuring seatbelts and safety measures during the ride.'**
  String get rideSafetyDesc;

  /// No description provided for @safeBehavior.
  ///
  /// In en, this message translates to:
  /// **'Safe behavior'**
  String get safeBehavior;

  /// No description provided for @safeBehaviorDesc.
  ///
  /// In en, this message translates to:
  /// **'Guidelines for passengers and drivers on safe behavior during the ride.'**
  String get safeBehaviorDesc;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @contactSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick contact with support for any suspicious or emergency situation.'**
  String get contactSupportDesc;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssue;

  /// No description provided for @complaintTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem type'**
  String get complaintTypeTitle;

  /// No description provided for @complaintDescTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get complaintDescTitle;

  /// No description provided for @complaintDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue in detail...'**
  String get complaintDescHint;

  /// No description provided for @complaintSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit complaint'**
  String get complaintSubmit;

  /// No description provided for @complaintSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted'**
  String get complaintSuccessTitle;

  /// No description provided for @complaintSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'We will respond within 24 hours'**
  String get complaintSuccessBody;

  /// No description provided for @complaintOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get complaintOk;

  /// No description provided for @complaintError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your request'**
  String get complaintError;

  /// No description provided for @complaintTypeDriver.
  ///
  /// In en, this message translates to:
  /// **'Issue with driver'**
  String get complaintTypeDriver;

  /// No description provided for @complaintTypePassenger.
  ///
  /// In en, this message translates to:
  /// **'Issue with passenger'**
  String get complaintTypePassenger;

  /// No description provided for @complaintTypeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical issue'**
  String get complaintTypeTechnical;

  /// No description provided for @complaintTypeBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing issue'**
  String get complaintTypeBilling;

  /// No description provided for @complaintTypeSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety issue'**
  String get complaintTypeSafety;

  /// No description provided for @whatsappUs.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappUs;

  /// No description provided for @whatsappUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Chat with us on WhatsApp'**
  String get whatsappUsDesc;

  /// No description provided for @supportDesc.
  ///
  /// In en, this message translates to:
  /// **'We’re here to help you anytime, anywhere.'**
  String get supportDesc;

  /// No description provided for @chatWithUs.
  ///
  /// In en, this message translates to:
  /// **'Chat with us'**
  String get chatWithUs;

  /// No description provided for @chatWithUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a live chat with our support team.'**
  String get chatWithUsDesc;

  /// No description provided for @chatComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat feature coming soon!'**
  String get chatComingSoon;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get callUs;

  /// No description provided for @callUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Call our support hotline.'**
  String get callUsDesc;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get emailUs;

  /// No description provided for @emailUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Send us an email and we’ll respond promptly.'**
  String get emailUsDesc;

  /// No description provided for @faqDesc.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions.'**
  String get faqDesc;

  /// No description provided for @faqComingSoon.
  ///
  /// In en, this message translates to:
  /// **'FAQ page coming soon!'**
  String get faqComingSoon;

  /// No description provided for @supportFooter.
  ///
  /// In en, this message translates to:
  /// **'Your safety and satisfaction are our top priority.'**
  String get supportFooter;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get faqTitle;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find quick answers to the most common questions'**
  String get faqSubtitle;

  /// No description provided for @faqPaymentQ.
  ///
  /// In en, this message translates to:
  /// **'How do I pay for a ride?'**
  String get faqPaymentQ;

  /// No description provided for @faqPaymentA.
  ///
  /// In en, this message translates to:
  /// **'You can pay using cash, card, or your in-app balance.'**
  String get faqPaymentA;

  /// No description provided for @faqScheduleQ.
  ///
  /// In en, this message translates to:
  /// **'How do scheduled rides work?'**
  String get faqScheduleQ;

  /// No description provided for @faqScheduleA.
  ///
  /// In en, this message translates to:
  /// **'You can book a ride up to 90 days in advance and arrive on time.'**
  String get faqScheduleA;

  /// No description provided for @faqCancelQ.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel a ride?'**
  String get faqCancelQ;

  /// No description provided for @faqCancelA.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can cancel for free up to 60 minutes before pickup.'**
  String get faqCancelA;

  /// No description provided for @faqSafetyQ.
  ///
  /// In en, this message translates to:
  /// **'Is my ride safe?'**
  String get faqSafetyQ;

  /// No description provided for @faqSafetyA.
  ///
  /// In en, this message translates to:
  /// **'All drivers are verified and safety features are available during your ride.'**
  String get faqSafetyA;

  /// No description provided for @faqSupportQ.
  ///
  /// In en, this message translates to:
  /// **'How can I contact support?'**
  String get faqSupportQ;

  /// No description provided for @faqSupportA.
  ///
  /// In en, this message translates to:
  /// **'You can chat with us, call us, or send us an email anytime.'**
  String get faqSupportA;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NovaRide Rider App'**
  String get appName;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aboutDesc.
  ///
  /// In en, this message translates to:
  /// **'NovaRide Rider App helps you get where you need to go safely, comfortably, and on time.'**
  String get aboutDesc;

  /// No description provided for @aboutFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Comfortable Rides'**
  String get aboutFeature1Title;

  /// No description provided for @aboutFeature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy smooth and reliable rides with trusted drivers.'**
  String get aboutFeature1Desc;

  /// No description provided for @aboutFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Schedule Ahead'**
  String get aboutFeature2Title;

  /// No description provided for @aboutFeature2Desc.
  ///
  /// In en, this message translates to:
  /// **'Plan your trips in advance and travel stress-free.'**
  String get aboutFeature2Desc;

  /// No description provided for @aboutFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Safety First'**
  String get aboutFeature3Title;

  /// No description provided for @aboutFeature3Desc.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our top priority every step of the way.'**
  String get aboutFeature3Desc;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'© 2026 NovaRide Rider App. All rights reserved.'**
  String get aboutFooter;

  /// No description provided for @rideExpenses.
  ///
  /// In en, this message translates to:
  /// **'Ride Expenses'**
  String get rideExpenses;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @expenseCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get expenseCustomRange;

  /// No description provided for @expenseTapToChangeDates.
  ///
  /// In en, this message translates to:
  /// **'Tap to change dates'**
  String get expenseTapToChangeDates;

  /// No description provided for @expenseSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get expenseSelectDateRange;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get selectMonth;

  /// No description provided for @totalRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get totalRides;

  /// No description provided for @avgRide.
  ///
  /// In en, this message translates to:
  /// **'Avg / ride'**
  String get avgRide;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense breakdown'**
  String get expenseBreakdown;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @rides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export CSV report'**
  String get exportReport;

  /// No description provided for @exportReportHint.
  ///
  /// In en, this message translates to:
  /// **'Share a spreadsheet with all rides in this period'**
  String get exportReportHint;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense report ready to share'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export report. Try again.'**
  String get exportFailed;

  /// No description provided for @exportNoRides.
  ///
  /// In en, this message translates to:
  /// **'No completed rides in this period to export'**
  String get exportNoRides;

  /// No description provided for @exportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Preparing report…'**
  String get exportInProgress;

  /// No description provided for @expenseCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'NovaRide — Ride expenses'**
  String get expenseCsvTitle;

  /// No description provided for @expenseCsvPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get expenseCsvPeriod;

  /// No description provided for @expenseCsvGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get expenseCsvGenerated;

  /// No description provided for @expenseCsvTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get expenseCsvTotal;

  /// No description provided for @expenseCsvRideCount.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get expenseCsvRideCount;

  /// No description provided for @expenseCsvColRideId.
  ///
  /// In en, this message translates to:
  /// **'Ride ID'**
  String get expenseCsvColRideId;

  /// No description provided for @expenseCsvColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseCsvColDate;

  /// No description provided for @expenseCsvColFrom.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get expenseCsvColFrom;

  /// No description provided for @expenseCsvColTo.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get expenseCsvColTo;

  /// No description provided for @expenseCsvColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (SYP)'**
  String get expenseCsvColAmount;

  /// No description provided for @expenseCsvColPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get expenseCsvColPayment;

  /// No description provided for @expenseCsvColPromo.
  ///
  /// In en, this message translates to:
  /// **'Promo'**
  String get expenseCsvColPromo;

  /// No description provided for @expenseCsvColDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount (SYP)'**
  String get expenseCsvColDiscount;

  /// No description provided for @expenseCsvColDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get expenseCsvColDistance;

  /// No description provided for @expenseCsvCurrency.
  ///
  /// In en, this message translates to:
  /// **'SYP'**
  String get expenseCsvCurrency;

  /// No description provided for @promoSaved.
  ///
  /// In en, this message translates to:
  /// **'Promo savings'**
  String get promoSaved;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'This information helps us personalize your experience'**
  String get profileSetupDesc;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety matters'**
  String get safetyTitle;

  /// No description provided for @safetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add an emergency contact so we can help you quickly if something goes wrong.'**
  String get safetyDesc;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get contactName;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get contactPhone;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @callEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Call emergency contact'**
  String get callEmergencyContact;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share live location'**
  String get shareLocation;

  /// No description provided for @shareLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Your location will be shared with your emergency contact during rides'**
  String get shareLocationDesc;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddress;

  /// No description provided for @workAddress.
  ///
  /// In en, this message translates to:
  /// **'Work Address'**
  String get workAddress;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @familyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your family safe and connected'**
  String get familyProfileTitle;

  /// No description provided for @familyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With a family profile, you can manage rides, payments, and safety for your loved ones.'**
  String get familyProfileSubtitle;

  /// No description provided for @familyProfilePoint1.
  ///
  /// In en, this message translates to:
  /// **'Get real-time updates to track your family\'s rides and ensure their safety.'**
  String get familyProfilePoint1;

  /// No description provided for @familyProfilePoint2.
  ///
  /// In en, this message translates to:
  /// **'Manage payments for your whole family with a shared payment method.'**
  String get familyProfilePoint2;

  /// No description provided for @familyProfilePoint3.
  ///
  /// In en, this message translates to:
  /// **'Monitor ride history and spending for up to 9 family members.'**
  String get familyProfilePoint3;

  /// No description provided for @createFamilyProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Family Profile'**
  String get createFamilyProfile;

  /// No description provided for @familyProfileTerms.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to the Terms of Use of Family Profile and acknowledge the Privacy Notice.'**
  String get familyProfileTerms;

  /// No description provided for @familyAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is this profile for?'**
  String get familyAgeTitle;

  /// No description provided for @over18.
  ///
  /// In en, this message translates to:
  /// **'Over 18'**
  String get over18;

  /// No description provided for @over18Desc.
  ///
  /// In en, this message translates to:
  /// **'For adults who can manage their own rides.'**
  String get over18Desc;

  /// No description provided for @under18.
  ///
  /// In en, this message translates to:
  /// **'Under 18'**
  String get under18;

  /// No description provided for @under18Desc.
  ///
  /// In en, this message translates to:
  /// **'For minors who need supervision and safety tracking.'**
  String get under18Desc;

  /// No description provided for @addFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Add family members'**
  String get addFamilyMembers;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member name'**
  String get memberName;

  /// No description provided for @memberPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get memberPhone;

  /// No description provided for @relation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relation;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @son.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get son;

  /// No description provided for @daughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get daughter;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @familyProfileSummary.
  ///
  /// In en, this message translates to:
  /// **'Family Profile Summary'**
  String get familyProfileSummary;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// No description provided for @familyMaxMembers.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 9 family members'**
  String get familyMaxMembers;

  /// No description provided for @familySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save family profile'**
  String get familySaveFailed;

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @father.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get father;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @familyInviteMother.
  ///
  /// In en, this message translates to:
  /// **'Invite mother'**
  String get familyInviteMother;

  /// No description provided for @familyInviteFather.
  ///
  /// In en, this message translates to:
  /// **'Invite father'**
  String get familyInviteFather;

  /// No description provided for @familyInviteParent.
  ///
  /// In en, this message translates to:
  /// **'Invite co-parent'**
  String get familyInviteParent;

  /// No description provided for @familyInviteParentDesc.
  ///
  /// In en, this message translates to:
  /// **'Links their app account to your family profile — shared trip tracking and payments like Uber Family'**
  String get familyInviteParentDesc;

  /// No description provided for @familySendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get familySendInvite;

  /// No description provided for @familyInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent'**
  String get familyInviteSent;

  /// No description provided for @familyInviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'You joined the family profile'**
  String get familyInviteAccepted;

  /// No description provided for @familyPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending invites'**
  String get familyPendingInvites;

  /// No description provided for @familyInviteFrom.
  ///
  /// In en, this message translates to:
  /// **'Invite from'**
  String get familyInviteFrom;

  /// No description provided for @familyActiveRides.
  ///
  /// In en, this message translates to:
  /// **'Family rides now'**
  String get familyActiveRides;

  /// No description provided for @familyEmptyMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite parents or family by phone number'**
  String get familyEmptyMembers;

  /// No description provided for @familyStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get familyStatusPending;

  /// No description provided for @familyStatusLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get familyStatusLinked;

  /// No description provided for @familyStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get familyStatusDeclined;

  /// No description provided for @familyStatusContact.
  ///
  /// In en, this message translates to:
  /// **'Contact only'**
  String get familyStatusContact;

  /// No description provided for @familyYouAreOwner.
  ///
  /// In en, this message translates to:
  /// **'You manage this family profile'**
  String get familyYouAreOwner;

  /// No description provided for @familyManagedBy.
  ///
  /// In en, this message translates to:
  /// **'Family of'**
  String get familyManagedBy;

  /// No description provided for @familyCanManage.
  ///
  /// In en, this message translates to:
  /// **'Co-manage'**
  String get familyCanManage;

  /// No description provided for @familyCanPay.
  ///
  /// In en, this message translates to:
  /// **'Can pay'**
  String get familyCanPay;

  /// No description provided for @familyRoleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get familyRoleParent;

  /// No description provided for @familyRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get familyRoleMember;

  /// No description provided for @familyFillAll.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields'**
  String get familyFillAll;

  /// No description provided for @familyRideActive.
  ///
  /// In en, this message translates to:
  /// **'Active ride'**
  String get familyRideActive;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite teenagers and adults'**
  String get inviteTitle;

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a family profile to help make life easier - for you and your loved ones.'**
  String get inviteSubtitle;

  /// No description provided for @featureSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Teenager account safety'**
  String get featureSafetyTitle;

  /// No description provided for @featureSafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Teenagers get built-in safety features and top-rated drivers.'**
  String get featureSafetyDesc;

  /// No description provided for @featureTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow trips in real time'**
  String get featureTrackingTitle;

  /// No description provided for @featureTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your family\'s live location.'**
  String get featureTrackingDesc;

  /// No description provided for @featurePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay for your family'**
  String get featurePaymentTitle;

  /// No description provided for @featurePaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a shared payment method.'**
  String get featurePaymentDesc;

  /// No description provided for @featureLimitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set spending limits'**
  String get featureLimitsTitle;

  /// No description provided for @featureLimitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how much members can spend.'**
  String get featureLimitsDesc;

  /// No description provided for @adult.
  ///
  /// In en, this message translates to:
  /// **'I\'m an adult'**
  String get adult;

  /// No description provided for @adultDesc.
  ///
  /// In en, this message translates to:
  /// **'Ages 18 and older'**
  String get adultDesc;

  /// No description provided for @teen.
  ///
  /// In en, this message translates to:
  /// **'I\'m a teenager'**
  String get teen;

  /// No description provided for @teenDesc.
  ///
  /// In en, this message translates to:
  /// **'Ages 13 - 17'**
  String get teenDesc;

  /// No description provided for @inviteAdultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite adults to your Family profile'**
  String get inviteAdultsTitle;

  /// No description provided for @inviteAdultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take care of your loved ones. You\'ll be able to:'**
  String get inviteAdultsSubtitle;

  /// No description provided for @inviteAdultsFeature1.
  ///
  /// In en, this message translates to:
  /// **'Pay for trips and orders'**
  String get inviteAdultsFeature1;

  /// No description provided for @inviteAdultsFeature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Share a payment method.'**
  String get inviteAdultsFeature1Desc;

  /// No description provided for @inviteAdultsFeature2.
  ///
  /// In en, this message translates to:
  /// **'Set spending limits'**
  String get inviteAdultsFeature2;

  /// No description provided for @inviteAdultsFeature2Desc.
  ///
  /// In en, this message translates to:
  /// **'Manage your family\'s monthly spending.'**
  String get inviteAdultsFeature2Desc;

  /// No description provided for @inviteAdultsFeature3.
  ///
  /// In en, this message translates to:
  /// **'Follow trips'**
  String get inviteAdultsFeature3;

  /// No description provided for @inviteAdultsFeature3Desc.
  ///
  /// In en, this message translates to:
  /// **'Track trips from start to finish.'**
  String get inviteAdultsFeature3Desc;

  /// No description provided for @inviteAdultsFeature4.
  ///
  /// In en, this message translates to:
  /// **'Stay in touch'**
  String get inviteAdultsFeature4;

  /// No description provided for @inviteAdultsFeature4Desc.
  ///
  /// In en, this message translates to:
  /// **'Connect with family members anytime.'**
  String get inviteAdultsFeature4Desc;

  /// No description provided for @inviteAdultsButton.
  ///
  /// In en, this message translates to:
  /// **'Invite adults'**
  String get inviteAdultsButton;

  /// No description provided for @inviteTeenAdults.
  ///
  /// In en, this message translates to:
  /// **'Invite teenagers and adults'**
  String get inviteTeenAdults;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Follow trips in real time'**
  String get track;

  /// No description provided for @trackDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your family\'s live location.'**
  String get trackDesc;

  /// No description provided for @payDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a shared payment method.'**
  String get payDesc;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Set spending limits'**
  String get limit;

  /// No description provided for @limitDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how much members can spend.'**
  String get limitDesc;

  /// No description provided for @invitePay.
  ///
  /// In en, this message translates to:
  /// **'Pay for trips and orders'**
  String get invitePay;

  /// No description provided for @invitePayDesc.
  ///
  /// In en, this message translates to:
  /// **'Share a payment method.'**
  String get invitePayDesc;

  /// No description provided for @inviteLimit.
  ///
  /// In en, this message translates to:
  /// **'Set spending limits'**
  String get inviteLimit;

  /// No description provided for @inviteLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your family\'s monthly spending.'**
  String get inviteLimitDesc;

  /// No description provided for @inviteFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow trips'**
  String get inviteFollow;

  /// No description provided for @inviteFollowDesc.
  ///
  /// In en, this message translates to:
  /// **'Track trips from start to finish.'**
  String get inviteFollowDesc;

  /// No description provided for @brother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get brother;

  /// No description provided for @sister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get sister;

  /// No description provided for @wife.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get wife;

  /// No description provided for @husband.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get husband;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @yourPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Your personal data'**
  String get yourPersonalData;

  /// No description provided for @downloadYourData.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your data'**
  String get downloadYourData;

  /// No description provided for @downloadYourDataDesc.
  ///
  /// In en, this message translates to:
  /// **'You can request a full copy of all your stored personal information.'**
  String get downloadYourDataDesc;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all associated data.'**
  String get deleteAccountDesc;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trips'**
  String get upcomingTrips;

  /// No description provided for @noUpcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'No trips at the moment'**
  String get noUpcomingTrips;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book your trip now'**
  String get bookNow;

  /// No description provided for @waterTankerTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Tanker Order'**
  String get waterTankerTitle;

  /// No description provided for @barrels.
  ///
  /// In en, this message translates to:
  /// **'Barrels'**
  String get barrels;

  /// No description provided for @waterType.
  ///
  /// In en, this message translates to:
  /// **'Water Type'**
  String get waterType;

  /// No description provided for @selectWaterType.
  ///
  /// In en, this message translates to:
  /// **'Select water type'**
  String get selectWaterType;

  /// No description provided for @drinkingWater.
  ///
  /// In en, this message translates to:
  /// **'Drinking Water'**
  String get drinkingWater;

  /// No description provided for @regularWater.
  ///
  /// In en, this message translates to:
  /// **'Regular Water'**
  String get regularWater;

  /// No description provided for @agriculturalWater.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Water'**
  String get agriculturalWater;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select your location'**
  String get selectLocation;

  /// No description provided for @estimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get estimatedPrice;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get eta;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @carWashTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Wash Service'**
  String get carWashTitle;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceType;

  /// No description provided for @exteriorWash.
  ///
  /// In en, this message translates to:
  /// **'Exterior Wash'**
  String get exteriorWash;

  /// No description provided for @interiorWash.
  ///
  /// In en, this message translates to:
  /// **'Interior Cleaning'**
  String get interiorWash;

  /// No description provided for @fullWash.
  ///
  /// In en, this message translates to:
  /// **'Full Service'**
  String get fullWash;

  /// No description provided for @carsCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Cars'**
  String get carsCount;

  /// No description provided for @carType.
  ///
  /// In en, this message translates to:
  /// **'Car Type'**
  String get carType;

  /// No description provided for @smallCar.
  ///
  /// In en, this message translates to:
  /// **'Small Car'**
  String get smallCar;

  /// No description provided for @suv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get suv;

  /// No description provided for @truck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truck;

  /// No description provided for @movingService.
  ///
  /// In en, this message translates to:
  /// **'Moving Service'**
  String get movingService;

  /// No description provided for @moveItems.
  ///
  /// In en, this message translates to:
  /// **'Move Items'**
  String get moveItems;

  /// No description provided for @movingDescription.
  ///
  /// In en, this message translates to:
  /// **'Transport furniture, boxes, and more'**
  String get movingDescription;

  /// No description provided for @movingTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving Service'**
  String get movingTitle;

  /// No description provided for @itemsType.
  ///
  /// In en, this message translates to:
  /// **'Items Type'**
  String get itemsType;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get furniture;

  /// No description provided for @boxes.
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get boxes;

  /// No description provided for @mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed Items'**
  String get mixed;

  /// No description provided for @vehicleSize.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Size'**
  String get vehicleSize;

  /// No description provided for @smallTruck.
  ///
  /// In en, this message translates to:
  /// **'Small Truck'**
  String get smallTruck;

  /// No description provided for @mediumTruck.
  ///
  /// In en, this message translates to:
  /// **'Medium Truck'**
  String get mediumTruck;

  /// No description provided for @largeTruck.
  ///
  /// In en, this message translates to:
  /// **'Large Truck'**
  String get largeTruck;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @hey.
  ///
  /// In en, this message translates to:
  /// **'Hey'**
  String get hey;

  /// No description provided for @pricesmayvary.
  ///
  /// In en, this message translates to:
  /// **'Prices may vary'**
  String get pricesmayvary;

  /// No description provided for @seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seats;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Permanently delete your account and all data?'**
  String get deleteAccountConfirm;

  /// No description provided for @dataExportReady.
  ///
  /// In en, this message translates to:
  /// **'Your data export is ready to share'**
  String get dataExportReady;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @keep_Ride.
  ///
  /// In en, this message translates to:
  /// **'Keep Ride'**
  String get keep_Ride;

  /// No description provided for @your_driver_is_on_the_way.
  ///
  /// In en, this message translates to:
  /// **'Your driver is on the way.'**
  String get your_driver_is_on_the_way;

  /// No description provided for @cancel_ride.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride?'**
  String get cancel_ride;

  /// No description provided for @cancel_ride_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride?'**
  String get cancel_ride_confirm;

  /// No description provided for @ride_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled'**
  String get ride_cancelled;

  /// No description provided for @findYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding your driver...'**
  String get findYourDriver;

  /// No description provided for @yourDriverIsOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your driver is on the way'**
  String get yourDriverIsOnTheWay;

  /// No description provided for @driverHasArrived.
  ///
  /// In en, this message translates to:
  /// **'Your driver has arrived!'**
  String get driverHasArrived;

  /// No description provided for @youAreOnBoard.
  ///
  /// In en, this message translates to:
  /// **'You are on board'**
  String get youAreOnBoard;

  /// No description provided for @headingToDestination.
  ///
  /// In en, this message translates to:
  /// **'Heading to destination'**
  String get headingToDestination;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get when;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @searchDestinationforscudule.
  ///
  /// In en, this message translates to:
  /// **'Search destination...'**
  String get searchDestinationforscudule;

  /// No description provided for @confirmSchedule.
  ///
  /// In en, this message translates to:
  /// **'Confirm Schedule'**
  String get confirmSchedule;

  /// No description provided for @validTime.
  ///
  /// In en, this message translates to:
  /// **'✓ Valid time'**
  String get validTime;

  /// No description provided for @minAhead.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Min 30 minutes ahead'**
  String get minAhead;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @fare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fare;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date & time'**
  String get selectDateTime;

  /// No description provided for @selectDestination.
  ///
  /// In en, this message translates to:
  /// **'Please select destination'**
  String get selectDestination;

  /// No description provided for @scheduleAhead.
  ///
  /// In en, this message translates to:
  /// **'Please schedule at least 30 minutes ahead'**
  String get scheduleAhead;

  /// No description provided for @minimumAhead.
  ///
  /// In en, this message translates to:
  /// **'Minimum 30 minutes ahead'**
  String get minimumAhead;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready to schedule'**
  String get ready;

  /// No description provided for @tapMap.
  ///
  /// In en, this message translates to:
  /// **'Tap map to select destination'**
  String get tapMap;

  /// No description provided for @selectDateDestination.
  ///
  /// In en, this message translates to:
  /// **'Select date & destination'**
  String get selectDateDestination;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @tapMapSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select your location'**
  String get tapMapSelect;

  /// No description provided for @gettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address...'**
  String get gettingAddress;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @gettingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get gettingYourLocation;

  /// No description provided for @enableLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow location access in your device settings to book a ride'**
  String get enableLocationPermission;

  /// No description provided for @rideNoLongerActive.
  ///
  /// In en, this message translates to:
  /// **'This ride is no longer active'**
  String get rideNoLongerActive;

  /// No description provided for @rideDismissed.
  ///
  /// In en, this message translates to:
  /// **'Ride screen closed'**
  String get rideDismissed;

  /// No description provided for @cancelRideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this ride?'**
  String get cancelRideConfirm;

  /// No description provided for @cancellingRide.
  ///
  /// In en, this message translates to:
  /// **'Cancelling ride…'**
  String get cancellingRide;

  /// No description provided for @rideNoDriverPhone.
  ///
  /// In en, this message translates to:
  /// **'Driver phone number is not available'**
  String get rideNoDriverPhone;

  /// No description provided for @rideCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start a phone call'**
  String get rideCallFailed;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @sosButton.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get sosButton;

  /// No description provided for @sosActivated.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert sent'**
  String get sosActivated;

  /// No description provided for @safetyDuringRide.
  ///
  /// In en, this message translates to:
  /// **'Safety during ride'**
  String get safetyDuringRide;

  /// No description provided for @callEmergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Call emergency (112)'**
  String get callEmergencyServices;

  /// No description provided for @rideSummary.
  ///
  /// In en, this message translates to:
  /// **'Ride Summary'**
  String get rideSummary;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @rideScheduled.
  ///
  /// In en, this message translates to:
  /// **'Ride Scheduled! 🎉'**
  String get rideScheduled;

  /// No description provided for @rideIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Ride #{id}'**
  String rideIdLabel(int id);

  /// No description provided for @yourdriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver will be notified 15 minutes before your scheduled time.'**
  String get yourdriver;

  /// No description provided for @ride.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get ride;

  /// No description provided for @rideStepFinding.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get rideStepFinding;

  /// No description provided for @rideStepAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get rideStepAssigned;

  /// No description provided for @rideStepArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get rideStepArrived;

  /// No description provided for @rideStepRiding.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get rideStepRiding;

  /// No description provided for @rateYourRide.
  ///
  /// In en, this message translates to:
  /// **'Rate your ride'**
  String get rateYourRide;

  /// No description provided for @howWasYourTrip.
  ///
  /// In en, this message translates to:
  /// **'How was your trip?'**
  String get howWasYourTrip;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get ratingSubmitted;

  /// No description provided for @ratingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit rating'**
  String get ratingFailed;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @scheduledRideActivated.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled ride is now searching for a driver'**
  String get scheduledRideActivated;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get chatEmpty;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatTypeMessage;

  /// No description provided for @chatWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Chat with driver'**
  String get chatWithDriver;

  /// No description provided for @myScheduledRides.
  ///
  /// In en, this message translates to:
  /// **'My scheduled rides'**
  String get myScheduledRides;

  /// No description provided for @noScheduledRides.
  ///
  /// In en, this message translates to:
  /// **'No scheduled rides'**
  String get noScheduledRides;

  /// No description provided for @noScheduledRidesHint.
  ///
  /// In en, this message translates to:
  /// **'Schedule a ride and it will appear here'**
  String get noScheduledRidesHint;

  /// No description provided for @cancelScheduledRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel scheduled ride'**
  String get cancelScheduledRideTitle;

  /// No description provided for @cancelScheduledRideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this scheduled ride?'**
  String get cancelScheduledRideConfirm;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keepIt;

  /// No description provided for @cancelRideAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get cancelRideAction;

  /// No description provided for @rescheduleRideAction.
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get rescheduleRideAction;

  /// No description provided for @rescheduleRideSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ride time updated'**
  String get rescheduleRideSuccess;

  /// No description provided for @scheduleMinLeadTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup must be at least 30 minutes from now'**
  String get scheduleMinLeadTime;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get cancelling;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled'**
  String get rideCancelled;

  /// No description provided for @calculatingPrice.
  ///
  /// In en, this message translates to:
  /// **'Calculating price…'**
  String get calculatingPrice;

  /// No description provided for @setDateDestForPrice.
  ///
  /// In en, this message translates to:
  /// **'Set date and destination to see the estimated price'**
  String get setDateDestForPrice;

  /// No description provided for @kmMinutes.
  ///
  /// In en, this message translates to:
  /// **'{km} km · {min} min'**
  String kmMinutes(String km, String min);

  /// No description provided for @surgePricing.
  ///
  /// In en, this message translates to:
  /// **'Surge pricing'**
  String get surgePricing;

  /// No description provided for @surgeElevated.
  ///
  /// In en, this message translates to:
  /// **'Rising demand'**
  String get surgeElevated;

  /// No description provided for @surgeHigh.
  ///
  /// In en, this message translates to:
  /// **'High demand'**
  String get surgeHigh;

  /// No description provided for @surgeVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high demand'**
  String get surgeVeryHigh;

  /// No description provided for @surgeExplain.
  ///
  /// In en, this message translates to:
  /// **'High demand has temporarily raised the price'**
  String get surgeExplain;

  /// No description provided for @surgeExplainZone.
  ///
  /// In en, this message translates to:
  /// **'High demand in {zone} has temporarily raised the price'**
  String surgeExplainZone(String zone);

  /// No description provided for @surgeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Prices are ×{mult} higher than usual due to high demand right now.'**
  String surgeDialogBody(String mult);

  /// No description provided for @surgeDialogBodyZone.
  ///
  /// In en, this message translates to:
  /// **'Prices are ×{mult} higher than usual due to high demand in {zone} right now.'**
  String surgeDialogBodyZone(String mult, String zone);

  /// No description provided for @surgeDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Prices drop as demand eases.'**
  String get surgeDialogHint;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @surgeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Demand & pricing map'**
  String get surgeMapTitle;

  /// No description provided for @surgeMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live demand zones'**
  String get surgeMapSubtitle;

  /// No description provided for @surgeMapNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get surgeMapNormal;

  /// No description provided for @surgeMapUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String surgeMapUpdated(String time);

  /// No description provided for @surgeNoZones.
  ///
  /// In en, this message translates to:
  /// **'No active demand zones right now'**
  String get surgeNoZones;

  /// No description provided for @viewSurgeMap.
  ///
  /// In en, this message translates to:
  /// **'Demand map'**
  String get viewSurgeMap;

  /// No description provided for @accessibleRide.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get accessibleRide;

  /// No description provided for @vehicleTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleTypeLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodLabel;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashPayment;

  /// No description provided for @shamCashPayment.
  ///
  /// In en, this message translates to:
  /// **'Sham Cash'**
  String get shamCashPayment;

  /// No description provided for @ratingTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'What went well?'**
  String get ratingTagsTitle;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get ratingCommentHint;

  /// No description provided for @ratingTagClean.
  ///
  /// In en, this message translates to:
  /// **'Clean car'**
  String get ratingTagClean;

  /// No description provided for @ratingTagFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get ratingTagFriendly;

  /// No description provided for @ratingTagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get ratingTagOnTime;

  /// No description provided for @ratingTagSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe driving'**
  String get ratingTagSafe;

  /// No description provided for @ratingTagNavigation.
  ///
  /// In en, this message translates to:
  /// **'Good route'**
  String get ratingTagNavigation;

  /// No description provided for @ratingTagProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get ratingTagProfessional;

  /// No description provided for @tipTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a tip for your driver'**
  String get tipTitle;

  /// No description provided for @tipNone.
  ///
  /// In en, this message translates to:
  /// **'No tip'**
  String get tipNone;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @ratingStarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Star rating'**
  String get ratingStarsLabel;

  /// No description provided for @addSavedPlace.
  ///
  /// In en, this message translates to:
  /// **'Add saved place'**
  String get addSavedPlace;

  /// No description provided for @placeLabel.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get placeLabel;

  /// No description provided for @placeAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get placeAddress;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @noSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get noSavedPlaces;

  /// No description provided for @multiStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Add stops'**
  String get multiStopTitle;

  /// No description provided for @addStop.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get addStop;

  /// No description provided for @removeStop.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeStop;

  /// No description provided for @splitFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Split fare'**
  String get splitFareTitle;

  /// No description provided for @splitFareHint.
  ///
  /// In en, this message translates to:
  /// **'Friend pays their share via app invite'**
  String get splitFareHint;

  /// No description provided for @splitFarePhone.
  ///
  /// In en, this message translates to:
  /// **'Friend\'s phone number'**
  String get splitFarePhone;

  /// No description provided for @splitFarePercent.
  ///
  /// In en, this message translates to:
  /// **'Their share (%)'**
  String get splitFarePercent;

  /// No description provided for @splitFareInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Split fare invites'**
  String get splitFareInvitesTitle;

  /// No description provided for @splitFareInvitesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No split fare invites'**
  String get splitFareInvitesEmpty;

  /// No description provided for @splitFareAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get splitFareAccept;

  /// No description provided for @splitFareDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get splitFareDecline;

  /// No description provided for @splitFareAccepted.
  ///
  /// In en, this message translates to:
  /// **'Split fare accepted'**
  String get splitFareAccepted;

  /// No description provided for @splitFareAcceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'You accepted this split'**
  String get splitFareAcceptedStatus;

  /// No description provided for @splitFareYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get splitFareYourShare;

  /// No description provided for @splitFarePayShare.
  ///
  /// In en, this message translates to:
  /// **'Pay my share'**
  String get splitFarePayShare;

  /// No description provided for @splitFareFriendInvite.
  ///
  /// In en, this message translates to:
  /// **'Split fare invite'**
  String get splitFareFriendInvite;

  /// No description provided for @splitFareInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to your friend'**
  String get splitFareInviteSent;

  /// No description provided for @splitFarePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for friend to accept'**
  String get splitFarePending;

  /// No description provided for @splitFarePrimaryShare.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get splitFarePrimaryShare;

  /// No description provided for @promoActivated.
  ///
  /// In en, this message translates to:
  /// **'Activated {code} — {percent}% off'**
  String promoActivated(String code, String percent);

  /// No description provided for @promoActiveNextRide.
  ///
  /// In en, this message translates to:
  /// **'Active for your next ride'**
  String get promoActiveNextRide;

  /// No description provided for @promoApplyCode.
  ///
  /// In en, this message translates to:
  /// **'Apply code'**
  String get promoApplyCode;

  /// No description provided for @promoTapToActivate.
  ///
  /// In en, this message translates to:
  /// **'Tap to activate'**
  String get promoTapToActivate;

  /// No description provided for @promoMinFare.
  ///
  /// In en, this message translates to:
  /// **'Min. fare {amount}'**
  String promoMinFare(String amount);

  /// No description provided for @promoValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String promoValidUntil(String date);

  /// No description provided for @promoPullRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get promoPullRefresh;

  /// No description provided for @promoActivatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get promoActivatedBadge;

  /// No description provided for @confirmRide.
  ///
  /// In en, this message translates to:
  /// **'Confirm ride'**
  String get confirmRide;

  /// No description provided for @offlineRideQueued.
  ///
  /// In en, this message translates to:
  /// **'Ride saved — we\'ll book when you\'re back online'**
  String get offlineRideQueued;

  /// No description provided for @offlineScheduledRideQueued.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride saved — we\'ll confirm when you\'re back online'**
  String get offlineScheduledRideQueued;

  /// No description provided for @offlineQueueFlushing.
  ///
  /// In en, this message translates to:
  /// **'Sending queued ride requests…'**
  String get offlineQueueFlushing;

  /// No description provided for @offlineQueueFlushDone.
  ///
  /// In en, this message translates to:
  /// **'Queued rides submitted successfully'**
  String get offlineQueueFlushDone;

  /// No description provided for @offlineQueuePendingOnline.
  ///
  /// In en, this message translates to:
  /// **'{count} ride(s) waiting to sync'**
  String offlineQueuePendingOnline(int count);

  /// No description provided for @offlineQueuePendingScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled ride(s) queued offline'**
  String offlineQueuePendingScheduled(int count);

  /// No description provided for @offlineQueuePendingInstant.
  ///
  /// In en, this message translates to:
  /// **'{count} instant ride(s) queued offline'**
  String offlineQueuePendingInstant(int count);

  /// No description provided for @offlineQueuePendingMixed.
  ///
  /// In en, this message translates to:
  /// **'{scheduled} scheduled and {instant} instant ride(s) queued'**
  String offlineQueuePendingMixed(int scheduled, int instant);

  /// No description provided for @a11yOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get a11yOpenMenu;

  /// No description provided for @a11ySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety options'**
  String get a11ySafety;

  /// No description provided for @a11ySurgeMap.
  ///
  /// In en, this message translates to:
  /// **'Open demand map'**
  String get a11ySurgeMap;

  /// No description provided for @a11yRecenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter map on your location'**
  String get a11yRecenterMap;

  /// No description provided for @a11ySelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select {vehicle}'**
  String a11ySelectVehicle(String vehicle);

  /// No description provided for @a11yScheduleRide.
  ///
  /// In en, this message translates to:
  /// **'Schedule ride for later'**
  String get a11yScheduleRide;

  /// No description provided for @a11yWhereTo.
  ///
  /// In en, this message translates to:
  /// **'Choose destination'**
  String get a11yWhereTo;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @discountPromo.
  ///
  /// In en, this message translates to:
  /// **'Discount {code}: -{amount}'**
  String discountPromo(String code, String amount);

  /// No description provided for @referralTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get referralTitle;

  /// No description provided for @referralYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get referralYourCode;

  /// No description provided for @referralCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get referralCopied;

  /// No description provided for @referralTotal.
  ///
  /// In en, this message translates to:
  /// **'Total referrals'**
  String get referralTotal;

  /// No description provided for @referralRewarded.
  ///
  /// In en, this message translates to:
  /// **'Rewarded'**
  String get referralRewarded;

  /// No description provided for @referralPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get referralPending;

  /// No description provided for @referralEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get referralEarned;

  /// No description provided for @referralApplyHint.
  ///
  /// In en, this message translates to:
  /// **'Have a code? Enter it here'**
  String get referralApplyHint;

  /// No description provided for @referralApply.
  ///
  /// In en, this message translates to:
  /// **'Apply code'**
  String get referralApply;

  /// No description provided for @referralApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied'**
  String get referralApplied;

  /// No description provided for @splitFareDeclinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Friend declined split fare'**
  String get splitFareDeclinedStatus;

  /// No description provided for @splitFarePaidStatus.
  ///
  /// In en, this message translates to:
  /// **'Friend paid their share'**
  String get splitFarePaidStatus;

  /// No description provided for @splitFareRequiresShamCash.
  ///
  /// In en, this message translates to:
  /// **'Split fare requires Sham Cash'**
  String get splitFareRequiresShamCash;

  /// No description provided for @rideNumber.
  ///
  /// In en, this message translates to:
  /// **'Ride #{id}'**
  String rideNumber(int id);

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get actionFailed;

  /// No description provided for @codeSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code sent'**
  String get codeSentSuccess;

  /// No description provided for @distanceKmUnit.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKmUnit(String km);

  /// No description provided for @rideEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'ETA: {minutes} min'**
  String rideEtaMinutes(int minutes);

  /// No description provided for @tripStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tripStatusScheduled;

  /// No description provided for @tripStatusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get tripStatusSearching;

  /// No description provided for @tripStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver on the way'**
  String get tripStatusAssigned;

  /// No description provided for @tripStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived'**
  String get tripStatusArrived;

  /// No description provided for @tripStatusOnboard.
  ///
  /// In en, this message translates to:
  /// **'On board'**
  String get tripStatusOnboard;

  /// No description provided for @tripStatusStarted.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripStatusStarted;

  /// No description provided for @tripStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStatusCompleted;

  /// No description provided for @tripStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripStatusCancelled;

  /// No description provided for @tripStatusNoDriver.
  ///
  /// In en, this message translates to:
  /// **'No driver'**
  String get tripStatusNoDriver;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardPayment;

  /// No description provided for @noDriverFoundRetry.
  ///
  /// In en, this message translates to:
  /// **'No driver found — you can retry search'**
  String get noDriverFoundRetry;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @failedToUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get failedToUploadPhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. Are you sure?'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountAction;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedBody.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} confirmed'**
  String orderPlacedBody(String id);

  /// No description provided for @orderEta.
  ///
  /// In en, this message translates to:
  /// **'ETA: {eta}'**
  String orderEta(String eta);

  /// No description provided for @orderPlaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order'**
  String get orderPlaceFailed;

  /// No description provided for @multiStopNumber.
  ///
  /// In en, this message translates to:
  /// **'Stop {n}'**
  String multiStopNumber(int n);

  /// No description provided for @locationPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not determine location'**
  String get locationPickFailed;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get loginError;

  /// No description provided for @fareEstimateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate fare'**
  String get fareEstimateFailed;

  /// No description provided for @locationPickFor.
  ///
  /// In en, this message translates to:
  /// **'{place} — could not determine location'**
  String locationPickFor(String place);

  /// No description provided for @reportTypeSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get reportTypeSafety;

  /// No description provided for @reportTypeDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get reportTypeDriver;

  /// No description provided for @reportTypeBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get reportTypeBilling;

  /// No description provided for @reportTypeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get reportTypeTechnical;

  /// No description provided for @reportDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue…'**
  String get reportDescribeHint;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @benefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits & offers'**
  String get benefitsTitle;

  /// No description provided for @benefitsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Get more from NovaRide'**
  String get benefitsHeadline;

  /// No description provided for @benefitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Family profiles, promotions, referrals, and split fare — all in one place.'**
  String get benefitsDesc;

  /// No description provided for @benefitsFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track rides for family members'**
  String get benefitsFamilySubtitle;

  /// No description provided for @benefitsPromosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active promo codes'**
  String get benefitsPromosSubtitle;

  /// No description provided for @benefitsReferralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and earn'**
  String get benefitsReferralSubtitle;

  /// No description provided for @benefitsSplitFareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Split fare invitations'**
  String get benefitsSplitFareSubtitle;

  /// No description provided for @privacyRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy request'**
  String get privacyRequestTitle;

  /// No description provided for @privacyOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional details…'**
  String get privacyOptionalDetails;

  /// No description provided for @privacyRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get privacyRequestSubmitted;

  /// No description provided for @privacyRequestsGdpr.
  ///
  /// In en, this message translates to:
  /// **'Privacy requests (GDPR)'**
  String get privacyRequestsGdpr;

  /// No description provided for @privacyAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request data access'**
  String get privacyAccessTitle;

  /// No description provided for @privacyAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Right to access your data'**
  String get privacyAccessSubtitle;

  /// No description provided for @privacyErasureTitle.
  ///
  /// In en, this message translates to:
  /// **'Request data erasure'**
  String get privacyErasureTitle;

  /// No description provided for @privacyErasureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Right to erasure'**
  String get privacyErasureSubtitle;

  /// No description provided for @policyUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Policy update'**
  String get policyUpdateTitle;

  /// No description provided for @policyUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Please review the updated policies and accept to continue.'**
  String get policyUpdateBody;

  /// No description provided for @surgeChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Surge ×{mult}{zone}'**
  String surgeChipLabel(String mult, String zone);

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @gpsLocation.
  ///
  /// In en, this message translates to:
  /// **'GPS location'**
  String get gpsLocation;

  /// No description provided for @noDriverRetryShort.
  ///
  /// In en, this message translates to:
  /// **'No driver found — retry search'**
  String get noDriverRetryShort;

  /// No description provided for @poolRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared ride (NovaPool)'**
  String get poolRideTitle;

  /// No description provided for @poolRideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save up to 30% — share the ride'**
  String get poolRideSubtitle;

  /// No description provided for @poolPassengersLabel.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get poolPassengersLabel;

  /// No description provided for @vehicleMoto.
  ///
  /// In en, this message translates to:
  /// **'Moto'**
  String get vehicleMoto;

  /// No description provided for @vehicleMotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1 rider · Fast & affordable'**
  String get vehicleMotoSubtitle;

  /// No description provided for @vehicleVanSeatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'6+ seats'**
  String get vehicleVanSeatsSubtitle;

  /// No description provided for @vehicleTaxiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Licensed taxi'**
  String get vehicleTaxiSubtitle;

  /// No description provided for @vehicleCarSeatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'4 seats'**
  String get vehicleCarSeatsSubtitle;

  /// No description provided for @rideTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get rideTripDetails;

  /// No description provided for @rideTripDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Meet your driver at the pickup point'**
  String get rideTripDetailsHint;

  /// No description provided for @safetyRecordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio for added safety'**
  String get safetyRecordAudio;

  /// No description provided for @safetyRecordStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get safetyRecordStart;

  /// No description provided for @safetyRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get safetyRecording;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @activeRideMeetDriver.
  ///
  /// In en, this message translates to:
  /// **'Meet your driver at the pickup point'**
  String get activeRideMeetDriver;

  /// No description provided for @activeRideMeetDriverEta.
  ///
  /// In en, this message translates to:
  /// **'Pick up in {minutes} min'**
  String activeRideMeetDriverEta(int minutes);

  /// No description provided for @activeRideArriveDropoffEta.
  ///
  /// In en, this message translates to:
  /// **'Arrive at destination in {minutes} min'**
  String activeRideArriveDropoffEta(int minutes);

  /// No description provided for @ridePickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get ridePickupLabel;

  /// No description provided for @rideDropoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get rideDropoffLabel;

  /// No description provided for @mapMeetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get mapMeetingPoint;

  /// No description provided for @rideDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get rideDriverLabel;

  /// No description provided for @rideOpenSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get rideOpenSafety;

  /// No description provided for @rideCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride?'**
  String get rideCancelTitle;

  /// No description provided for @multiStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get multiStopLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
