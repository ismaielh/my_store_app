import 'dart:math'; // Required for random number generation if needed (e.g., for some animations)
import 'dart:ui'; // Required for UI effects (e.g., blur)

import 'package:flutter/cupertino.dart'; // Required for Cupertino icons (e.g., arrow_right)
import 'package:flutter/material.dart'; // Required for core Flutter Material Design widgets
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
import 'package:my_store_app/onboarding_auth_screens.dart'; // For AuthScreen
import 'package:my_store_app/home_cart_screens.dart'; // For HomeScreen, CartScreen
import 'package:my_store_app/admin_user_screens.dart'; // For AdminPanelScreen, UserSettingsScreen

// =============================================================================
// RIVE ANIMATION COMPONENTS (مكونات الرسوم المتحركة Rive)
// =============================================================================

/// Rive Animation utility class for loading controllers and state machines.
class RiveUtils {
  // It's crucial to ensure these Rive files exist in the assets/RiveAssets/ folder
  // and are declared in pubspec.yaml under 'assets:'
  static StateMachineController getRiveController(
      Artboard artboard,
      {String? stateMachineName}) {
    // Made stateMachineName nullable
    StateMachineController? controller =
        StateMachineController.fromArtboard(
            artboard,
            stateMachineName ??
                'State Machine 1'); // Use null-aware operator
    if (controller == null) {
      // Handle the case where the state machine isn't found if needed
      debugPrint(
          'Error: StateMachineController not found for artboard ${artboard.name} and state machine $stateMachineName');
      throw Exception('StateMachineController not found');
    }
    artboard.addController(controller);
    return controller;
  }
}

/// Rive Model to hold animation data.
class RiveModel {
  final String src;
  final String artboard;
  final String stateMachineName;
  final String titleKey; // Changed to titleKey for localization
  late SMIBool? input;

  RiveModel({
    required this.src,
    required this.artboard,
    required this.stateMachineName,
    required this.titleKey,
  });

  set setInput(SMIBool status) {
    input = status;
  }
}

/// Holds Rive animation menu data (using keys for localization).
List<RiveModel> sideMenu = [
  RiveModel(
    src: "assets/RiveAssets/icons.riv",
    artboard: "HOME",
    stateMachineName: "HOME_interactivity",
    titleKey:
        "home", // Use localization key (e.g., appLocalizations.home)
  ),
  // Note: CHAT and SEARCH are now handled by standard Flutter Icons directly in SideBar
  // Therefore, their RiveModels are removed from this list if they are no longer Rive-based.
  // The 'TIMER' Rive asset for Admin Panel will now be at index 1.
  RiveModel(
    src: "assets/RiveAssets/icons.riv",
    artboard: "TIMER", // Now represents Admin Panel
    stateMachineName: "TIMER_Interactivity",
    titleKey:
        "adminPanelTitle", // Use localization key (e.g., appLocalizations.adminPanelTitle)
  ),
];

// =============================================================================
// ENTRY POINT AND SIDEBAR (Main Navigation Structure)
// =============================================================================

/// Main entry point for the application after authentication.
/// Manages main content views and sidebar navigation.
class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => EntryPointState();
}

