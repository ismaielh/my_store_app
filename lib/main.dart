import 'dart:io'; // Required for File operations (image_picker)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// You might need to import firebase_options.dart if you used flutterfire configure
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // If you used `flutterfire configure`, uncomment the line below:
    // options: DefaultFirebaseOptions.currentPlatform,
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
      ],
      child: MaterialApp(
        title: 'متجري الإلكتروني',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''),
          Locale('en', ''),
        ],
        localeResolutionCallback: (locale, supportedLocales) {
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
          // fontFamily: 'Cairo', // Uncomment if you added Cairo font in pubspec.yaml
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
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blueGrey,
                width: 2,
              ),
            ),
            labelStyle: const TextStyle(color: Colors.black54),
            hintStyle: const TextStyle(color: Colors.black38),
            fillColor: Colors.grey[50],
            filled: true,
          ),
          cardTheme: CardTheme(
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

// Extension to allow copying UserModel with new values
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

  String getWhatsAppMessage() {
    if (_items.isEmpty) {
      return 'مرحباً، أود الاستفسار عن المنتجات المتوفرة في متجركم.';
    }

    String message = 'مرحباً، أود طلب المنتجات التالية:\n\n';
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      message +=
          '${i + 1}. ${item.product.name} (رقم: ${item.product.productNumber}) - الكمية: ${item.quantity}\n';
    }
    message +=
        '\nالإجمالي: ${totalAmount.toStringAsFixed(2)} ر.س';
    message += '\n\nالرجاء تأكيد الطلب.';
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
    notifyListeners();
    try {
      _currentUser = await _firestoreService.getUser(uid);
      _isAdmin = _currentUser?.isAdmin ?? false;
    } catch (e) {
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
      UserCredential result = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
      User? user = result.user;

      if (user != null) {
        bool isAdmin =
            (email ==
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
      print('Firebase Auth Error (Register): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Error (Register): $e');
      throw Exception('حدث خطأ أثناء إنشاء الحساب.');
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (Login): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Error (Login): $e');
      throw Exception('حدث خطأ أثناء تسجيل الدخول.');
    }
  }

  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
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
      print(
        'Firebase Auth Error (Reset Password): ${e.message}',
      );
      throw Exception(e.message);
    } catch (e) {
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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage(
    File imageFile,
    String productId,
  ) async {
    try {
      Reference ref = _storage
          .ref()
          .child('product_images')
          .child('$productId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('فشل تحميل الصورة.');
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
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
                    '${product.price.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      color:
                          Theme.of(
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
                      label: const Text('أضف للسلة'),
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitAuthForm() async {
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
        user = await _authService.registerWithEmailAndPassword(
          _email,
          _password,
          _name,
          _address,
        );
      }

      if (user != null) {
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).fetchUserData(user.uid);
        _showSnackBar(
          _isLogin
              ? 'تم تسجيل الدخول بنجاح!'
              : 'تم إنشاء الحساب بنجاح!',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ في المصادقة.';
      if (e.code == 'user-not-found') {
        errorMessage = 'لا يوجد مستخدم بهذا البريد الإلكتروني.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'كلمة المرور غير صحيحة.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'كلمة المرور ضعيفة جداً.';
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'متجري',
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
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !value.contains('@')) {
                          return 'الرجاء إدخال بريد إلكتروني صالح.';
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
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'كلمة المرور يجب أن تتكون من 6 أحرف على الأقل.';
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
                              'confirm_password',
                            ),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim() !=
                                      _password.trim()) {
                                return 'كلمة المرور غير متطابقة.';
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
                            decoration: const InputDecoration(
                              labelText: 'الاسم (اختياري)',
                              prefixIcon: Icon(Icons.person),
                            ),
                            onSaved: (value) {
                              _name = value!.trim();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('address'),
                            decoration: const InputDecoration(
                              labelText: 'العنوان (اختياري)',
                              prefixIcon: Icon(
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
                                ? 'تسجيل الدخول'
                                : 'إنشاء حساب',
                          ),
                        ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? 'ليس لديك حساب؟ أنشئ حساباً الآن'
                            : 'لديك حساب بالفعل؟ تسجيل الدخول',
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
                              'الرجاء إدخال بريد إلكتروني صالح لإعادة تعيين كلمة المرور.',
                              isError: true,
                            );
                            return;
                          }
                          try {
                            setState(() {
                              _isLoading = true;
                            });
                            await _authService
                                .sendPasswordResetEmail(_email);
                            _showSnackBar(
                              'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
                            );
                          } catch (e) {
                            _showSnackBar(
                              e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                              isError: true,
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        child: Text(
                          'هل نسيت كلمة المرور؟',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const CartScreen(),
                    ),
                  );
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
                userProvider.currentUser?.name ?? 'مستخدم جديد',
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
              title: const Text('الرئيسية'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('إعدادات الحساب'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const UserSettingsScreen(),
                  ),
                );
              },
            ),
            if (userProvider.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('لوحة تحكم الأدمن'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const AdminPanelScreen(),
                    ),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _authService.signOut();
                userProvider.clearUser();
                cartProvider.clearCart();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (ctx) => const AuthScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
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
                'خطأ في تحميل المنتجات: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد منتجات حالياً.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
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
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (ctx) => ProductDetailScreen(
                              product: product,
                            ),
                      ),
                    ),
                onAddToCart: () {
                  cartProvider.addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إضافة ${product.name} إلى السلة!',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          );
        },
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
              '${widget.product.price.toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'رقم المنتج: ${widget.product.productNumber}',
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
                    setState(() {
                      if (_quantity > 1) _quantity--;
                    });
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
                    setState(() {
                      _quantity++;
                    });
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
                    'تم إضافة ${widget.product.name} (الكمية: $_quantity) إلى السلة!',
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('أضف إلى السلة'),
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

  Future<void> _sendOrderViaWhatsApp(
    BuildContext context,
    String message,
  ) async {
    const String whatsappNumber =
        '+966501234567'; // IMPORTANT: Change this to your actual WhatsApp number

    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$whatsappNumber&text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      _showSnackBar(
        context,
        'لا يمكن فتح واتساب. تأكد من تثبيته على جهازك.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('سلة الشراء')),
      body:
          cartProvider.items.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'سلة الشراء فارغة!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'أضف بعض المنتجات لتبدأ التسوق.',
                      style: TextStyle(
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
                        final cartItem =
                            cartProvider.items[index];
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
                                            TextOverflow
                                                .ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${cartItem.product.price.toStringAsFixed(2)} ر.س',
                                        style: TextStyle(
                                          color:
                                              Theme.of(context)
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
                                                        .product
                                                        .id,
                                                  );
                                            },
                                          ),
                                          Text(
                                            '${cartItem.quantity}',
                                            style:
                                                const TextStyle(
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
                                                        .product
                                                        .id,
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
                                                        .product
                                                        .id,
                                                  );
                                              _showSnackBar(
                                                context,
                                                'تم حذف المنتج من السلة.',
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
                            const Text(
                              'الإجمالي:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cartProvider.totalAmount.toStringAsFixed(2)} ر.س',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            _sendOrderViaWhatsApp(
                              context,
                              cartProvider.getWhatsAppMessage(),
                            );
                            cartProvider.clearCart();
                            _showSnackBar(
                              context,
                              'تم إرسال الطلب عبر واتساب!',
                            );
                          },
                          icon: Icon(Icons.facebook),
                          label: const Text(
                            'إرسال الطلب عبر واتساب',
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
                              'تم إفراغ السلة.',
                            );
                          },
                          child: const Text('إفراغ السلة'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

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
        _showSnackBar('تم حفظ التغييرات بنجاح!');
      }
    } catch (e) {
      _showSnackBar(
        'فشل حفظ التغييرات: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    String? currentPassword;
    String? newPassword;
    String? confirmNewPassword;

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تغيير كلمة المرور'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                    ),
                    onChanged:
                        (value) => currentPassword = value,
                  ),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText:
                          'كلمة المرور الجديدة (6 أحرف على الأقل)',
                    ),
                    onChanged: (value) => newPassword = value,
                  ),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                    ),
                    onChanged:
                        (value) => confirmNewPassword = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPassword == null ||
                      newPassword!.length < 6) {
                    _showSnackBar(
                      'كلمة المرور الجديدة يجب أن تتكون من 6 أحرف على الأقل.',
                      isError: true,
                    );
                    return;
                  }
                  if (newPassword != confirmNewPassword) {
                    _showSnackBar(
                      'كلمة المرور الجديدة غير متطابقة.',
                      isError: true,
                    );
                    return;
                  }
                  if (currentPassword == null ||
                      currentPassword!.isEmpty) {
                    _showSnackBar(
                      'الرجاء إدخال كلمة المرور الحالية.',
                      isError: true,
                    );
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    User? user =
                        FirebaseAuth.instance.currentUser;
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
                        'تم تغيير كلمة المرور بنجاح!',
                      );
                      Navigator.of(ctx).pop();
                    }
                  } on FirebaseAuthException catch (e) {
                    String errorMessage =
                        'فشل تغيير كلمة المرور.';
                    if (e.code == 'wrong-password') {
                      errorMessage =
                          'كلمة المرور الحالية غير صحيحة.';
                    } else if (e.code ==
                        'requires-recent-login') {
                      errorMessage =
                          'الرجاء تسجيل الدخول مرة أخرى لتغيير كلمة المرور.';
                    }
                    _showSnackBar(errorMessage, isError: true);
                  } catch (e) {
                    _showSnackBar(
                      'حدث خطأ: ${e.toString().replaceFirst('Exception: ', '')}',
                      isError: true,
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('تغيير'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الحساب')),
      body:
          userProvider.isLoading
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
                            color:
                                Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: TextEditingController(
                          text:
                              userProvider.currentUser?.email ??
                              'غير متوفر',
                        ),
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'الرجاء إدخال اسمك.';
                          }
                          return null;
                        },
                        onSaved:
                            (value) =>
                                _nameController.text = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        onSaved:
                            (value) =>
                                _addressController.text = value!,
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                  onPressed: _updateUserData,
                                  child: const Text(
                                    'حفظ التغييرات',
                                  ),
                                ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _changePassword,
                          child: const Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(fontSize: 16),
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
                            Navigator.of(
                              context,
                            ).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder:
                                    (ctx) => const AuthScreen(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('تسجيل الخروج'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('تأكيد الحذف'),
                content: Text(
                  'هل أنت متأكد أنك تريد حذف المنتج "${product.name}"؟',
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => Navigator.of(ctx).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('حذف'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        if (product.imageUrl.isNotEmpty) {
          await _storageService.deleteProductImage(
            product.imageUrl,
          );
        }
        await _firestoreService.deleteProduct(product.id);
        _showSnackBar('تم حذف المنتج بنجاح!');
      } catch (e) {
        _showSnackBar(
          'فشل حذف المنتج: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
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
                'خطأ في تحميل المنتجات: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد منتجات حالياً. اضغط على زر الإضافة لإضافة منتج جديد.',
                style: TextStyle(
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
                    '${product.price.toStringAsFixed(2)} ر.س - رقم: ${product.productNumber}',
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => ManageProductScreen(
                                    product: product,
                                  ),
                            ),
                          );
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const ManageProductScreen(),
            ),
          );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    setState(() {
      if (pickedFile != null) {
        _pickedImage = File(pickedFile.path);
      } else {
        print('لم يتم اختيار صورة.');
      }
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_pickedImage == null &&
        (_currentImageUrl == null ||
            _currentImageUrl!.isEmpty)) {
      _showSnackBar('الرجاء اختيار صورة للمنتج.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrlToSave = _currentImageUrl;

      if (_pickedImage != null) {
        if (_currentImageUrl != null &&
            _currentImageUrl!.isNotEmpty) {
          await _storageService.deleteProductImage(
            _currentImageUrl!,
          );
        }
        imageUrlToSave = await _storageService
            .uploadProductImage(
              _pickedImage!,
              widget.product?.id ??
                  DateTime.now().millisecondsSinceEpoch
                      .toString(),
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
        _showSnackBar('تم إضافة المنتج بنجاح!');
      } else {
        await _firestoreService.updateProduct(
          widget.product!.id,
          newProduct.toFirestore(),
        );
        _showSnackBar('تم تعديل المنتج بنجاح!');
      }
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar(
        'فشل العملية: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد',
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
                    backgroundImage:
                        _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (_currentImageUrl != null &&
                                    _currentImageUrl!.isNotEmpty
                                ? NetworkImage(_currentImageUrl!)
                                    as ImageProvider
                                : null),
                    child:
                        (_pickedImage == null &&
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
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال اسم المنتج.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم المنتج (فريد للواتساب)',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال رقم المنتج.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعر (ر.س)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      double.tryParse(value) == null) {
                    return 'الرجاء إدخال سعر صالح.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال وصف للمنتج.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                          onPressed: _submitProduct,
                          icon: Icon(
                            isEditing ? Icons.save : Icons.add,
                          ),
                          label: Text(
                            isEditing
                                ? 'حفظ التغييرات'
                                : 'إضافة المنتج',
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
