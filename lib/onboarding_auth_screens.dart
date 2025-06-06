import 'dart:io'; // Required for file operations (e.g., image picking)
import 'dart:math'; // Required for random number generation if needed (e.g., for some animations)
import 'dart:ui'; // Required for UI effects (e.g., blur)

import 'package:flutter/cupertino.dart'; // Required for Cupertino icons (e.g., arrow_right)
import 'package:flutter/material.dart'; // Required for core Flutter Material Design widgets
import 'package:flutter_localizations/flutter_localizations.dart'; // Required for localization delegates
import 'package:flutter_svg/flutter_svg.dart'; // Required for displaying SVG images
import 'package:provider/provider.dart'; // Required for state management
import 'package:rive/rive.dart'
    hide
        Image; // Rive package for animations, hiding dart:ui Image to avoid conflict

// Firebase & Cloudinary imports
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication

// Importing AppLocalizations for internationalization (generated file)
import 'package:my_store_app/l10n/app_localizations.dart';

// Importing services and providers from main.dart
import 'package:my_store_app/main.dart';
import 'package:my_store_app/entry_point_sidebar.dart'; // For EntryPoint

// =============================================================================
// SCREENS (Application Screens)
// =============================================================================

/// Onboding Screen (Welcome/Intro Screen).
class OnbodingScreen extends StatefulWidget {
  const OnbodingScreen({super.key});

  @override
  State<OnbodingScreen> createState() => _OnbodingScreenState();
}

class _OnbodingScreenState extends State<OnbodingScreen> {
  late RiveAnimationController
      _btnAnimationController; // Rive animation controller for the button

  bool isShowSignInDialog =
      false; // State to control dialog visibility (deprecated, now direct navigation)

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation(
      "active",
      autoplay: false,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            left: 100,
            bottom: 200,
            child: Image.asset("assets/Backgrounds/Spline.png"),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: const SizedBox(),
            ),
          ),
          RiveAnimation.asset(
            "assets/RiveAssets/shapes.riv",
            // Specify artboard and stateMachineName if they are different from default
            // artboard: "New Artboard", // Example
            // stateMachineName: "State Machine 1", // Example
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: const SizedBox(),
            ),
          ),
          AnimatedPositioned(
            top: isShowSignInDialog ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            duration: const Duration(milliseconds: 240),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          Text(
                            appLocalizations.onboardingTitle,
                            style: const TextStyle(
                              fontSize: 60,
                              fontFamily: "Poppins",
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            appLocalizations.onboardingSubtitle,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    GestureDetector(
                      onTap: () {
                        _btnAnimationController.isActive = true;
                        Future.delayed(
                          const Duration(milliseconds: 800),
                          () {
                            setState(() {
                              isShowSignInDialog =
                                  !isShowSignInDialog;
                            });
                            debugPrint(
                                "Animated button tapped on OnbodingScreen.");
                            // Directly navigate to AuthScreen
                            Navigator.of(context)
                                .pushReplacement(
                              MaterialPageRoute(
                                  builder: (ctx) =>
                                      const AuthScreen()),
                            );
                          },
                        );
                      },
                      child: SizedBox(
                        height: 64,
                        width: 260,
                        child: Stack(
                          children: [
                            RiveAnimation.asset(
                              "assets/RiveAssets/button.riv",
                              controllers: [
                                _btnAnimationController
                              ],
                              // artboard: "New Artboard", // Example if needed
                              // stateMachineName: "State Machine 1", // Example if needed
                            ),
                            Positioned.fill(
                              top: 8,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_right,
                                    color: Theme.of(context)
                                        .primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appLocalizations
                                        .startTheCourse,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const Spacer(), // Removed the unwanted text section here
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Authentication screen (Login/Sign Up).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<
      FormState>(); // Key for Form Widget to validate inputs
  bool _isLogin =
      true; // To determine if the screen is in login or signup mode
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';
  String _address = '';
  bool _isLoading =
      false; // To show loading indicator during network operations

  final AuthService _authService =
      AuthService(); // Authentication service

  final TextEditingController _passwordController =
      TextEditingController(); // To control password field
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // To control confirm password field

  /// Helper function to display SnackBar messages to the user.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted)
      return; // Ensure the Widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Function to submit the authentication form (login or signup).
  Future<void> _submitAuthForm() async {
    final appLocalizations = AppLocalizations.of(context)!;
    // Validate all form fields
    if (!_formKey.currentState!.validate()) {
      debugPrint("AuthScreen: Form validation failed.");
      return;
    }
    _formKey.currentState!.save(); // Save field values
    debugPrint(
        "AuthScreen: Attempting to submit form: isLogin=$_isLogin, email=$_email");

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      User? user;
      if (_isLogin) {
        // Attempt to login
        user = await _authService.signInWithEmailAndPassword(
          _email,
          _password,
        );
        debugPrint("AuthScreen: User logged in: ${user?.email}");
      } else {
        // Attempt to register
        if (_password != _confirmPassword) {
          _showSnackBar(appLocalizations.passwordMismatch,
              isError: true);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          debugPrint("AuthScreen: Password mismatch.");
          return;
        }
        user = await _authService.registerWithEmailAndPassword(
          _email,
          _password,
          _name,
          _address,
        );
        debugPrint(
            "AuthScreen: User registered: ${user?.email}");
      }

      if (user != null) {
        if (_isLogin) {
          debugPrint(
              "AuthScreen: User authenticated successfully: ${user.email}");
          // Fetch user data after successful login
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).fetchUserData(user.uid);
          _showSnackBar(appLocalizations.loggedInSuccessfully);
          if (mounted) {
            debugPrint(
                "AuthScreen: Navigating to EntryPoint after successful login.");
            // Navigate to EntryPoint after login
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) =>
                    const EntryPoint(), // Navigate to EntryPoint
              ),
            );
          }
        } else {
          // After registration, we don't auto-login until email is verified
          _showSnackBar(
              appLocalizations.emailVerificationNeeded);
          _showSnackBar(appLocalizations.emailVerificationSent);
          // Return to login screen for user to log in after verification
          if (mounted) {
            debugPrint(
                "AuthScreen: Navigating back to AuthScreen after registration for verification.");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => const AuthScreen(),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
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
        // Custom error for email verification
        errorMessage = appLocalizations.verifyEmailToLogin;
      }
      _showSnackBar(errorMessage, isError: true);
      debugPrint(
          "AuthScreen: Firebase Auth Error: ${e.code} - ${e.message}");
    } catch (e) {
      // Handle general errors
      _showSnackBar(
        '${appLocalizations.errorOccurred}${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      debugPrint("AuthScreen: General Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // End loading
        });
      }
      debugPrint(
          "AuthScreen: Auth form submission finished. isLoading=$_isLoading");
    }
  }

  @override
  void dispose() {
    _passwordController
        .dispose(); // Dispose controllers to prevent memory leaks
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
                          true, // Hide input text (password)
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
                    // Display additional registration fields only if in signup mode
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
                    // Display loading indicator or button based on loading state
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
                                !_isLogin; // Toggle screen mode
                            _passwordController
                                .clear(); // Clear password fields
                            _confirmPasswordController.clear();
                            _formKey.currentState
                                ?.reset(); // Reset form state
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
                    // Display "Forgot Password" button only in login mode
                    if (_isLogin)
                      TextButton(
                        onPressed: () async {
                          // Validate email before sending reset link
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
