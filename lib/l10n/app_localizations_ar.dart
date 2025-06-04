// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'متجري الإلكتروني';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get nameOptional => 'الاسم (اختياري)';

  @override
  String get addressOptional => 'العنوان (اختياري)';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get noAccount => 'ليس لديك حساب؟ أنشئ حساباً الآن';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get emailRequired => 'الرجاء إدخال بريد إلكتروني صالح.';

  @override
  String get passwordLength => 'كلمة المرور يجب أن تتكون من 6 أحرف على الأقل.';

  @override
  String get passwordMismatch => 'كلمة المرور وتأكيد كلمة المرور غير متطابقين.';

  @override
  String get authError => 'حدث خطأ في المصادقة.';

  @override
  String get userNotFound => 'لا يوجد مستخدم بهذا البريد الإلكتروني.';

  @override
  String get wrongPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get emailAlreadyInUse => 'هذا البريد الإلكتروني مستخدم بالفعل.';

  @override
  String get weakPassword => 'كلمة المرور ضعيفة جداً.';

  @override
  String get invalidEmail => 'صيغة البريد الإلكتروني غير صالحة.';

  @override
  String get networkError =>
      'فشل الاتصال بالشبكة. الرجاء التحقق من اتصالك بالإنترنت.';

  @override
  String get accountCreated => 'تم إنشاء الحساب بنجاح!';

  @override
  String get loggedInSuccessfully => 'تم تسجيل الدخول بنجاح!';

  @override
  String get resetPasswordEmailSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة (6 أحرف على الأقل)';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordChangeFailed => 'فشل تغيير كلمة المرور.';

  @override
  String get wrongCurrentPassword => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get reauthenticateRequired =>
      'الرجاء تسجيل الدخول مرة أخرى لتغيير كلمة المرور.';

  @override
  String get errorOccurred => 'حدث خطأ: ';

  @override
  String get homeTitle => 'المنتجات';

  @override
  String get cartTitle => 'سلة الشراء';

  @override
  String get settingsTitle => 'إعدادات الحساب';

  @override
  String get adminPanelTitle => 'لوحة تحكم الأدمن';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get newProduct => 'إضافة منتج جديد';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get productNumber => 'رقم المنتج (فريد للواتساب)';

  @override
  String get priceSAR => 'السعر (ر.س)';

  @override
  String get description => 'الوصف';

  @override
  String get selectImage => 'الرجاء اختيار صورة للمنتج.';

  @override
  String get productAdded => 'تم إضافة المنتج بنجاح!';

  @override
  String get productUpdated => 'تم تعديل المنتج بنجاح!';

  @override
  String get operationFailed => 'فشل العملية: ';

  @override
  String get addToCart => 'أضف للسلة';

  @override
  String get cartEmpty => 'سلة الشراء فارغة!';

  @override
  String get addProductsToShop => 'أضف بعض المنتجات لتبدأ التسوق.';

  @override
  String get total => 'الإجمالي:';

  @override
  String get sendOrderWhatsApp => 'إرسال الطلب عبر واتساب';

  @override
  String get clearCart => 'إفراغ السلة';

  @override
  String get whatsappNotInstalled =>
      'لا يمكن فتح واتساب. تأكد من تثبيته على جهازك.';

  @override
  String get orderSent => 'تم إرسال الطلب عبر واتساب!';

  @override
  String get productDeleted => 'تم حذف المنتج بنجاح!';

  @override
  String get deleteFailed => 'فشل حذف المنتج: ';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String confirmDeleteProduct(Object productName) {
    return 'هل أنت متأكد أنك تريد حذف المنتج \"$productName\"؟';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get noProducts =>
      'لا توجد منتجات حالياً. اضغط على زر الإضافة لإضافة منتج جديد.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get loginRequired => 'الرجاء تسجيل الدخول للمتابعة.';

  @override
  String get emailVerificationNeeded =>
      'تم إنشاء الحساب! الرجاء التحقق من بريدك الإلكتروني لتسجيل الدخول.';

  @override
  String get emailVerificationSent =>
      'تم إرسال بريد التحقق إلى بريدك الإلكتروني. الرجاء التحقق من صندوق الوارد.';

  @override
  String get verifyEmailToLogin =>
      'الرجاء التحقق من بريدك الإلكتروني لتسجيل الدخول.';

  @override
  String get whatsappChoiceTitle => 'اختر تطبيق واتساب';

  @override
  String get whatsappChoiceMessage =>
      'أي تطبيق واتساب تود استخدامه لإرسال الطلب؟';

  @override
  String get whatsappStandard => 'واتساب العادي';

  @override
  String get whatsappBusiness => 'واتساب للأعمال';

  @override
  String get updateAccountSuccessfully => 'تم تحديث إعدادات الحساب بنجاح!';

  @override
  String get fetchingUserDataError => 'خطأ في جلب بيانات المستخدم: ';

  @override
  String get updateUserDataError => 'خطأ في تحديث بيانات المستخدم: ';

  @override
  String get createAccountError => 'حدث خطأ أثناء إنشاء الحساب.';

  @override
  String get signInError => 'حدث خطأ أثناء تسجيل الدخول.';

  @override
  String get signOutError => 'حدث خطأ أثناء تسجيل الخروج.';

  @override
  String get sendResetEmailError =>
      'حدث خطأ أثناء إرسال بريد إعادة تعيين كلمة المرور.';

  @override
  String get loadingProductsError => 'خطأ في تحميل المنتجات: ';

  @override
  String get noProductsAvailable => 'لا توجد منتجات حالياً.';

  @override
  String productAddedToCart(Object productName) {
    return 'تم إضافة $productName إلى السلة!';
  }

  @override
  String productQuantityAddedToCart(Object productName, Object quantity) {
    return 'تم إضافة $productName (الكمية: $quantity) إلى السلة!';
  }

  @override
  String get productRemovedFromCart => 'تم حذف المنتج من السلة.';

  @override
  String get cartCleared => 'تم إفراغ السلة.';

  @override
  String get enterYourName => 'الرجاء إدخال اسمك.';

  @override
  String get enterValidPrice => 'الرجاء إدخال سعر صالح.';

  @override
  String get enterProductNumber => 'الرجاء إدخال رقم المنتج.';

  @override
  String get enterProductName => 'الرجاء إدخال اسم المنتج.';

  @override
  String get enterProductDescription => 'الرجاء إدخال وصف للمنتج.';

  @override
  String get imageNotSelected => 'لم يتم اختيار صورة.';

  @override
  String get whatsappInquiryMessage =>
      'مرحباً، أود الاستفسار عن المنتجات المتوفرة في متجركم.';

  @override
  String get productNumberShort => 'رقم';

  @override
  String get quantity => 'الكمية';

  @override
  String get currencySymbol => 'ل.س';

  @override
  String get whatsappOrderStart => 'مرحباً، أود طلب المنتجات التالية:\n\n';

  @override
  String get whatsappConfirmOrder => 'الرجاء تأكيد الطلب.';

  @override
  String get passwordChangeSuccess => 'تم تغيير كلمة المرور بنجاح!';

  @override
  String get name => 'الاسم';

  @override
  String get address => 'العنوان';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get skippingOldImageDeletion =>
      'تجاوز حذف الصورة القديمة من Cloudinary من جانب العميل.';

  @override
  String get newUser => 'مستخدم جديد';

  @override
  String get home => 'الرئيسية';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get languageChangedSuccessfully => 'تم تغيير اللغة بنجاح!';

  @override
  String get enterCurrentPassword => 'الرجاء إدخال كلمة المرور الحالية.';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get customerAddress => 'عنوان العميل';

  @override
  String get productNumberExists =>
      'رقم المنتج موجود بالفعل. الرجاء إدخال رقم فريد.';

  @override
  String get priceUSD => 'السعر (دولار)';

  @override
  String get dollarExchangeRate => 'سعر صرف الدولار (ل.س)';

  @override
  String get enterDollarExchangeRate => 'الرجاء إدخال سعر صرف الدولار.';

  @override
  String get syrianPound => 'ل.س';

  @override
  String get dollarExchangeRateUpdated => 'تم تحديث سعر صرف الدولار بنجاح!';

  @override
  String get productNameAr => 'اسم المنتج (العربية)';

  @override
  String get productNameEn => 'اسم المنتج (الإنجليزية)';

  @override
  String get productDescriptionAr => 'وصف المنتج (العربية)';

  @override
  String get productDescriptionEn => 'وصف المنتج (الإنجليزية)';

  @override
  String get enterProductNameAr => 'الرجاء إدخال اسم المنتج باللغة العربية.';

  @override
  String get enterProductNameEn => 'الرجاء إدخال اسم المنتج باللغة الإنجليزية.';

  @override
  String get enterProductDescriptionAr =>
      'الرجاء إدخال وصف المنتج باللغة العربية.';

  @override
  String get enterProductDescriptionEn =>
      'الرجاء إدخال وصف المنتج باللغة الإنجليزية.';
}