class EntryPointState extends State<EntryPoint>
    with SingleTickerProviderStateMixin {
  bool isSideBarOpen =
      false; // State to control sidebar visibility

  // Initialize _currentBody directly with HomeScreen (default for all users)
  Widget _currentBody = const HomeScreen();

  SMIBool?
      isMenuOpenInput; // Rive input for animated menu button

  late AnimationController
      _animationController; // Controller for sidebar animation
  late Animation<double>
      scalAnimation; // Scaling animation for main content
  late Animation<double>
      animation; // Rotation animation for main content

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(
        () {
          setState(() {}); // Rebuild on animation updates
        },
      );
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: Curves.fastOutSlowIn));
    animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: Curves.fastOutSlowIn));

    // Initial body for all users should be HomeScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
          "EntryPoint initState post-frame callback: Initial body set to HomeScreen.");
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
        artboard, "State Machine");
    if (controller == null) {
      debugPrint(
          'Error: StateMachineController not found for menu_button.riv');
      return;
    }
    artboard.addController(controller);
    isMenuOpenInput = controller.findSMI('isOpen') as SMIBool;

    // Set initial state of Rive button to 'Menu' (meaning `true` for Rive's inverted logic)
    // This assumes Rive asset has `true` = Menu and `false` = X.
    isMenuOpenInput?.value = true;

    debugPrint("Rive animation for menu button initialized.");
  }

  void onMenuButtonPressed() {
    setState(() {
      isSideBarOpen = !isSideBarOpen;
      // If isSideBarOpen is true (sidebar is open), we want isMenuOpenInput.value to be false (showing X).
      // If isSideBarOpen is false (sidebar is closed), we want isMenuOpenInput.value to be true (showing Menu).
      // This maps our internal state (`isSideBarOpen`) to the inverted Rive input logic.
      isMenuOpenInput?.value = !isSideBarOpen;

      if (isSideBarOpen) {
        _animationController.forward(); // Open animation
      } else {
        _animationController.reverse(); // Close animation
      }
      debugPrint(
          "Menu button pressed. Sidebar now: $isSideBarOpen");
    });
  }

  @override
  Widget build(BuildContext context) {
    // Corrected the Directionality check
    final isRTL =
        Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(
          0xFF17203A), // Dark background for sidebar effect
      resizeToAvoidBottomInset:
          false, // Prevents resize when keyboard appears
      extendBody:
          true, // Extends body behind bottom navigation bar

      body: Stack(
        children: [
          // Animated Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            width: 288,
            left: isRTL
                ? null
                : (isSideBarOpen
                    ? 0
                    : -288), // LTR: left changes
            right: isRTL
                ? (isSideBarOpen ? 0 : -288)
                : null, // RTL: right changes
            height: MediaQuery.of(context).size.height,
            child: const SideBar(), // Your SideBar widget
          ),

          // Main content area, animated to scale and move
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(animation.value -
                  30 * animation.value * pi / 180),
            child: Transform.translate(
              offset: Offset(
                  isRTL
                      ? -animation.value * 265
                      : animation.value * 265,
                  0), // Adjust offset for RTL
              child: Transform.scale(
                scale: scalAnimation.value,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                      Radius.circular(isSideBarOpen ? 24 : 0)),
                  child:
                      _currentBody, // Display the current body (HomeScreen/AdminProductsScreen)
                ),
              ),
            ),
          ),

          // Menu button (toggle sidebar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            // Position based on LTR/RTL and sidebar state
            left: isRTL ? null : (isSideBarOpen ? 220 : 0),
            right: isRTL ? (isSideBarOpen ? 220 : 0) : null,
            top:
                16, // Adjusted top position to avoid text overlap
            child: GestureDetector(
              onTap: onMenuButtonPressed,
              child: Container(
                // Ensure margin is correctly applied for both directions
                margin: EdgeInsets.only(
                    left: isRTL ? 0 : 16,
                    right: isRTL ? 16 : 0,
                    top: 16),
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: RiveAnimation.asset(
                  "assets/RiveAssets/menu_button.riv",
                  onInit: onRiveInit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar widget for navigation.
class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final cartProvider =
        Provider.of<CartProvider>(context, listen: false);
    final localeProvider =
        Provider.of<LocaleProvider>(context, listen: false);

    // Function to get localized title based on titleKey
    String getLocalizedTitle(
        String titleKey, AppLocalizations appLocalizations) {
      switch (titleKey) {
        case "home":
          return appLocalizations.home;
        case "cartTitle":
          return appLocalizations.cartTitle;
        case "settingsTitle":
          return appLocalizations.settingsTitle;
        case "adminPanelTitle":
          return appLocalizations.adminPanelTitle;
        default:
          return titleKey; // Fallback to key if not found
      }
    }

    // Define consistent text style and icon color for sidebar items (except logout)
    const Color unifiedSidebarColor = Color(
        0xFFF7F7F7); // A bright, consistent white/off-white
    const TextStyle sidebarTextStyle = TextStyle(
        color: unifiedSidebarColor,
        fontWeight: FontWeight.normal);
    const Color sidebarIconColor =
        unifiedSidebarColor; // Unified icon color for most items
    const Color logoutColor = Color.fromARGB(
        255, 255, 100, 100); // Logout specific color

    // Thin white divider style
    const Widget thinWhiteDivider = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 24), // Keep padding for alignment
      child: Divider(
        color: Colors.white,
        height: 1.0,
        thickness: 0.5,
      ),
    );

    return SafeArea(
      child: Container(
        width: 288,
        height: double.infinity,
        color: const Color(
            0xFF17203A), // Dark background for sidebar
        child: Column(
          children: [
            InfoCard(
              name: userProvider.currentUser?.name ??
                  appLocalizations.newUser,
              email: userProvider.currentUser?.email ??
                  'user@example.com',
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 24, top: 32, bottom: 16),
              child: Text(
                appLocalizations.browse.toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(
                        color: unifiedSidebarColor,
                        fontWeight: FontWeight
                            .bold), // Unified style for section title
              ),
            ),
            Expanded(
              // Use Expanded to push remaining items to bottom
              child: ListView(
                // Use ListView to make items scrollable if too many
                padding: EdgeInsets
                    .zero, // Remove default ListView padding
                children: [
                  // Home option - Rive animation
                  BtmNavItem(
                    rive: sideMenu[0],
                    localizedTitle: getLocalizedTitle(
                        sideMenu[0].titleKey,
                        appLocalizations), // Pass appLocalizations
                    press: () {
                      // Set current body to HomeScreen (default for all)
                      (context as Element)
                          .findAncestorStateOfType<
                              EntryPointState>()
                          ?.setState(() {
                        (context)
                            .findAncestorStateOfType<
                                EntryPointState>()
                            ?._currentBody = const HomeScreen();
                      });
                      // Close sidebar after navigation
                      (context)
                          .findAncestorStateOfType<
                              EntryPointState>()
                          ?.onMenuButtonPressed();
                    },
                    appLocalizations: appLocalizations,
                  ),
                  thinWhiteDivider, // Divider after Home

                  // Cart option - conditional, only for non-admin users - using standard Flutter Icon
                  if (!userProvider.isAdmin)
                    ListTile(
                      leading: const Icon(Icons.shopping_cart,
                          color:
                              sidebarIconColor), // Standard shopping cart icon
                      title: Text(
                        appLocalizations.cartTitle,
                        style: sidebarTextStyle,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const CartScreen(),
                          ),
                        );
                        (context as Element)
                            .findAncestorStateOfType<
                                EntryPointState>()
                            ?.onMenuButtonPressed();
                      },
                    ),
                  if (!userProvider.isAdmin)
                    thinWhiteDivider, // Divider after Cart (conditional)

                  // Settings option - using standard Flutter Icon
                  ListTile(
                    leading: const Icon(Icons.settings,
                        color:
                            sidebarIconColor), // Standard settings icon
                    title: Text(
                      appLocalizations.settingsTitle,
                      style: sidebarTextStyle,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) =>
                              const UserSettingsScreen(),
                        ),
                      );
                      (context as Element)
                          .findAncestorStateOfType<
                              EntryPointState>()
                          ?.onMenuButtonPressed();
                    },
                  ),
                  thinWhiteDivider, // Divider after Settings

                  // Admin Panel option (conditional) - Rive animation
                  if (userProvider.isAdmin)
                    BtmNavItem(
                      rive: sideMenu[
                          1], // Index 1 for TIMER artboard from sideMenu (as chat/search are now standard)
                      localizedTitle: getLocalizedTitle(
                          sideMenu[1].titleKey,
                          appLocalizations), // Pass appLocalizations
                      press: () {
                        final newBody = const AdminPanelScreen();
                        (context as Element)
                            .findAncestorStateOfType<
                                EntryPointState>()
                            ?.setState(() {
                          (context)
                              .findAncestorStateOfType<
                                  EntryPointState>()
                              ?._currentBody = newBody;
                        });
                        (context)
                            .findAncestorStateOfType<
                                EntryPointState>()
                            ?.onMenuButtonPressed();
                      },
                      appLocalizations: appLocalizations,
                    ),
                  if (userProvider.isAdmin)
                    thinWhiteDivider, // Divider after Admin Panel (conditional)

                  // Language change option - already using ListTile
                  ListTile(
                    leading: const Icon(Icons.language,
                        color:
                            sidebarIconColor), // Unified icon color
                    title: Text(
                      appLocalizations.changeLanguage,
                      style:
                          sidebarTextStyle, // Unified text style
                    ),
                    onTap: () {
                      (context as Element)
                          .findAncestorStateOfType<
                              EntryPointState>()
                          ?.onMenuButtonPressed();
                      _showLanguagePickerDialog(
                          context, localeProvider);
                    },
                  ),
                  // No divider after Language, as Logout is a separate section
                ],
              ),
            ),
            // Logout option - placed at the very bottom, outside the Expanded ListView
            ListTile(
              leading: const Icon(Icons.logout,
                  color: logoutColor), // Specific logout color
              title: Text(
                appLocalizations.logout,
                style: const TextStyle(
                    color: logoutColor,
                    fontWeight: FontWeight
                        .normal), // Specific logout color for text
              ),
              onTap: () async {
                await _authService
                    .signOut(); // Sign out from Firebase
                userProvider
                    .clearUser(); // Clear user data from provider
                cartProvider.clearCart(); // Clear cart
                // REMOVED: Navigator.of(context).pushAndRemoveUntil(...)
                // Let the StreamBuilder in main.dart handle navigation based on auth state changes.
                // It will automatically navigate to OnbodingScreen when signOut() completes.
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to show language picker dialog, copied from old HomeScreen
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
                localeProvider.setLocale(
                    const Locale('en', '')); // Set English
                if (mounted) {
                  Navigator.of(ctx).pop(); // Close dialog
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
                localeProvider.setLocale(
                    const Locale('ar', '')); // Set Arabic
                if (mounted) {
                  Navigator.of(ctx).pop(); // Close dialog
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

/// Info card for sidebar (user details).
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.name,
    required this.email,
  });

  final String name, email;

  @override
  Widget build(BuildContext context) {
    // Ensuring these colors match the unified sidebar scheme or are designed to contrast appropriately
    const Color infoCardTextColor =
        Color(0xFFF7F7F7); // Matching unifiedSidebarColor
    const Color infoCardSubtitleColor =
        Colors.white70; // Slightly muted for subtitle
    const Color infoCardIconColor = Color(
        0xFFF7F7F7); // Matching unifiedSidebarColor for icon

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.white24,
        child: Icon(
          CupertinoIcons.person,
          color: infoCardIconColor, // Unified icon color
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
            color: infoCardTextColor,
            fontWeight:
                FontWeight.bold), // Unified text color and style
      ),
      subtitle: Text(
        email,
        style: const TextStyle(
            color:
                infoCardSubtitleColor), // Slightly different for subtitle
      ),
    );
  }
}

