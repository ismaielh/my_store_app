import 'dart:io'; // Required for file operations (e.g., image picking)
import 'dart:typed_data'; // Required for Uint8List on web image handling (kept for compatibility in some parts)

import 'package:flutter/material.dart'; // Core Flutter Material Design widgets
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_localizations/flutter_localizations.dart'; // For localization delegates
import 'package:firebase_core/firebase_core.dart'; // Firebase core initialization
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:my_store_app/firebase_options.dart'; // Importing your actual generated firebase_options.dart file
import 'package:my_store_app/l10n/app_localizations.dart'; // Importing AppLocalizations for internationalization
import 'package:provider/provider.dart'; // For state management
import 'package:image_picker/image_picker.dart'; // For picking images from gallery
import 'package:url_launcher/url_launcher.dart'; // For launching URLs (e.g., WhatsApp)
import 'package:cloudinary_public/cloudinary_public.dart'; // Cloudinary for image uploads

// Importing newly split screen files
import 'package:my_store_app/onboarding_auth_screens.dart'; // For OnbodingScreen and AuthScreen
import 'package:my_store_app/entry_point_sidebar.dart'; // For EntryPoint

/// Main entry point of the application.
/// Initializes Firebase and runs the app.
void main() async {
  // Ensure Widgets are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with default options for the current platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Run the application
  runApp(const MyApp());
}

/// The main Widget for the application.
/// Sets up Providers and manages authentication state to display the appropriate screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider for managing the shopping cart
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        // Provider for managing user data and their admin status
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        // Provider for managing the application's locale (language)
        ChangeNotifierProvider(
            create: (ctx) => LocaleProvider()),
        // Provider for managing the dollar exchange rate
        ChangeNotifierProvider(
            create: (ctx) => ExchangeRateProvider()),
      ],
      // Consumer to listen for language changes and update the app accordingly
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Generate app title based on selected language
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appName,
            // Define supported localization delegates
            localizationsDelegates: const [
              AppLocalizations
                  .delegate, // Our custom localization delegate
              GlobalMaterialLocalizations
                  .delegate, // Material Design components localization delegate
              GlobalWidgetsLocalizations
                  .delegate, // Widgets localization delegate
              GlobalCupertinoLocalizations
                  .delegate, // Cupertino components localization delegate
            ],
            // Supported locales in the application
            supportedLocales: const [
              Locale('ar', ''), // Support Arabic
              Locale('en', ''), // Support English
            ],
            // Set the current locale of the app based on LocaleProvider
            locale: localeProvider.locale,
            // Function to resolve locale if user's preferred locale is not supported
            localeResolutionCallback:
                (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode ==
                    locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales
                  .first; // Fallback to the first supported language (Arabic in this case)
            },
            // Define general app theme properties
            theme: ThemeData(
              primarySwatch: Colors.blueGrey, // Primary color
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.blueGrey,
                accentColor: Colors.deepOrangeAccent,
              ).copyWith(
                  secondary: Colors
                      .deepOrangeAccent), // Secondary color
              // fontFamily: 'Cairo', // You can enable this font if you have the font file (requires adding to pubspec.yaml)
              // AppBar design enhancements
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4.0, // Increased shadow for depth
                shadowColor:
                    Colors.grey.withOpacity(0.3), // Shadow color
                titleTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22, // Larger title font size
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: const IconThemeData(
                    color: Colors.black87), // AppBar icon color
                actionsIconTheme: const IconThemeData(
                    color: Colors
                        .black87), // AppBar actions icon color
                shape: const RoundedRectangleBorder(
                  // Rounded bottom corners
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
              // ElevatedButton design enhancements
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors
                      .deepOrangeAccent, // Background color
                  foregroundColor:
                      Colors.white, // Text and icon color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        12), // More rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 3, // Add shadow to buttons
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      12), // More rounded corners
                  borderSide:
                      const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      12), // More rounded corners
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
              cardTheme: const CardThemeData(
                elevation: 5, // Larger shadow for cards
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(
                      15)), // More rounded corners
                ),
                shadowColor: Colors.black12, // Card shadow color
              ),
            ),
            // Manage authentication state to display the initial screen (Login/Home)
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance
                  .authStateChanges(), // Listen for authentication state changes
              builder: (context, snapshot) {
                // If connection state is waiting, show loading indicator
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  debugPrint(
                      "Auth state: Waiting for connection.");
                  return const Center(
                      child:
                          CircularProgressIndicator()); // Show loading while checking auth state
                }
                // If user is logged in
                if (snapshot.hasData) {
                  debugPrint(
                      "Auth state: User logged in (${snapshot.data!.email}).");
                  // If user is logged in, fetch their data (including admin status)
                  return FutureBuilder(
                    future: Provider.of<UserProvider>(context,
                            listen: false)
                        .fetchUserData(snapshot.data!.uid),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        debugPrint(
                            "Auth state: Fetching user data.");
                        return const Center(
                            child:
                                CircularProgressIndicator()); // Show loading while fetching user data
                      }
                      // User data fetched, now safe to render EntryPoint
                      debugPrint(
                          "Auth state: User data fetched, rendering EntryPoint.");
                      return const EntryPoint();
                    },
                  );
                }
                debugPrint(
                    "Auth state: No user logged in, rendering OnbodingScreen.");
                return const OnbodingScreen(); // If not logged in, show Onboding screen
              },
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// MODELS (Data Models)
// =============================================================================

