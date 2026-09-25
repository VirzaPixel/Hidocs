import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HiDocs'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Dynamic forms & smart quizzes'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccount;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get signUpNow;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login now'**
  String get loginNow;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP code'**
  String get enterOtp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

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

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

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

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @nQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String nQuestions(Object count);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @language_switch_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_switch_title;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @fillForm.
  ///
  /// In en, this message translates to:
  /// **'Fill Form'**
  String get fillForm;

  /// No description provided for @submitResponse.
  ///
  /// In en, this message translates to:
  /// **'Submit Answers'**
  String get submitResponse;

  /// No description provided for @yourAnswers.
  ///
  /// In en, this message translates to:
  /// **'Your Answers'**
  String get yourAnswers;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detail;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get totalScore;

  /// No description provided for @responses.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get responses;

  /// No description provided for @chooseMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select more than one answer'**
  String get chooseMultiple;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @outOfStars.
  ///
  /// In en, this message translates to:
  /// **'{value} out of {max} stars'**
  String outOfStars(Object max, Object value);

  /// No description provided for @flagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged for review'**
  String get flagged;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @notAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get notAnswered;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @questionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question Number'**
  String get questionNumber;

  /// No description provided for @questionsSummary.
  ///
  /// In en, this message translates to:
  /// **'Question Summary'**
  String get questionsSummary;

  /// No description provided for @colorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
  String get colorScheme;

  /// No description provided for @pickColorScheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Color Theme'**
  String get pickColorScheme;

  /// No description provided for @pickColorSchemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your own colors'**
  String get pickColorSchemeSubtitle;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColor;

  /// No description provided for @customActive.
  ///
  /// In en, this message translates to:
  /// **'Custom Active'**
  String get customActive;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get pickColor;

  /// No description provided for @pickCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Custom Color'**
  String get pickCustomColor;

  /// No description provided for @pickAnyColor.
  ///
  /// In en, this message translates to:
  /// **'Choose any color you like'**
  String get pickAnyColor;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @emailCannotChange.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailCannotChange;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @authTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Token'**
  String get authTokenTitle;

  /// No description provided for @shareToken.
  ///
  /// In en, this message translates to:
  /// **'Share this token with participants. Keep the token private.'**
  String get shareToken;

  /// No description provided for @enterToken.
  ///
  /// In en, this message translates to:
  /// **'Enter access token'**
  String get enterToken;

  /// No description provided for @scanForm.
  ///
  /// In en, this message translates to:
  /// **'Scan Form'**
  String get scanForm;

  /// No description provided for @scanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the form QR code or barcode'**
  String get scanInstruction;

  /// No description provided for @scanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Form found!'**
  String get scanSuccess;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code, barcode, or link. Try again.'**
  String get scanFailed;

  /// No description provided for @linkInput.
  ///
  /// In en, this message translates to:
  /// **'Enter Link'**
  String get linkInput;

  /// No description provided for @enterFormLink.
  ///
  /// In en, this message translates to:
  /// **'Enter form link'**
  String get enterFormLink;

  /// No description provided for @answerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please answer all required questions first.'**
  String get answerRequired;

  /// No description provided for @submitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your answers were submitted successfully.'**
  String get submitSuccess;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get thankYou;

  /// No description provided for @timeUpAutoSubmit.
  ///
  /// In en, this message translates to:
  /// **'Time is up! Your answers have been submitted automatically.'**
  String get timeUpAutoSubmit;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistory;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Joined since {year}'**
  String memberSince(Object year);

  /// No description provided for @totalResponse.
  ///
  /// In en, this message translates to:
  /// **'Total Responses'**
  String get totalResponse;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get selectLanguage;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @imagePickError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image.'**
  String get imagePickError;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to Your Account'**
  String get loginScreenTitle;

  /// No description provided for @loginScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The Most Secure Exam Platform'**
  String get loginScreenSubtitle;

  /// No description provided for @wrongEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get wrongEmail;

  /// No description provided for @passMin6.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passMin6;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @min3.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters'**
  String get min3;

  /// No description provided for @min6.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get min6;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passRequired;

  /// No description provided for @userRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get userRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @invalidEmailFmt.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFmt;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up & Get Started'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join HiDocs today!'**
  String get registerSubtitle;

  /// No description provided for @verifyEmailBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailBtn;

  /// No description provided for @verifyCreate.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyCreate;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @otp6digit.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP code'**
  String get otp6digit;

  /// No description provided for @otpDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP code sent to your email to complete registration.'**
  String get otpDesc;

  /// No description provided for @otp180.
  ///
  /// In en, this message translates to:
  /// **'Your OTP code is valid for 180 seconds. Check your spam folder as well.'**
  String get otp180;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'An OTP code has been sent to {email}.'**
  String otpSentTo(Object email);

  /// No description provided for @registerSuccessLogin.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please login.'**
  String get registerSuccessLogin;

  /// No description provided for @backToRegister.
  ///
  /// In en, this message translates to:
  /// **'Edit registration details'**
  String get backToRegister;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendInSec.
  ///
  /// In en, this message translates to:
  /// **'Resend in {s} seconds'**
  String resendInSec(Object s);

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'name@domain.com'**
  String get emailPlaceholder;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailExample.
  ///
  /// In en, this message translates to:
  /// **'example@hidocs.com'**
  String get emailExample;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get usernameHint;

  /// No description provided for @code6Hint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get code6Hint;

  /// No description provided for @fillWorkForm.
  ///
  /// In en, this message translates to:
  /// **'Fill out & complete forms'**
  String get fillWorkForm;

  /// No description provided for @formDigitalPlatform.
  ///
  /// In en, this message translates to:
  /// **'Digital form & exam platform'**
  String get formDigitalPlatform;

  /// No description provided for @greetHi.
  ///
  /// In en, this message translates to:
  /// **'Hello, '**
  String get greetHi;

  /// No description provided for @helloWave.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get helloWave;

  /// No description provided for @noFormsYetU.
  ///
  /// In en, this message translates to:
  /// **'No completed forms yet'**
  String get noFormsYetU;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @noHistorySub.
  ///
  /// In en, this message translates to:
  /// **'Forms you have completed will appear here'**
  String get noHistorySub;

  /// No description provided for @lastHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent History'**
  String get lastHistory;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noResultFilter.
  ///
  /// In en, this message translates to:
  /// **'No matching forms'**
  String get noResultFilter;

  /// No description provided for @changeFilter.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filter or keyword.'**
  String get changeFilter;

  /// No description provided for @noResponseYet.
  ///
  /// In en, this message translates to:
  /// **'No responses yet'**
  String get noResponseYet;

  /// No description provided for @formImageGagal.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get formImageGagal;

  /// No description provided for @formDetail.
  ///
  /// In en, this message translates to:
  /// **'Form Details'**
  String get formDetail;

  /// No description provided for @formInfoSub.
  ///
  /// In en, this message translates to:
  /// **'Read the information below before filling out this form.'**
  String get formInfoSub;

  /// No description provided for @startFill.
  ///
  /// In en, this message translates to:
  /// **'Start Filling Form'**
  String get startFill;

  /// No description provided for @fillAsExam.
  ///
  /// In en, this message translates to:
  /// **'This is an exam form. Make sure you are ready before starting.'**
  String get fillAsExam;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @timerMinutesStr.
  ///
  /// In en, this message translates to:
  /// **'{m} minutes'**
  String timerMinutesStr(Object m);

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @draftStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get draftStatus;

  /// No description provided for @noQuestionYet.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get noQuestionYet;

  /// No description provided for @whichToken.
  ///
  /// In en, this message translates to:
  /// **'An access token from the form creator is required'**
  String get whichToken;

  /// No description provided for @timerStartNote.
  ///
  /// In en, this message translates to:
  /// **'The timer starts when the form begins and cannot be paused.'**
  String get timerStartNote;

  /// No description provided for @examReadyNote.
  ///
  /// In en, this message translates to:
  /// **'Make sure you are ready before starting.'**
  String get examReadyNote;

  /// No description provided for @autoSubmitNote.
  ///
  /// In en, this message translates to:
  /// **'Answers are submitted automatically when time runs out.'**
  String get autoSubmitNote;

  /// No description provided for @noQuestionsYetF.
  ///
  /// In en, this message translates to:
  /// **'This form has no questions.'**
  String get noQuestionsYetF;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @emptyResults.
  ///
  /// In en, this message translates to:
  /// **'No results to display.'**
  String get emptyResults;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @formResult.
  ///
  /// In en, this message translates to:
  /// **'Form Results'**
  String get formResult;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @noHistoryU.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryU;

  /// No description provided for @historyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer Details'**
  String get historyAnswer;

  /// No description provided for @historySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get historySubmitted;

  /// No description provided for @participant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get participant;

  /// No description provided for @valueScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String valueScore(Object score);

  /// No description provided for @noSubmissionHistory.
  ///
  /// In en, this message translates to:
  /// **'No submission history yet'**
  String get noSubmissionHistory;

  /// No description provided for @scorePct.
  ///
  /// In en, this message translates to:
  /// **'Score {score}%'**
  String scorePct(Object score);

  /// No description provided for @nilaiMax.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / {max}'**
  String nilaiMax(Object max, Object score);

  /// No description provided for @nilaiOnly.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String nilaiOnly(Object score);

  /// No description provided for @answerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answerLabel;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {c} / {total}'**
  String questionOf(Object c, Object total);

  /// No description provided for @questionNo.
  ///
  /// In en, this message translates to:
  /// **'Question Number'**
  String get questionNo;

  /// No description provided for @legendAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get legendAnswer;

  /// No description provided for @legendFlag.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get legendFlag;

  /// No description provided for @legendBlank.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get legendBlank;

  /// No description provided for @legendNow.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get legendNow;

  /// No description provided for @flagForReview.
  ///
  /// In en, this message translates to:
  /// **'Flag for review'**
  String get flagForReview;

  /// No description provided for @flaggedReview.
  ///
  /// In en, this message translates to:
  /// **'Flagged for review'**
  String get flaggedReview;

  /// No description provided for @unflag.
  ///
  /// In en, this message translates to:
  /// **'Review flag removed'**
  String get unflag;

  /// No description provided for @flagAdded.
  ///
  /// In en, this message translates to:
  /// **'Question flagged for review'**
  String get flagAdded;

  /// No description provided for @flagCountNote.
  ///
  /// In en, this message translates to:
  /// **'{n} questions flagged for review'**
  String flagCountNote(Object n);

  /// No description provided for @shortAnsHint.
  ///
  /// In en, this message translates to:
  /// **'Type a short answer...'**
  String get shortAnsHint;

  /// No description provided for @typingAnsHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get typingAnsHint;

  /// No description provided for @writeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Write your code answer here...'**
  String get writeCodeHint;

  /// No description provided for @writeFormulaHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer or formula...'**
  String get writeFormulaHint;

  /// No description provided for @leftCol.
  ///
  /// In en, this message translates to:
  /// **'Left Column'**
  String get leftCol;

  /// No description provided for @rightCol.
  ///
  /// In en, this message translates to:
  /// **'Right Column'**
  String get rightCol;

  /// No description provided for @choosePair.
  ///
  /// In en, this message translates to:
  /// **'Choose Pair'**
  String get choosePair;

  /// No description provided for @pick.
  ///
  /// In en, this message translates to:
  /// **'Choose...'**
  String get pick;

  /// No description provided for @clearChoice.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearChoice;

  /// No description provided for @submitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// No description provided for @timeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up'**
  String get timeUp;

  /// No description provided for @notAnsweredDash.
  ///
  /// In en, this message translates to:
  /// **'— Not answered —'**
  String get notAnsweredDash;

  /// No description provided for @preparingImages.
  ///
  /// In en, this message translates to:
  /// **'Preparing question images...'**
  String get preparingImages;

  /// No description provided for @convertingImages.
  ///
  /// In en, this message translates to:
  /// **'Converting questions to images ({done}/{total})'**
  String convertingImages(Object done, Object total);

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @failSendResp.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit answers. Check your connection.'**
  String get failSendResp;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @askTokenFrom.
  ///
  /// In en, this message translates to:
  /// **'Ask the form creator or supervisor for the token.'**
  String get askTokenFrom;

  /// No description provided for @wrongToken.
  ///
  /// In en, this message translates to:
  /// **'Incorrect token'**
  String get wrongToken;

  /// No description provided for @tokenEnsureCorrect.
  ///
  /// In en, this message translates to:
  /// **' — make sure the token is correct'**
  String get tokenEnsureCorrect;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @formAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Form Access Token'**
  String get formAccessToken;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @tokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Access token copied'**
  String get tokenCopied;

  /// No description provided for @enterLinkFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter the form link first.'**
  String get enterLinkFirst;

  /// No description provided for @formNotFound.
  ///
  /// In en, this message translates to:
  /// **'Form not found.'**
  String get formNotFound;

  /// No description provided for @alreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You have already submitted this form'**
  String get alreadySubmitted;

  /// No description provided for @pasteLinkToOpen.
  ///
  /// In en, this message translates to:
  /// **'Paste the form link to open and fill it out.'**
  String get pasteLinkToOpen;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @loadingForm.
  ///
  /// In en, this message translates to:
  /// **'Loading Form...'**
  String get loadingForm;

  /// No description provided for @infoExamTime.
  ///
  /// In en, this message translates to:
  /// **'Exam Time'**
  String get infoExamTime;

  /// No description provided for @infoToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get infoToken;

  /// No description provided for @afterSubmitCant.
  ///
  /// In en, this message translates to:
  /// **'After submitting, you cannot fill out this form again.'**
  String get afterSubmitCant;

  /// No description provided for @enterTokenStart.
  ///
  /// In en, this message translates to:
  /// **'Enter Token & Start'**
  String get enterTokenStart;

  /// No description provided for @hdImage.
  ///
  /// In en, this message translates to:
  /// **'HD Image'**
  String get hdImage;

  /// No description provided for @statQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get statQuestions;

  /// No description provided for @themeCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize Theme'**
  String get themeCustomize;

  /// No description provided for @pilihBahasa.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get pilihBahasa;

  /// No description provided for @themeImage.
  ///
  /// In en, this message translates to:
  /// **'Header Image'**
  String get themeImage;

  /// No description provided for @themeImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a photo as the dashboard header background'**
  String get themeImageDesc;

  /// No description provided for @themeReset.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Theme'**
  String get themeReset;

  /// No description provided for @themeResetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Reset header colors and image to the HiDocs default theme'**
  String get themeResetPrompt;

  /// No description provided for @themeResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore the default theme?'**
  String get themeResetConfirm;

  /// No description provided for @themeResetDone.
  ///
  /// In en, this message translates to:
  /// **'Theme restored to default'**
  String get themeResetDone;

  /// No description provided for @themeImagePicked.
  ///
  /// In en, this message translates to:
  /// **'Image applied as theme'**
  String get themeImagePicked;

  /// No description provided for @themePickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get themePickImage;

  /// No description provided for @themeRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get themeRemoveImage;

  /// No description provided for @pickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read the selected image'**
  String get pickImageFailed;

  /// No description provided for @navLegendAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get navLegendAnswered;

  /// No description provided for @navLegendFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged / Review'**
  String get navLegendFlagged;

  /// No description provided for @navLegendUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Not Answered'**
  String get navLegendUnanswered;

  /// No description provided for @navLegendCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Question'**
  String get navLegendCurrent;

  /// No description provided for @flagQuestion.
  ///
  /// In en, this message translates to:
  /// **'Flag for Review'**
  String get flagQuestion;

  /// No description provided for @unflagQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove Review Flag'**
  String get unflagQuestion;

  /// No description provided for @flaggedSummary.
  ///
  /// In en, this message translates to:
  /// **'Flagged Questions: {count}'**
  String flaggedSummary(Object count);

  /// No description provided for @answeredSummary.
  ///
  /// In en, this message translates to:
  /// **'Answered: {count}'**
  String answeredSummary(Object count);

  /// No description provided for @tokenRequiredErr.
  ///
  /// In en, this message translates to:
  /// **'Enter the exam token to continue'**
  String get tokenRequiredErr;

  /// No description provided for @scoreCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get scoreCorrect;

  /// No description provided for @scoreIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get scoreIncorrect;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @scoreFinal.
  ///
  /// In en, this message translates to:
  /// **'Final Score'**
  String get scoreFinal;

  /// No description provided for @questionPoint.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get questionPoint;

  /// No description provided for @questionAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get questionAnswered;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Application'**
  String get aboutApp;

  /// No description provided for @madeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤'**
  String get madeWith;

  /// No description provided for @aboutDesc.
  ///
  /// In en, this message translates to:
  /// **'HiDocs is a modern platform for creating and managing dynamic forms and online quizzes.'**
  String get aboutDesc;

  /// No description provided for @aboutHiDocsDesc.
  ///
  /// In en, this message translates to:
  /// **'HiDocs! is an application that makes it easy for users to access and fill out digital forms, quizzes, and online exams. Users can access forms through links or QR Codes, submit their answers easily, and view their submission history and response results.'**
  String get aboutHiDocsDesc;

  /// No description provided for @userFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'User Features'**
  String get userFeaturesTitle;

  /// No description provided for @featAccessForms.
  ///
  /// In en, this message translates to:
  /// **'Access Forms via Link or QR Code'**
  String get featAccessForms;

  /// No description provided for @featFillForms.
  ///
  /// In en, this message translates to:
  /// **'Fill Out Forms'**
  String get featFillForms;

  /// No description provided for @featViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View Submission History'**
  String get featViewHistory;

  /// No description provided for @featOneTimeSubmission.
  ///
  /// In en, this message translates to:
  /// **'One-Time Submission'**
  String get featOneTimeSubmission;

  /// No description provided for @thanksForUsing.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using HiDocs!'**
  String get thanksForUsing;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed.'**
  String get connectionFailed;

  /// No description provided for @failedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedGeneric;

  /// No description provided for @failedDot.
  ///
  /// In en, this message translates to:
  /// **'Failed.'**
  String get failedDot;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get tryAgain;

  /// No description provided for @loadFailedConn.
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Check your connection.'**
  String get loadFailedConn;

  /// No description provided for @errOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errOccurred(Object error);

  /// No description provided for @failedErr.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedErr(Object error);

  /// No description provided for @errorErr.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorErr(Object error);

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get invalidPassword;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields.'**
  String get fillAllFields;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordNotMatch;

  /// No description provided for @otpSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'A new OTP code has been sent to your email.'**
  String get otpSentSuccess;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP code.'**
  String get otpInvalid;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registerSuccess;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully.'**
  String get accountCreated;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful.'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @scanQrAction.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQrAction;

  /// No description provided for @pasteLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Paste Link'**
  String get pasteLinkAction;

  /// No description provided for @helloNameWave.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String helloNameWave(Object name);

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get notFound;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @accessRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Range'**
  String get accessRangeLabel;

  /// No description provided for @activateImmediatelySub.
  ///
  /// In en, this message translates to:
  /// **'Form goes live right after saving'**
  String get activateImmediatelySub;

  /// No description provided for @activateImmediatelyTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Immediately'**
  String get activateImmediatelyTitle;

  /// No description provided for @addAtLeastOneQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question'**
  String get addAtLeastOneQuestion;

  /// No description provided for @addOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOptionLabel;

  /// No description provided for @addQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestionLabel;

  /// No description provided for @assignPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign Points'**
  String get assignPointsLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @closeMustBeAfterOpen.
  ///
  /// In en, this message translates to:
  /// **'Close time must be after open time'**
  String get closeMustBeAfterOpen;

  /// No description provided for @closeTimeBeforeOpenTime.
  ///
  /// In en, this message translates to:
  /// **'Close time cannot be before open time'**
  String get closeTimeBeforeOpenTime;

  /// No description provided for @codePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write code here...'**
  String get codePlaceholder;

  /// No description provided for @correctAnswerOptional.
  ///
  /// In en, this message translates to:
  /// **'Correct answer (optional)'**
  String get correctAnswerOptional;

  /// No description provided for @createForm.
  ///
  /// In en, this message translates to:
  /// **'Create Form'**
  String get createForm;

  /// No description provided for @customLinkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. math-quiz-10'**
  String get customLinkHint;

  /// No description provided for @customLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Link'**
  String get customLinkLabel;

  /// No description provided for @deleteOptionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete option'**
  String get deleteOptionTooltip;

  /// No description provided for @deleteQuestionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete question'**
  String get deleteQuestionTooltip;

  /// No description provided for @editBlockedHasResponses.
  ///
  /// In en, this message translates to:
  /// **'Form cannot be edited because it already has responses'**
  String get editBlockedHasResponses;

  /// No description provided for @editForm.
  ///
  /// In en, this message translates to:
  /// **'Edit Form'**
  String get editForm;

  /// No description provided for @enterLatexFormula.
  ///
  /// In en, this message translates to:
  /// **'Enter LaTeX formula'**
  String get enterLatexFormula;

  /// No description provided for @examDurationHintText.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no time limit'**
  String get examDurationHintText;

  /// No description provided for @examDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam Duration'**
  String get examDurationLabel;

  /// No description provided for @examModeSub.
  ///
  /// In en, this message translates to:
  /// **'With timer, scores, and correct answers'**
  String get examModeSub;

  /// No description provided for @examModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Mode'**
  String get examModeTitle;

  /// No description provided for @failedToInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to insert image'**
  String get failedToInsertImage;

  /// No description provided for @finishingUp.
  ///
  /// In en, this message translates to:
  /// **'Finishing up...'**
  String get finishingUp;

  /// No description provided for @formBehaviorLabel.
  ///
  /// In en, this message translates to:
  /// **'Form Behavior'**
  String get formBehaviorLabel;

  /// No description provided for @formCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Form created successfully'**
  String get formCreatedSuccess;

  /// No description provided for @formInformation.
  ///
  /// In en, this message translates to:
  /// **'Form Information'**
  String get formInformation;

  /// No description provided for @formLinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Share this link so others can fill out the form'**
  String get formLinkDesc;

  /// No description provided for @formLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Form Link'**
  String get formLinkLabel;

  /// No description provided for @formSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save form'**
  String get formSaveError;

  /// No description provided for @formTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chapter 1 Math Quiz'**
  String get formTitleHint;

  /// No description provided for @formTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Form Title'**
  String get formTitleLabel;

  /// No description provided for @formTitleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 3 characters'**
  String get formTitleMinLength;

  /// No description provided for @formTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Form title is required'**
  String get formTitleRequired;

  /// No description provided for @formTypeSecurityMode.
  ///
  /// In en, this message translates to:
  /// **'Form Type & Security'**
  String get formTypeSecurityMode;

  /// No description provided for @formUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Form updated successfully'**
  String get formUpdatedSuccess;

  /// No description provided for @hideResultsSub.
  ///
  /// In en, this message translates to:
  /// **'Participants won\'t see results'**
  String get hideResultsSub;

  /// No description provided for @hideResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide Results'**
  String get hideResultsTitle;

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// No description provided for @insertCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert Code'**
  String get insertCodeTitle;

  /// No description provided for @insertCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Insert code'**
  String get insertCodeTooltip;

  /// No description provided for @insertFormulaLabel.
  ///
  /// In en, this message translates to:
  /// **'Insert Formula'**
  String get insertFormulaLabel;

  /// No description provided for @insertImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get insertImageTooltip;

  /// No description provided for @insertLabel.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insertLabel;

  /// No description provided for @insertMathTooltip.
  ///
  /// In en, this message translates to:
  /// **'Insert math formula'**
  String get insertMathTooltip;

  /// No description provided for @invalidLatexFormula.
  ///
  /// In en, this message translates to:
  /// **'Invalid LaTeX formula'**
  String get invalidLatexFormula;

  /// No description provided for @longTextHintNote.
  ///
  /// In en, this message translates to:
  /// **'Long text answer for essays'**
  String get longTextHintNote;

  /// No description provided for @mathFormulaTitle.
  ///
  /// In en, this message translates to:
  /// **'Math Formula'**
  String get mathFormulaTitle;

  /// No description provided for @mathHintNote.
  ///
  /// In en, this message translates to:
  /// **'Use LaTeX to write formulas'**
  String get mathHintNote;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @mustBeLoggedInToCreateForm.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to create a form'**
  String get mustBeLoggedInToCreateForm;

  /// No description provided for @noQuestionsYetSub.
  ///
  /// In en, this message translates to:
  /// **'Tap add to create your first question'**
  String get noQuestionsYetSub;

  /// No description provided for @noQuestionsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get noQuestionsYetTitle;

  /// No description provided for @noTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get noTimeLimit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @oneTimeSubmitSub.
  ///
  /// In en, this message translates to:
  /// **'Participants can only submit once'**
  String get oneTimeSubmitSub;

  /// No description provided for @oneTimeSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'One-Time Submit'**
  String get oneTimeSubmitTitle;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @openUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Open with no time limit'**
  String get openUnlimited;

  /// No description provided for @optionTextHint.
  ///
  /// In en, this message translates to:
  /// **'Option text...'**
  String get optionTextHint;

  /// No description provided for @pointsMax100.
  ///
  /// In en, this message translates to:
  /// **'Max 100 points'**
  String get pointsMax100;

  /// No description provided for @prepQuestionImages.
  ///
  /// In en, this message translates to:
  /// **'Preparing question images...'**
  String get prepQuestionImages;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @previewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Preview will appear here'**
  String get previewPlaceholder;

  /// No description provided for @privateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateLabel;

  /// No description provided for @privateSublabel.
  ///
  /// In en, this message translates to:
  /// **'Only with access token'**
  String get privateSublabel;

  /// No description provided for @publicLabel.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicLabel;

  /// No description provided for @publicSublabel.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can fill it'**
  String get publicSublabel;

  /// No description provided for @qCodeInput.
  ///
  /// In en, this message translates to:
  /// **'Code Input'**
  String get qCodeInput;

  /// No description provided for @qCodeInputSub.
  ///
  /// In en, this message translates to:
  /// **'Answer as program code'**
  String get qCodeInputSub;

  /// No description provided for @qEssay.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get qEssay;

  /// No description provided for @qEssaySub.
  ///
  /// In en, this message translates to:
  /// **'Long text answer'**
  String get qEssaySub;

  /// No description provided for @qImageChoice.
  ///
  /// In en, this message translates to:
  /// **'Image Choice'**
  String get qImageChoice;

  /// No description provided for @qImageChoiceSub.
  ///
  /// In en, this message translates to:
  /// **'Pick one image'**
  String get qImageChoiceSub;

  /// No description provided for @qMathFormula.
  ///
  /// In en, this message translates to:
  /// **'Math Formula'**
  String get qMathFormula;

  /// No description provided for @qMathFormulaSub.
  ///
  /// In en, this message translates to:
  /// **'Answer as LaTeX formula'**
  String get qMathFormulaSub;

  /// No description provided for @qMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get qMultipleChoice;

  /// No description provided for @qMultipleChoiceSub.
  ///
  /// In en, this message translates to:
  /// **'Select one or more answers'**
  String get qMultipleChoiceSub;

  /// No description provided for @qRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get qRating;

  /// No description provided for @qRatingSub.
  ///
  /// In en, this message translates to:
  /// **'Star rating'**
  String get qRatingSub;

  /// No description provided for @qShortAnswer.
  ///
  /// In en, this message translates to:
  /// **'Short Answer'**
  String get qShortAnswer;

  /// No description provided for @qShortAnswerSub.
  ///
  /// In en, this message translates to:
  /// **'Short single-line text'**
  String get qShortAnswerSub;

  /// No description provided for @qYesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes / No'**
  String get qYesNo;

  /// No description provided for @qYesNoSub.
  ///
  /// In en, this message translates to:
  /// **'Yes or no choice'**
  String get qYesNoSub;

  /// No description provided for @qCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Checkboxes'**
  String get qCheckbox;

  /// No description provided for @qCheckboxSub.
  ///
  /// In en, this message translates to:
  /// **'Select multiple answers'**
  String get qCheckboxSub;

  /// No description provided for @qMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get qMatching;

  /// No description provided for @qMatchingSub.
  ///
  /// In en, this message translates to:
  /// **'Match left-right pairs'**
  String get qMatchingSub;

  /// No description provided for @addPairLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Pair'**
  String get addPairLabel;

  /// No description provided for @matchingLeftHint.
  ///
  /// In en, this message translates to:
  /// **'Left...'**
  String get matchingLeftHint;

  /// No description provided for @matchingRightHint.
  ///
  /// In en, this message translates to:
  /// **'Right...'**
  String get matchingRightHint;

  /// No description provided for @matchingHintNote.
  ///
  /// In en, this message translates to:
  /// **'Add left-right pairs. Participants match each left item to the right answer.'**
  String get matchingHintNote;

  /// No description provided for @deletePairTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete pair'**
  String get deletePairTooltip;

  /// No description provided for @randomizeLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Randomize link'**
  String get randomizeLinkTooltip;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredLabel;

  /// No description provided for @resultVisibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Control what participants see after submitting'**
  String get resultVisibilityDesc;

  /// No description provided for @resultVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Result Visibility'**
  String get resultVisibilityLabel;

  /// No description provided for @scheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Set form open and close schedule'**
  String get scheduleDesc;

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleLabel;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @sharingVisibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Control who can access the form'**
  String get sharingVisibilityDesc;

  /// No description provided for @sharingVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Sharing Visibility'**
  String get sharingVisibilityLabel;

  /// No description provided for @shortTextHintNote.
  ///
  /// In en, this message translates to:
  /// **'Short single-line text answer'**
  String get shortTextHintNote;

  /// No description provided for @showResultAndScoreSub.
  ///
  /// In en, this message translates to:
  /// **'Participants see correct answers and score'**
  String get showResultAndScoreSub;

  /// No description provided for @showResultAndScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Result & Score'**
  String get showResultAndScoreTitle;

  /// No description provided for @showResultOnlySub.
  ///
  /// In en, this message translates to:
  /// **'Participants only see correct answers'**
  String get showResultOnlySub;

  /// No description provided for @showResultOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Result Only'**
  String get showResultOnlyTitle;

  /// No description provided for @shuffleOptionsSub.
  ///
  /// In en, this message translates to:
  /// **'Option order is randomized per participant'**
  String get shuffleOptionsSub;

  /// No description provided for @shuffleOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle Options'**
  String get shuffleOptionsTitle;

  /// No description provided for @shuffleQuestionsSub.
  ///
  /// In en, this message translates to:
  /// **'Question order is randomized per participant'**
  String get shuffleQuestionsSub;

  /// No description provided for @shuffleQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle Questions'**
  String get shuffleQuestionsTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @starsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get starsLabel;

  /// No description provided for @starterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Starter code for participants...'**
  String get starterCodeHint;

  /// No description provided for @surveyModeSub.
  ///
  /// In en, this message translates to:
  /// **'No scoring, focus on responses'**
  String get surveyModeSub;

  /// No description provided for @surveyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey Mode'**
  String get surveyModeTitle;

  /// No description provided for @tabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// No description provided for @tabQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get tabQuestions;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @timeAtLabel.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get timeAtLabel;

  /// No description provided for @writeQuestionHere.
  ///
  /// In en, this message translates to:
  /// **'Write your question here...'**
  String get writeQuestionHere;

  /// No description provided for @accessDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String accessDurationDays(Object count);

  /// No description provided for @accessDurationDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days} Days {hours} Hours'**
  String accessDurationDaysHours(Object days, Object hours);

  /// No description provided for @accessDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{count} Hours'**
  String accessDurationHours(Object count);

  /// No description provided for @accessDurationHoursMins.
  ///
  /// In en, this message translates to:
  /// **'{hours} Hours {mins} Mins'**
  String accessDurationHoursMins(Object hours, Object mins);

  /// No description provided for @accessDurationMins.
  ///
  /// In en, this message translates to:
  /// **'{count} Mins'**
  String accessDurationMins(Object count);

  /// No description provided for @convertingQuestionsToImages.
  ///
  /// In en, this message translates to:
  /// **'Converting {done} of {total} questions...'**
  String convertingQuestionsToImages(Object done, Object total);

  /// No description provided for @mcqNeedsCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Question {index} needs a correct answer'**
  String mcqNeedsCorrectAnswer(Object index);

  /// No description provided for @questionContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Question {index} content is empty'**
  String questionContentEmpty(Object index);

  /// No description provided for @modeUser.
  ///
  /// In en, this message translates to:
  /// **'User Mode'**
  String get modeUser;

  /// No description provided for @modeCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator Mode'**
  String get modeCreator;

  /// No description provided for @modeUserDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill forms and view history'**
  String get modeUserDesc;

  /// No description provided for @modeCreatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your forms'**
  String get modeCreatorDesc;

  /// No description provided for @switchToMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to'**
  String get switchToMode;

  /// No description provided for @examTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Token'**
  String get examTokenTitle;

  /// No description provided for @examTokenDesc.
  ///
  /// In en, this message translates to:
  /// **'Announce this token in class. Students enter it to start the exam.'**
  String get examTokenDesc;

  /// No description provided for @examTokenProtectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Token Protection'**
  String get examTokenProtectedTitle;

  /// No description provided for @examTokenProtectedSub.
  ///
  /// In en, this message translates to:
  /// **'Students must enter the token to start the exam'**
  String get examTokenProtectedSub;

  /// No description provided for @examTokenRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get examTokenRegenerate;

  /// No description provided for @examTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Exam token copied'**
  String get examTokenCopied;

  /// No description provided for @modeExam.
  ///
  /// In en, this message translates to:
  /// **'EXAM'**
  String get modeExam;

  /// No description provided for @modeSurvey.
  ///
  /// In en, this message translates to:
  /// **'SURVEY'**
  String get modeSurvey;

  /// No description provided for @examBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam mode — note the limits'**
  String get examBannerTitle;

  /// No description provided for @questionBank.
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get questionBank;

  /// No description provided for @tabMyForms.
  ///
  /// In en, this message translates to:
  /// **'My Forms'**
  String get tabMyForms;

  /// No description provided for @tabTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get tabTemplates;

  /// No description provided for @takeFromBank.
  ///
  /// In en, this message translates to:
  /// **'Take from Question Bank'**
  String get takeFromBank;

  /// No description provided for @noFormsBank.
  ///
  /// In en, this message translates to:
  /// **'No forms yet'**
  String get noFormsBank;

  /// No description provided for @noTemplatesBank.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get noTemplatesBank;

  /// No description provided for @noQuestionsInForm.
  ///
  /// In en, this message translates to:
  /// **'No questions in this form'**
  String get noQuestionsInForm;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Math, Science'**
  String get categoryHint;

  /// No description provided for @addToFormCount.
  ///
  /// In en, this message translates to:
  /// **'Add to form ({count})'**
  String addToFormCount(Object count);

  /// No description provided for @nOptions.
  ///
  /// In en, this message translates to:
  /// **'{count} options'**
  String nOptions(Object count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @categoryFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get categoryFilterHint;

  /// No description provided for @authFooterTagline.
  ///
  /// In en, this message translates to:
  /// **'HiDocs • The Safest Exam Platform'**
  String get authFooterTagline;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
