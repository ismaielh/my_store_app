import 'dart:io'; // Required for file operations (e.g., image picking)
import 'dart:typed_data'; // For Uint8List when handling web images (though not used for Cloudinary upload anymore)

import 'package:flutter/material.dart'; // Core Flutter Material Design widgets
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:my_store_app/onboarding_auth_screens.dart';
import 'package:provider/provider.dart'; // For state management
import 'package:image_picker/image_picker.dart'; // For picking images from gallery
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication

// Importing AppLocalizations for internationalization (generated file)
import 'package:my_store_app/l10n/app_localizations.dart';

// Importing models, providers, and services from main.dart
import 'package:my_store_app/main.dart'; // Contains Product, UserModel, Providers, Services

// =============================================================================
// SCREENS (Application Screens)
// =============================================================================

/// User settings screen.
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
    // Initialize controllers with current user values
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

  /// Helper function to display SnackBar messages to the user.
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

  /// Update user data (name and address).
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

  /// Function to change user password.
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
              // Validate inputs
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
                  // Re-authenticate user before changing password
                  AuthCredential credential =
                      EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassword!,
                  );
                  await user.reauthenticateWithCredential(
                    credential,
                  );
                  await user.updatePassword(
                      newPassword!); // Update password
                  _showSnackBar(
                    appLocalizations.passwordChangeSuccess,
                  );
                  if (mounted) {
                    Navigator.of(ctx).pop();
                  }
                }
              } on FirebaseAuthException catch (e) {
                // Handle authentication errors
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
                          true, // Make email field read-only
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
                              .signOut(); // Sign out
                          userProvider
                              .clearUser(); // Clear user data
                          Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).clearCart(); // Clear cart
                          if (mounted) {
                            // Navigate back to AuthScreen and remove all previous screens
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

/// Admin panel screen, for managing products and dollar exchange rate.
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
    // Initialize dollar rate controller with current value from provider
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

  /// Helper function to display SnackBar messages to the user.
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

  /// Function to update dollar exchange rate.
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

  /// Function to delete a product.
  Future<void> _deleteProduct(Product product) async {
    final appLocalizations = AppLocalizations.of(context)!;
    // Show confirmation dialog before deletion
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appLocalizations.confirmDelete),
            content: Text(
              appLocalizations.confirmDeleteProduct(
                  product.getLocalizedName(
                      context)), // Using localized name
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
          // Call Cloudinary image deletion service (Note: This requires a backend for security)
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

  /// Function to update data on pull-to-refresh.
  Future<void> _onRefresh() async {
    debugPrint("AdminPanelScreen: _onRefresh initiated.");
    // Re-fetch exchange rate
    await Provider.of<ExchangeRateProvider>(context,
            listen: false)
        .fetchExchangeRate();
    // Since getProducts() is a StreamBuilder, it listens for changes automatically.
    // We can just return Future.value(true) to dismiss the refresh indicator.
    debugPrint(
        "AdminPanelScreen: _onRefresh completed. Exchange rate fetched.");
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final exchangeRateProvider =
        Provider.of<ExchangeRateProvider>(context);
    final double dollarRate =
        exchangeRateProvider.dollarExchangeRate;

    // Update controller value when exchange rate changes from Provider
    // This condition avoids infinite updates during widget rebuild
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
          // Dollar exchange rate input field
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
                                  .syrianPound, // SYP
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
          // Product list (with RefreshIndicator)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh, // Refresh function
              child: StreamBuilder<List<Product>>(
                stream: _firestoreService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    debugPrint(
                        "AdminPanelScreen: Products are loading...");
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    debugPrint(
                        "AdminPanelScreen: Error loading products: ${snapshot.error}");
                    return Center(
                      child: Text(
                        '${appLocalizations.loadingProductsError}${snapshot.error}',
                      ),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    debugPrint(
                        "AdminPanelScreen: No products found.");
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
                  debugPrint(
                      "AdminPanelScreen: ${snapshot.data!.length} products loaded.");
                  final products = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: products.length,
                    itemBuilder: (ctx, index) {
                      final product = products[index];
                      final double priceInSYP = product.price *
                          dollarRate; // Calculate price in SYP
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
                                debugPrint(
                                    'Error loading admin product image: $error');
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: Image.asset(
                                    'assets/Images/placeholder.png', // Fallback to a local placeholder image
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            product.getLocalizedName(
                                context), // Using localized name
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

/// Product management screen (Add/Edit).
class ManageProductScreen extends StatefulWidget {
  final Product?
      product; // Product to edit (if null, it means adding a new product)

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
      _nameArController; // Controller for product name in Arabic
  late TextEditingController
      _nameEnController; // Controller for product name in English
  late TextEditingController _productNumberController;
  late TextEditingController
      _priceController; // Controller for product price in USD
  late TextEditingController
      _descriptionArController; // Controller for product description in Arabic
  late TextEditingController
      _descriptionEnController; // Controller for product description in English

  File? _pickedImageFile; // Local file for the selected image
  String?
      _currentImageUrl; // Current image URL for the product (if exists)
  bool _isLoading = false; // To show loading indicator

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product values (if editing) or empty values (if adding)
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
          '', // Default price in USD
    );
    _descriptionArController = TextEditingController(
      text: widget.product?.description['ar'] ?? '',
    );
    _descriptionEnController = TextEditingController(
      text: widget.product?.description['en'] ?? '',
    );
    _currentImageUrl = widget.product?.imageUrl;
    debugPrint(
        "ManageProductScreen initialized. Is editing=${widget.product != null}");
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameArController.dispose();
    _nameEnController.dispose();
    _productNumberController.dispose();
    _priceController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    super.dispose();
  }

  /// Helper function to display SnackBar messages to the user.
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

  /// Function to pick an image from the gallery (for mobile/desktop only).
  Future<void> _pickImage() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (kIsWeb) {
      _showSnackBar(appLocalizations.imagePickingWebDisabled,
          isError: true);
      return;
    }
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Image quality (to reduce file size)
    );
    if (mounted) {
      setState(() {
        if (pickedFile != null) {
          _pickedImageFile = File(pickedFile.path);
          debugPrint("Image selected: ${pickedFile.path}");
        } else {
          debugPrint(
              appLocalizations.imageNotSelected); // For debug
        }
      });
    }
  }

  /// Function to submit product data (add or edit).
  Future<void> _submitProduct() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      debugPrint("ManageProductScreen: Form validation failed.");
      return;
    }
    _formKey.currentState!.save();

    // Check if an image is selected for mobile, or if a current image exists
    if (!kIsWeb &&
        _pickedImageFile == null &&
        (_currentImageUrl == null ||
            _currentImageUrl!.isEmpty)) {
      _showSnackBar(appLocalizations.selectImage, isError: true);
      return;
    }
    // For web, if it's not mobile, we need to consider if an old image exists or if we expect to upload one.
    // Since we explicitly disable web upload, we'll only allow if _currentImageUrl exists for editing,
    // or block if trying to add new product on web without image.
    if (kIsWeb &&
        _currentImageUrl == null &&
        widget.product == null) {
      _showSnackBar(
          appLocalizations.addingNewProductsWebDisabled,
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });
    debugPrint(
        "ManageProductScreen: Attempting to submit product.");

    try {
      // Check for duplicate product number
      bool productNumberExists =
          await _firestoreService.checkProductNumberExists(
        _productNumberController.text.trim(),
        excludeProductId: widget
            .product?.id, // Exclude current product if editing
      );
      debugPrint(
          "ManageProductScreen: Checking for product number '${_productNumberController.text.trim()}', exists: $productNumberExists");

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

      // If a new image is selected (and not web), upload it to Cloudinary
      if (!kIsWeb && _pickedImageFile != null) {
        if (widget.product != null &&
            widget.product!.imageUrl.isNotEmpty) {
          debugPrint(appLocalizations
              .skippingOldImageDeletion); // For debug
        }

        imageUrlToSave =
            await _storageService.uploadProductImage(
          _pickedImageFile!,
          widget.product?.id ??
              DateTime.now()
                  .millisecondsSinceEpoch
                  .toString(), // Use unique ID for image
        );
        debugPrint(
            "Image uploaded to Cloudinary: $imageUrlToSave");
      }

      // Create new or updated product object
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
            _priceController.text.trim()), // Save price in USD
        imageUrl: imageUrlToSave ?? '',
      );

      // Add or update product in Firestore
      if (widget.product == null) {
        await _firestoreService.addProduct(newProduct);
        _showSnackBar(appLocalizations.productAdded);
        debugPrint("New product added to Firestore.");
      } else {
        await _firestoreService.updateProduct(
          widget.product!.id,
          newProduct.toFirestore(),
        );
        _showSnackBar(appLocalizations.productUpdated);
        debugPrint("Product updated in Firestore.");
      }
      if (mounted) {
        // Navigate back to AdminPanelScreen after successful operation
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar(
        '${appLocalizations.operationFailed}${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      debugPrint(
          "ManageProductScreen: Error during submission: $e");
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
        null; // To determine if in edit or add mode
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
                      _pickImage, // On tap, open image gallery
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[200],
                    // Display selected image or current product image
                    backgroundImage: _pickedImageFile != null
                        ? FileImage(_pickedImageFile!)
                            as ImageProvider<Object>
                        : (_currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                            ? NetworkImage(_currentImageUrl!)
                                as ImageProvider<Object>
                            : null),
                    // Display camera icon if no image
                    child: (_pickedImageFile == null &&
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
              // Product name field (Arabic)
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
              // Product name field (English)
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
                      .priceUSD, // Label changed to Dollar
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
              // Product description field (Arabic)
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
              // Product description field (English)
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