/// Represents the product data model.
class Product {
  final String id;
  final Map<String, String>
      name; // Name as a Map for multiple languages
  final String productNumber;
  final Map<String, String>
      description; // Description as a Map for multiple languages
  final double
      price; // Price in USD (converted to SYP for display)
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.productNumber,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  /// Helper function to get the product name in the current app locale.
  /// If translation is not available, it tries to fallback to Arabic, then English.
  String getLocalizedName(BuildContext context) {
    final String languageCode =
        Localizations.localeOf(context).languageCode;
    return name[languageCode] ??
        name['ar'] ??
        name['en'] ??
        'No Name';
  }

  /// Helper function to get the product description in the current app locale.
  /// If translation is not available, it tries to fallback to Arabic, then English.
  String getLocalizedDescription(BuildContext context) {
    final String languageCode =
        Localizations.localeOf(context).languageCode;
    return description[languageCode] ??
        description['ar'] ??
        description['en'] ??
        'No Description';
  }

  /// Factory function to create a Product object from a Firestore DocumentSnapshot.
  /// Handles fields that might be String or Map (for compatibility with old data).
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // Handle 'name' field, whether it's a String (old data) or a Map (new data)
    Map<String, String> nameMap;
    if (data['name'] is String) {
      // If String, assume it's Arabic and duplicate for English as initial value
      nameMap = {'ar': data['name'], 'en': data['name']};
    } else if (data['name'] is Map) {
      // If Map, convert it to Map<String, String>
      nameMap = Map<String, String>.from(data['name']);
    } else {
      // Default value if field is missing or of unexpected type
      nameMap = {'ar': '', 'en': ''};
    }

    // Handle 'description' field, whether it's a String or a Map, similarly
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
      // Default value if field is missing or of unexpected type
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

  /// Converts a Product object to a Map for saving to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name, // Save name as a Map
      'productNumber': productNumber,
      'description': description, // Save description as a Map
      'price': price, // Save price in USD
      'imageUrl': imageUrl,
      'timestamp': FieldValue
          .serverTimestamp(), // Add timestamp for product ordering
    };
  }
}

/// Represents a single item in the shopping cart.
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  /// Calculates the total price of the item (USD price * quantity).
  double get totalPriceUSD => product.price * quantity;
}

/// Represents the user data model.
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

  /// Factory function to create a UserModel object from a Firestore DocumentSnapshot.
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

  /// Converts a UserModel object to a Map for saving to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'address': address,
      'isAdmin': isAdmin,
    };
  }
}

