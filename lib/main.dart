import 'dart:io'; // مطلوب لعمليات الملفات (مثل اختيار الصور)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_store_app/firebase_options.dart';
import 'package:my_store_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // استيراد حزمة Cloudinary لرفع الصور

/// نقطة الدخول الرئيسية للتطبيق.
/// تقوم بتهيئة Firebase وتشغيل التطبيق.
void main() async {
  // التأكد من تهيئة Widgets قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة Firebase باستخدام الخيارات الافتراضية للمنصة الحالية
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // تشغيل التطبيق
  runApp(const MyApp());
}

/// الـ Widget الرئيسي للتطبيق.
/// يقوم بإعداد المزودات (Providers) وإدارة حالة المصادقة لعرض الشاشة المناسبة.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // مزود لإدارة سلة التسوق
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        // مزود لإدارة بيانات المستخدم وحالته (أدمن أم لا)
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        // مزود لإدارة لغة التطبيق
        ChangeNotifierProvider(
            create: (ctx) => LocaleProvider()),
        // مزود لإدارة سعر صرف الدولار
        ChangeNotifierProvider(
            create: (ctx) => ExchangeRateProvider()),
      ],
      // Consumer للاستماع إلى تغييرات اللغة وتحديث التطبيق بناءً عليها
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // توليد عنوان التطبيق بناءً على اللغة المختارة
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appName,
            // تحديد مندوبي الترجمة المدعومين
            localizationsDelegates: const [
              AppLocalizations
                  .delegate, // مندوب الترجمة الخاص بنا
              GlobalMaterialLocalizations
                  .delegate, // مندوب ترجمة مكونات Material Design
              GlobalWidgetsLocalizations
                  .delegate, // مندوب ترجمة Widgets
              GlobalCupertinoLocalizations
                  .delegate, // مندوب ترجمة مكونات Cupertino
            ],
            // اللغات المدعومة في التطبيق
            supportedLocales: const [
              Locale('ar', ''), // دعم اللغة العربية
              Locale('en', ''), // دعم اللغة الإنجليزية
            ],
            // تحديد اللغة الحالية للتطبيق بناءً على LocaleProvider
            locale: localeProvider.locale,
            // دالة لحل اللغة إذا لم تكن اللغة المفضلة للمستخدم مدعومة
            localeResolutionCallback:
                (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode ==
                    locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales
                  .first; // العودة إلى أول لغة مدعومة (العربية في هذه الحالة)
            },
            // تعريف سمات التصميم العامة للتطبيق
            theme: ThemeData(
              primarySwatch: Colors.blueGrey, // اللون الأساسي
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.blueGrey,
                accentColor: Colors.deepOrangeAccent,
              ).copyWith(
                  secondary:
                      Colors.deepOrangeAccent), // اللون الثانوي
              // fontFamily: 'Cairo', // يمكنك تفعيل هذا الخط إذا كان لديك ملف الخط (يتطلب إضافة الخط إلى pubspec.yaml)
              // تحسينات تصميم شريط التطبيق (AppBar)
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4.0, // زيادة الظل لإعطاء عمق
                shadowColor:
                    Colors.grey.withOpacity(0.3), // لون الظل
                titleTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22, // حجم أكبر للعنوان
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: const IconThemeData(
                    color: Colors
                        .black87), // لون أيقونات الـ AppBar
                actionsIconTheme: const IconThemeData(
                    color: Colors
                        .black87), // لون أيقونات الإجراءات في الـ AppBar
                shape: const RoundedRectangleBorder(
                  // حواف سفلية مستديرة
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
              // تحسينات تصميم الأزرار المرتفعة (ElevatedButton)
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepOrangeAccent, // لون الخلفية
                  foregroundColor:
                      Colors.white, // لون النص والأيقونات
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        12), // حواف مستديرة أكثر
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 3, // إضافة ظل للأزرار
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      12), // حواف مستديرة أكثر
                  borderSide:
                      const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      12), // حواف مستديرة أكثر
                  borderSide: const BorderSide(
                    color: Colors.blueGrey,
                    width: 2,
                  ),
                ),
                labelStyle:
                    const TextStyle(color: Colors.black54),
                hintStyle:
                    const TextStyle(color: Colors.black38),
                fillColor: Colors.grey[50],
                filled: true,
              ),
              cardTheme: CardThemeData(
                elevation: 5, // ظل أكبر للبطاقات
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      15), // حواف مستديرة أكثر
                ),
                shadowColor: Colors.black
                    .withOpacity(0.1), // لون ظل البطاقات
              ),
            ),
            // إدارة حالة المصادقة لعرض الشاشة الأولية (تسجيل الدخول/الرئيسية)
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance
                  .authStateChanges(), // الاستماع لتغييرات حالة المصادقة
              builder: (context, snapshot) {
                // إذا كانت حالة الاتصال تنتظر، اعرض مؤشر التحميل
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                // إذا كان المستخدم مسجلاً الدخول
                if (snapshot.hasData) {
                  // جلب بيانات المستخدم بعد تسجيل الدخول
                  return FutureBuilder(
                    future: Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).fetchUserData(snapshot.data!.uid),
                    builder: (context, userSnapshot) {
                      // إذا كانت حالة الاتصال تنتظر، اعرض مؤشر التحميل
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // بعد جلب بيانات المستخدم، اعرض الشاشة الرئيسية
                      return const HomeScreen();
                    },
                  );
                }
                // إذا لم يكن المستخدم مسجلاً الدخول، اعرض شاشة المصادقة
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// MODELS (نماذج البيانات)
// =============================================================================

/// يمثل نموذج بيانات المنتج.
class Product {
  final String id;
  final Map<String, String>
      name; // الاسم الآن كـ Map للغات (مثال: {'ar': 'قميص', 'en': 'Shirt'})
  final String productNumber;
  final Map<String, String>
      description; // الوصف الآن كـ Map للغات
  final double
      price; // السعر هنا بالدولار الأمريكي (يتم تحويله إلى الليرة السورية للعرض)
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.productNumber,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  /// دالة مساعدة للحصول على اسم المنتج باللغة الحالية للتطبيق.
  /// إذا لم تكن الترجمة متاحة للغة الحالية، تحاول العودة إلى العربية ثم الإنجليزية.
  String getLocalizedName(BuildContext context) {
    final String languageCode =
        Localizations.localeOf(context).languageCode;
    return name[languageCode] ??
        name['ar'] ??
        name['en'] ??
        'No Name';
  }

  /// دالة مساعدة للحصول على وصف المنتج باللغة الحالية للتطبيق.
  /// إذا لم تكن الترجمة متاحة للغة الحالية، تحاول العودة إلى العربية ثم الإنجليزية.
  String getLocalizedDescription(BuildContext context) {
    final String languageCode =
        Localizations.localeOf(context).languageCode;
    return description[languageCode] ??
        description['ar'] ??
        description['en'] ??
        'No Description';
  }

