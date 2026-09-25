// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HiDocs';

  @override
  String get appTagline => 'Dynamic forms & smart quizzes';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get user => 'User';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get username => 'Username';

  @override
  String get createAccount => 'Create Account';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get signUpNow => 'Sign up now';

  @override
  String get loginNow => 'Login now';

  @override
  String get otpVerification => 'OTP Verification';

  @override
  String get enterOtp => 'Enter OTP code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get search => 'Search';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get submit => 'Submit';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get back => 'Back';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get retry => 'Try Again';

  @override
  String get none => 'None';

  @override
  String get all => 'All';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String nQuestions(Object count) {
    return '$count questions';
  }

  @override
  String get active => 'Active';

  @override
  String get closed => 'Closed';

  @override
  String get inactive => 'Inactive';

  @override
  String get status => 'Status';

  @override
  String get type => 'Type';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get language => 'Language';

  @override
  String get language_switch_title => 'Language';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get english => 'English';

  @override
  String get question => 'Question';

  @override
  String get fillForm => 'Fill Form';

  @override
  String get submitResponse => 'Submit Answers';

  @override
  String get yourAnswers => 'Your Answers';

  @override
  String get detail => 'Details';

  @override
  String get score => 'Score';

  @override
  String get points => 'Points';

  @override
  String get totalScore => 'Total Score';

  @override
  String get responses => 'Responses';

  @override
  String get chooseMultiple => 'Select more than one answer';

  @override
  String get notSelected => 'Not selected';

  @override
  String outOfStars(Object max, Object value) {
    return '$value out of $max stars';
  }

  @override
  String get flagged => 'Flagged for review';

  @override
  String get answered => 'Answered';

  @override
  String get notAnswered => 'Not answered';

  @override
  String get current => 'Current';

  @override
  String get questionNumber => 'Question Number';

  @override
  String get questionsSummary => 'Question Summary';

  @override
  String get colorScheme => 'Color Scheme';

  @override
  String get pickColorScheme => 'Choose Color Theme';

  @override
  String get pickColorSchemeSubtitle => 'Customize your own colors';

  @override
  String get customColor => 'Custom Color';

  @override
  String get customActive => 'Custom Active';

  @override
  String get pickColor => 'Choose Color';

  @override
  String get pickCustomColor => 'Choose Custom Color';

  @override
  String get pickAnyColor => 'Choose any color you like';

  @override
  String get apply => 'Apply';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get emailCannotChange => 'Email cannot be changed';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get logout => 'Logout';

  @override
  String get account => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get others => 'Others';

  @override
  String get profile => 'Profile';

  @override
  String get authTokenTitle => 'Access Token';

  @override
  String get shareToken =>
      'Share this token with participants. Keep the token private.';

  @override
  String get enterToken => 'Enter access token';

  @override
  String get scanForm => 'Scan Form';

  @override
  String get scanInstruction =>
      'Point your camera at the form QR code or barcode';

  @override
  String get scanSuccess => 'Form found!';

  @override
  String get scanFailed => 'Invalid QR code, barcode, or link. Try again.';

  @override
  String get linkInput => 'Enter Link';

  @override
  String get enterFormLink => 'Enter form link';

  @override
  String get answerRequired => 'Please answer all required questions first.';

  @override
  String get submitSuccess => 'Your answers were submitted successfully.';

  @override
  String get thankYou => 'Thank You!';

  @override
  String get timeUpAutoSubmit =>
      'Time is up! Your answers have been submitted automatically.';

  @override
  String get noHistory => 'No history yet';

  @override
  String get member => 'Member';

  @override
  String memberSince(Object year) {
    return 'Joined since $year';
  }

  @override
  String get totalResponse => 'Total Responses';

  @override
  String get joined => 'Joined';

  @override
  String get selectLanguage => 'Choose Language';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get imagePickError => 'Failed to load image.';

  @override
  String get loginScreenTitle => 'Login to Your Account';

  @override
  String get loginScreenSubtitle => 'The Most Secure Exam Platform';

  @override
  String get wrongEmail => 'Invalid email';

  @override
  String get passMin6 => 'Minimum 8 characters';

  @override
  String get signIn => 'Sign In';

  @override
  String get min3 => 'Minimum 3 characters';

  @override
  String get min6 => 'Minimum 6 characters';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passRequired => 'Password is required';

  @override
  String get userRequired => 'Username is required';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get invalidEmailFmt => 'Invalid email format';

  @override
  String get registerTitle => 'Sign Up & Get Started';

  @override
  String get registerSubtitle => 'Join HiDocs today!';

  @override
  String get verifyEmailBtn => 'Verify Email';

  @override
  String get verifyCreate => 'Verify OTP';

  @override
  String get otpCode => 'OTP Code';

  @override
  String get otp6digit => 'Enter the 6-digit OTP code';

  @override
  String get otpDesc =>
      'Enter the 6-digit OTP code sent to your email to complete registration.';

  @override
  String get otp180 =>
      'Your OTP code is valid for 180 seconds. Check your spam folder as well.';

  @override
  String otpSentTo(Object email) {
    return 'An OTP code has been sent to $email.';
  }

  @override
  String get registerSuccessLogin => 'Registration successful! Please login.';

  @override
  String get backToRegister => 'Edit registration details';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendInSec(Object s) {
    return 'Resend in $s seconds';
  }

  @override
  String get emailPlaceholder => 'name@domain.com';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailExample => 'example@hidocs.com';

  @override
  String get usernameHint => 'Choose a username';

  @override
  String get code6Hint => 'Enter the 6-digit code';

  @override
  String get fillWorkForm => 'Fill out & complete forms';

  @override
  String get formDigitalPlatform => 'Digital form & exam platform';

  @override
  String get greetHi => 'Hello, ';

  @override
  String get helloWave => 'Welcome 👋';

  @override
  String get noFormsYetU => 'No completed forms yet';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get noHistorySub => 'Forms you have completed will appear here';

  @override
  String get lastHistory => 'Recent History';

  @override
  String get seeAll => 'See All';

  @override
  String get noResultFilter => 'No matching forms';

  @override
  String get changeFilter => 'Try changing the filter or keyword.';

  @override
  String get noResponseYet => 'No responses yet';

  @override
  String get formImageGagal => 'Failed to load image';

  @override
  String get formDetail => 'Form Details';

  @override
  String get formInfoSub =>
      'Read the information below before filling out this form.';

  @override
  String get startFill => 'Start Filling Form';

  @override
  String get fillAsExam =>
      'This is an exam form. Make sure you are ready before starting.';

  @override
  String get duration => 'Duration';

  @override
  String timerMinutesStr(Object m) {
    return '$m minutes';
  }

  @override
  String get closedStatus => 'Closed';

  @override
  String get activeStatus => 'Active';

  @override
  String get draftStatus => 'Inactive';

  @override
  String get noQuestionYet => 'No questions yet';

  @override
  String get whichToken => 'An access token from the form creator is required';

  @override
  String get timerStartNote =>
      'The timer starts when the form begins and cannot be paused.';

  @override
  String get examReadyNote => 'Make sure you are ready before starting.';

  @override
  String get autoSubmitNote =>
      'Answers are submitted automatically when time runs out.';

  @override
  String get noQuestionsYetF => 'This form has no questions.';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get processing => 'Processing...';

  @override
  String get emptyResults => 'No results to display.';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get reset => 'Reset';

  @override
  String get formResult => 'Form Results';

  @override
  String get historyTitle => 'History';

  @override
  String get noHistoryU => 'No history yet';

  @override
  String get historyAnswer => 'Answer Details';

  @override
  String get historySubmitted => 'Submitted';

  @override
  String get participant => 'Participant';

  @override
  String valueScore(Object score) {
    return 'Score: $score';
  }

  @override
  String get noSubmissionHistory => 'No submission history yet';

  @override
  String scorePct(Object score) {
    return 'Score $score%';
  }

  @override
  String nilaiMax(Object max, Object score) {
    return 'Score: $score / $max';
  }

  @override
  String nilaiOnly(Object score) {
    return 'Score: $score';
  }

  @override
  String get answerLabel => 'Answer';

  @override
  String questionOf(Object c, Object total) {
    return 'Question $c / $total';
  }

  @override
  String get questionNo => 'Question Number';

  @override
  String get legendAnswer => 'Answered';

  @override
  String get legendFlag => 'Flagged';

  @override
  String get legendBlank => 'Not answered';

  @override
  String get legendNow => 'Current';

  @override
  String get flagForReview => 'Flag for review';

  @override
  String get flaggedReview => 'Flagged for review';

  @override
  String get unflag => 'Review flag removed';

  @override
  String get flagAdded => 'Question flagged for review';

  @override
  String flagCountNote(Object n) {
    return '$n questions flagged for review';
  }

  @override
  String get shortAnsHint => 'Type a short answer...';

  @override
  String get typingAnsHint => 'Type your answer...';

  @override
  String get writeCodeHint => 'Write your code answer here...';

  @override
  String get writeFormulaHint => 'Write your answer or formula...';

  @override
  String get leftCol => 'Left Column';

  @override
  String get rightCol => 'Right Column';

  @override
  String get choosePair => 'Choose Pair';

  @override
  String get pick => 'Choose...';

  @override
  String get clearChoice => 'Clear';

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get timeUp => 'Time\'s Up';

  @override
  String get notAnsweredDash => '— Not answered —';

  @override
  String get preparingImages => 'Preparing question images...';

  @override
  String convertingImages(Object done, Object total) {
    return 'Converting questions to images ($done/$total)';
  }

  @override
  String get zoomOut => 'Zoom Out';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get failSendResp => 'Failed to submit answers. Check your connection.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get askTokenFrom =>
      'Ask the form creator or supervisor for the token.';

  @override
  String get wrongToken => 'Incorrect token';

  @override
  String get tokenEnsureCorrect => ' — make sure the token is correct';

  @override
  String get checking => 'Checking...';

  @override
  String get continueAction => 'Continue';

  @override
  String get formAccessToken => 'Form Access Token';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get tokenCopied => 'Access token copied';

  @override
  String get enterLinkFirst => 'Enter the form link first.';

  @override
  String get formNotFound => 'Form not found.';

  @override
  String get alreadySubmitted => 'You have already submitted this form';

  @override
  String get pasteLinkToOpen => 'Paste the form link to open and fill it out.';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get loadingForm => 'Loading Form...';

  @override
  String get infoExamTime => 'Exam Time';

  @override
  String get infoToken => 'Token';

  @override
  String get afterSubmitCant =>
      'After submitting, you cannot fill out this form again.';

  @override
  String get enterTokenStart => 'Enter Token & Start';

  @override
  String get hdImage => 'HD Image';

  @override
  String get statQuestions => 'Questions';

  @override
  String get themeCustomize => 'Customize Theme';

  @override
  String get pilihBahasa => 'Choose Language';

  @override
  String get themeImage => 'Header Image';

  @override
  String get themeImageDesc => 'Use a photo as the dashboard header background';

  @override
  String get themeReset => 'Restore Default Theme';

  @override
  String get themeResetPrompt =>
      'Reset header colors and image to the HiDocs default theme';

  @override
  String get themeResetConfirm =>
      'Are you sure you want to restore the default theme?';

  @override
  String get themeResetDone => 'Theme restored to default';

  @override
  String get themeImagePicked => 'Image applied as theme';

  @override
  String get themePickImage => 'Choose Image';

  @override
  String get themeRemoveImage => 'Remove Image';

  @override
  String get pickImageFailed => 'Failed to read the selected image';

  @override
  String get navLegendAnswered => 'Answered';

  @override
  String get navLegendFlagged => 'Flagged / Review';

  @override
  String get navLegendUnanswered => 'Not Answered';

  @override
  String get navLegendCurrent => 'Current Question';

  @override
  String get flagQuestion => 'Flag for Review';

  @override
  String get unflagQuestion => 'Remove Review Flag';

  @override
  String flaggedSummary(Object count) {
    return 'Flagged Questions: $count';
  }

  @override
  String answeredSummary(Object count) {
    return 'Answered: $count';
  }

  @override
  String get tokenRequiredErr => 'Enter the exam token to continue';

  @override
  String get scoreCorrect => 'Correct';

  @override
  String get scoreIncorrect => 'Incorrect';

  @override
  String get scoreLabel => 'Score';

  @override
  String get scoreFinal => 'Final Score';

  @override
  String get questionPoint => 'Points';

  @override
  String get questionAnswered => 'Answered';

  @override
  String get aboutApp => 'About Application';

  @override
  String get madeWith => 'Made with ❤';

  @override
  String get aboutDesc =>
      'HiDocs is a modern platform for creating and managing dynamic forms and online quizzes.';

  @override
  String get aboutHiDocsDesc =>
      'HiDocs! is an application that makes it easy for users to access and fill out digital forms, quizzes, and online exams. Users can access forms through links or QR Codes, submit their answers easily, and view their submission history and response results.';

  @override
  String get userFeaturesTitle => 'User Features';

  @override
  String get featAccessForms => 'Access Forms via Link or QR Code';

  @override
  String get featFillForms => 'Fill Out Forms';

  @override
  String get featViewHistory => 'View Submission History';

  @override
  String get featOneTimeSubmission => 'One-Time Submission';

  @override
  String get thanksForUsing => 'Thank you for using HiDocs!';

  @override
  String get connectionFailed => 'Connection failed.';

  @override
  String get failedGeneric => 'Failed';

  @override
  String get failedDot => 'Failed.';

  @override
  String get networkError =>
      'Connection failed. Please check your internet connection.';

  @override
  String get tryAgain => 'Please try again.';

  @override
  String get loadFailedConn => 'Failed to load. Check your connection.';

  @override
  String errOccurred(Object error) {
    return 'An error occurred: $error';
  }

  @override
  String failedErr(Object error) {
    return 'Failed: $error';
  }

  @override
  String errorErr(Object error) {
    return 'Error: $error';
  }

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get invalidPassword => 'Password must be at least 8 characters';

  @override
  String get requiredField => 'This field is required';

  @override
  String get fillAllFields => 'Please complete all fields.';

  @override
  String get passwordNotMatch => 'Passwords do not match';

  @override
  String get otpSentSuccess => 'A new OTP code has been sent to your email.';

  @override
  String get otpInvalid => 'Invalid or expired OTP code.';

  @override
  String get registerSuccess => 'Registration successful';

  @override
  String get accountCreated => 'Account created successfully.';

  @override
  String get welcome => 'Welcome!';

  @override
  String get loginSuccess => 'Login successful.';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get share => 'Share';

  @override
  String get scanQrAction => 'Scan QR';

  @override
  String get pasteLinkAction => 'Paste Link';

  @override
  String helloNameWave(Object name) {
    return 'Hello, $name 👋';
  }

  @override
  String get notFound => 'Not Found';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get accessRangeLabel => 'Access Range';

  @override
  String get activateImmediatelySub => 'Form goes live right after saving';

  @override
  String get activateImmediatelyTitle => 'Activate Immediately';

  @override
  String get addAtLeastOneQuestion => 'Add at least one question';

  @override
  String get addOptionLabel => 'Add Option';

  @override
  String get addQuestionLabel => 'Add Question';

  @override
  String get assignPointsLabel => 'Assign Points';

  @override
  String get closeLabel => 'Close';

  @override
  String get closeMustBeAfterOpen => 'Close time must be after open time';

  @override
  String get closeTimeBeforeOpenTime => 'Close time cannot be before open time';

  @override
  String get codePlaceholder => 'Write code here...';

  @override
  String get correctAnswerOptional => 'Correct answer (optional)';

  @override
  String get createForm => 'Create Form';

  @override
  String get customLinkHint => 'e.g. math-quiz-10';

  @override
  String get customLinkLabel => 'Custom Link';

  @override
  String get deleteOptionTooltip => 'Delete option';

  @override
  String get deleteQuestionTooltip => 'Delete question';

  @override
  String get editBlockedHasResponses =>
      'Form cannot be edited because it already has responses';

  @override
  String get editForm => 'Edit Form';

  @override
  String get enterLatexFormula => 'Enter LaTeX formula';

  @override
  String get examDurationHintText => 'Leave empty for no time limit';

  @override
  String get examDurationLabel => 'Exam Duration';

  @override
  String get examModeSub => 'With timer, scores, and correct answers';

  @override
  String get examModeTitle => 'Exam Mode';

  @override
  String get failedToInsertImage => 'Failed to insert image';

  @override
  String get finishingUp => 'Finishing up...';

  @override
  String get formBehaviorLabel => 'Form Behavior';

  @override
  String get formCreatedSuccess => 'Form created successfully';

  @override
  String get formInformation => 'Form Information';

  @override
  String get formLinkDesc => 'Share this link so others can fill out the form';

  @override
  String get formLinkLabel => 'Form Link';

  @override
  String get formSaveError => 'Failed to save form';

  @override
  String get formTitleHint => 'e.g. Chapter 1 Math Quiz';

  @override
  String get formTitleLabel => 'Form Title';

  @override
  String get formTitleMinLength => 'Title must be at least 3 characters';

  @override
  String get formTitleRequired => 'Form title is required';

  @override
  String get formTypeSecurityMode => 'Form Type & Security';

  @override
  String get formUpdatedSuccess => 'Form updated successfully';

  @override
  String get hideResultsSub => 'Participants won\'t see results';

  @override
  String get hideResultsTitle => 'Hide Results';

  @override
  String get hoursLabel => 'Hours';

  @override
  String get insertCodeTitle => 'Insert Code';

  @override
  String get insertCodeTooltip => 'Insert code';

  @override
  String get insertFormulaLabel => 'Insert Formula';

  @override
  String get insertImageTooltip => 'Insert image';

  @override
  String get insertLabel => 'Insert';

  @override
  String get insertMathTooltip => 'Insert math formula';

  @override
  String get invalidLatexFormula => 'Invalid LaTeX formula';

  @override
  String get longTextHintNote => 'Long text answer for essays';

  @override
  String get mathFormulaTitle => 'Math Formula';

  @override
  String get mathHintNote => 'Use LaTeX to write formulas';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get moveDown => 'Move down';

  @override
  String get moveUp => 'Move up';

  @override
  String get mustBeLoggedInToCreateForm =>
      'You must be logged in to create a form';

  @override
  String get noQuestionsYetSub => 'Tap add to create your first question';

  @override
  String get noQuestionsYetTitle => 'No questions yet';

  @override
  String get noTimeLimit => 'No time limit';

  @override
  String get ok => 'OK';

  @override
  String get oneTimeSubmitSub => 'Participants can only submit once';

  @override
  String get oneTimeSubmitTitle => 'One-Time Submit';

  @override
  String get openLabel => 'Open';

  @override
  String get openUnlimited => 'Open with no time limit';

  @override
  String get optionTextHint => 'Option text...';

  @override
  String get pointsMax100 => 'Max 100 points';

  @override
  String get prepQuestionImages => 'Preparing question images...';

  @override
  String get previewLabel => 'Preview';

  @override
  String get previewPlaceholder => 'Preview will appear here';

  @override
  String get privateLabel => 'Private';

  @override
  String get privateSublabel => 'Only with access token';

  @override
  String get publicLabel => 'Public';

  @override
  String get publicSublabel => 'Anyone with the link can fill it';

  @override
  String get qCodeInput => 'Code Input';

  @override
  String get qCodeInputSub => 'Answer as program code';

  @override
  String get qEssay => 'Essay';

  @override
  String get qEssaySub => 'Long text answer';

  @override
  String get qImageChoice => 'Image Choice';

  @override
  String get qImageChoiceSub => 'Pick one image';

  @override
  String get qMathFormula => 'Math Formula';

  @override
  String get qMathFormulaSub => 'Answer as LaTeX formula';

  @override
  String get qMultipleChoice => 'Multiple Choice';

  @override
  String get qMultipleChoiceSub => 'Select one or more answers';

  @override
  String get qRating => 'Rating';

  @override
  String get qRatingSub => 'Star rating';

  @override
  String get qShortAnswer => 'Short Answer';

  @override
  String get qShortAnswerSub => 'Short single-line text';

  @override
  String get qYesNo => 'Yes / No';

  @override
  String get qYesNoSub => 'Yes or no choice';

  @override
  String get qCheckbox => 'Checkboxes';

  @override
  String get qCheckboxSub => 'Select multiple answers';

  @override
  String get qMatching => 'Matching';

  @override
  String get qMatchingSub => 'Match left-right pairs';

  @override
  String get addPairLabel => 'Add Pair';

  @override
  String get matchingLeftHint => 'Left...';

  @override
  String get matchingRightHint => 'Right...';

  @override
  String get matchingHintNote =>
      'Add left-right pairs. Participants match each left item to the right answer.';

  @override
  String get deletePairTooltip => 'Delete pair';

  @override
  String get randomizeLinkTooltip => 'Randomize link';

  @override
  String get requiredLabel => 'Required';

  @override
  String get resultVisibilityDesc =>
      'Control what participants see after submitting';

  @override
  String get resultVisibilityLabel => 'Result Visibility';

  @override
  String get scheduleDesc => 'Set form open and close schedule';

  @override
  String get scheduleLabel => 'Schedule';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get sharingVisibilityDesc => 'Control who can access the form';

  @override
  String get sharingVisibilityLabel => 'Sharing Visibility';

  @override
  String get shortTextHintNote => 'Short single-line text answer';

  @override
  String get showResultAndScoreSub =>
      'Participants see correct answers and score';

  @override
  String get showResultAndScoreTitle => 'Show Result & Score';

  @override
  String get showResultOnlySub => 'Participants only see correct answers';

  @override
  String get showResultOnlyTitle => 'Show Result Only';

  @override
  String get shuffleOptionsSub => 'Option order is randomized per participant';

  @override
  String get shuffleOptionsTitle => 'Shuffle Options';

  @override
  String get shuffleQuestionsSub =>
      'Question order is randomized per participant';

  @override
  String get shuffleQuestionsTitle => 'Shuffle Questions';

  @override
  String get signOut => 'Sign Out';

  @override
  String get starsLabel => 'Stars';

  @override
  String get starterCodeHint => 'Starter code for participants...';

  @override
  String get surveyModeSub => 'No scoring, focus on responses';

  @override
  String get surveyModeTitle => 'Survey Mode';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabQuestions => 'Questions';

  @override
  String get tabSettings => 'Settings';

  @override
  String get timeAtLabel => 'at';

  @override
  String get writeQuestionHere => 'Write your question here...';

  @override
  String accessDurationDays(Object count) {
    return '$count Days';
  }

  @override
  String accessDurationDaysHours(Object days, Object hours) {
    return '$days Days $hours Hours';
  }

  @override
  String accessDurationHours(Object count) {
    return '$count Hours';
  }

  @override
  String accessDurationHoursMins(Object hours, Object mins) {
    return '$hours Hours $mins Mins';
  }

  @override
  String accessDurationMins(Object count) {
    return '$count Mins';
  }

  @override
  String convertingQuestionsToImages(Object done, Object total) {
    return 'Converting $done of $total questions...';
  }

  @override
  String mcqNeedsCorrectAnswer(Object index) {
    return 'Question $index needs a correct answer';
  }

  @override
  String questionContentEmpty(Object index) {
    return 'Question $index content is empty';
  }

  @override
  String get modeUser => 'User Mode';

  @override
  String get modeCreator => 'Creator Mode';

  @override
  String get modeUserDesc => 'Fill forms and view history';

  @override
  String get modeCreatorDesc => 'Create and manage your forms';

  @override
  String get switchToMode => 'Switch to';

  @override
  String get examTokenTitle => 'Exam Token';

  @override
  String get examTokenDesc =>
      'Announce this token in class. Students enter it to start the exam.';

  @override
  String get examTokenProtectedTitle => 'Token Protection';

  @override
  String get examTokenProtectedSub =>
      'Students must enter the token to start the exam';

  @override
  String get examTokenRegenerate => 'Regenerate';

  @override
  String get examTokenCopied => 'Exam token copied';

  @override
  String get modeExam => 'EXAM';

  @override
  String get modeSurvey => 'SURVEY';

  @override
  String get examBannerTitle => 'Exam mode — note the limits';

  @override
  String get questionBank => 'Question Bank';

  @override
  String get tabMyForms => 'My Forms';

  @override
  String get tabTemplates => 'Templates';

  @override
  String get takeFromBank => 'Take from Question Bank';

  @override
  String get noFormsBank => 'No forms yet';

  @override
  String get noTemplatesBank => 'No templates available';

  @override
  String get noQuestionsInForm => 'No questions in this form';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'e.g. Math, Science';

  @override
  String addToFormCount(Object count) {
    return 'Add to form ($count)';
  }

  @override
  String nOptions(Object count) {
    return '$count options';
  }

  @override
  String get filterAll => 'All';

  @override
  String get categoryFilterHint => 'Filter by category';

  @override
  String get authFooterTagline =>
      'HiDocs • The Safest Exam Platform';
}