/// Extension on UserModel to add copyWith function.
extension UserModelCopyWith on UserModel {
  /// Creates a new copy of UserModel with optional changes to name and address.
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

/// Provider for managing the application's locale.
class LocaleProvider with ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  /// Sets the new locale for the application.
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners(); // Notify listeners of the change
  }

  /// Clears the selected locale (resets to default).
  void clearLocale() {
    _locale = null;
    notifyListeners();
  }
}

/// Provider for managing the dollar exchange rate.
class ExchangeRateProvider with ChangeNotifier {
  double _dollarExchangeRate = 0.0;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  double get dollarExchangeRate => _dollarExchangeRate;
  bool get isLoading => _isLoading;

  /// On provider initialization, fetches the exchange rate.
  ExchangeRateProvider() {
    fetchExchangeRate();
  }

  /// Fetches the exchange rate from Firestore.
  Future<void> fetchExchangeRate() async {
    _isLoading = true;
    notifyListeners();
    try {
      _dollarExchangeRate =
          await _firestoreService.getDollarExchangeRate();
    } catch (e) {
      debugPrint('Error fetching dollar exchange rate: $e');
      _dollarExchangeRate =
          0.0; // Default value in case of error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the dollar exchange rate in Firestore and notifies listeners.
  Future<void> updateDollarExchangeRate(double newRate) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateDollarExchangeRate(newRate);
      _dollarExchangeRate = newRate;
    } catch (e) {
      debugPrint('Error updating dollar exchange rate: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Provider for managing the shopping cart.
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  /// Calculates the total number of items in the cart.
  int get itemCount {
    return _items.fold(
      0,
      (total, current) => total + current.quantity,
    );
  }

  /// Calculates the total cart amount in SYP based on the dollar exchange rate.
  double totalAmountSYP(double dollarExchangeRate) {
    return _items.fold(
      0.0,
      (total, current) =>
          total + (current.totalPriceUSD * dollarExchangeRate),
    );
  }

  /// Adds a product to the cart or increases its quantity if already exists.
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

  /// Removes a product from the cart.
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Increases the quantity of a specific product in the cart.
  void increaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  /// Decreases the quantity of a specific product in the cart, removes it if quantity reaches zero.
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

  /// Clears all items from the cart.
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Generates a WhatsApp message containing order details and customer info.
  String getWhatsAppMessage(BuildContext context,
      UserModel? user, double dollarExchangeRate) {
    final appLocalizations = AppLocalizations.of(context)!;
    String message = '';

    // Add customer name and address if available
    if (user != null) {
      message +=
          '${appLocalizations.customerName}: ${user.name}\n';
      message +=
          '${appLocalizations.customerAddress}: ${user.address}\n\n';
    }

    // If cart is empty, send a general inquiry message
    if (_items.isEmpty) {
      message += appLocalizations.whatsappInquiryMessage;
    } else {
      // Build order message
      message += appLocalizations.whatsappOrderStart;
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        // Display localized product name, product number, quantity, and price in USD and SYP
        message +=
            '${i + 1}. ${item.product.getLocalizedName(context)} (${appLocalizations.productNumberShort}: ${item.product.productNumber}) - ${appLocalizations.quantity}: ${item.quantity}\n';
        message +=
            '  ${appLocalizations.priceUSD}: ${item.product.price.toStringAsFixed(2)} \$ (${(item.product.price * dollarExchangeRate).toStringAsFixed(2)} ${appLocalizations.currencySymbol})\n';
      }
      // Add total order amount in SYP
      message +=
          '\n${appLocalizations.total}: ${totalAmountSYP(dollarExchangeRate).toStringAsFixed(2)} ${appLocalizations.currencySymbol}';
      message += '\n\n${appLocalizations.whatsappConfirmOrder}';
    }
    return message;
  }
}

/// Provider for managing the current user data and their admin status.
class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  final FirestoreService _firestoreService = FirestoreService();

  /// Fetches user data from Firestore.
  Future<void> fetchUserData(String uid) async {
    _isLoading = true;
    debugPrint("UserProvider: Fetching user data for UID: $uid");
    try {
      _currentUser = await _firestoreService.getUser(uid);
      _isAdmin = _currentUser?.isAdmin ?? false;
      debugPrint(
          "UserProvider: User data fetched for UID: $uid, isAdmin: $_isAdmin");
    } catch (e) {
      debugPrint('UserProvider: Error fetching user data: $e');
      _currentUser = null;
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates user data in Firestore.
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
      // Update user data in the provider after successful save
      _currentUser = _currentUser?.copyWith(
        name: name,
        address: address,
      );
    } catch (e) {
      debugPrint('UserProvider: Error updating user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears user data from the provider (on logout).
  void clearUser() {
    _currentUser = null;
    _isAdmin = false;
    notifyListeners();
  }
}

// =============================================================================
// SERVICES (Interaction Services with Firebase)
// =============================================================================

/// Service for managing authentication operations (register, login, logout, password reset).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Registers a new user with email and password.
  /// Also creates user data in Firestore and sends a verification email.
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
        // Send verification email after account creation
        await user.sendEmailVerification();

        // Determine if user is admin based on email (MUST BE CHANGED IN PRODUCTION)
        bool isAdmin = (email ==
            'admin@example.com'); // IMPORTANT: Change this to your admin email
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
      debugPrint('Firebase Auth Error (Register): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error (Register): $e');
      throw Exception(
          'An error occurred during account creation.');
    }
  }

  /// Signs in an existing user with email and password.
  /// Also checks if the email has been verified.
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

      // Check email verification after successful login
      if (user != null && !user.emailVerified) {
        // Option to resend verification email if not verified (optional)
        // await user.sendEmailVerification();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message:
              'Email not verified. Please check your inbox.',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error (Login): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error (Login): $e');
      throw Exception('An error occurred during login.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      debugPrint('Error (Sign Out): $e');
      throw Exception('An error occurred during sign out.');
    }
  }

  /// Stream providing updates to the user's authentication state.
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Error (Reset Password): ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error (Reset Password): $e');
      throw Exception(
          'An error occurred while sending password reset email.');
    }
  }
}

