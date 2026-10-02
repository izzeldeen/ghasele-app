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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanyjo'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginSuccess;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready!'**
  String get signupSuccess;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get orders;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @setPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup location'**
  String get setPickupLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search for a location...'**
  String get searchLocation;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get orderHistory;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @addFunds.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get addFunds;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @addedFunds.
  ///
  /// In en, this message translates to:
  /// **'Funds added'**
  String get addedFunds;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @locationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Location confirmed'**
  String get locationConfirmed;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get locationNotFound;

  /// No description provided for @shirt.
  ///
  /// In en, this message translates to:
  /// **'Shirt'**
  String get shirt;

  /// No description provided for @pants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get pants;

  /// No description provided for @dress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get dress;

  /// No description provided for @jacket.
  ///
  /// In en, this message translates to:
  /// **'Jacket'**
  String get jacket;

  /// No description provided for @bedsheets.
  ///
  /// In en, this message translates to:
  /// **'Bed sheets'**
  String get bedsheets;

  /// No description provided for @curtains.
  ///
  /// In en, this message translates to:
  /// **'Curtains'**
  String get curtains;

  /// No description provided for @jod.
  ///
  /// In en, this message translates to:
  /// **'JOD'**
  String get jod;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get signIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signInToSeeYourOrders.
  ///
  /// In en, this message translates to:
  /// **'Log in to view your orders and save your addresses'**
  String get signInToSeeYourOrders;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in with Google. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterName;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @minCharacters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get minCharacters;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please choose a username'**
  String get pleaseEnterUsername;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Review & confirm order'**
  String get confirmOrder;

  /// No description provided for @minOrderWarning.
  ///
  /// In en, this message translates to:
  /// **'The minimum order is 2 JOD. Would you like to continue?'**
  String get minOrderWarning;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderCreated;

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your order'**
  String get orderFailed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve received your order. We\'ll keep you updated every step of the way.'**
  String get orderSuccessMessage;

  /// No description provided for @orderFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t place your order'**
  String get orderFailureTitle;

  /// No description provided for @orderFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while placing your order. Please try again.'**
  String get orderFailureMessage;

  /// No description provided for @goToMyOrders.
  ///
  /// In en, this message translates to:
  /// **'View my orders'**
  String get goToMyOrders;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @hasPendingOrder.
  ///
  /// In en, this message translates to:
  /// **'You already have an active order. Please wait until it\'s processed before placing another one.'**
  String get hasPendingOrder;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @contactNumberRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a contact number'**
  String get contactNumberRequiredTitle;

  /// No description provided for @contactNumberRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'We need a phone number so the driver can reach you about your order.'**
  String get contactNumberRequiredMessage;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get contactNumber;

  /// No description provided for @contactNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a contact number'**
  String get contactNumberRequired;

  /// No description provided for @contactNumberTicketHint.
  ///
  /// In en, this message translates to:
  /// **'You\'re not logged in, so support will use this number to reach you.'**
  String get contactNumberTicketHint;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @reliable.
  ///
  /// In en, this message translates to:
  /// **'Reliable'**
  String get reliable;

  /// No description provided for @serviceSlogan.
  ///
  /// In en, this message translates to:
  /// **'Professional laundry care, right at your doorstep'**
  String get serviceSlogan;

  /// No description provided for @joinSlogan.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of happy customers'**
  String get joinSlogan;

  /// No description provided for @selectPickupLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should we pick up?'**
  String get selectPickupLocationTitle;

  /// No description provided for @selectPickupLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose where you\'d like us to pick up your clothes.'**
  String get selectPickupLocationDesc;

  /// No description provided for @goToMap.
  ///
  /// In en, this message translates to:
  /// **'Choose a new location on the map'**
  String get goToMap;

  /// No description provided for @orChooseSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Or choose a saved location'**
  String get orChooseSavedLocation;

  /// No description provided for @savedLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved location'**
  String get savedLocation;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save this location'**
  String get saveLocation;

  /// No description provided for @askSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save this location for your next order?'**
  String get askSaveLocation;

  /// No description provided for @locationNameHint.
  ///
  /// In en, this message translates to:
  /// **'Location name (e.g. Home, Work)'**
  String get locationNameHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get actionRequired;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My support tickets'**
  String get myTickets;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New support ticket'**
  String get newTicket;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get noTickets;

  /// No description provided for @submitFirstTicket.
  ///
  /// In en, this message translates to:
  /// **'Contact support and we\'ll help you out'**
  String get submitFirstTicket;

  /// No description provided for @ticketSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your ticket has been sent!'**
  String get ticketSubmitted;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your ticket'**
  String get failedToSubmit;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in to contact support'**
  String get pleaseLogin;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @submitTicket.
  ///
  /// In en, this message translates to:
  /// **'Send ticket'**
  String get submitTicket;

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the issue'**
  String get briefDescription;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened...'**
  String get describeIssue;

  /// No description provided for @supportResponse.
  ///
  /// In en, this message translates to:
  /// **'Support reply'**
  String get supportResponse;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessage;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @orderIssue.
  ///
  /// In en, this message translates to:
  /// **'Order issue'**
  String get orderIssue;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @subjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get subjectRequired;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get messageRequired;

  /// No description provided for @photoOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional)'**
  String get photoOptional;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get attachPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large. Please choose an image under 5 MB.'**
  String get attachmentTooLarge;

  /// No description provided for @activeOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order is in progress'**
  String get activeOrderTitle;

  /// No description provided for @activeOrderTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to view your invoice number'**
  String get activeOrderTapHint;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceNumber;

  /// No description provided for @orderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatusLabel;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get phoneVerified;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent!'**
  String get codeSent;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The username or password is incorrect'**
  String get invalidCredentials;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number'**
  String get verifyPhoneNumber;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get noNotifications;

  /// No description provided for @noPrices.
  ///
  /// In en, this message translates to:
  /// **'No prices available right now'**
  String get noPrices;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get newOrder;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @backToPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Back to personal information'**
  String get backToPersonalInfo;

  /// No description provided for @setupPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password to keep your account secure'**
  String get setupPassword;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @enterPhoneToRegister.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we\'ll send you a verification code.'**
  String get enterPhoneToRegister;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your name and a password to finish setting up your account.'**
  String get completeProfileSubtitle;

  /// No description provided for @completeSignup.
  ///
  /// In en, this message translates to:
  /// **'Finish creating account'**
  String get completeSignup;

  /// No description provided for @codeSentToWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Code sent to WhatsApp'**
  String get codeSentToWhatsapp;

  /// No description provided for @codeSentToSms.
  ///
  /// In en, this message translates to:
  /// **'Code sent by SMS'**
  String get codeSentToSms;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'That code is invalid or expired. Please try again.'**
  String get invalidOtp;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterVerificationCode;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t connect to the server. Check your connection and try again.'**
  String get connectionError;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This can\'t be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteAccountWarning;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @priceExamples.
  ///
  /// In en, this message translates to:
  /// **'Price examples'**
  String get priceExamples;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @addMarketer.
  ///
  /// In en, this message translates to:
  /// **'Add marketer'**
  String get addMarketer;

  /// No description provided for @marketerName.
  ///
  /// In en, this message translates to:
  /// **'Marketer name'**
  String get marketerName;

  /// No description provided for @marketingCode.
  ///
  /// In en, this message translates to:
  /// **'Marketing code'**
  String get marketingCode;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get share;

  /// No description provided for @noMarketers.
  ///
  /// In en, this message translates to:
  /// **'No marketers added yet'**
  String get noMarketers;

  /// No description provided for @marketerAdded.
  ///
  /// In en, this message translates to:
  /// **'Marketer added successfully'**
  String get marketerAdded;

  /// No description provided for @marketerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Marketer removed successfully'**
  String get marketerDeleted;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverName;

  /// No description provided for @driverPhone.
  ///
  /// In en, this message translates to:
  /// **'Driver phone'**
  String get driverPhone;

  /// No description provided for @statusPendingCollection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for pickup'**
  String get statusPendingCollection;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get statusAssigned;

  /// No description provided for @statusCollected.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get statusCollected;

  /// No description provided for @statusCleaning.
  ///
  /// In en, this message translates to:
  /// **'Being cleaned'**
  String get statusCleaning;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for delivery'**
  String get statusReady;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'On the way to you'**
  String get statusOutForDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// No description provided for @ironing.
  ///
  /// In en, this message translates to:
  /// **'Ironing'**
  String get ironing;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Cleaning & ironing'**
  String get both;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @addPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Add a promo code'**
  String get addPromoCode;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get enterPromoCode;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved!'**
  String get locationSaved;

  /// No description provided for @locationOutsideAmman.
  ///
  /// In en, this message translates to:
  /// **'Please choose a location within Amman, Jordan.'**
  String get locationOutsideAmman;

  /// No description provided for @loginToSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Log in to save this location'**
  String get loginToSaveLocation;

  /// No description provided for @driverCollectionTab.
  ///
  /// In en, this message translates to:
  /// **'Pickups'**
  String get driverCollectionTab;

  /// No description provided for @driverDeliveryTab.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get driverDeliveryTab;

  /// No description provided for @driverNoCollectionTrips.
  ///
  /// In en, this message translates to:
  /// **'No pickup trips'**
  String get driverNoCollectionTrips;

  /// No description provided for @driverNoCollectionTripsDesc.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any pickup trips right now.'**
  String get driverNoCollectionTripsDesc;

  /// No description provided for @driverNoDeliveryTrips.
  ///
  /// In en, this message translates to:
  /// **'No delivery trips'**
  String get driverNoDeliveryTrips;

  /// No description provided for @driverNoDeliveryTripsDesc.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any delivery trips right now.'**
  String get driverNoDeliveryTripsDesc;

  /// No description provided for @driverCollected.
  ///
  /// In en, this message translates to:
  /// **'picked up'**
  String get driverCollected;

  /// No description provided for @driverDelivered.
  ///
  /// In en, this message translates to:
  /// **'delivered'**
  String get driverDelivered;

  /// No description provided for @driverReadyForHandover.
  ///
  /// In en, this message translates to:
  /// **'Ready to hand over'**
  String get driverReadyForHandover;

  /// No description provided for @driverInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get driverInProgress;

  /// No description provided for @driverStops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get driverStops;

  /// No description provided for @driverAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get driverAddItems;

  /// No description provided for @driverItemType.
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get driverItemType;

  /// No description provided for @driverQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get driverQuantity;

  /// No description provided for @driverSaveAndCollect.
  ///
  /// In en, this message translates to:
  /// **'Save items & mark as picked up'**
  String get driverSaveAndCollect;

  /// No description provided for @driverItemsSaved.
  ///
  /// In en, this message translates to:
  /// **'Items saved and order marked as picked up'**
  String get driverItemsSaved;

  /// No description provided for @driverAllCollected.
  ///
  /// In en, this message translates to:
  /// **'All {count} orders picked up'**
  String driverAllCollected(int count);

  /// No description provided for @driverNavigateToCleaner.
  ///
  /// In en, this message translates to:
  /// **'Navigate to cleaner'**
  String get driverNavigateToCleaner;

  /// No description provided for @driverHandOverToCleaner.
  ///
  /// In en, this message translates to:
  /// **'Finish trip & send to cleaning'**
  String get driverHandOverToCleaner;

  /// No description provided for @driverOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get driverOutForDelivery;

  /// No description provided for @driverMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get driverMarkDelivered;

  /// No description provided for @jodShort.
  ///
  /// In en, this message translates to:
  /// **'JOD'**
  String get jodShort;

  /// No description provided for @collectionTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup time'**
  String get collectionTime;

  /// No description provided for @selectCollectionTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a pickup time'**
  String get selectCollectionTime;

  /// No description provided for @noCollectionTimes.
  ///
  /// In en, this message translates to:
  /// **'No pickup times are available right now. Please try again later.'**
  String get noCollectionTimes;

  /// No description provided for @collectionTimesFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the pickup times. Check your connection and try again.'**
  String get collectionTimesFailed;

  /// No description provided for @fullyBooked.
  ///
  /// In en, this message translates to:
  /// **'Fully booked'**
  String get fullyBooked;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t attach the photo. Please try again.'**
  String get photoFailed;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device. Choose a photo from your gallery instead.'**
  String get cameraUnavailable;

  /// No description provided for @photoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or photo access is off. Enable it in Settings to attach a photo.'**
  String get photoPermissionDenied;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit phone number'**
  String get editPhoneNumber;

  /// No description provided for @nameChangeNote.
  ///
  /// In en, this message translates to:
  /// **'This is the name your driver will see when they arrive.'**
  String get nameChangeNote;

  /// No description provided for @phoneChangeNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this number to contact you about orders and to sign you in.'**
  String get phoneChangeNote;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your details have been saved!'**
  String get profileUpdated;

  /// No description provided for @phoneAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'That number is already linked to another account.'**
  String get phoneAlreadyInUse;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated!'**
  String get languageChanged;

  /// No description provided for @browsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get browsingAsGuest;

  /// No description provided for @guestBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to get more from Cleanyjo'**
  String get guestBenefitsTitle;

  /// No description provided for @guestBenefitOrders.
  ///
  /// In en, this message translates to:
  /// **'Keep all your orders in one place'**
  String get guestBenefitOrders;

  /// No description provided for @guestBenefitAddresses.
  ///
  /// In en, this message translates to:
  /// **'Save addresses and order faster'**
  String get guestBenefitAddresses;

  /// No description provided for @guestBenefitSupport.
  ///
  /// In en, this message translates to:
  /// **'Keep your support conversations in one place'**
  String get guestBenefitSupport;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get continueAsGuest;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appPreferences;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @orderSuccessNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll keep you posted'**
  String get orderSuccessNotifyTitle;

  /// No description provided for @orderSuccessNotifyText.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when your driver is on the way to pick up your order.'**
  String get orderSuccessNotifyText;

  /// No description provided for @orderSuccessCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Your clothes are in good hands'**
  String get orderSuccessCareTitle;

  /// No description provided for @orderSuccessCareText.
  ///
  /// In en, this message translates to:
  /// **'From pickup to delivery, we\'ll take care of your clothes every step of the way.'**
  String get orderSuccessCareText;

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call driver'**
  String get callDriver;

  /// No description provided for @callDriverFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open the phone app. You can dial the number manually.'**
  String get callDriverFailed;

  /// No description provided for @changeCollectionTime.
  ///
  /// In en, this message translates to:
  /// **'Change pickup time'**
  String get changeCollectionTime;

  /// No description provided for @saveNewTime.
  ///
  /// In en, this message translates to:
  /// **'Save new time'**
  String get saveNewTime;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentTime;

  /// No description provided for @collectionTimeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your pickup time has been updated!'**
  String get collectionTimeUpdated;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Your booked pickup time will be released. This action can\'t be undone.'**
  String get cancelOrderMessage;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep my order'**
  String get keepOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your order has been cancelled.'**
  String get orderCancelled;

  /// No description provided for @orderChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your order. Please try again.'**
  String get orderChangeFailed;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingPickPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us where to pick up'**
  String get onboardingPickPlaceTitle;

  /// No description provided for @onboardingPickPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Drop a pin where you\'d like us to collect from — home, office, or anywhere in Amman.'**
  String get onboardingPickPlaceBody;

  /// No description provided for @onboardingChooseTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a time that works for you'**
  String get onboardingChooseTimeTitle;

  /// No description provided for @onboardingChooseTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose an available pickup window and we\'ll come to you.'**
  String get onboardingChooseTimeBody;

  /// No description provided for @onboardingCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'We pick up & price your order'**
  String get onboardingCollectTitle;

  /// No description provided for @onboardingCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Your driver counts the items at pickup, then you\'ll see the exact price. No upfront payment.'**
  String get onboardingCollectBody;

  /// No description provided for @onboardingDeliverTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean clothes, back at your door'**
  String get onboardingDeliverTitle;

  /// No description provided for @onboardingDeliverBody.
  ///
  /// In en, this message translates to:
  /// **'Track your order at every step, and we\'ll bring your clean clothes back to the same location.'**
  String get onboardingDeliverBody;

  /// No description provided for @priceFixed.
  ///
  /// In en, this message translates to:
  /// **'{price} JOD'**
  String priceFixed(String price);

  /// No description provided for @priceStartingFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price} JOD'**
  String priceStartingFrom(String price);

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} JOD'**
  String priceRange(String min, String max);

  /// No description provided for @cleaningAndIroning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning & Ironing'**
  String get cleaningAndIroning;

  /// No description provided for @driverItemPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get driverItemPrice;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items added yet'**
  String get noItemsYet;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @phoneMustBe9Digits.
  ///
  /// In en, this message translates to:
  /// **'The phone number must be 9 digits (7XXXXXXXX)'**
  String get phoneMustBe9Digits;

  /// No description provided for @sendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the code. Please try again.'**
  String get sendCodeFailed;

  /// No description provided for @codeVerified.
  ///
  /// In en, this message translates to:
  /// **'Code verified'**
  String get codeVerified;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {phone} on WhatsApp.'**
  String otpSentTo(String phone);

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account.'**
  String get resetPasswordDesc;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset. Please log in.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reset your password. Please try again.'**
  String get passwordResetFailed;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered phone number and we\'ll send you a code on WhatsApp to reset your password.'**
  String get forgotPasswordDesc;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in with Apple. Please try again.'**
  String get appleSignInFailed;

  /// No description provided for @saveLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this location. Please try again.'**
  String get saveLocationFailed;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @ammanJordan.
  ///
  /// In en, this message translates to:
  /// **'Amman, Jordan'**
  String get ammanJordan;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @loadTripsFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the trips. Please try again.'**
  String get loadTripsFailed;

  /// No description provided for @saveItemsFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save the items. Please try again.'**
  String get saveItemsFailed;

  /// No description provided for @markCollectedFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t mark the order as picked up. Please try again.'**
  String get markCollectedFailed;

  /// No description provided for @handOverFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t hand over the trip. Please try again.'**
  String get handOverFailed;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please update Cleanyjo to keep using the app. The new version includes improvements and fixes.'**
  String get updateRequiredMessage;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
