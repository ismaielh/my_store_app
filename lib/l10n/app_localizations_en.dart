// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'My E-Store';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get login => 'Login';

  @override
  String get createAccount => 'Create Account';

  @override
  String get noAccount => 'Don\'t have an account? Create one now';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get emailRequired => 'Please enter a valid email.';

  @override
  String get passwordLength => 'Password must be at least 6 characters.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get authError => 'Authentication error occurred.';

  @override
  String get userNotFound => 'No user found for that email.';

  @override
  String get wrongPassword => 'Wrong password provided.';

  @override
  String get emailAlreadyInUse => 'This email is already in use.';

  @override
  String get weakPassword => 'Password is too weak.';

  @override
  String get invalidEmail => 'Invalid email format.';

  @override
  String get networkError =>
      'Network connection failed. Please check your internet.';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get loggedInSuccessfully => 'Logged in successfully!';

  @override
  String get resetPasswordEmailSent =>
      'Password reset link sent to your email.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password (at least 6 characters)';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordChangeFailed => 'Password change failed.';

  @override
  String get wrongCurrentPassword => 'Current password is incorrect.';

  @override
  String get reauthenticateRequired =>
      'Please log in again to change password.';

  @override
  String get errorOccurred => 'An error occurred: ';

  @override
  String get homeTitle => 'Products';

  @override
  String get cartTitle => 'Shopping Cart';

  @override
  String get settingsTitle => 'Account Settings';

  @override
  String get adminPanelTitle => 'Admin Panel';

  @override
  String get logout => 'Logout';

  @override
  String get newProduct => 'Add New Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get productName => 'Product Name';

  @override
  String get productNumber => 'Product Number (unique for WhatsApp)';

  @override
  String get priceSAR => 'Price (SAR)';

  @override
  String get description => 'Description';

  @override
  String get selectImage => 'Please select a product image.';

  @override
  String get productAdded => 'Product added successfully!';

  @override
  String get productUpdated => 'Product updated successfully!';

  @override
  String get operationFailed => 'Operation failed: ';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get cartEmpty => 'Your cart is empty!';

  @override
  String get addProductsToShop => 'Add some products to start shopping.';

  @override
  String get total => 'Total:';

  @override
  String get sendOrderWhatsApp => 'Send Order via WhatsApp';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get whatsappNotInstalled =>
      'WhatsApp is not installed on your device.';

  @override
  String get orderSent => 'Order sent via WhatsApp!';

  @override
  String get productDeleted => 'Product deleted successfully!';

  @override
  String get deleteFailed => 'Failed to delete product: ';

  @override
  String get confirmDelete => 'Confirm Deletion';

  @override
  String confirmDeleteProduct(Object productName) {
    return 'Are you sure you want to delete \"$productName\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noProducts =>
      'No products available currently. Click the add button to add a new product.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get changePassword => 'Change Password';

  @override
  String get loginRequired => 'Please log in to continue.';

  @override
  String get emailVerificationNeeded =>
      'Account created! Please verify your email to log in.';

  @override
  String get emailVerificationSent =>
      'Verification email sent to your email. Please check your inbox.';

  @override
  String get verifyEmailToLogin => 'Please verify your email to log in.';

  @override
  String get whatsappChoiceTitle => 'Choose WhatsApp App';

  @override
  String get whatsappChoiceMessage =>
      'Which WhatsApp app would you like to use to send the order?';

  @override
  String get whatsappStandard => 'Standard WhatsApp';

  @override
  String get whatsappBusiness => 'WhatsApp Business';

  @override
  String get updateAccountSuccessfully =>
      'Account settings updated successfully!';

  @override
  String get fetchingUserDataError => 'Error fetching user data: ';

  @override
  String get updateUserDataError => 'Error updating user data: ';

  @override
  String get createAccountError =>
      'An error occurred while creating the account.';

  @override
  String get signInError => 'An error occurred while signing in.';

  @override
  String get signOutError => 'An error occurred while signing out.';

  @override
  String get sendResetEmailError =>
      'An error occurred while sending the password reset email.';

  @override
  String get loadingProductsError => 'Error loading products: ';

  @override
  String get noProductsAvailable => 'No products available currently.';

  @override
  String productAddedToCart(Object productName) {
    return 'Added $productName to cart!';
  }

  @override
  String productQuantityAddedToCart(Object productName, Object quantity) {
    return 'Added $productName (Quantity: $quantity) to cart!';
  }

  @override
  String get productRemovedFromCart => 'Product removed from cart.';

  @override
  String get cartCleared => 'Cart cleared.';

  @override
  String get enterYourName => 'Please enter your name.';

  @override
  String get enterValidPrice => 'Please enter a valid price.';

  @override
  String get enterProductNumber => 'Please enter a product number.';

  @override
  String get enterProductName => 'Please enter product name.';

  @override
  String get enterProductDescription => 'Please enter product description.';

  @override
  String get imageNotSelected => 'No image selected.';

  @override
  String get whatsappInquiryMessage =>
      'Hello, I would like to inquire about the available products in your store.';

  @override
  String get productNumberShort => 'No.';

  @override
  String get quantity => 'Quantity';

  @override
  String get currencySymbol => 'SYP';

  @override
  String get whatsappOrderStart =>
      'Hello, I would like to order the following products:\n\n';

  @override
  String get whatsappConfirmOrder => 'Please confirm the order.';

  @override
  String get passwordChangeSuccess => 'Password changed successfully!';

  @override
  String get name => 'Name';

  @override
  String get address => 'Address';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get skippingOldImageDeletion =>
      'Skipping old Cloudinary image deletion from client-side.';

  @override
  String get newUser => 'New User';

  @override
  String get home => 'Home';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageChangedSuccessfully => 'Language changed successfully!';

  @override
  String get enterCurrentPassword => 'Please enter your current password.';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerAddress => 'Customer Address';

  @override
  String get productNumberExists =>
      'Product number already exists. Please enter a unique number.';

  @override
  String get priceUSD => 'Price (USD)';

  @override
  String get dollarExchangeRate => 'Dollar Exchange Rate (SYP)';

  @override
  String get enterDollarExchangeRate =>
      'Please enter the dollar exchange rate.';

  @override
  String get syrianPound => 'SYP';

  @override
  String get dollarExchangeRateUpdated =>
      'Dollar exchange rate updated successfully!';

  @override
  String get productNameAr => 'Product Name (Arabic)';

  @override
  String get productNameEn => 'Product Name (English)';

  @override
  String get productDescriptionAr => 'Product Description (Arabic)';

  @override
  String get productDescriptionEn => 'Product Description (English)';

  @override
  String get enterProductNameAr => 'Please enter product name in Arabic.';

  @override
  String get enterProductNameEn => 'Please enter product name in English.';

  @override
  String get enterProductDescriptionAr =>
      'Please enter product description in Arabic.';

  @override
  String get enterProductDescriptionEn =>
      'Please enter product description in English.';
}
