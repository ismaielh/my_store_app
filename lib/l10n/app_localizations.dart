import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'My E-Store'**
  String get appName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one now'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get haveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get emailRequired;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error occurred.'**
  String get authError;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found for that email.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided.'**
  String get wrongPassword;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get weakPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmail;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed. Please check your internet.'**
  String get networkError;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreated;

  /// No description provided for @loggedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully!'**
  String get loggedInSuccessfully;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetPasswordEmailSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password (at least 6 characters)'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Password change failed.'**
  String get passwordChangeFailed;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get wrongCurrentPassword;

  /// No description provided for @reauthenticateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to change password.'**
  String get reauthenticateRequired;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: '**
  String get errorOccurred;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get homeTitle;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cartTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get settingsTitle;

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanelTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productNumber.
  ///
  /// In en, this message translates to:
  /// **'Product Number (unique for WhatsApp)'**
  String get productNumber;

  /// No description provided for @priceSAR.
  ///
  /// In en, this message translates to:
  /// **'Price (SAR)'**
  String get priceSAR;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select a product image.'**
  String get selectImage;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully!'**
  String get productUpdated;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: '**
  String get operationFailed;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty!'**
  String get cartEmpty;

  /// No description provided for @addProductsToShop.
  ///
  /// In en, this message translates to:
  /// **'Add some products to start shopping.'**
  String get addProductsToShop;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get total;

  /// No description provided for @sendOrderWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send Order via WhatsApp'**
  String get sendOrderWhatsApp;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed on your device.'**
  String get whatsappNotInstalled;

  /// No description provided for @orderSent.
  ///
  /// In en, this message translates to:
  /// **'Order sent via WhatsApp!'**
  String get orderSent;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully!'**
  String get productDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product: '**
  String get deleteFailed;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{productName}\"?'**
  String confirmDeleteProduct(Object productName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available currently. Click the add button to add a new product.'**
  String get noProducts;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue.'**
  String get loginRequired;

  /// No description provided for @emailVerificationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please verify your email to log in.'**
  String get emailVerificationNeeded;

  /// No description provided for @emailVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to your email. Please check your inbox.'**
  String get emailVerificationSent;

  /// No description provided for @verifyEmailToLogin.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email to log in.'**
  String get verifyEmailToLogin;

  /// No description provided for @whatsappChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose WhatsApp App'**
  String get whatsappChoiceTitle;

  /// No description provided for @whatsappChoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Which WhatsApp app would you like to use to send the order?'**
  String get whatsappChoiceMessage;

  /// No description provided for @whatsappStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard WhatsApp'**
  String get whatsappStandard;

  /// No description provided for @whatsappBusiness.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Business'**
  String get whatsappBusiness;

  /// No description provided for @updateAccountSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account settings updated successfully!'**
  String get updateAccountSuccessfully;

  /// No description provided for @fetchingUserDataError.
  ///
  /// In en, this message translates to:
  /// **'Error fetching user data: '**
  String get fetchingUserDataError;

  /// No description provided for @updateUserDataError.
  ///
  /// In en, this message translates to:
  /// **'Error updating user data: '**
  String get updateUserDataError;

  /// No description provided for @createAccountError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while creating the account.'**
  String get createAccountError;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while signing in.'**
  String get signInError;

  /// No description provided for @signOutError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while signing out.'**
  String get signOutError;

  /// No description provided for @sendResetEmailError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while sending the password reset email.'**
  String get sendResetEmailError;

  /// No description provided for @loadingProductsError.
  ///
  /// In en, this message translates to:
  /// **'Error loading products: '**
  String get loadingProductsError;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available currently.'**
  String get noProductsAvailable;

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {productName} to cart!'**
  String productAddedToCart(Object productName);

  /// No description provided for @productQuantityAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {productName} (Quantity: {quantity}) to cart!'**
  String productQuantityAddedToCart(Object productName, Object quantity);

  /// No description provided for @productRemovedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Product removed from cart.'**
  String get productRemovedFromCart;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared.'**
  String get cartCleared;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get enterYourName;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price.'**
  String get enterValidPrice;

  /// No description provided for @enterProductNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product number.'**
  String get enterProductNumber;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter product name.'**
  String get enterProductName;

  /// No description provided for @enterProductDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter product description.'**
  String get enterProductDescription;

  /// No description provided for @imageNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected.'**
  String get imageNotSelected;

  /// No description provided for @whatsappInquiryMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, I would like to inquire about the available products in your store.'**
  String get whatsappInquiryMessage;

  /// No description provided for @productNumberShort.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get productNumberShort;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currencySymbol;

  /// No description provided for @whatsappOrderStart.
  ///
  /// In en, this message translates to:
  /// **'Hello, I would like to order the following products:\n\n'**
  String get whatsappOrderStart;

  /// No description provided for @whatsappConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the order.'**
  String get whatsappConfirmOrder;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangeSuccess;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @skippingOldImageDeletion.
  ///
  /// In en, this message translates to:
  /// **'Skipping old Cloudinary image deletion from client-side.'**
  String get skippingOldImageDeletion;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get newUser;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully!'**
  String get languageChangedSuccessfully;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password.'**
  String get enterCurrentPassword;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
