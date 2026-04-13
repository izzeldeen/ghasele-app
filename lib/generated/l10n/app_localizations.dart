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
  /// **'Ghasele'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
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
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
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
  /// **'Login Successful!'**
  String get loginSuccess;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get signupSuccess;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
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
  /// **'Set Pickup Location'**
  String get setPickupLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location...'**
  String get searchLocation;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
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
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @addFunds.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get addFunds;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @addedFunds.
  ///
  /// In en, this message translates to:
  /// **'Added Funds'**
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
  /// **'Bedsheets'**
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
  /// **'Sign In'**
  String get signIn;

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
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @minCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minCharacters;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseEnterUsername;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @minOrderWarning.
  ///
  /// In en, this message translates to:
  /// **'Minimum order is 2 JOD. Would you like to proceed?'**
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
  /// **'Order created successfully!'**
  String get orderCreated;

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order'**
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
  /// **'Order Placed Successfully!'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your laundry order has been received and is being processed.'**
  String get orderSuccessMessage;

  /// No description provided for @orderFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Failed'**
  String get orderFailureTitle;

  /// No description provided for @orderFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while placing your order. Please try again.'**
  String get orderFailureMessage;

  /// No description provided for @goToMyOrders.
  ///
  /// In en, this message translates to:
  /// **'Go to My Orders'**
  String get goToMyOrders;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @hasPendingOrder.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending order. Please wait for it to be processed.'**
  String get hasPendingOrder;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

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
  /// **'Professional laundry service at your doorstep'**
  String get serviceSlogan;

  /// No description provided for @joinSlogan.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of satisfied customers'**
  String get joinSlogan;

  /// No description provided for @selectPickupLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Pickup Location'**
  String get selectPickupLocationTitle;

  /// No description provided for @selectPickupLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Please select the location where you want us to pick up your clothes.'**
  String get selectPickupLocationDesc;

  /// No description provided for @goToMap.
  ///
  /// In en, this message translates to:
  /// **'Go to Map & Select New Location'**
  String get goToMap;

  /// No description provided for @orChooseSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'OR Choose Saved Location'**
  String get orChooseSavedLocation;

  /// No description provided for @savedLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved Location'**
  String get savedLocation;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocation;

  /// No description provided for @askSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save this location for later?'**
  String get askSaveLocation;

  /// No description provided for @locationNameHint.
  ///
  /// In en, this message translates to:
  /// **'Location Name (e.g. Home, Work)'**
  String get locationNameHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get newTicket;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTickets;

  /// No description provided for @submitFirstTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit your first support ticket'**
  String get submitFirstTicket;

  /// No description provided for @ticketSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Ticket submitted successfully!'**
  String get ticketSubmitted;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit ticket'**
  String get failedToSubmit;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login to submit a ticket'**
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
  /// **'Submit Ticket'**
  String get submitTicket;

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief description of issue'**
  String get briefDescription;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue in detail...'**
  String get describeIssue;

  /// No description provided for @supportResponse.
  ///
  /// In en, this message translates to:
  /// **'Support Response'**
  String get supportResponse;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message'**
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
  /// **'Order Issue'**
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
  /// **'Subject required'**
  String get subjectRequired;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message required'**
  String get messageRequired;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone Verified'**
  String get phoneVerified;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code Sent'**
  String get codeSent;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Username or password incorrect'**
  String get invalidCredentials;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhoneNumber;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
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
  /// **'Back to Personal Info'**
  String get backToPersonalInfo;

  /// No description provided for @setupPassword.
  ///
  /// In en, this message translates to:
  /// **'Set up your password to secure your account'**
  String get setupPassword;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion'**
  String get deleteAccountWarning;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @priceExamples.
  ///
  /// In en, this message translates to:
  /// **'Price Examples'**
  String get priceExamples;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @addMarketer.
  ///
  /// In en, this message translates to:
  /// **'Add New Marketer'**
  String get addMarketer;

  /// No description provided for @marketerName.
  ///
  /// In en, this message translates to:
  /// **'Marketer Name'**
  String get marketerName;

  /// No description provided for @marketingCode.
  ///
  /// In en, this message translates to:
  /// **'Marketing Code'**
  String get marketingCode;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
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
  /// **'Marketer deleted successfully'**
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
  /// **'Driver Phone'**
  String get driverPhone;

  /// No description provided for @statusPendingCollection.
  ///
  /// In en, this message translates to:
  /// **'Pending Collection'**
  String get statusPendingCollection;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver Assigned'**
  String get statusAssigned;

  /// No description provided for @statusCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get statusCollected;

  /// No description provided for @statusCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get statusCleaning;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
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
  /// **'Both'**
  String get both;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get promoCode;

  /// No description provided for @addPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Add promo code'**
  String get addPromoCode;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code here'**
  String get enterPromoCode;
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