/// Service for interacting with the Firestore database.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a new user in the 'users' collection.
  Future<void> createUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore());
  }

  /// Fetches data for a specific user from the 'users' collection.
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc =
        await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Updates existing user data in the 'users' collection.
  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Gets a Stream of product list, ordered by timestamp descending.
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

  /// Adds a new product to the 'products' collection.
  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }

  /// Updates existing product data in the 'products' collection.
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('products').doc(productId).update(data);
  }

  /// Deletes a product from the 'products' collection.
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Checks if a product number already exists (excluding the current product when editing).
  Future<bool> checkProductNumberExists(String productNumber,
      {String? excludeProductId}) async {
    Query query = _db
        .collection('products')
        .where('productNumber', isEqualTo: productNumber);

    if (excludeProductId != null) {
      // If editing, exclude the current product from the check
      query = query.where(FieldPath.documentId,
          isNotEqualTo: excludeProductId);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.isNotEmpty;
  }

  /// Fetches the dollar exchange rate from the 'settings' collection.
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
    return 0.0; // Default value if rate is not found
  }

  /// Updates the dollar exchange rate in the 'settings' collection.
  Future<void> updateDollarExchangeRate(double newRate) async {
    await _db.collection('settings').doc('exchangeRate').set(
        {
          'dollarRate': newRate,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(
            merge: true)); // Merge data instead of overwriting
  }
}