/// Bottom Navigation Item (used in sidebar now for Rive animations).
class BtmNavItem extends StatelessWidget {
  const BtmNavItem({
    super.key,
    required this.rive,
    required this.press,
    required this.localizedTitle, // Added for localized title
    required this.appLocalizations, // Added appLocalizations
  });

  final RiveModel rive;
  final VoidCallback press;
  final String localizedTitle; // The already localized title
  final AppLocalizations
      appLocalizations; // AppLocalizations instance

  @override
  Widget build(BuildContext context) {
    // Define consistent text style for sidebar items
    const TextStyle sidebarItemTextStyle = TextStyle(
        color: Color(0xFFF7F7F7), fontWeight: FontWeight.normal);
    // sidebarItemIconColor is already defined in _SideBarState, but passed implicitly here.
    // Assuming the Rive asset's colors are handled within the Rive file itself.

    return Stack(
      children: [
        // Removed AnimatedPositioned Container. ListTile's built-in hover/splash will handle feedback.
        ListTile(
          onTap: press,
          leading: SizedBox(
            height: 34,
            width: 34,
            child: RiveAnimation.asset(
              rive.src,
              fit: BoxFit.cover,
              artboard: rive.artboard,
              onInit: (artboard) {
                rive.input = RiveUtils.getRiveController(
                        artboard,
                        stateMachineName: rive.stateMachineName)
                    .findSMI("active") as SMIBool;
              },
            ),
          ),
          title: Text(
            localizedTitle, // Use the passed localized title
            style:
                sidebarItemTextStyle, // Unified text color and style
          ),
        ),
      ],
    );
  }
}
