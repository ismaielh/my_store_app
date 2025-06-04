import 'dart:io'; // Required for File operations (image_picker)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // قم بالتعليق على هذا السطر أو حذفه
import 'package:my_store_app/firebase_options.dart';
import 'package:my_store_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // استيراد حزمة Cloudinary

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        ChangeNotifierProvider(
            create: (ctx) =>
                LocaleProvider()), // إضافة LocaleProvider
      ],
      child: Consumer<LocaleProvider>(
        // استخدام Consumer للاستماع لتغييرات اللغة
        builder: (context, localeProvider, child) {
          return MaterialApp(
            // استخدام الترجمة لعنوان التطبيق
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appName,
            localizationsDelegates: const [
              AppLocalizations
                  .delegate, // إضافة delegate الخاص بالترجمة
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', ''), // دعم اللغة العربية
              Locale('en', ''), // دعم اللغة الإنجليزية
            ],
            locale: localeProvider
                .locale, // تحديد اللغة بناءً على LocaleProvider
            localeResolutionCallback:
                (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode ==
                    locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            theme: ThemeData(
              primarySwatch: Colors.blueGrey,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.blueGrey,
                accentColor: Colors.deepOrangeAccent,
              ).copyWith(secondary: Colors.deepOrangeAccent),
              // fontFamily: 'Cairo', // يمكنك تفعيل هذا الخط إذا كان لديك ملف الخط
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0.5,
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData) {
                  return FutureBuilder(
                    future: Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).fetchUserData(snapshot.data!.uid),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return const HomeScreen();
                    },
                  );
                }
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
// MODELS
// =============================================================================

class Product {
  final String id;
  final String name;
  final String productNumber;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.productNumber,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      productNumber: data['productNumber'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'productNumber': productNumber,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

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

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'address': address,
      'isAdmin': isAdmin,
    };
  }
}

extension on UserModel {
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
// PROVIDERS (State Management)
// =============================================================================

class LocaleProvider with ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    notifyListeners();
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  int get itemCount {
    return _items.fold(
      0,
      (total, current) => total + current.quantity,
    );
  }

  double get totalAmount {
    return _items.fold(
      0.0,
      (total, current) => total + current.totalPrice,
    );
  }

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

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

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

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  String getWhatsAppMessage(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_items.isEmpty) {
      return appLocalizations.whatsappInquiryMessage;
    }

    String message = appLocalizations.whatsappOrderStart;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      message +=
          '${i + 1}. ${item.product.name} (${appLocalizations.productNumberShort}: ${item.product.productNumber}) - ${appLocalizations.quantity}: ${item.quantity}\n';
    }
    message +=
        '\n${appLocalizations.total}: ${totalAmount.toStringAsFixed(2)} ${appLocalizations.currencySymbol}';
    message += '\n\n${appLocalizations.whatsappConfirmOrder}';
    return message;
  }
}

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  final FirestoreService _firestoreService = FirestoreService();

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

  void clearUser() {
    _currentUser = null;
    _isAdmin = false;
    notifyListeners();
  }
}