/// Service for managing image upload and deletion using Cloudinary.
class StorageService {
  // Change these values to your Cloudinary credentials
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dva0b4u0g', // <<< REPLACE WITH YOUR CLOUD NAME
    'my_store_unsigned_upload', // <<< You will need to create an Upload Preset in Cloudinary
    cache: false,
  );

  // Note: API Key and API Secret are not used directly here for unsigned uploads.
  // However, you will need API Secret if you use Signed Uploads or other API Calls.
  // For security, it's preferable to use Signed Uploads via a backend server.

  /// Uploads a product image to Cloudinary.
  /// This function is now designed ONLY for mobile/desktop (File).
  Future<String> uploadProductImage(
    File imageFile, // Expecting a File type for mobile/desktop
    String productId, // Can be used as public_id in Cloudinary
  ) async {
    try {
      CloudinaryFile fileToUpload = CloudinaryFile.fromFile(
        imageFile.path,
        resourceType: CloudinaryResourceType.Image,
        folder:
            'product_images', // Folder to save images in Cloudinary
        publicId:
            productId, // File name in Cloudinary (can be unique)
      );

      final response = await cloudinary.uploadFile(fileToUpload);
      debugPrint(
          'Cloudinary Upload Response: ${response.secureUrl}');
      return response
          .secureUrl; // This is the secure image URL (HTTPS)
    } on CloudinaryException catch (e) {
      debugPrint('Cloudinary Error: ${e.message}');
      throw Exception(
          'Failed to upload image to Cloudinary: ${e.message}');
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image.');
    }
  }

  /// Deletes a product image from Cloudinary.
  /// (Note: This operation usually requires a backend for security).
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      // To use deleteResource, you would need API Key and API Secret
      // This operation should be done from a backend server (like Firebase Functions) for security.
      // If you use it directly from the client, you expose your API Secret.

      // Extract publicId from the URL
      // Example: https://res.cloudinary.com/YOUR_CLOUD_NAME/image/upload/v12345/product_images/some_product_id.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final publicIdWithExtension =
            pathSegments.last; // e.g., some_product_id.jpg
        final folder = pathSegments[
            pathSegments.length - 2]; // e.g., product_images
        final publicId =
            '$folder/${publicIdWithExtension.split('.').first}'; // e.g., product_images/some_product_id

        // This operation requires a signature (signature) or API Key and API Secret
        // And it is not directly supported by cloudinary_public for the client.
        // You would need to use Cloudinary SDK on a backend server (Node.js, Python, etc.)
        // Or use Signed Uploads with temporary deletion.
        debugPrint(
            'Cloudinary delete is complex from client-side. Skipping for now.');
        debugPrint(
            'To delete, you typically need a backend to call Cloudinary API with API Secret.');
        // For now, we will just print a message.
        // In a real app, you would send a request to your backend to delete the image.
      }
    } catch (e) {
      debugPrint(
          'Error deleting image from Cloudinary (client-side attempt): $e');
    }
  }
}

// =============================================================================
// WIDGETS (Graphical User Interface Components)
// =============================================================================

/// Product display card in the home screen.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback?
      onAddToCart; // Made nullable for conditional display

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart, // Made nullable
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    // Access exchange rate provider to calculate price in SYP
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context);
    final double dollarRate =
        exchangeRateProvider.dollarExchangeRate;
    final double priceInSYP = product.price * dollarRate;

    return Card(
      clipBehavior: Clip
          .antiAlias, // To ensure image is clipped correctly with rounded corners
      child: InkWell(
        onTap:
            onTap, // Function to be called when the card is tapped
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: product
                    .id, // For creating a smooth transition effect between screens
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // Function to build an alternative interface in case of image loading failure
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                        'Error loading image for product ${product.id}: $error');
                    return Container(
                      color: Colors.grey[200],
                      child: Image.asset(
                        'assets/Images/placeholder.png', // Fallback to a local placeholder image
                        fit: BoxFit.cover,
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
                        context), // Using localized name
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow
                        .ellipsis, // Show "..." if text is too long
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Display price in SYP
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
                  // Conditionally display "Add to Cart" button
                  if (onAddToCart != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                        onPressed:
                            onAddToCart, // Function to be called when "Add to Cart" button is tapped
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
                          textStyle:
                              const TextStyle(fontSize: 14),
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
