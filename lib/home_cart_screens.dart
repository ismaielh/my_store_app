import 'package:flutter/material.dart'; // Core Flutter Material Design widgets
import 'package:provider/provider.dart'; // For state management
import 'package:url_launcher/url_launcher.dart'; // For launching URLs (e.g., WhatsApp)

// Importing AppLocalizations for internationalization (generated file)
import 'package:my_store_app/l10n/app_localizations.dart';

// Importing models, providers, and services from main.dart
import 'package:my_store_app/main.dart';
import 'package:my_store_app/entry_point_sidebar.dart'; // For EntryPointState
import 'package:my_store_app/admin_user_screens.dart'; // For ManageProductScreen

// =============================================================================
// SCREENS (Application Screens)
// =============================================================================

/// Home screen for the application, displays a list of products.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  /// Function to update data on pull-to-refresh.
  Future<void> _onRefresh() async {
    debugPrint("HomeScreen: _onRefresh initiated.");
    // Re-fetch exchange rate
    await Provider.of<ExchangeRateProvider>(context,
            listen: false)
        .fetchExchangeRate();
    // Since getProducts() is a StreamBuilder, it listens for changes automatically.
    // We can just return Future.value(true) to dismiss the refresh indicator.
    debugPrint(
        "HomeScreen: _onRefresh completed. Exchange rate fetched.");
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) ==
        TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.homeTitle),
        centerTitle: true,
        // REMOVED: leading property here. The custom Rive menu button now handles this.
        actions: [
          if (!userProvider
              .isAdmin) // Show cart icon only if not admin
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                      Icons.shopping_cart), // Shopping cart icon
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
                // Display item count in cart if greater than zero
                if (cartProvider.itemCount > 0)
                  Positioned(
                    // Adjust position based on RTL/LTR
                    right: isRTL ? null : 5,
                    left: isRTL ? 5 : null,
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
      // Add RefreshIndicator for pull-to-refresh
      body: RefreshIndicator(
        onRefresh: _onRefresh, // Refresh function
        child: StreamBuilder<List<Product>>(
          stream: _firestoreService
              .getProducts(), // Listen for product changes in Firestore
          builder: (context, snapshot) {
            // Display loading indicator
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              debugPrint("HomeScreen: Products are loading...");
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // Display error message if there's an error fetching data
            if (snapshot.hasError) {
              debugPrint(
                  "HomeScreen: Error loading products: ${snapshot.error}");
              return Center(
                child: Text(
                  '${appLocalizations.loadingProductsError}${snapshot.error}',
                ),
              );
            }
            // Display message if no products exist
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              debugPrint("HomeScreen: No products found.");
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
                "HomeScreen: ${snapshot.data!.length} products loaded.");
            final products = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns in the grid
                childAspectRatio:
                    0.75, // Aspect ratio for each item
                crossAxisSpacing:
                    16.0, // Horizontal spacing between items
                mainAxisSpacing:
                    16.0, // Vertical spacing between items
              ),
              itemCount: products.length,
              itemBuilder: (ctx, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // Update tap behavior for products based on user role
                    if (userProvider.isAdmin) {
                      // Navigate to ManageProductScreen if admin
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
                      // Navigate to ProductDetailScreen if regular user
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
                  // Pass onAddToCart only if not admin, otherwise pass null
                  onAddToCart: userProvider.isAdmin
                      ? null // Pass null when user is admin
                      : () {
                          cartProvider.addItem(product);
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  appLocalizations
                                      .productAddedToCart(product
                                          .getLocalizedName(
                                              context)), // Using localized name
                                ),
                                duration:
                                    const Duration(seconds: 1),
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
}

/// Product detail screen.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  int _quantity = 1; // Quantity of the product to add to cart

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
        dollarRate; // Calculate price in SYP

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product.getLocalizedName(
              context))), // Using localized name in AppBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: widget.product
                  .id, // For creating a smooth transition effect
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                      'Error loading product detail image for product ${widget.product.id}: $error');
                  return Container(
                    color: Colors.grey[200],
                    height: 250,
                    child: Image.asset(
                      'assets/Images/placeholder.png', // Fallback to a local placeholder image
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.product.getLocalizedName(
                  context), // Using localized name
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // Display price in SYP
              '${priceInSYP.toStringAsFixed(2)} ${appLocalizations.currencySymbol}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // Display price in USD as well (optional)
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
                  context), // Using localized description
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
                          context), // Using localized name
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

/// Shopping cart screen.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Unified WhatsApp number used in the app (Syria)
  static const String _whatsappPhoneNumber = '963980756485';

  /// Helper function to display SnackBar messages to the user.
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

  /// Helper function to launch WhatsApp app or WhatsApp Web.
  Future<void> _launchWhatsApp({
    required BuildContext context,
    required String phoneNumber,
    required String message,
  }) async {
    final appLocalizations = AppLocalizations.of(context)!;

    // Clean phone number to ensure it's digits-only format
    String cleanedPhoneNumber =
        phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Attempt to open WhatsApp app directly
    String whatsappAppUrl =
        'whatsapp://send?phone=$cleanedPhoneNumber&text=${Uri.encodeComponent(message)}';

    try {
      bool launched = await launchUrl(
        Uri.parse(whatsappAppUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // If app failed to open, fallback to WhatsApp Web (wa.me)
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
      // Catch any errors during launchUrl attempt itself
      _showSnackBar(
        context,
        appLocalizations.whatsappNotInstalled,
        isError: true,
      );
      debugPrint('Error launching WhatsApp: $e'); // For debug
    }
  }

  /// Function to display a dialog to choose between regular WhatsApp or WhatsApp Business.
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
                    _whatsappPhoneNumber, // Use unified number
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
                    _whatsappPhoneNumber, // Use unified number
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
    final userProvider =
        Provider.of<UserProvider>(context); // Get user data
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
                                    debugPrint(
                                        'Error loading cart item image: $error');
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: Image.asset(
                                        'assets/Images/placeholder.png', // Fallback to a local placeholder image
                                        fit: BoxFit.cover,
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
                                              context), // Using localized name
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
                                      // Display price in SYP
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
                                      // Display price in USD as well (optional)
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
                            // Display total in SYP
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
                          // Send user data and exchange rate with WhatsApp message
                          _showWhatsAppChoiceDialog(
                              context,
                              cartProvider.getWhatsAppMessage(
                                  context,
                                  Provider.of<UserProvider>(
                                          context,
                                          listen: false)
                                      .currentUser,
                                  dollarRate));
                          cartProvider.clearCart();
                          _showSnackBar(
                            context,
                            appLocalizations.orderSent,
                          );
                        },
                        icon: const Icon(Icons
                            .chat), // Changed icon to a generic chat icon
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