  /// دالة مصنع (factory) لإنشاء كائن Product من DocumentSnapshot من Firestore.
  /// تتعامل مع الحقول التي قد تكون String أو Map (للتوافق مع البيانات القديمة).
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // التعامل مع حقل 'name' سواء كان String (بيانات قديمة) أو Map (بيانات جديدة)
    Map<String, String> nameMap;
    if (data['name'] is String) {
      // إذا كان String، افترض أنه عربي وكرره للإنجليزي كقيمة مبدئية
      nameMap = {'ar': data['name'], 'en': data['name']};
    } else if (data['name'] is Map) {
      // إذا كان Map، قم بتحويله إلى Map<String, String>
      nameMap = Map<String, String>.from(data['name']);
    } else {
      // قيمة افتراضية إذا كان الحقل غير موجود أو بنوع غير متوقع
      nameMap = {'ar': '', 'en': ''};
    }

    // التعامل مع حقل 'description' سواء كان String أو Map بنفس الطريقة
    Map<String, String> descriptionMap;
    if (data['description'] is String) {
      descriptionMap = {
        'ar': data['description'],
        'en': data['description']
      };
    } else if (data['description'] is Map) {
      descriptionMap =
          Map<String, String>.from(data['description']);
    } else {
      descriptionMap = {'ar': '', 'en': ''};
    }

    return Product(
      id: doc.id,
      name: nameMap,
      productNumber: data['productNumber'] ?? '',
      description: descriptionMap,
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  /// تحويل كائن Product إلى Map ليتم حفظه في Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name, // حفظ الاسم كـ Map
      'productNumber': productNumber,
      'description': description, // حفظ الوصف كـ Map
      'price': price, // حفظ السعر بالدولار
      'imageUrl': imageUrl,
      'timestamp': FieldValue
          .serverTimestamp(), // إضافة طابع زمني لترتيب المنتجات
    };
  }
}

/// يمثل عنصرًا واحدًا في سلة التسوق.
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  /// يحسب السعر الإجمالي للعنصر (السعر بالدولار * الكمية).
  double get totalPriceUSD => product.price * quantity;
}

/// يمثل نموذج بيانات المستخدم.
class UserModel {
  final String uid;
  final String email;
  String name;
  String address;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    this.name = 'مستخدم جديد',
    this.address = '',
    this.isAdmin = false,
  });

  /// دالة مصنع (factory) لإنشاء كائن UserModel من DocumentSnapshot من Firestore.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'مستخدم جديد',
      address: data['address'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  /// تحويل كائن UserModel إلى Map ليتم حفظه في Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'address': address,
      'isAdmin': isAdmin,
    };
  }
}

/// امتداد لـ UserModel لإضافة دالة copyWith.
extension on UserModel {
  /// ينشئ نسخة جديدة من UserModel مع إمكانية تغيير الاسم والعنوان.
  UserModel copyWith({String? name, String? address}) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      address: address ?? this.address,
      isAdmin: isAdmin,
    );
  }
}

// =============================================================================
// PROVIDERS (إدارة الحالة)
// =============================================================================

/// مزود لإدارة لغة التطبيق.
class LocaleProvider with ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  /// تعيين اللغة الجديدة للتطبيق.
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners(); // إعلام المستمعين بالتغيير
  }

  /// مسح اللغة المحددة (العودة إلى الافتراضي).
  void clearLocale() {
    _locale = null;
    notifyListeners();
  }
}

/// مزود لإدارة سعر صرف الدولار.
class ExchangeRateProvider with ChangeNotifier {
  double _dollarExchangeRate = 0.0;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  double get dollarExchangeRate => _dollarExchangeRate;
  bool get isLoading => _isLoading;

  /// عند تهيئة المزود، يقوم بجلب سعر الصرف.
  ExchangeRateProvider() {
    _fetchExchangeRate();
  }

  /// جلب سعر الصرف من Firestore.
  Future<void> _fetchExchangeRate() async {
    _isLoading = true;
    notifyListeners();
    try {
      _dollarExchangeRate =
          await _firestoreService.getDollarExchangeRate();
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error fetching dollar exchange rate: $e');
      _dollarExchangeRate = 0.0; // قيمة افتراضية في حالة الخطأ
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث سعر صرف الدولار في Firestore وإعلام المستمعين.
  Future<void> updateDollarExchangeRate(double newRate) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateDollarExchangeRate(newRate);
      _dollarExchangeRate = newRate;
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error updating dollar exchange rate: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// مزود لإدارة سلة التسوق.
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  /// يحسب العدد الإجمالي للعناصر في السلة.
  int get itemCount {
    return _items.fold(
      0,
      (total, current) => total + current.quantity,
    );
  }

  /// يحسب السعر الإجمالي لسلة التسوق بالليرة السورية بناءً على سعر صرف الدولار.
  double totalAmountSYP(double dollarExchangeRate) {
    return _items.fold(
      0.0,
      (total, current) =>
          total + (current.totalPriceUSD * dollarExchangeRate),
    );
  }

  /// إضافة منتج إلى سلة التسوق أو زيادة كميته إذا كان موجوداً.
  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  /// إزالة منتج من سلة التسوق.
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// زيادة كمية منتج معين في سلة التسوق.
  void increaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  /// تقليل كمية منتج معين في سلة التسوق، وإزالته إذا وصلت الكمية إلى صفر.
  void decreaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// مسح جميع العناصر من سلة التسوق.
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// توليد رسالة واتساب تحتوي على تفاصيل الطلب وبيانات العميل.
  String getWhatsAppMessage(BuildContext context,
      UserModel? user, double dollarExchangeRate) {
    final appLocalizations = AppLocalizations.of(context)!;
    String message = '';

    // إضافة اسم العميل وعنوانه إذا كانا متاحين
    if (user != null) {
      message +=
          '${appLocalizations.customerName}: ${user.name}\n';
      message +=
          '${appLocalizations.customerAddress}: ${user.address}\n\n';
    }

    // إذا كانت السلة فارغة، أرسل رسالة استفسار عامة
    if (_items.isEmpty) {
      message += appLocalizations.whatsappInquiryMessage;
    } else {
      // بناء رسالة الطلب
      message += appLocalizations.whatsappOrderStart;
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        // عرض اسم المنتج المترجم، رقم المنتج، الكمية، والسعر بالدولار والليرة السورية
        message +=
            '${i + 1}. ${item.product.getLocalizedName(context)} (${appLocalizations.productNumberShort}: ${item.product.productNumber}) - ${appLocalizations.quantity}: ${item.quantity}\n';
        message +=
            '  ${appLocalizations.priceUSD}: ${item.product.price.toStringAsFixed(2)} \$ (${(item.product.price * dollarExchangeRate).toStringAsFixed(2)} ${appLocalizations.currencySymbol})\n';
      }
      // إضافة الإجمالي الكلي للطلب بالليرة السورية
      message +=
          '\n${appLocalizations.total}: ${totalAmountSYP(dollarExchangeRate).toStringAsFixed(2)} ${appLocalizations.currencySymbol}';
      message += '\n\n${appLocalizations.whatsappConfirmOrder}';
    }
    return message;
  }
}

/// مزود لإدارة بيانات المستخدم الحالي وحالته (أدمن أم لا).
class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  final FirestoreService _firestoreService = FirestoreService();

