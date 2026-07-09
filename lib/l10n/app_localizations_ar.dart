// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get splashTitle => 'نوفاريد';

  @override
  String get splashSubtitle => 'مرحباً بك في تطبيق نوفاريد للركاب';

  @override
  String get welcomeTitle => 'مرحباً بك في NovaRide';

  @override
  String get welcomeSubtitle => 'رحلتك أقرب مما تتخيل.';

  @override
  String get login_title => 'تسجيل الدخول';

  @override
  String get phoneHint => 'رقم الهاتف';

  @override
  String get loginButton => 'دخول';

  @override
  String get otpTitle => 'رمز التحقق';

  @override
  String get otpSubtitle => 'أدخل رمز التحقق المرسل إلى';

  @override
  String get otpHint => 'أدخل الرمز';

  @override
  String get confirm => 'تأكيد';

  @override
  String get resend => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال ($seconds)';
  }

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get failedToSendOtp => 'تعذّر إرسال رمز التحقق';

  @override
  String get invalidResponse => 'استجابة غير صالحة من السيرفر';

  @override
  String get failedToUpdateProfile => 'تعذّر تحديث الملف الشخصي';

  @override
  String get otpError => 'يرجى إدخال رمز التحقق كاملاً';

  @override
  String get loginSubtitle => 'أدخل رقم هاتفك للمتابعة';

  @override
  String get invalidOtp => 'رمز التحقق غير صحيح';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get registerFullName => 'الاسم الكامل';

  @override
  String get registerEmailOptional => 'الإيميل (اختياري)';

  @override
  String get registerPhone => 'رقم الهاتف';

  @override
  String get registerAgree => 'أوافق على ';

  @override
  String get registerPolicies => 'اوافق على سياسة الخصوصية وشروط الاستخدام';

  @override
  String get registerButton => 'إنشاء حساب';

  @override
  String get policiesTitle => 'سياسة الخصوصية وشروط الاستخدام';

  @override
  String get policiesFullText => 'ضع هنا النص الكامل للوثائق القانونية';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameHint => 'أدخل اسمك الكامل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get optional => 'اختياري';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get birthDate => 'تاريخ الميلاد';

  @override
  String get termsAgreement => 'أوافق على الشروط والأحكام';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get introTitle => 'مرحباً بك في NovaRide!';

  @override
  String get introSubtitle => 'نحن سعداء بانضمامك إلينا. استعد لرحلات مريحة، آمنة وسريعة أينما كنت.';

  @override
  String get startNow => 'ابدأ الآن';

  @override
  String get legalText => 'بإنشائك حساب، فإنك توافق على الشروط وسياسة الخصوصية.';

  @override
  String get letsGo => 'هيا بنا ننطلق';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get whereTo => 'إلى أين؟';

  @override
  String get rideNow => 'رحلة الآن';

  @override
  String get schedule => 'جدولة';

  @override
  String get suggestions => 'اقتراحات';

  @override
  String get home => 'المنزل';

  @override
  String get work => 'العمل';

  @override
  String get mall => 'المول';

  @override
  String get from => 'من أين';

  @override
  String get later => 'لاحقًا';

  @override
  String get myAccount => 'حسابي';

  @override
  String get payment => 'الدفع';

  @override
  String get promotions => 'العروض';

  @override
  String get enterPromo => 'أدخل رمز ترويجي';

  @override
  String get subscriptions => 'الاشتراكات';

  @override
  String get myRides => 'رحلاتي';

  @override
  String get safety => 'السلامة';

  @override
  String get support => 'الدعم';

  @override
  String get about => 'حول التطبيق';

  @override
  String get searchDestination => 'إلى أين تريد الذهاب؟';

  @override
  String get car => 'سيارة';

  @override
  String get van => 'فان';

  @override
  String get taxi => 'تاكسي';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get expenseYourRides => 'Expense Your Rides';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get familyProfile => 'الملف العائلي';

  @override
  String get loginSecurity => 'تسجيل الدخول والأمان';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get savedPlaces => 'الأماكن المحفوظة';

  @override
  String get addHomeAddress => 'أضف عنوان المنزل';

  @override
  String get addWorkAddress => 'أضف عنوان العمل';

  @override
  String get addPlace => 'أضف مكانًا';

  @override
  String get language => 'اللغة';

  @override
  String get communicationPrefs => 'تفضيلات التواصل';

  @override
  String get calendars => ' رحلاتي';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get paymentMethods => 'طرق الدفع';

  @override
  String get creditCard => 'بطاقة ائتمان';

  @override
  String get paypal => 'باي بال';

  @override
  String get wallet => 'المحفظة الإلكترونية';

  @override
  String get shamCash => 'شام كاش';

  @override
  String get enterPromoCode => 'أدخل رمز الخصم';

  @override
  String get availablePromotions => 'العروض المتاحة';

  @override
  String get balance => 'الرصيد';

  @override
  String get currencySYP => 'ل.س';

  @override
  String get balanceAmount => '0 ل.س';

  @override
  String get whatIsBalance => 'ما هو الرصيد؟';

  @override
  String get balanceExplanation => 'الرصيد هو المبلغ المتوفر في حسابك لاستخدامه في الدفع.';

  @override
  String get seeBalanceTransactions => 'عرض حركات الرصيد';

  @override
  String get pay => 'الدفع';

  @override
  String get applePay => 'Apple Pay';

  @override
  String get cash => 'نقداً';

  @override
  String get addCard => 'إضافة بطاقة خصم / ائتمان';

  @override
  String get workProfile => 'إعداد ملف العمل';

  @override
  String get workProfileDesc => 'قم بإعداد ملف العمل لاستلام مدفوعات الرحلات على حساب العمل.';

  @override
  String get balanceDesc => 'الرصيد هو طريقة دفع افتراضية داخل التطبيق تُستخدم لدفع ثمن المنتجات.';

  @override
  String get howToTopUp => 'كيف أقوم بشحن رصيدي؟';

  @override
  String get topUpExplanation => 'للأسف، لا يمكنك حاليًا شحن رصيدك في موقعك إذا كان لديك رصيد صفر أو إيجابي. نحن نعمل على ذلك!\n\nإذا كان لديك رصيد سلبي، يمكنك استخدام بطاقات الخصم أو الائتمان (ماستركارد، فيزا، أمريكان إكسبريس)، النقد، شام كاش، باي بال، بانكونتاكت، آيديل، داينرز كلوب، إم-بييسا، وجي سي بي لتسوية رصيدك.\n\nيمكن أيضًا شحن رصيدك عبر الاستردادات.';

  @override
  String get howToUseBalance => 'كيف أستخدمه؟';

  @override
  String get howToUseBalanceDesc => 'يتم تطبيق رصيدك تلقائيًا على طلبك. إذا وصل رصيدك إلى الصفر، سيتم استخدام طريقة دفع أخرى لتغطية التكلفة المتبقية.';

  @override
  String get faq => 'الأسئلة الشائعة';

  @override
  String get whyNegativeBalance => 'لماذا رصيدي سلبي؟';

  @override
  String get whyNegativeBalanceDesc => 'قد يكون رصيدك سلبيًا إذا فشلت عملية دفع سابقة. يمكنك تسويته عن طريق تقديم طلب جديد أو استخدام طريقة دفع متاحة.';

  @override
  String get someoneToppedUp => 'قام شخص ما بشحن رصيدي بالفعل';

  @override
  String get someoneToppedUpDesc => 'قد يكون فريق الدعم لدينا قد أصدر لك استردادًا لطلب سابق.';

  @override
  String get balanceExpire => 'هل يمكن أن ينتهي رصيدي؟';

  @override
  String get balanceExpireDesc => 'قد تنتهي صلاحية الرصيد المكتسب كاسترداد نقدي. الرصيد المضاف بطرق أخرى لا ينتهي.';

  @override
  String get withdrawBalance => 'هل يمكنني سحب رصيدي؟';

  @override
  String get withdrawBalanceDesc => 'لا. يمكن استخدام الرصيد للمدفوعات ولكنه لا يمكن سحبه.';

  @override
  String get settleBalance => 'ما هي طرق الدفع التي يمكنني استخدامها لتسوية رصيدي؟';

  @override
  String get settleBalanceDesc => 'يمكنك استخدام بطاقات البنك أو المحافظ الإلكترونية. المزيد من طرق الدفع قادمة قريبًا.';

  @override
  String get balanceCurrency => 'لماذا تغير رصيدي في بلد آخر؟';

  @override
  String get balanceCurrencyDesc => 'يستخدم رصيدك عملة البلد الذي تتواجد فيه حاليًا. ستكون الأرصدة بعملات أخرى متاحة عند عودتك.';

  @override
  String get onProgress => 'على قيد العمل';

  @override
  String get scheduledRidesTitle => 'الرحلات المجدولة - لتسهيل رحلتك';

  @override
  String get scheduledRidesDesc => 'لا داعي للقلق بشأن الحصول على رحلة، خطط مسبقًا وتمتع براحة البال.';

  @override
  String get past => 'السابقة';

  @override
  String get noPastRides => 'ليس لديك أي رحلة بعد';

  @override
  String get upcoming => 'المقبلة';

  @override
  String get noUpcomingRides => 'لا توجد رحلات قادمة';

  @override
  String get upcomingRidesDesc => 'مهما كان جدولك، يمكن للرحلة المجدولة إيصالك في الوقت المحدد';

  @override
  String get learnHowItWorks => 'تعلم كيف تعمل';

  @override
  String get scheduleTitle1 => 'مثالي لأي مناسبة';

  @override
  String get scheduleDesc1 => 'حجوزات العشاء؟ موعد طبيب؟ جدولة رحلة والوصول في الوقت المحدد.';

  @override
  String get scheduleTitle2 => 'راحة البال في أي مكان تذهب إليه';

  @override
  String get scheduleDesc2 => 'السفر إلى الخارج؟ احجز رحلات حتى 90 يومًا مقدمًا! خطط رحلتك بدون توتر!';

  @override
  String get scheduleTitle3 => 'المرونة مضمونة';

  @override
  String get scheduleDesc3 => 'ألغِ رحلتك مجانًا قبل 60 دقيقة من الاستلام.';

  @override
  String get scheduleTitle4 => 'تخطيط بلا توتر';

  @override
  String get scheduleDesc4 => 'لا داعي للقلق بشأن العثور على رحلة في الوقت المناسب. فقط احجز مسبقًا وسنتولى الباقي.';

  @override
  String get scheduleRideButton => 'جدولة رحلة';

  @override
  String get idealForOccasion => 'مثالية لأي مناسبة';

  @override
  String get idealForOccasionDesc => 'عشاء؟ موعد طبي؟\nقم بجدولة رحلة واصل في الوقت المحدد.';

  @override
  String get peaceOfMind => 'راحة البال أينما ذهبت';

  @override
  String get peaceOfMindDesc => 'مسافر إلى الخارج؟ احجز رحلاتك حتى 90 يومًا مسبقًا!';

  @override
  String get planStressFree => 'خطط لرحلتك بدون توتر';

  @override
  String get planStressFreeDesc => 'لا تقلق بشأن إيجاد رحلة في الوقت المناسب.\nاحجز مسبقًا ونحن نهتم بالباقي.';

  @override
  String get flexibilityGuaranteed => 'مرونة مضمونة';

  @override
  String get flexibilityGuaranteedDesc => 'يمكنك إلغاء الرحلة مجانًا قبل 60 دقيقة من موعد الانطلاق.';

  @override
  String get scheduleRide => 'جدولة رحلة';

  @override
  String get scheduleRideComingSoon => 'ميزة جدولة الرحلات قادمة قريبًا!';

  @override
  String get driverVerification => 'التحقق من السائق';

  @override
  String get driverVerificationDesc => 'جميع السائقين تم التحقق منهم ومطابقة الهوية.';

  @override
  String get emergencyAssistance => 'مساعدة الطوارئ';

  @override
  String get emergencyAssistanceDesc => 'زر الطوارئ في التطبيق للتواصل السريع مع الجهات المختصة.';

  @override
  String get rideSafety => 'سلامة الرحلة';

  @override
  String get rideSafetyDesc => 'التأكد من حزام الأمان ووسائل السلامة أثناء الرحلة.';

  @override
  String get safeBehavior => 'السلوك الآمن';

  @override
  String get safeBehaviorDesc => 'تعليمات للراكب والسائق حول السلوك الآمن أثناء الرحلة.';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get contactSupportDesc => 'تواصل سريع مع الدعم لأي حالة مريبة أو طارئة.';

  @override
  String get reportIssue => 'الإبلاغ عن مشكلة';

  @override
  String get complaintTypeTitle => 'نوع المشكلة';

  @override
  String get complaintDescTitle => 'وصف المشكلة';

  @override
  String get complaintDescHint => 'اشرح مشكلتك بالتفصيل...';

  @override
  String get complaintSubmit => 'إرسال الشكوى';

  @override
  String get complaintSuccessTitle => 'تم إرسال شكواك بنجاح';

  @override
  String get complaintSuccessBody => 'سنرد عليك خلال 24 ساعة';

  @override
  String get complaintOk => 'حسناً';

  @override
  String get complaintError => 'حدث خطأ أثناء إرسال الطلب';

  @override
  String get complaintTypeDriver => 'مشكلة مع السائق';

  @override
  String get complaintTypePassenger => 'مشكلة مع راكب';

  @override
  String get complaintTypeTechnical => 'مشكلة تقنية';

  @override
  String get complaintTypeBilling => 'مشكلة مالية';

  @override
  String get complaintTypeSafety => 'مشكلة سلامة';

  @override
  String get whatsappUs => 'واتساب';

  @override
  String get whatsappUsDesc => 'تواصل معنا عبر واتساب';

  @override
  String get supportDesc => 'نحن هنا لمساعدتك في أي وقت وأي مكان.';

  @override
  String get chatWithUs => 'الدردشة معنا';

  @override
  String get chatWithUsDesc => 'ابدأ دردشة مباشرة مع فريق الدعم لدينا.';

  @override
  String get chatComingSoon => 'ميزة الدردشة قادمة قريبًا!';

  @override
  String get callUs => 'اتصل بنا';

  @override
  String get callUsDesc => 'اتصل بخط الدعم الخاص بنا.';

  @override
  String get emailUs => 'راسلنا عبر البريد الإلكتروني';

  @override
  String get emailUsDesc => 'أرسل لنا بريدًا إلكترونيًا وسنرد عليك بسرعة.';

  @override
  String get faqDesc => 'اعثر على إجابات للأسئلة الشائعة.';

  @override
  String get faqComingSoon => 'صفحة الأسئلة الشائعة قادمة قريبًا!';

  @override
  String get supportFooter => 'سلامتك ورضاك هما أولويتنا القصوى.';

  @override
  String get faqTitle => 'كيف يمكننا مساعدتك؟';

  @override
  String get faqSubtitle => 'إجابات سريعة على أكثر الأسئلة شيوعاً';

  @override
  String get faqPaymentQ => 'كيف يمكنني الدفع مقابل الرحلة؟';

  @override
  String get faqPaymentA => 'يمكنك الدفع نقداً، بالبطاقة، أو باستخدام رصيدك داخل التطبيق.';

  @override
  String get faqScheduleQ => 'كيف تعمل الرحلات المجدولة؟';

  @override
  String get faqScheduleA => 'يمكنك حجز رحلة حتى 90 يوماً مسبقاً والوصول في الوقت المحدد.';

  @override
  String get faqCancelQ => 'هل يمكنني إلغاء الرحلة؟';

  @override
  String get faqCancelA => 'نعم، يمكنك الإلغاء مجاناً حتى 60 دقيقة قبل موعد الرحلة.';

  @override
  String get faqSafetyQ => 'هل الرحلة آمنة؟';

  @override
  String get faqSafetyA => 'جميع السائقين موثوقين وتتوفر ميزات أمان أثناء الرحلة.';

  @override
  String get faqSupportQ => 'كيف أتواصل مع الدعم؟';

  @override
  String get faqSupportA => 'يمكنك الدردشة معنا، الاتصال بنا، أو مراسلتنا عبر البريد الإلكتروني.';

  @override
  String get appName => 'تطبيق NovaRide للركاب';

  @override
  String get version => 'الإصدار';

  @override
  String get aboutDesc => 'تطبيق NovaRide للركاب يساعدك على الوصول إلى حيث تحتاج بأمان وراحة وفي الوقت المحدد.';

  @override
  String get aboutFeature1Title => 'رحلات مريحة';

  @override
  String get aboutFeature1Desc => 'استمتع برحلات سلسة وموثوقة مع سائقين موثوقين.';

  @override
  String get aboutFeature2Title => 'جدولة مسبقة';

  @override
  String get aboutFeature2Desc => 'خطط رحلاتك مسبقًا وسافر بدون توتر.';

  @override
  String get aboutFeature3Title => 'السلامة أولاً';

  @override
  String get aboutFeature3Desc => 'سلامتك هي أولويتنا القصوى في كل خطوة من الرحلة.';

  @override
  String get aboutFooter => '© 2026 تطبيق NovaRide. جميع الحقوق محفوظة.';

  @override
  String get rideExpenses => 'مصروفات الرحلات';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get expenseCustomRange => 'مخصص';

  @override
  String get expenseTapToChangeDates => 'اضغط لتغيير التواريخ';

  @override
  String get expenseSelectDateRange => 'اختر الفترة';

  @override
  String get selectMonth => 'اختر الشهر';

  @override
  String get totalRides => 'الرحلات';

  @override
  String get avgRide => 'متوسط / رحلة';

  @override
  String get expenseBreakdown => 'تفصيل المصروفات';

  @override
  String get personal => 'شخصي';

  @override
  String get other => 'أخرى';

  @override
  String get rides => 'الرحلات';

  @override
  String get exportReport => 'تصدير تقرير CSV';

  @override
  String get exportReportHint => 'مشاركة جدول بكل الرحلات المكتملة في هذه الفترة';

  @override
  String get exportSuccess => 'التقرير جاهز للمشاركة';

  @override
  String get exportFailed => 'تعذّر التصدير. حاول مرة أخرى.';

  @override
  String get exportNoRides => 'لا توجد رحلات مكتملة في هذه الفترة';

  @override
  String get exportInProgress => 'جاري تجهيز التقرير…';

  @override
  String get expenseCsvTitle => 'NovaRide — مصروفات الرحلات';

  @override
  String get expenseCsvPeriod => 'الفترة';

  @override
  String get expenseCsvGenerated => 'تاريخ التصدير';

  @override
  String get expenseCsvTotal => 'الإجمالي';

  @override
  String get expenseCsvRideCount => 'عدد الرحلات';

  @override
  String get expenseCsvColRideId => 'رقم الرحلة';

  @override
  String get expenseCsvColDate => 'التاريخ';

  @override
  String get expenseCsvColFrom => 'من';

  @override
  String get expenseCsvColTo => 'إلى';

  @override
  String get expenseCsvColAmount => 'المبلغ (ل.س)';

  @override
  String get expenseCsvColPayment => 'الدفع';

  @override
  String get expenseCsvColPromo => 'كود الخصم';

  @override
  String get expenseCsvColDiscount => 'الخصم (ل.س)';

  @override
  String get expenseCsvColDistance => 'المسافة (كم)';

  @override
  String get expenseCsvCurrency => 'ل.س';

  @override
  String get promoSaved => 'توفير العروض';

  @override
  String get paymentCard => 'بطاقة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get completeProfile => 'أكمل ملفك الشخصي';

  @override
  String get profileSetupTitle => 'أخبرنا عنك';

  @override
  String get profileSetupDesc => 'هذه المعلومات تساعدنا في تخصيص تجربتك';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get continueText => 'متابعة';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get safetyTitle => 'سلامتك تهمنا';

  @override
  String get safetyDesc => 'أضف جهة اتصال للطوارئ حتى نتمكن من مساعدتك بسرعة إذا حدث خطأ ما.';

  @override
  String get emergencyContact => 'جهة اتصال الطوارئ';

  @override
  String get contactName => 'اسم جهة الاتصال';

  @override
  String get contactPhone => 'رقم الهاتف';

  @override
  String get save => 'حفظ';

  @override
  String get savedSuccessfully => 'تم الحفظ بنجاح';

  @override
  String get callEmergencyContact => 'اتصل بجهة اتصال الطوارئ';

  @override
  String get shareLocation => 'مشاركة الموقع المباشر';

  @override
  String get shareLocationDesc => 'سيتم مشاركة موقعك مع جهة اتصال الطوارئ الخاصة بك أثناء الرحلات';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get basicInfo => 'المعلومات الأساسية';

  @override
  String get addresses => 'العناوين';

  @override
  String get gender => 'الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get homeAddress => 'عنوان المنزل';

  @override
  String get workAddress => 'عنوان العمل';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get start => 'ابدأ';

  @override
  String get familyProfileTitle => 'حافظ على أمان عائلتك واتصالهم';

  @override
  String get familyProfileSubtitle => 'مع الملف العائلي يمكنك إدارة الرحلات والدفع والأمان لأفراد عائلتك.';

  @override
  String get familyProfilePoint1 => 'احصل على تحديثات فورية لتتبع رحلات عائلتك وضمان سلامتهم.';

  @override
  String get familyProfilePoint2 => 'إدارة المدفوعات لجميع أفراد العائلة باستخدام طريقة دفع مشتركة.';

  @override
  String get familyProfilePoint3 => 'راقب سجل الرحلات والمصاريف لما يصل إلى 9 أفراد.';

  @override
  String get createFamilyProfile => 'إنشاء ملف عائلي';

  @override
  String get familyProfileTerms => 'من خلال التسجيل، فإنك توافق على شروط استخدام الملف العائلي وتقر بإشعار الخصوصية.';

  @override
  String get familyAgeTitle => 'لمن هذا الملف؟';

  @override
  String get over18 => 'فوق 18';

  @override
  String get over18Desc => 'للبالغين القادرين على إدارة رحلاتهم.';

  @override
  String get under18 => 'تحت 18';

  @override
  String get under18Desc => 'للأطفال الذين يحتاجون إلى إشراف وتتبع للسلامة.';

  @override
  String get addFamilyMembers => 'إضافة أفراد العائلة';

  @override
  String get memberName => 'اسم الفرد';

  @override
  String get memberPhone => 'رقم الهاتف';

  @override
  String get relation => 'العلاقة';

  @override
  String get addMember => 'إضافة فرد';

  @override
  String get son => 'ابن';

  @override
  String get daughter => 'ابنة';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get familyProfileSummary => 'ملخص الملف العائلي';

  @override
  String get age => 'العمر';

  @override
  String get familyMembers => 'أفراد العائلة';

  @override
  String get familyMaxMembers => 'الحد الأقصى 9 أفراد في الملف العائلي';

  @override
  String get familySaveFailed => 'تعذر حفظ الملف العائلي';

  @override
  String get mother => 'أم';

  @override
  String get father => 'أب';

  @override
  String get accept => 'قبول';

  @override
  String get decline => 'رفض';

  @override
  String get familyInviteMother => 'دعوة الأم';

  @override
  String get familyInviteFather => 'دعوة الأب';

  @override
  String get familyInviteParent => 'دعوة ولي الأمر';

  @override
  String get familyInviteParentDesc => 'يربط حسابها/حسابه بالملف العائلي — يستطيع تتبع الرحلات والدفع مثل Uber Family';

  @override
  String get familySendInvite => 'إرسال الدعوة';

  @override
  String get familyInviteSent => 'تم إرسال الدعوة';

  @override
  String get familyInviteAccepted => 'انضممت للملف العائلي';

  @override
  String get familyPendingInvites => 'دعوات بانتظارك';

  @override
  String get familyInviteFrom => 'دعوة من';

  @override
  String get familyActiveRides => 'رحلات العائلة الآن';

  @override
  String get familyEmptyMembers => 'ادعُ الأم والأب أو أفراد العائلة برقم الهاتف';

  @override
  String get familyStatusPending => 'بانتظار القبول';

  @override
  String get familyStatusLinked => 'مرتبط';

  @override
  String get familyStatusDeclined => 'مرفوض';

  @override
  String get familyStatusContact => 'جهة اتصال';

  @override
  String get familyYouAreOwner => 'أنت مدير الملف العائلي';

  @override
  String get familyManagedBy => 'ملف عائلة';

  @override
  String get familyCanManage => 'إدارة مشتركة';

  @override
  String get familyCanPay => 'دفع مشترك';

  @override
  String get familyRoleParent => 'ولي أمر';

  @override
  String get familyRoleMember => 'فرد';

  @override
  String get familyFillAll => 'أكمل كل الحقول';

  @override
  String get familyRideActive => 'رحلة جارية';

  @override
  String get inviteTitle => 'دعوة المراهقين والبالغين';

  @override
  String get inviteSubtitle => 'أنشئ ملف عائلي لتسهيل الحياة لك ولأحبائك.';

  @override
  String get featureSafetyTitle => 'أمان حساب المراهقين';

  @override
  String get featureSafetyDesc => 'ميزات أمان مدمجة وسائقين موثوقين.';

  @override
  String get featureTrackingTitle => 'تتبع الرحلات مباشرة';

  @override
  String get featureTrackingDesc => 'تابع موقع عائلتك لحظة بلحظة.';

  @override
  String get featurePaymentTitle => 'الدفع عن العائلة';

  @override
  String get featurePaymentDesc => 'استخدم وسيلة دفع مشتركة.';

  @override
  String get featureLimitsTitle => 'تحديد حدود الإنفاق';

  @override
  String get featureLimitsDesc => 'اختر المبلغ المسموح لكل فرد.';

  @override
  String get adult => 'أنا بالغ';

  @override
  String get adultDesc => '18 سنة وما فوق';

  @override
  String get teen => 'أنا مراهق';

  @override
  String get teenDesc => 'من 13 إلى 17';

  @override
  String get inviteAdultsTitle => 'دعوة البالغين إلى الملف العائلي';

  @override
  String get inviteAdultsSubtitle => 'اعتنِ بأحبائك، يمكنك:';

  @override
  String get inviteAdultsFeature1 => 'الدفع للرحلات والطلبات';

  @override
  String get inviteAdultsFeature1Desc => 'مشاركة وسيلة الدفع.';

  @override
  String get inviteAdultsFeature2 => 'تحديد حدود الإنفاق';

  @override
  String get inviteAdultsFeature2Desc => 'إدارة المصروف الشهري.';

  @override
  String get inviteAdultsFeature3 => 'تتبع الرحلات';

  @override
  String get inviteAdultsFeature3Desc => 'من البداية حتى النهاية.';

  @override
  String get inviteAdultsFeature4 => 'تواصل مباشر';

  @override
  String get inviteAdultsFeature4Desc => 'تواصل مع أفراد العائلة في أي وقت.';

  @override
  String get inviteAdultsButton => 'دعوة البالغين';

  @override
  String get inviteTeenAdults => 'Invite teenagers and adults';

  @override
  String get track => 'اتبع الرحلات مباشرة';

  @override
  String get trackDesc => 'تابع موقع عائلتك لحظة بلحظة.';

  @override
  String get payDesc => 'استخدم وسيلة دفع مشتركة.';

  @override
  String get limit => 'تحديد حدود الإنفاق';

  @override
  String get limitDesc => 'اختر المبلغ المسموح لكل فرد.';

  @override
  String get invitePay => 'الدفع للرحلات والطلبات';

  @override
  String get invitePayDesc => 'مشاركة طريقة الدفع.';

  @override
  String get inviteLimit => 'تحديد حدود الإنفاق';

  @override
  String get inviteLimitDesc => 'إدارة الإنفاق الشهري للعائلة.';

  @override
  String get inviteFollow => 'تتبع الرحلات';

  @override
  String get inviteFollowDesc => 'تتبع الرحلات من البداية للنهاية.';

  @override
  String get brother => 'أخ';

  @override
  String get sister => 'أخت';

  @override
  String get wife => 'زوجة';

  @override
  String get husband => 'زوج';

  @override
  String get summary => 'ملخص';

  @override
  String get yourPersonalData => 'بياناتك الشخصية';

  @override
  String get downloadYourData => 'تحميل نسخة من بياناتك';

  @override
  String get downloadYourDataDesc => 'يمكنك طلب نسخة كاملة من جميع معلوماتك المخزنة.';

  @override
  String get deleteAccountDesc => 'حذف حسابك نهائيًا وجميع البيانات المرتبطة به.';

  @override
  String get download => 'تحميل';

  @override
  String get upcomingTrips => 'رحلاتي اللاحقة';

  @override
  String get noUpcomingTrips => 'لا يوجد رحلات حالياً';

  @override
  String get bookNow => 'احجز رحلتك من الآن';

  @override
  String get waterTankerTitle => 'طلب صهريج مياه';

  @override
  String get barrels => 'عدد البراميل';

  @override
  String get waterType => 'نوع المياه';

  @override
  String get selectWaterType => 'اختر نوع المياه';

  @override
  String get drinkingWater => 'مياه شرب';

  @override
  String get regularWater => 'مياه عادية';

  @override
  String get agriculturalWater => 'مياه زراعية';

  @override
  String get location => 'الموقع';

  @override
  String get selectLocation => 'حدد موقعك';

  @override
  String get estimatedPrice => 'السعر التقديري';

  @override
  String get eta => 'وقت الوصول المتوقع';

  @override
  String get placeOrder => 'تأكيد الطلب';

  @override
  String get now => 'الآن';

  @override
  String get carWashTitle => 'غسيل سيارات متنقل';

  @override
  String get serviceType => 'نوع الخدمة';

  @override
  String get exteriorWash => 'غسيل خارجي';

  @override
  String get interiorWash => 'تنظيف داخلي';

  @override
  String get fullWash => 'غسيل كامل';

  @override
  String get carsCount => 'عدد السيارات';

  @override
  String get carType => 'نوع السيارة';

  @override
  String get smallCar => 'سيارة صغيرة';

  @override
  String get suv => 'دفع رباعي';

  @override
  String get truck => 'شاحنة';

  @override
  String get movingService => 'خدمة نقل';

  @override
  String get moveItems => 'نقل الأغراض';

  @override
  String get movingDescription => 'نقل الأثاث والصناديق وغيرها';

  @override
  String get movingTitle => 'خدمة نقل';

  @override
  String get itemsType => 'نوع الأغراض';

  @override
  String get furniture => 'أثاث';

  @override
  String get boxes => 'صناديق';

  @override
  String get mixed => 'متنوع';

  @override
  String get vehicleSize => 'حجم السيارة';

  @override
  String get smallTruck => 'شاحنة صغيرة';

  @override
  String get mediumTruck => 'شاحنة متوسطة';

  @override
  String get largeTruck => 'شاحنة كبيرة';

  @override
  String get workers => 'عدد العمال';

  @override
  String get noData => 'لا توجد بيانات متاحة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get guest => 'ضيف';

  @override
  String get hey => 'مرحباً';

  @override
  String get pricesmayvary => 'قد تختلف الأسعار';

  @override
  String get seats => 'عدد المقاعد';

  @override
  String get noTransactions => 'لا توجد معاملات بعد';

  @override
  String get deleteAccountConfirm => 'لا يمكن التراجع. حذف حسابك وجميع بياناتك نهائيًا؟';

  @override
  String get dataExportReady => 'نسخة بياناتك جاهزة للمشاركة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get keep_Ride => 'الحفاظ على الرحلة';

  @override
  String get your_driver_is_on_the_way => '.سائقك في الطريق.';

  @override
  String get cancel_ride => 'إلغاء الرحلـة ?';

  @override
  String get cancel_ride_confirm => 'هل أنت متأكد من إلغاء هذه الرحلة؟';

  @override
  String get ride_cancelled => 'تم إلغاء الرحلة';

  @override
  String get findYourDriver => 'ابحث عن سائقك...';

  @override
  String get yourDriverIsOnTheWay => 'سائقك في الطريق';

  @override
  String get driverHasArrived => 'سائقك قد وصل!';

  @override
  String get youAreOnBoard => 'أنت على متن الرحلة';

  @override
  String get headingToDestination => 'في الطريق إلى الوجهة';

  @override
  String get when => 'متى؟';

  @override
  String get pickup => 'نقطة الانطلاق';

  @override
  String get destination => 'الوجهة';

  @override
  String get searchDestinationforscudule => 'ابحث عن وجهة...';

  @override
  String get confirmSchedule => 'تأكيد الجدولة';

  @override
  String get validTime => '✓ وقت صالح';

  @override
  String get minAhead => '⚠️ يجب قبل 30 دقيقة على الأقل';

  @override
  String get done => 'تم';

  @override
  String get fare => 'السعر';

  @override
  String get selectDateTime => 'اختر التاريخ والوقت';

  @override
  String get selectDestination => 'يرجى اختيار الوجهة';

  @override
  String get scheduleAhead => 'يجب أن يكون الحجز قبل 30 دقيقة على الأقل';

  @override
  String get minimumAhead => 'يجب أن يكون قبل 30 دقيقة على الأقل';

  @override
  String get ready => 'جاهز للجدولة';

  @override
  String get tapMap => 'اضغط على الخريطـة لاختيار الوجهة';

  @override
  String get selectDateDestination => 'اختر التاريخ والوجهة';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get tapMapSelect => 'اضغط على الخريطة لاختيار موقعك';

  @override
  String get gettingAddress => 'جاري جلب العنوان...';

  @override
  String get unknownLocation => 'موقع غير معروف';

  @override
  String get gettingYourLocation => 'جاري تحديد موقعك…';

  @override
  String get enableLocationPermission => 'يرجى السماح بالوصول إلى الموقع من إعدادات الجهاز لحجز رحلة';

  @override
  String get rideNoLongerActive => 'هذه الرحلة لم تعد نشطة';

  @override
  String get rideDismissed => 'تم إغلاق شاشة الرحلة';

  @override
  String get cancelRideConfirm => 'هل تريد إلغاء هذه الرحلة؟';

  @override
  String get cancellingRide => 'جاري إلغاء الرحلة…';

  @override
  String get rideNoDriverPhone => 'رقم السائق غير متوفر';

  @override
  String get rideCallFailed => 'تعذّر إجراء المكالمة';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا يوجد إشعارات';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get sosButton => 'طوارئ SOS';

  @override
  String get sosActivated => 'تم إرسال تنبيه الطوارئ';

  @override
  String get safetyDuringRide => 'السلامة أثناء الرحلة';

  @override
  String get callEmergencyServices => 'اتصال بالطوارئ (112)';

  @override
  String get rideSummary => 'ملخص الرحلة';

  @override
  String get to => 'إلى';

  @override
  String get rideScheduled => '🎉تم جدولة الرحلة!';

  @override
  String rideIdLabel(int id) {
    return 'رحلة #$id';
  }

  @override
  String get yourdriver => 'سائقك سيتم إعلامه 15 دقيقة قبل وقت الجدولة.';

  @override
  String get ride => 'رحلة';

  @override
  String get rideStepFinding => 'البحث';

  @override
  String get rideStepAssigned => 'تم التعيين';

  @override
  String get rideStepArrived => 'وصل السائق';

  @override
  String get rideStepRiding => 'في الرحلة';

  @override
  String get rateYourRide => 'قيّم رحلتك';

  @override
  String get howWasYourTrip => 'كيف كانت رحلتك؟';

  @override
  String get skip => 'تخطّي';

  @override
  String get submit => 'إرسال';

  @override
  String get ratingSubmitted => 'شكراً لتقييمك!';

  @override
  String get ratingFailed => 'تعذّر إرسال التقييم';

  @override
  String get comingSoon => 'قريباً!';

  @override
  String get scheduledRideActivated => 'رحلتك المجدولة بدأت البحث عن سائق';

  @override
  String get chatEmpty => 'لا رسائل بعد. ابدأ المحادثة!';

  @override
  String get chatTypeMessage => 'اكتب رسالة…';

  @override
  String get chatWithDriver => 'محادثة السائق';

  @override
  String get myScheduledRides => 'رحلاتي المجدولة';

  @override
  String get noScheduledRides => 'لا توجد رحلات مجدولة';

  @override
  String get noScheduledRidesHint => 'اجدول رحلة لتظهر هنا';

  @override
  String get cancelScheduledRideTitle => 'إلغاء الرحلة المجدولة';

  @override
  String get cancelScheduledRideConfirm => 'هل أنت متأكد من إلغاء هذه الرحلة المجدولة؟';

  @override
  String get keepIt => 'تراجع';

  @override
  String get cancelRideAction => 'إلغاء الرحلة';

  @override
  String get rescheduleRideAction => 'تعديل الموعد';

  @override
  String get rescheduleRideSuccess => 'تم تحديث موعد الرحلة';

  @override
  String get scheduleMinLeadTime => 'يجب أن يكون الموعد بعد 30 دقيقة على الأقل';

  @override
  String get cancelling => 'جارٍ الإلغاء…';

  @override
  String get rideCancelled => 'تم إلغاء الرحلة';

  @override
  String get calculatingPrice => 'جارِ حساب السعر…';

  @override
  String get setDateDestForPrice => 'حدّد الموعد والوجهة لعرض السعر التقديري';

  @override
  String kmMinutes(String km, String min) {
    return '$km كم · $min دقيقة';
  }

  @override
  String get surgePricing => 'تسعير الذروة';

  @override
  String get surgeElevated => 'طلب متزايد';

  @override
  String get surgeHigh => 'الطلب مرتفع';

  @override
  String get surgeVeryHigh => 'الطلب مرتفع جداً';

  @override
  String get surgeExplain => 'ارتفاع الطلب رفع السعر مؤقتاً';

  @override
  String surgeExplainZone(String zone) {
    return 'ارتفاع الطلب في $zone رفع السعر مؤقتاً';
  }

  @override
  String surgeDialogBody(String mult) {
    return 'الأسعار أعلى من المعتاد بمقدار ×$mult بسبب ارتفاع الطلب حالياً.';
  }

  @override
  String surgeDialogBodyZone(String mult, String zone) {
    return 'الأسعار أعلى من المعتاد بمقدار ×$mult بسبب ارتفاع الطلب في $zone حالياً.';
  }

  @override
  String get surgeDialogHint => 'تنخفض الأسعار عند تراجع الطلب.';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get surgeMapTitle => 'خريطة الطلب والأسعار';

  @override
  String get surgeMapSubtitle => 'مناطق الطلب الحيّة';

  @override
  String get surgeMapNormal => 'عادي';

  @override
  String surgeMapUpdated(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get surgeNoZones => 'لا توجد مناطق طلب مرتفع حالياً';

  @override
  String get viewSurgeMap => 'خريطة الطلب';

  @override
  String get accessibleRide => 'ملائم للكراسي المتحركة';

  @override
  String get vehicleTypeLabel => 'نوع المركبة';

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get cashPayment => 'كاش';

  @override
  String get shamCashPayment => 'شام كاش';

  @override
  String get ratingTagsTitle => 'ما الذي أعجبك؟';

  @override
  String get ratingCommentHint => 'أضف تعليقاً (اختياري)';

  @override
  String get ratingTagClean => 'سيارة نظيفة';

  @override
  String get ratingTagFriendly => 'ودود';

  @override
  String get ratingTagOnTime => 'في الوقت';

  @override
  String get ratingTagSafe => 'قيادة آمنة';

  @override
  String get ratingTagNavigation => 'مسار جيد';

  @override
  String get ratingTagProfessional => 'محترف';

  @override
  String get tipTitle => 'إكرامية للسائق';

  @override
  String get tipNone => 'بدون إكرامية';

  @override
  String get submitRating => 'إرسال التقييم';

  @override
  String get ratingStarsLabel => 'تقييم بالنجوم';

  @override
  String get addSavedPlace => 'إضافة مكان محفوظ';

  @override
  String get placeLabel => 'اسم المكان';

  @override
  String get placeAddress => 'العنوان';

  @override
  String get latitude => 'خط العرض';

  @override
  String get longitude => 'خط الطول';

  @override
  String get noSavedPlaces => 'لا أماكن محفوظة بعد';

  @override
  String get multiStopTitle => 'محطات إضافية';

  @override
  String get addStop => 'إضافة محطة';

  @override
  String get removeStop => 'إزالة';

  @override
  String get splitFareTitle => 'تقسيم الأجرة';

  @override
  String get splitFareHint => 'يدفع الصديق حصته عبر دعوة التطبيق';

  @override
  String get splitFarePhone => 'رقم هاتف الصديق';

  @override
  String get splitFarePercent => 'حصته (%)';

  @override
  String get splitFareInvitesTitle => 'دعوات تقسيم الأجرة';

  @override
  String get splitFareInvitesEmpty => 'لا توجد دعوات تقسيم';

  @override
  String get splitFareAccept => 'قبول';

  @override
  String get splitFareDecline => 'رفض';

  @override
  String get splitFareAccepted => 'تم قبول تقسيم الأجرة';

  @override
  String get splitFareAcceptedStatus => 'قبلت هذا التقسيم';

  @override
  String get splitFareYourShare => 'حصتك';

  @override
  String get splitFarePayShare => 'ادفع حصتي';

  @override
  String get splitFareFriendInvite => 'دعوة تقسيم أجرة';

  @override
  String get splitFareInviteSent => 'تم إرسال الدعوة لصديقك';

  @override
  String get splitFarePending => 'بانتظار قبول الصديق';

  @override
  String get splitFarePrimaryShare => 'أنت تدفع';

  @override
  String promoActivated(String code, String percent) {
    return 'تم تفعيل $code — خصم $percent%';
  }

  @override
  String get promoActiveNextRide => 'كود نشط للرحلة القادمة';

  @override
  String get promoApplyCode => 'تطبيق الكود';

  @override
  String get promoTapToActivate => 'اضغط للتفعيل';

  @override
  String promoMinFare(String amount) {
    return 'حد أدنى $amount';
  }

  @override
  String promoValidUntil(String date) {
    return 'حتى $date';
  }

  @override
  String get promoPullRefresh => 'اسحب للأسفل للتحديث';

  @override
  String get promoActivatedBadge => 'مفعّل';

  @override
  String get confirmRide => 'تأكيد الرحلة';

  @override
  String get offlineRideQueued => 'تم حفظ الطلب — سنحجز عند عودة الاتصال';

  @override
  String get offlineScheduledRideQueued => 'تم حفظ الرحلة المجدولة — سنؤكدها عند عودة الاتصال';

  @override
  String get offlineQueueFlushing => 'جارٍ إرسال الطلبات المحفوظة…';

  @override
  String get offlineQueueFlushDone => 'تم إرسال الطلبات المحفوظة بنجاح';

  @override
  String offlineQueuePendingOnline(int count) {
    return '$count رحلة بانتظار المزامنة';
  }

  @override
  String offlineQueuePendingScheduled(int count) {
    return '$count رحلة مجدولة محفوظة دون اتصال';
  }

  @override
  String offlineQueuePendingInstant(int count) {
    return '$count رحلة فورية محفوظة دون اتصال';
  }

  @override
  String offlineQueuePendingMixed(int scheduled, int instant) {
    return '$scheduled مجدولة و$instant فورية محفوظة دون اتصال';
  }

  @override
  String get a11yOpenMenu => 'فتح القائمة';

  @override
  String get a11ySafety => 'خيارات السلامة';

  @override
  String get a11ySurgeMap => 'فتح خريطة الطلب';

  @override
  String get a11yRecenterMap => 'توسيط الخريطة على موقعك';

  @override
  String a11ySelectVehicle(String vehicle) {
    return 'اختيار $vehicle';
  }

  @override
  String get a11yScheduleRide => 'جدولة رحلة لاحقاً';

  @override
  String get a11yWhereTo => 'اختيار الوجهة';

  @override
  String get minutesShort => 'دقيقة';

  @override
  String discountPromo(String code, String amount) {
    return 'خصم $code: -$amount';
  }

  @override
  String get referralTitle => 'ادعُ أصدقاءك';

  @override
  String get referralYourCode => 'رمز الإحالة الخاص بك';

  @override
  String get referralCopied => 'تم نسخ الرمز';

  @override
  String get referralTotal => 'إجمالي الإحالات';

  @override
  String get referralRewarded => 'مكافأة';

  @override
  String get referralPending => 'قيد الانتظار';

  @override
  String get referralEarned => 'إجمالي الأرباح';

  @override
  String get referralApplyHint => 'لديك رمز؟ أدخله هنا';

  @override
  String get referralApply => 'تطبيق الرمز';

  @override
  String get referralApplied => 'تم تطبيق رمز الإحالة';

  @override
  String get splitFareDeclinedStatus => 'الصديق رفض تقسيم الأجرة';

  @override
  String get splitFarePaidStatus => 'الصديق دفع حصته';

  @override
  String get splitFareRequiresShamCash => 'تقسيم الأجرة يتطلب شام كاش';

  @override
  String rideNumber(int id) {
    return 'رحلة #$id';
  }

  @override
  String get actionFailed => 'فشلت العملية';

  @override
  String get codeSentSuccess => 'تم إرسال الرمز';

  @override
  String distanceKmUnit(String km) {
    return '$km كم';
  }

  @override
  String rideEtaMinutes(int minutes) {
    return 'الوصول خلال $minutes د';
  }

  @override
  String get tripStatusScheduled => 'مجدولة';

  @override
  String get tripStatusSearching => 'بحث';

  @override
  String get tripStatusAssigned => 'السائق في الطريق';

  @override
  String get tripStatusArrived => 'وصل السائق';

  @override
  String get tripStatusOnboard => 'صعدت';

  @override
  String get tripStatusStarted => 'جارية';

  @override
  String get tripStatusCompleted => 'مكتملة';

  @override
  String get tripStatusCancelled => 'ملغاة';

  @override
  String get tripStatusNoDriver => 'لا سائق';

  @override
  String get availableBalance => 'الرصيد المتاح';

  @override
  String get cardPayment => 'بطاقة';

  @override
  String get noDriverFoundRetry => 'لم نجد سائقاً — يمكنك إعادة البحث';

  @override
  String get failedToLoad => 'تعذّر التحميل';

  @override
  String get failedToUploadPhoto => 'تعذّر رفع الصورة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get deleteAccountWarning => 'هذا الإجراء لا يمكن التراجع عنه. هل أنت متأكد؟';

  @override
  String get deleteAccountAction => 'حذف';

  @override
  String get fillAllFields => 'يرجى تعبئة جميع الحقول';

  @override
  String get failedToSave => 'فشل الحفظ';

  @override
  String get orderPlacedTitle => 'تم تأكيد الطلب!';

  @override
  String orderPlacedBody(String id) {
    return 'طلب #$id مؤكد';
  }

  @override
  String orderEta(String eta) {
    return 'الوصول: $eta';
  }

  @override
  String get orderPlaceFailed => 'فشل إرسال الطلب';

  @override
  String multiStopNumber(int n) {
    return 'توقف $n';
  }

  @override
  String get locationPickFailed => 'تعذّر تحديد الموقع';

  @override
  String get loginError => 'حدث خطأ';

  @override
  String get fareEstimateFailed => 'تعذّر حساب السعر';

  @override
  String locationPickFor(String place) {
    return '$place — تعذّر تحديد الموقع';
  }

  @override
  String get reportTypeSafety => 'سلامة';

  @override
  String get reportTypeDriver => 'السائق';

  @override
  String get reportTypeBilling => 'الدفع';

  @override
  String get reportTypeTechnical => 'تقني';

  @override
  String get reportDescribeHint => 'صف المشكلة…';

  @override
  String get reportSubmitted => 'تم إرسال البلاغ';

  @override
  String get benefitsTitle => 'المزايا والعروض';

  @override
  String get benefitsHeadline => 'استفد من مزايا NovaRide';

  @override
  String get benefitsDesc => 'إدارة العائلة، العروض، الإحالات، وتقسيم الأجرة — كلها من مكان واحد.';

  @override
  String get benefitsFamilySubtitle => 'تابع رحلات أفراد العائلة';

  @override
  String get benefitsPromosSubtitle => 'أكواد خصم نشطة';

  @override
  String get benefitsReferralSubtitle => 'ادعُ أصدقاءك واكسب';

  @override
  String get benefitsSplitFareSubtitle => 'دعوات تقسيم الأجرة';

  @override
  String get privacyRequestTitle => 'طلب خصوصية';

  @override
  String get privacyOptionalDetails => 'تفاصيل اختيارية…';

  @override
  String get privacyRequestSubmitted => 'تم إرسال الطلب';

  @override
  String get privacyRequestsGdpr => 'طلبات الخصوصية (GDPR)';

  @override
  String get privacyAccessTitle => 'طلب نسخة بياناتي';

  @override
  String get privacyAccessSubtitle => 'الحق في الوصول لبياناتك';

  @override
  String get privacyErasureTitle => 'طلب حذف البيانات';

  @override
  String get privacyErasureSubtitle => 'الحق في المحو';

  @override
  String get policyUpdateTitle => 'تحديث السياسات';

  @override
  String get policyUpdateBody => 'يرجى مراجعة السياسات المحدّثة والموافقة للمتابعة.';

  @override
  String surgeChipLabel(String mult, String zone) {
    return 'ذروة ×$mult$zone';
  }

  @override
  String get updatePersonalInfo => 'حدّث معلوماتك الشخصية';

  @override
  String get gpsLocation => 'موقع GPS';

  @override
  String get noDriverRetryShort => 'لم نجد سائقاً — أعد البحث';

  @override
  String get poolRideTitle => 'رحلة مشتركة (NovaPool)';

  @override
  String get poolRideSubtitle => 'وفّر حتى 30% — شارك السيارة';

  @override
  String get poolPassengersLabel => 'عدد الركاب';

  @override
  String get vehicleMoto => 'موتور';

  @override
  String get vehicleMotoSubtitle => 'راكب واحد · سريع واقتصادي';

  @override
  String get vehicleVanSeatsSubtitle => '6+ ركاب';

  @override
  String get vehicleTaxiSubtitle => 'تكسي مرخّص';

  @override
  String get vehicleCarSeatsSubtitle => '4 ركاب';

  @override
  String get rideTripDetails => 'تفاصيل المشوار';

  @override
  String get rideTripDetailsHint => 'التقِ بالشريك السائق في موقع الالتقاء';

  @override
  String get safetyRecordAudio => 'سجّل الصوت لمزيد من السلامة';

  @override
  String get safetyRecordStart => 'ابدأ';

  @override
  String get safetyRecording => 'جاري التسجيل...';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String get activeRideMeetDriver => 'التقِ بالشريك السائق في موقع الالتقاء';

  @override
  String activeRideMeetDriverEta(int minutes) {
    return 'الالتقاء بالشريك السائق خلال $minutes من الدقائق';
  }

  @override
  String activeRideArriveDropoffEta(int minutes) {
    return 'الوصول للوجهة خلال $minutes من الدقائق';
  }

  @override
  String get ridePickupLabel => 'نقطة الانطلاق';

  @override
  String get rideDropoffLabel => 'الوجهة';

  @override
  String get mapMeetingPoint => 'نقطة الالتقاء';

  @override
  String get rideDriverLabel => 'السائق';

  @override
  String get rideOpenSafety => 'السلامة';

  @override
  String get rideCancelTitle => 'إلغاء الرحلة؟';

  @override
  String get multiStopLabel => 'محطة';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';
}