// =============================================================================
// SERVICES (Firebase Interactions)
// =============================================================================

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

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

        bool isAdmin = (email ==
            'admin@example.com'); // IMPORTANT: Change this to your actual admin email
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
        // يمكن إرسال بريد التحقق مرة أخرى إذا لم يتم التحقق منه
        // await user.sendEmailVerification(); // اختياري: أعد إرسال البريد عند محاولة تسجيل الدخول
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

  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      // For production, consider using a logging framework instead of print
      print('Error (Sign Out): $e');
      throw Exception('حدث خطأ أثناء تسجيل الخروج.');
    }
  }

  Stream<User?> get user {
    return _auth.authStateChanges();
  }

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

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc =
        await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(uid).update(data);
  }

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

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('products').doc(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }
}

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
// WIDGETS
// =============================================================================

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: product.id,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
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
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
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
// SCREENS
// =============================================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';
  String _address = '';
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

  Future<void> _submitAuthForm() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      User? user;
      if (_isLogin) {
        user = await _authService.signInWithEmailAndPassword(
          _email,
          _password,
        );
      } else {
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
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).fetchUserData(user.uid);
          _showSnackBar(appLocalizations.loggedInSuccessfully);
          if (mounted) {
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
  }

  @override
  void dispose() {
    _passwordController.dispose();
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
                      obscureText: true,
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
                            _isLogin = !_isLogin;
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            _formKey.currentState?.reset();
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
                    if (_isLogin)
                      TextButton(
                        onPressed: () async {
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

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
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
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
                  Navigator.pop(context);
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
                await _authService.signOut();
                userProvider.clearUser();
                cartProvider.clearCart();
                if (mounted) {
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
      body: StreamBuilder<List<Product>>(
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
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ProductDetailScreen(
                          product: product,
                        ),
                      ),
                    );
                  }
                },
                onAddToCart: () {
                  cartProvider.addItem(product);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          appLocalizations
                              .productAddedToCart(product.name),
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
    );
  }

  // دالة لعرض مربع حوار اختيار اللغة
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
                localeProvider.setLocale(const Locale('en', ''));
                if (mounted) {
                  Navigator.of(ctx).pop();
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
                localeProvider.setLocale(const Locale('ar', ''));
                if (mounted) {
                  Navigator.of(ctx).pop();
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

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  int _quantity = 1;

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: widget.product.id,
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
              widget.product.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.product.price.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
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
              widget.product.description,
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
                      widget.product.name,
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

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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

  // Helper to launch WhatsApp
  Future<void> _launchWhatsApp({
    required BuildContext context,
    required String phoneNumber,
    required String message,
    String?
        appPackage, // e.g., 'com.whatsapp' or 'com.whatsapp.w4b' for Android
  }) async {
    final appLocalizations = AppLocalizations.of(context)!;
    String url =
        'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}';

    // On Android, we can try to target a specific package.
    // On iOS, the 'whatsapp://' scheme usually opens the correct app if installed.
    // For a more robust solution on Android, consider `url_launcher_android` to specify package.
    if (Platform.isAndroid && appPackage != null) {
      try {
        // This is a common way to try specific package on Android, but not guaranteed on all devices/versions.
        // It tries to open the URL, and if it fails, it might fall back to general intent.
        bool launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          // Fallback to general URL if specific package launch fails
          await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print(
            'Error trying to launch specific WhatsApp package: $e'); // For debug
        // Fallback to general launch if specific package launch throws an error
        try {
          await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication);
        } catch (e) {
          _showSnackBar(
            context,
            appLocalizations.whatsappNotInstalled,
            isError: true,
          );
          print(
              'Error launching WhatsApp (general fallback): $e'); // For debug
        }
      }
    } else {
      // For iOS and others, general launch usually works
      try {
        await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      } catch (e) {
        _showSnackBar(
          context,
          appLocalizations.whatsappNotInstalled,
          isError: true,
        );
        print(
            'Error launching WhatsApp (iOS/general): $e'); // For debug
      }
    }
  }

  Future<void> _showWhatsAppChoiceDialog(
      BuildContext context, String message) async {
    final appLocalizations = AppLocalizations.of(context)!;
    const String whatsappNumber =
        '+966980756485'; // الرقم الجديد للواتساب

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
                phoneNumber: whatsappNumber,
                message: message,
                appPackage:
                    'com.whatsapp', // Standard WhatsApp package for Android
              );
            },
            child: Text(appLocalizations.whatsappStandard),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _launchWhatsApp(
                context: context,
                phoneNumber: whatsappNumber,
                message: message,
                appPackage:
                    'com.whatsapp.w4b', // WhatsApp Business package for Android
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
                                      cartItem.product.name,
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
                                      '${cartItem.product.price.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.bold,
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
                            '${cartProvider.totalAmount.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showWhatsAppChoiceDialog(
                              context,
                              cartProvider
                                  .getWhatsAppMessage(context));
                          cartProvider.clearCart();
                          _showSnackBar(
                            context,
                            appLocalizations.orderSent,
                          );
                        },
                        icon: const Icon(Icons.facebook),
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
                  appLocalizations
                      .enterCurrentPassword, // Corrected to use translated string
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
                  AuthCredential credential =
                      EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassword!,
                  );
                  await user.reauthenticateWithCredential(
                    credential,
                  );
                  await user.updatePassword(newPassword!);
                  _showSnackBar(
                    appLocalizations.passwordChangeSuccess,
                  );
                  if (mounted) {
                    Navigator.of(ctx).pop();
                  }
                }
              } on FirebaseAuthException catch (e) {
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
                      readOnly: true,
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
                          await _authService.signOut();
                          userProvider.clearUser();
                          Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).clearCart();
                          if (mounted) {
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

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() =>
      _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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

  Future<void> _deleteProduct(Product product) async {
    final appLocalizations = AppLocalizations.of(context)!;
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appLocalizations.confirmDelete),
            content: Text(
              appLocalizations
                  .confirmDeleteProduct(product.name),
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

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.adminPanelTitle),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Product>>(
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
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
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
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${product.price.toStringAsFixed(2)} ${appLocalizations.currencySymbol} - ${appLocalizations.productNumberShort}: ${product.productNumber}',
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
                        onPressed: () => _deleteProduct(product),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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

class ManageProductScreen extends StatefulWidget {
  final Product? product;

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

  late TextEditingController _nameController;
  late TextEditingController _productNumberController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  File? _pickedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.product?.name ?? '',
    );
    _productNumberController = TextEditingController(
      text: widget.product?.productNumber ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _currentImageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productNumberController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  Future<void> _pickImage() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (mounted) {
      // Check mounted after async operation
      setState(() {
        if (pickedFile != null) {
          _pickedImage = File(pickedFile.path);
        } else {
          // For production, consider using a logging framework instead of print
          print(appLocalizations.imageNotSelected);
        }
      });
    }
  }

  Future<void> _submitProduct() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_pickedImage == null &&
        (_currentImageUrl == null ||
            _currentImageUrl!.isEmpty)) {
      _showSnackBar(appLocalizations.selectImage, isError: true);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String? imageUrlToSave = _currentImageUrl;

      if (_pickedImage != null) {
        if (widget.product != null &&
            widget.product!.imageUrl.isNotEmpty) {
          // For production, consider using a logging framework instead of print
          print(appLocalizations.skippingOldImageDeletion);
        }
        imageUrlToSave =
            await _storageService.uploadProductImage(
          _pickedImage!,
          widget.product?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }

      final newProduct = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        productNumber: _productNumberController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: imageUrlToSave ?? '',
      );

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
        Navigator.of(context).pop();
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
    final isEditing = widget.product != null;
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
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                            ? NetworkImage(_currentImageUrl!)
                                as ImageProvider
                            : null),
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: appLocalizations.productName,
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.enterProductName;
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
                  labelText: appLocalizations.priceSAR,
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
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: appLocalizations.description,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations
                        .enterProductDescription;
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