  /// جلب بيانات المستخدم من Firestore.
  Future<void> fetchUserData(String uid) async {
    _isLoading = true;
    try {
      _currentUser = await _firestoreService.getUser(uid);
      _isAdmin = _currentUser?.isAdmin ?? false;
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error fetching user data: $e');
      _currentUser = null;
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث بيانات المستخدم في Firestore.
  Future<void> updateUserData(
    String uid,
    String name,
    String address,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateUser(uid, {
        'name': name,
        'address': address,
      });
      // تحديث بيانات المستخدم في المزود بعد الحفظ بنجاح
      _currentUser = _currentUser?.copyWith(
        name: name,
        address: address,
      );
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error updating user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// مسح بيانات المستخدم من المزود (عند تسجيل الخروج).
  void clearUser() {
    _currentUser = null;
    _isAdmin = false;
    notifyListeners();
  }
}

// =============================================================================
// SERVICES (خدمات التفاعل مع Firebase)
// =============================================================================

/// خدمة لإدارة عمليات المصادقة (التسجيل، تسجيل الدخول، تسجيل الخروج، إعادة تعيين كلمة المرور).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// تسجيل مستخدم جديد باستخدام البريد الإلكتروني وكلمة المرور.
  /// يقوم أيضاً بإنشاء بيانات المستخدم في Firestore وإرسال بريد التحقق.
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String address,
  ) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // إرسال بريد التحقق بعد إنشاء الحساب
        await user.sendEmailVerification();

        // تحديد ما إذا كان المستخدم أدمن بناءً على البريد الإلكتروني (يجب تغييره في الإنتاج)
        bool isAdmin = (email ==
            'admin@example.com'); // هام: غير هذا إلى بريدك الإلكتروني الخاص بالأدمن
        await _firestoreService.createUser(
          UserModel(
            uid: user.uid,
            email: user.email!,
            name: name,
            address: address,
            isAdmin: isAdmin,
          ),
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // For production, consider using a logging framework instead of print
      print('Firebase Auth Error (Register): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error (Register): $e');
      throw Exception('حدث خطأ أثناء إنشاء الحساب.');
    }
  }

  /// تسجيل دخول مستخدم موجود باستخدام البريد الإلكتروني وكلمة المرور.
  /// يتحقق أيضاً من أن البريد الإلكتروني قد تم التحقق منه.
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // التحقق من البريد الإلكتروني بعد تسجيل الدخول
      if (user != null && !user.emailVerified) {
        // يمكن إرسال بريد التحقق مرة أخرى إذا لم يتم التحقق منه (اختياري)
        // await user.sendEmailVerification();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message:
              'البريد الإلكتروني لم يتم التحقق منه. الرجاء التحقق من بريدك.',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // For production, consider using a logging framework instead of print
      print('Firebase Auth Error (Login): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error (Login): $e');
      throw Exception('حدث خطأ أثناء تسجيل الدخول.');
    }
  }

  /// تسجيل خروج المستخدم الحالي.
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error (Sign Out): $e');
      throw Exception('حدث خطأ أثناء تسجيل الخروج.');
    }
  }

  /// Stream يوفر تحديثات لحالة المصادقة للمستخدم.
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  /// إرسال بريد إلكتروني لإعادة تعيين كلمة المرور.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // For production, consider using a logging framework instead of print
      print(
        'Firebase Auth Error (Reset Password): ${e.message}',
      );
      throw Exception(e.message);
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error (Reset Password): $e');
      throw Exception(
        'حدث خطأ أثناء إرسال بريد إعادة تعيين كلمة المرور.',
      );
    }
  }
}

/// خدمة للتفاعل مع قاعدة بيانات Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// إنشاء مستخدم جديد في مجموعة 'users'.
  Future<void> createUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore());
  }

  /// جلب بيانات مستخدم معين من مجموعة 'users'.
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc =
        await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// تحديث بيانات مستخدم موجود في مجموعة 'users'.
  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// الحصول على Stream لقائمة المنتجات، مرتبة حسب الطابع الزمني تنازلياً.
  Stream<List<Product>> getProducts() {
    return _db
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    });
  }

  /// إضافة منتج جديد إلى مجموعة 'products'.
  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }

  /// تحديث بيانات منتج موجود في مجموعة 'products'.
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('products').doc(productId).update(data);
  }

  /// حذف منتج من مجموعة 'products'.
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// التحقق مما إذا كان رقم المنتج موجوداً بالفعل (مع استثناء المنتج الحالي عند التعديل).
  Future<bool> checkProductNumberExists(String productNumber,
      {String? excludeProductId}) async {
    Query query = _db
        .collection('products')
        .where('productNumber', isEqualTo: productNumber);

    if (excludeProductId != null) {
      // إذا كنا نقوم بالتعديل، استبعد المنتج الحالي من التحقق
      query = query.where(FieldPath.documentId,
          isNotEqualTo: excludeProductId);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.isNotEmpty;
  }

  /// جلب سعر صرف الدولار من مجموعة 'settings'.
  Future<double> getDollarExchangeRate() async {
    DocumentSnapshot doc = await _db
        .collection('settings')
        .doc('exchangeRate')
        .get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['dollarRate']
              ?.toDouble() ??
          0.0;
    }
    return 0.0; // قيمة افتراضية إذا لم يتم العثور على السعر
  }

  /// تحديث سعر صرف الدولار في مجموعة 'settings'.
  Future<void> updateDollarExchangeRate(double newRate) async {
    await _db.collection('settings').doc('exchangeRate').set(
        {
          'dollarRate': newRate,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(
            merge: true)); // دمج البيانات بدلاً من الكتابة فوقها
  }
}

/// خدمة لإدارة عمليات تحميل وحذف الصور باستخدام Cloudinary.
class StorageService {
  // قم بتغيير هذه القيم إلى بيانات اعتماد Cloudinary الخاصة بك
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dva0b4u0g', // <<< استبدل بـ Cloud Name الخاص بك
    'my_store_unsigned_upload', // <<< ستحتاج لإنشاء Upload Preset في Cloudinary
    cache: false,
  );

  // ملاحظة: API Key و API Secret لا تستخدم مباشرة هنا للرفع العام (unsigned upload).
  // ولكنك ستحتاج إلى API Secret إذا كنت ستستخدم Signed Uploads أو API Calls أخرى.
  // لغرض الأمان، يفضل استخدام Signed Uploads عبر خادم خلفي.

  /// تحميل صورة منتج إلى Cloudinary.
  Future<String> uploadProductImage(
    File imageFile,
    String
        productId, // يمكن استخدام هذا كـ public_id في Cloudinary
  ) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder:
              'product_images', // المجلد الذي ستحفظ فيه الصور في Cloudinary
          publicId:
              productId, // اسم الملف في Cloudinary (يمكن أن يكون فريداً)
        ),
      );
      // For production, consider using a logging framework instead of print
      print('Cloudinary Upload Response: ${response.secureUrl}');
      return response
          .secureUrl; // هذا هو رابط الصورة الآمن (HTTPS)
    } on CloudinaryException catch (e) {
      // For production, consider using a logging framework instead of print
      print('Cloudinary Error: ${e.message}');
      throw Exception(
          'فشل تحميل الصورة إلى Cloudinary: ${e.message}');
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error uploading image: $e');
      throw Exception('فشل تحميل الصورة.');
    }
  }

  /// حذف صورة منتج من Cloudinary.
  /// (ملاحظة: هذه العملية تتطلب عادةً خادمًا خلفيًا للأمان).
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      // لاستخدام deleteResource، ستحتاج إلى API Key و API Secret
      // وهذه العملية يجب أن تتم من خادم خلفي (مثل Firebase Functions) للأمان.
      // إذا كنت تستخدمها مباشرة من العميل، فإنك تعرض API Secret الخاص بك.

      // استخراج الـ publicId من الـ URL
      // مثال: https://res.cloudinary.com/YOUR_CLOUD_NAME/image/upload/v12345/product_images/some_product_id.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final publicIdWithExtension =
            pathSegments.last; // e.g., some_product_id.jpg
        final folder = pathSegments[
            pathSegments.length - 2]; // e.g., product_images
        final publicId =
            '$folder/${publicIdWithExtension.split('.').first}'; // e.g., product_images/some_product_id

        // هذه العملية تتطلب توقيع (signature) أو API Key و API Secret
        // وهي غير مدعومة مباشرة بـ cloudinary_public للعميل.
        // ستحتاج إلى استخدام Cloudinary SDK على خادم خلفي (Node.js, Python, etc.)
        // أو استخدام Signed Uploads مع حذف مؤقت.
        // For production, consider using a logging framework instead of print
        print(
            'Cloudinary delete is complex from client-side. Skipping for now.');
        print(
            'To delete, you typically need a backend to call Cloudinary API with API Secret.');
        // For now, we will just print a message.
        // In a real app, you would send a request to your backend to delete the image.
      }
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print(
          'Error deleting image from Cloudinary (client-side attempt): $e');
    }
  }
}

// =============================================================================
// WIDGETS (مكونات الواجهة الرسومية)
// =============================================================================

/// بطاقة عرض المنتج في الشاشة الرئيسية.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    // الوصول إلى مزود سعر الصرف لحساب السعر بالليرة السورية
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context);
    final double dollarRate =
        exchangeRateProvider.dollarExchangeRate;
    final double priceInSYP = product.price * dollarRate;

    return Card(
      clipBehavior: Clip
          .antiAlias, // لضمان قص الصورة بشكل صحيح مع الحواف المستديرة
      child: InkWell(
        onTap: onTap, // دالة يتم استدعاؤها عند النقر على البطاقة
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: product
                    .id, // لإنشاء تأثير انتقال سلس بين الشاشات
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // دالة لبناء واجهة بديلة في حالة فشل تحميل الصورة
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.getLocalizedName(
                        context), // استخدام الاسم المترجم
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow
                        .ellipsis, // لإظهار "..." إذا كان النص طويلاً
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // عرض السعر بالليرة السورية
                    '${priceInSYP.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed:
                          onAddToCart, // دالة يتم استدعاؤها عند النقر على زر "إضافة إلى السلة"
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        size: 18,
                      ),
                      label: Text(appLocalizations.addToCart),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCREENS (الشاشات)
// =============================================================================

/// شاشة المصادقة (تسجيل الدخول/التسجيل).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<
      FormState>(); // مفتاح لـ Form Widget للتحقق من صحة المدخلات
  bool _isLogin =
      true; // لتحديد ما إذا كانت الشاشة لوضع تسجيل الدخول أو التسجيل
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';
  String _address = '';
  bool _isLoading =
      false; // لإظهار مؤشر التحميل أثناء عمليات الشبكة

  final AuthService _authService =
      AuthService(); // خدمة المصادقة

  final TextEditingController _passwordController =
      TextEditingController(); // للتحكم في حقل كلمة المرور
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // للتحكم في حقل تأكيد كلمة المرور

  /// دالة مساعدة لعرض رسائل SnackBar للمستخدم.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted)
      return; // التأكد من أن الـ Widget لا يزال موجوداً في الشجرة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// دالة لإرسال نموذج المصادقة (تسجيل الدخول أو التسجيل).
  Future<void> _submitAuthForm() async {
    final appLocalizations = AppLocalizations.of(context)!;
    // التحقق من صحة جميع حقول النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // حفظ قيم الحقول

    setState(() {
      _isLoading = true; // بدء التحميل
    });

    try {
      User? user;
      if (_isLogin) {
        // محاولة تسجيل الدخول
        user = await _authService.signInWithEmailAndPassword(
          _email,
          _password,
        );
      } else {
        // محاولة التسجيل
        if (_password != _confirmPassword) {
          _showSnackBar(appLocalizations.passwordMismatch,
              isError: true);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
        user = await _authService.registerWithEmailAndPassword(
          _email,
          _password,
          _name,
          _address,
        );
      }

      if (user != null) {
        if (_isLogin) {
          // جلب بيانات المستخدم بعد تسجيل الدخول بنجاح
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).fetchUserData(user.uid);
          _showSnackBar(appLocalizations.loggedInSuccessfully);
          if (mounted) {
            // الانتقال إلى الشاشة الرئيسية بعد تسجيل الدخول
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => const HomeScreen(),
              ),
            );
          }
        } else {
          // بعد التسجيل، لا نسجل الدخول تلقائياً حتى يتم التحقق من البريد
          _showSnackBar(
              appLocalizations.emailVerificationNeeded);
          _showSnackBar(appLocalizations.emailVerificationSent);
          // نعود إلى شاشة تسجيل الدخول ليقوم المستخدم بتسجيل الدخول بعد التحقق
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => const AuthScreen(),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // معالجة أخطاء المصادقة من Firebase
      String errorMessage = appLocalizations.authError;
      if (e.code == 'user-not-found') {
        errorMessage = appLocalizations.userNotFound;
      } else if (e.code == 'wrong-password') {
        errorMessage = appLocalizations.wrongPassword;
      } else if (e.code == 'email-already-in-use') {
        errorMessage = appLocalizations.emailAlreadyInUse;
      } else if (e.code == 'weak-password') {
        errorMessage = appLocalizations.weakPassword;
      } else if (e.code == 'invalid-email') {
        errorMessage = appLocalizations.invalidEmail;
      } else if (e.code == 'network-request-failed') {
        errorMessage = appLocalizations.networkError;
      } else if (e.code == 'email-not-verified') {
        // خطأ مخصص للتحقق من البريد
        errorMessage = appLocalizations.verifyEmailToLogin;
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      // معالجة الأخطاء العامة
      _showSnackBar(
        '${appLocalizations.errorOccurred}${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // إنهاء التحميل
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController
        .dispose(); // التخلص من المتحكمات لتجنب تسرب الذاكرة
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appLocalizations.appName,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('email'),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: appLocalizations.email,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !value.contains('@')) {
                          return appLocalizations.emailRequired;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _email = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('password'),
                      controller: _passwordController,
                      obscureText:
                          true, // لإخفاء النص المدخل (كلمة المرور)
                      decoration: InputDecoration(
                        labelText: appLocalizations.password,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return appLocalizations.passwordLength;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    // عرض حقول التسجيل الإضافية فقط إذا كانت الشاشة في وضع التسجيل
                    if (!_isLogin)
                      Column(
                        children: [
                          TextFormField(
                            key: const ValueKey(
                                'confirm_password'),
                            controller:
                                _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: appLocalizations
                                  .confirmPassword,
                              prefixIcon:
                                  const Icon(Icons.lock_reset),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim() !=
                                      _passwordController.text
                                          .trim()) {
                                return appLocalizations
                                    .passwordMismatch;
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _confirmPassword = value!.trim();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('name'),
                            decoration: InputDecoration(
                              labelText:
                                  appLocalizations.nameOptional,
                              prefixIcon:
                                  const Icon(Icons.person),
                            ),
                            onSaved: (value) {
                              _name = value!.trim();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('address'),
                            decoration: InputDecoration(
                              labelText: appLocalizations
                                  .addressOptional,
                              prefixIcon: const Icon(
                                Icons.location_on,
                              ),
                            ),
                            onSaved: (value) {
                              _address = value!.trim();
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    const SizedBox(height: 20),
                    // عرض مؤشر التحميل أو الزر بناءً على حالة التحميل
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _submitAuthForm,
                            child: Text(
                              _isLogin
                                  ? appLocalizations.login
                                  : appLocalizations
                                      .createAccount,
                            ),
                          ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _isLogin =
                                !_isLogin; // تبديل وضع الشاشة
                            _passwordController
                                .clear(); // مسح حقول كلمة المرور
                            _confirmPasswordController.clear();
                            _formKey.currentState
                                ?.reset(); // إعادة تعيين حالة النموذج
                          });
                        }
                      },
                      child: Text(
                        _isLogin
                            ? appLocalizations.noAccount
                            : appLocalizations.haveAccount,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    // عرض زر "نسيت كلمة المرور" فقط في وضع تسجيل الدخول
                    if (_isLogin)
                      TextButton(
                        onPressed: () async {
                          // التحقق من صحة البريد الإلكتروني قبل إرسال رابط إعادة التعيين
                          if (_email.isEmpty ||
                              !_email.contains('@')) {
                            _showSnackBar(
                              appLocalizations.emailRequired,
                              isError: true,
                            );
                            return;
                          }
                          try {
                            if (mounted) {
                              setState(() {
                                _isLoading = true;
                              });
                            }
                            await _authService
                                .sendPasswordResetEmail(_email);
                            _showSnackBar(
                              appLocalizations
                                  .resetPasswordEmailSent,
                            );
                          } catch (e) {
                            _showSnackBar(
                              '${appLocalizations.sendResetEmailError}${e.toString().replaceFirst('Exception: ', '')}',
                              isError: true,
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        child: Text(
                          appLocalizations.forgotPassword,
                          style: TextStyle(
                            color:
                                Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الشاشة الرئيسية للتطبيق، تعرض قائمة المنتجات.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  /// دالة لتحديث البيانات عند السحب للأسفل.
  Future<void> _onRefresh() async {
    // إعادة جلب سعر الصرف
    await Provider.of<ExchangeRateProvider>(context,
            listen: false)
        ._fetchExchangeRate();
    // بما أن getProducts() هو StreamBuilder، فإنه يستمع للتغييرات تلقائياً.
    // يمكننا فقط إرجاع Future.value(true) لإغلاق مؤشر التحديث.
    // إذا كانت هناك حاجة لإعادة تحميل المنتجات بشكل صريح، يمكن إضافة منطق هنا.
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context,
        listen: false); // للوصول لـ setLocale

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.homeTitle),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
                Icons.menu), // أيقونة القائمة الجانبية
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer(); // فتح القائمة الجانبية
            },
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                    Icons.shopping_cart), // أيقونة سلة التسوق
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const CartScreen(),
                      ),
                    );
                  }
                },
              ),
              // عرض عدد العناصر في السلة إذا كان أكبر من صفر
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // رأس القائمة الجانبية مع معلومات المستخدم
            UserAccountsDrawerHeader(
              accountName: Text(
                userProvider.currentUser?.name ??
                    appLocalizations.newUser,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                userProvider.currentUser?.email ??
                    'user@example.com',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(appLocalizations.home),
              onTap: () {
                if (mounted) {
                  Navigator.pop(
                      context); // إغلاق القائمة الجانبية
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(appLocalizations.settingsTitle),
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) =>
                          const UserSettingsScreen(),
                    ),
                  );
                }
              },
            ),
            // عرض لوحة الأدمن فقط إذا كان المستخدم أدمن
            if (userProvider.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(appLocalizations.adminPanelTitle),
                onTap: () {
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            const AdminPanelScreen(),
                      ),
                    );
                  }
                },
              ),
            // خيار تغيير اللغة
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(appLocalizations.changeLanguage),
              onTap: () {
                if (mounted) {
                  Navigator.pop(context); // إغلاق الدرج
                  _showLanguagePickerDialog(
                      context, localeProvider);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: Text(
                appLocalizations.logout,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                if (mounted) {
                  Navigator.pop(context);
                }
                await _authService
                    .signOut(); // تسجيل الخروج من Firebase
                userProvider
                    .clearUser(); // مسح بيانات المستخدم من المزود
                cartProvider.clearCart(); // مسح سلة التسوق
                if (mounted) {
                  // العودة إلى شاشة المصادقة وإزالة جميع الشاشات السابقة من الـ stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (ctx) => const AuthScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      // إضافة RefreshIndicator للسحب للأسفل لتحديث الصفحة
      body: RefreshIndicator(
        onRefresh: _onRefresh, // دالة التحديث
        child: StreamBuilder<List<Product>>(
          stream: _firestoreService
              .getProducts(), // الاستماع لتغييرات المنتجات في Firestore
          builder: (context, snapshot) {
            // عرض مؤشر التحميل
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // عرض رسالة خطأ إذا كان هناك خطأ في جلب البيانات
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${appLocalizations.loadingProductsError}${snapshot.error}',
                ),
              );
            }
            // عرض رسالة إذا لم تكن هناك منتجات
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  appLocalizations.noProducts,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final products = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // عمودين في الشبكة
                childAspectRatio:
                    0.75, // نسبة العرض إلى الارتفاع لكل عنصر
                crossAxisSpacing:
                    16.0, // المسافة الأفقية بين العناصر
                mainAxisSpacing:
                    16.0, // المسافة العمودية بين العناصر
              ),
              itemCount: products.length,
              itemBuilder: (ctx, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // تحديث سلوك النقر للمنتجات بناءً على دور المستخدم
                    if (userProvider.isAdmin) {
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ManageProductScreen(
                              product: product,
                            ),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ProductDetailScreen(
                              product: product,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  onAddToCart: () {
                    cartProvider.addItem(product);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            appLocalizations.productAddedToCart(
                                product.getLocalizedName(
                                    context)), // استخدام الاسم المترجم
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// دالة لعرض مربع حوار لاختيار لغة التطبيق.
  void _showLanguagePickerDialog(
      BuildContext context, LocaleProvider localeProvider) {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLocalizations.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                localeProvider.setLocale(const Locale(
                    'en', '')); // تعيين اللغة الإنجليزية
                if (mounted) {
                  Navigator.of(ctx).pop(); // إغلاق مربع الحوار
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(appLocalizations
                          .languageChangedSuccessfully),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('العربية'),
              onTap: () {
                localeProvider.setLocale(const Locale(
                    'ar', '')); // تعيين اللغة العربية
                if (mounted) {
                  Navigator.of(ctx).pop(); // إغلاق مربع الحوار
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(appLocalizations
                          .languageChangedSuccessfully),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة تفاصيل المنتج.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  int _quantity = 1; // كمية المنتج المراد إضافتها إلى السلة

  /// دالة مساعدة لعرض رسائل SnackBar للمستخدم.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(
      context,
      listen: false,
    );
    final appLocalizations = AppLocalizations.of(context)!;
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context);
    final double dollarRate =
        exchangeRateProvider.dollarExchangeRate;
    final double priceInSYP = widget.product.price *
        dollarRate; // حساب السعر بالليرة السورية

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product.getLocalizedName(
              context))), // استخدام الاسم المترجم في الـ AppBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: widget.product.id, // لإنشاء تأثير انتقال سلس
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    height: 250,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.product.getLocalizedName(
                  context), // استخدام الاسم المترجم
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // عرض السعر بالليرة السورية
              '${priceInSYP.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // عرض السعر بالدولار أيضًا (اختياري)
              '${appLocalizations.priceUSD}: ${widget.product.price.toStringAsFixed(2)} \$',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${appLocalizations.productNumberShort}: ${widget.product.productNumber}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.product.getLocalizedDescription(
                  context), // استخدام الوصف المترجم
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        if (_quantity > 1) _quantity--;
                      });
                    }
                  },
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _quantity++;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  cartProvider.addItem(
                    widget.product,
                    quantity: _quantity,
                  );
                  _showSnackBar(
                    appLocalizations.productQuantityAddedToCart(
                      widget.product.getLocalizedName(
                          context), // استخدام الاسم المترجم
                      _quantity,
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(appLocalizations.addToCart),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة سلة التسوق.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // رقم الواتساب الموحد المستخدم في التطبيق (سوريا)
  static const String _whatsappPhoneNumber = '963980756485';

  /// دالة مساعدة لعرض رسائل SnackBar للمستخدم.
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// دالة مساعدة لفتح تطبيق واتساب أو واتساب ويب.
  Future<void> _launchWhatsApp({
    required BuildContext context,
    required String phoneNumber,
    required String message,
  }) async {
    final appLocalizations = AppLocalizations.of(context)!;

    // تنظيف رقم الهاتف للتأكد من أنه بتنسيق أرقام فقط
    String cleanedPhoneNumber =
        phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // محاولة فتح تطبيق واتساب مباشرةً
    String whatsappAppUrl =
        'whatsapp://send?phone=$cleanedPhoneNumber&text=${Uri.encodeComponent(message)}';

    try {
      bool launched = await launchUrl(
        Uri.parse(whatsappAppUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // إذا فشل فتح التطبيق، العودة إلى واتساب عبر الويب (wa.me)
        String webWhatsappUrl =
            'https://wa.me/$cleanedPhoneNumber?text=${Uri.encodeComponent(message)}';
        bool webLaunched = await launchUrl(
          Uri.parse(webWhatsappUrl),
          mode: LaunchMode.externalApplication,
        );

        if (!webLaunched) {
          _showSnackBar(
            context,
            appLocalizations.whatsappNotInstalled,
            isError: true,
          );
        }
      }
    } catch (e) {
      // التقاط أي أخطاء أثناء محاولة launchUrl نفسها
      _showSnackBar(
        context,
        appLocalizations.whatsappNotInstalled,
        isError: true,
      );
      print('Error launching WhatsApp: $e'); // For debug
    }
  }

  /// دالة لعرض مربع حوار لاختيار بين واتساب العادي أو واتساب للأعمال.
  Future<void> _showWhatsAppChoiceDialog(
      BuildContext context, String message) async {
    final appLocalizations = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLocalizations.whatsappChoiceTitle),
        content: Text(appLocalizations.whatsappChoiceMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _launchWhatsApp(
                context: context,
                phoneNumber:
                    _whatsappPhoneNumber, // استخدام الرقم الموحد
                message: message,
              );
            },
            child: Text(appLocalizations.whatsappStandard),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _launchWhatsApp(
                context: context,
                phoneNumber:
                    _whatsappPhoneNumber, // استخدام الرقم الموحد
                message: message,
              );
            },
            child: Text(appLocalizations.whatsappBusiness),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<UserProvider>(
        context); // للحصول على بيانات المستخدم
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context);
    final double dollarRate =
        exchangeRateProvider.dollarExchangeRate;
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.cartTitle)),
      body: cartProvider.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    appLocalizations.cartEmpty,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    appLocalizations.addProductsToShop,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (ctx, index) {
                      final cartItem = cartProvider.items[index];
                      final double priceInSYP =
                          cartItem.product.price * dollarRate;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8.0),
                                child: Image.network(
                                  cartItem.product.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons
                                            .image_not_supported,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartItem.product
                                          .getLocalizedName(
                                              context), // استخدام الاسم المترجم
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      // عرض السعر بالليرة السورية
                                      '${priceInSYP.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      // عرض السعر بالدولار أيضًا (اختياري)
                                      '${appLocalizations.priceUSD}: ${cartItem.product.price.toStringAsFixed(2)} \$',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons
                                                .remove_circle_outline,
                                          ),
                                          onPressed: () {
                                            cartProvider
                                                .decreaseQuantity(
                                              cartItem
                                                  .product.id,
                                            );
                                          },
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons
                                                .add_circle_outline,
                                          ),
                                          onPressed: () {
                                            cartProvider
                                                .increaseQuantity(
                                              cartItem
                                                  .product.id,
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            cartProvider
                                                .removeItem(
                                              cartItem
                                                  .product.id,
                                            );
                                            _showSnackBar(
                                              context,
                                              appLocalizations
                                                  .productRemovedFromCart,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appLocalizations.total,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            // عرض الإجمالي بالليرة السورية
                            '${cartProvider.totalAmountSYP(dollarRate).toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          // إرسال بيانات المستخدم وسعر الصرف مع رسالة الواتساب
                          _showWhatsAppChoiceDialog(
                              context,
                              cartProvider.getWhatsAppMessage(
                                  context,
                                  userProvider.currentUser,
                                  dollarRate));
                          cartProvider.clearCart();
                          _showSnackBar(
                            context,
                            appLocalizations.orderSent,
                          );
                        },
                        icon: const Icon(Icons
                            .chat), // تغيير الأيقونة إلى أيقونة عامة
                        label: Text(
                          appLocalizations.sendOrderWhatsApp,
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(
                            double.infinity,
                            50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          cartProvider.clearCart();
                          _showSnackBar(
                            context,
                            appLocalizations.cartCleared,
                          );
                        },
                        child: Text(appLocalizations.clearCart),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// شاشة إعدادات المستخدم.
class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() =>
      _UserSettingsScreenState();
}

class _UserSettingsScreenState
    extends State<UserSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكمات بقيم المستخدم الحالية
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    _nameController = TextEditingController(
      text: userProvider.currentUser?.name ?? '',
    );
    _addressController = TextEditingController(
      text: userProvider.currentUser?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// دالة مساعدة لعرض رسائل SnackBar للمستخدم.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// تحديث بيانات المستخدم (الاسم والعنوان).
  Future<void> _updateUserData() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );
      if (userProvider.currentUser?.uid != null) {
        await userProvider.updateUserData(
          userProvider.currentUser!.uid,
          _nameController.text.trim(),
          _addressController.text.trim(),
        );
        _showSnackBar(
            appLocalizations.updateAccountSuccessfully);
      }
    } catch (e) {
      _showSnackBar(
        '${appLocalizations.updateUserDataError}${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// دالة لتغيير كلمة مرور المستخدم.
  Future<void> _changePassword() async {
    final appLocalizations = AppLocalizations.of(context)!;
    String? currentPassword;
    String? newPassword;
    String? confirmNewPassword;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLocalizations.changePassword),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.currentPassword,
                ),
                onChanged: (value) => currentPassword = value,
              ),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.newPassword,
                ),
                onChanged: (value) => newPassword = value,
              ),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.confirmNewPassword,
                ),
                onChanged: (value) => confirmNewPassword = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text(appLocalizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              // التحقق من صحة المدخلات
              if (newPassword == null ||
                  newPassword!.length < 6) {
                _showSnackBar(
                  appLocalizations.passwordLength,
                  isError: true,
                );
                return;
              }
              if (newPassword != confirmNewPassword) {
                _showSnackBar(
                  appLocalizations.passwordMismatch,
                  isError: true,
                );
                return;
              }
              if (currentPassword == null ||
                  currentPassword!.isEmpty) {
                _showSnackBar(
                  appLocalizations.enterCurrentPassword,
                  isError: true,
                );
                return;
              }

              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // إعادة مصادقة المستخدم قبل تغيير كلمة المرور
                  AuthCredential credential =
                      EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassword!,
                  );
                  await user.reauthenticateWithCredential(
                    credential,
                  );
                  await user.updatePassword(
                      newPassword!); // تحديث كلمة المرور
                  _showSnackBar(
                    appLocalizations.passwordChangeSuccess,
                  );
                  if (mounted) {
                    Navigator.of(ctx).pop();
                  }
                }
              } on FirebaseAuthException catch (e) {
                // معالجة أخطاء المصادقة
                String errorMessage =
                    appLocalizations.passwordChangeFailed;
                if (e.code == 'wrong-password') {
                  errorMessage =
                      appLocalizations.wrongCurrentPassword;
                } else if (e.code == 'requires-recent-login') {
                  errorMessage =
                      appLocalizations.reauthenticateRequired;
                }
                _showSnackBar(errorMessage, isError: true);
              } catch (e) {
                _showSnackBar(
                  '${appLocalizations.errorOccurred}${e.toString().replaceFirst('Exception: ', '')}',
                  isError: true,
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: Text(appLocalizations.changePassword),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar:
          AppBar(title: Text(appLocalizations.settingsTitle)),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: TextEditingController(
                        text: userProvider.currentUser?.email ??
                            appLocalizations.notAvailable,
                      ),
                      readOnly:
                          true, // جعل حقل البريد الإلكتروني للقراءة فقط
                      decoration: InputDecoration(
                        labelText: appLocalizations.email,
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.name,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return appLocalizations.enterYourName;
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          _nameController.text = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.address,
                        prefixIcon:
                            const Icon(Icons.location_on),
                      ),
                      onSaved: (value) =>
                          _addressController.text = value!,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _updateUserData,
                              child: Text(
                                appLocalizations.saveChanges,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: _changePassword,
                        child: Text(
                          appLocalizations.changePassword,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _authService
                              .signOut(); // تسجيل الخروج
                          userProvider
                              .clearUser(); // مسح بيانات المستخدم
                          Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).clearCart(); // مسح سلة التسوق
                          if (mounted) {
                            // العودة إلى شاشة المصادقة وإزالة جميع الشاشات السابقة
                            Navigator.of(
                              context,
                            ).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (ctx) =>
                                    const AuthScreen(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(appLocalizations.logout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// شاشة لوحة تحكم الأدمن، لإدارة المنتجات وسعر صرف الدولار.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() =>
      _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  late TextEditingController _dollarRateController;
  bool _isLoadingExchangeRate = false;

  @override
  void initState() {
    super.initState();
    // تهيئة متحكم سعر الدولار بقيمته الحالية من المزود
    _dollarRateController = TextEditingController(
      text: Provider.of<ExchangeRateProvider>(context,
              listen: false)
          .dollarExchangeRate
          .toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _dollarRateController.dispose();
    super.dispose();
  }

  /// دالة مساعدة لعرض رسائل SnackBar للمستخدم.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// دالة لتحديث سعر صرف الدولار.
  Future<void> _updateDollarRate() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final newRate =
        double.tryParse(_dollarRateController.text.trim());

    if (newRate == null || newRate <= 0) {
      _showSnackBar(appLocalizations.enterValidPrice,
          isError: true);
      return;
    }

    setState(() {
      _isLoadingExchangeRate = true;
    });

    try {
      await Provider.of<ExchangeRateProvider>(context,
              listen: false)
          .updateDollarExchangeRate(newRate);
      _showSnackBar(appLocalizations.dollarExchangeRateUpdated);
    } catch (e) {
      _showSnackBar(
        '${appLocalizations.operationFailed}${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExchangeRate = false;
        });
      }
    }
  }

  /// دالة لحذف منتج.
  Future<void> _deleteProduct(Product product) async {
    final appLocalizations = AppLocalizations.of(context)!;
    // عرض مربع حوار للتأكيد قبل الحذف
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appLocalizations.confirmDelete),
            content: Text(
              appLocalizations.confirmDeleteProduct(
                  product.getLocalizedName(
                      context)), // استخدام الاسم المترجم
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(ctx).pop(false);
                  }
                },
                child: Text(appLocalizations.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(appLocalizations.delete),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        if (product.imageUrl.isNotEmpty) {
          // استدعاء خدمة حذف الصورة من Cloudinary (ملاحظة: هذا يتطلب خادمًا خلفيًا للأمان)
          await _storageService.deleteProductImage(
            product.imageUrl,
          );
        }
        await _firestoreService.deleteProduct(product.id);
        _showSnackBar(appLocalizations.productDeleted);
      } catch (e) {
        _showSnackBar(
          '${appLocalizations.deleteFailed}${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  /// دالة لتحديث البيانات عند السحب للأسفل.
  Future<void> _onRefresh() async {
    // إعادة جلب سعر الصرف
    await Provider.of<ExchangeRateProvider>(context,
            listen: false)
        ._fetchExchangeRate();
    // بما أن getProducts() هو StreamBuilder، فإنه يستمع للتغييرات تلقائياً.
    // يمكننا فقط إرجاع Future.value(true) لإغلاق مؤشر التحديث.
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context);
    final double dollarRate =
        exchangeRateProvider.dollarExchangeRate;

    // تحديث قيمة controller عندما يتغير سعر الصرف من Provider
    // يتم هذا الشرط لتجنب التحديث اللانهائي عند إعادة بناء الـ widget
    if (_dollarRateController.text !=
            dollarRate.toStringAsFixed(2) &&
        !_isLoadingExchangeRate) {
      _dollarRateController.text = dollarRate.toStringAsFixed(2);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.adminPanelTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // حقل إدخال سعر الدولار
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.dollarExchangeRate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dollarRateController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: appLocalizations
                                  .dollarExchangeRate,
                              prefixIcon:
                                  const Icon(Icons.attach_money),
                              suffixText: appLocalizations
                                  .syrianPound, // ل.س
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  double.tryParse(value) ==
                                      null ||
                                  double.parse(value) <= 0) {
                                return appLocalizations
                                    .enterValidPrice;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        _isLoadingExchangeRate
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _updateDollarRate,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15),
                                ),
                                child: Text(appLocalizations
                                    .saveChanges),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // قائمة المنتجات (مع RefreshIndicator)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh, // دالة التحديث
              child: StreamBuilder<List<Product>>(
                stream: _firestoreService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${appLocalizations.loadingProductsError}${snapshot.error}',
                      ),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        appLocalizations.noProducts,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final products = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: products.length,
                    itemBuilder: (ctx, index) {
                      final product = products[index];
                      final double priceInSYP = product.price *
                          dollarRate; // حساب السعر بالليرة السورية
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8.0),
                            child: Image.network(
                              product.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            product.getLocalizedName(
                                context), // استخدام الاسم المترجم
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${product.price.toStringAsFixed(2)} \$ - ${priceInSYP.toStringAsFixed(2)} ${appLocalizations.currencySymbol} - ${appLocalizations.productNumberShort}: ${product.productNumber}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) =>
                                            ManageProductScreen(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteProduct(product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const ManageProductScreen(),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// شاشة إدارة المنتج (إضافة/تعديل).
class ManageProductScreen extends StatefulWidget {
  final Product?
      product; // المنتج المراد تعديله (إذا كان null، فهذا يعني إضافة منتج جديد)

  const ManageProductScreen({super.key, this.product});

  @override
  State<ManageProductScreen> createState() =>
      _ManageProductScreenState();
}

class _ManageProductScreenState
    extends State<ManageProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController
      _nameArController; // متحكم لاسم المنتج باللغة العربية
  late TextEditingController
      _nameEnController; // متحكم لاسم المنتج باللغة الإنجليزية
  late TextEditingController _productNumberController;
  late TextEditingController
      _priceController; // متحكم لسعر المنتج بالدولار
  late TextEditingController
      _descriptionArController; // متحكم لوصف المنتج باللغة العربية
  late TextEditingController
      _descriptionEnController; // متحكم لوصف المنتج باللغة الإنجليزية

  File? _pickedImage; // الملف المحلي للصورة المختارة
  String?
      _currentImageUrl; // رابط الصورة الحالي للمنتج (إذا كان موجوداً)
  bool _isLoading = false; // لإظهار مؤشر التحميل

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكمات بقيم المنتج الموجود (إذا كان تعديلاً) أو قيم فارغة (إذا كان إضافة)
    _nameArController = TextEditingController(
      text: widget.product?.name['ar'] ?? '',
    );
    _nameEnController = TextEditingController(
      text: widget.product?.name['en'] ?? '',
    );
    _productNumberController = TextEditingController(
      text: widget.product?.productNumber ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ??
          '', // السعر الافتراضي بالدولار
    );
    _descriptionArController = TextEditingController(
      text: widget.product?.description['ar'] ?? '',
    );
    _descriptionEnController = TextEditingController(
      text: widget.product?.description['en'] ?? '',
    );
    _currentImageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    // التخلص من المتحكمات لتجنب تسرب الذاكرة
    _nameArController.dispose();
    _nameEnController.dispose();
    _productNumberController.dispose();
    _priceController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    super.dispose();
  }

  /// دالة مساعدة لعرض رسائل SnackBar للمستخدم.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// دالة لاختيار صورة من معرض الصور.
  Future<void> _pickImage() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // جودة الصورة (لتقليل حجم الملف)
    );
    if (mounted) {
      setState(() {
        if (pickedFile != null) {
          _pickedImage = File(pickedFile.path);
        } else {
          print(appLocalizations.imageNotSelected); // For debug
        }
      });
    }
  }

  /// دالة لإرسال بيانات المنتج (إضافة أو تعديل).
  Future<void> _submitProduct() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // التحقق مما إذا تم اختيار صورة
    if (_pickedImage == null &&
        (_currentImageUrl == null ||
            _currentImageUrl!.isEmpty)) {
      _showSnackBar(appLocalizations.selectImage, isError: true);
      return;
    }

    setState(() {
      _isLoading = true; // بدء التحميل
    });

    try {
      // التحقق من تكرار رقم المنتج
      bool productNumberExists =
          await _firestoreService.checkProductNumberExists(
        _productNumberController.text.trim(),
        excludeProductId: widget.product
            ?.id, // استبعاد المنتج الحالي إذا كان تعديلاً
      );

      if (productNumberExists) {
        _showSnackBar(appLocalizations.productNumberExists,
            isError: true);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      String? imageUrlToSave = _currentImageUrl;

      // إذا تم اختيار صورة جديدة، قم بتحميلها إلى Cloudinary
      if (_pickedImage != null) {
        if (widget.product != null &&
            widget.product!.imageUrl.isNotEmpty) {
          print(appLocalizations
              .skippingOldImageDeletion); // For debug
        }
        imageUrlToSave =
            await _storageService.uploadProductImage(
          _pickedImage!,
          widget.product?.id ??
              DateTime.now()
                  .millisecondsSinceEpoch
                  .toString(), // استخدام ID فريد للصورة
        );
      }

      // إنشاء كائن المنتج الجديد أو المحدث
      final newProduct = Product(
        id: widget.product?.id ?? '',
        name: {
          'ar': _nameArController.text.trim(),
          'en': _nameEnController.text.trim(),
        },
        productNumber: _productNumberController.text.trim(),
        description: {
          'ar': _descriptionArController.text.trim(),
          'en': _descriptionEnController.text.trim(),
        },
        price: double.parse(
            _priceController.text.trim()), // حفظ السعر بالدولار
        imageUrl: imageUrlToSave ?? '',
      );

      // إضافة أو تحديث المنتج في Firestore
      if (widget.product == null) {
        await _firestoreService.addProduct(newProduct);
        _showSnackBar(appLocalizations.productAdded);
      } else {
        await _firestoreService.updateProduct(
          widget.product!.id,
          newProduct.toFirestore(),
        );
        _showSnackBar(appLocalizations.productUpdated);
      }
      if (mounted) {
        Navigator.of(context).pop(); // العودة إلى الشاشة السابقة
      }
    } catch (e) {
      _showSnackBar(
        '${appLocalizations.operationFailed}${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product !=
        null; // لتحديد ما إذا كنا في وضع التعديل أو الإضافة
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? appLocalizations.editProduct
              : appLocalizations.newProduct,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap:
                      _pickImage, // عند النقر، يتم فتح معرض الصور
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[200],
                    // عرض الصورة المختارة أو الصورة الحالية للمنتج
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                            ? NetworkImage(_currentImageUrl!)
                                as ImageProvider
                            : null),
                    // عرض أيقونة الكاميرا إذا لم تكن هناك صورة
                    child: (_pickedImage == null &&
                            (_currentImageUrl == null ||
                                _currentImageUrl!.isEmpty))
                        ? Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // حقل اسم المنتج (العربية)
              TextFormField(
                controller: _nameArController,
                decoration: InputDecoration(
                  labelText: appLocalizations.productNameAr,
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.enterProductNameAr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // حقل اسم المنتج (الإنجليزية)
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: appLocalizations.productNameEn,
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.enterProductNameEn;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNumberController,
                decoration: InputDecoration(
                  labelText: appLocalizations.productNumber,
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.enterProductNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: appLocalizations
                      .priceUSD, // تغيير التسمية إلى دولار
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      double.tryParse(value) == null) {
                    return appLocalizations.enterValidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // حقل وصف المنتج (العربية)
              TextFormField(
                controller: _descriptionArController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText:
                      appLocalizations.productDescriptionAr,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations
                        .enterProductDescriptionAr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // حقل وصف المنتج (الإنجليزية)
              TextFormField(
                controller: _descriptionEnController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText:
                      appLocalizations.productDescriptionEn,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations
                        .enterProductDescriptionEn;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _submitProduct,
                        icon: Icon(
                          isEditing ? Icons.save : Icons.add,
                        ),
                        label: Text(
                          isEditing
                              ? appLocalizations.saveChanges
                              : appLocalizations.newProduct,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
