import 'package:flutter/material.dart';
import '../widgets/orientation_logo.dart';
import '../services/api/auth_api.dart';
import '../utils/auth_helper.dart';
import 'account_info_screen.dart';
import 'account_deletion_pending_screen.dart';
import 'join_us_screen.dart';
import 'login_screen.dart';
import 'add_reel_screen.dart';
import 'change_inventory_screen.dart';
import 'about_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'admin_dashboard_screen.dart';

enum UserRole { user, developer, admin }

class AccountScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const AccountScreen({super.key, this.onProfileUpdated});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const Color brandRed = Color(0xFFE50914);
  final AuthApi _authApi = AuthApi();

  String _userName = 'User';
  String _userEmail = '';
  String _userRole = 'user';
  String _userProfilePicture = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 1. Load cached info first
    final userInfo = await _authApi.getStoredUserInfo();
    if (mounted) {
      setState(() {
        // Use firstName + lastName if available, otherwise fallback to username
        final firstName = userInfo['firstName'] ?? '';
        final lastName = userInfo['lastName'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          _userName = '$firstName $lastName'.trim();
        } else {
          _userName = userInfo['username'] ?? 'Guest';
        }
        _userEmail = userInfo['email'] ?? '';
        _userRole = userInfo['role'] ?? 'user';
        _userProfilePicture = userInfo['profilePicture'] ?? '';
        _isLoading = false;
      });
    }

    // 2. Fetch fresh user profile in background
    try {
      final freshProfile = await _authApi.getUserProfile();
      if (mounted) {
        setState(() {
          final firstName = freshProfile['firstName'] ?? '';
          final lastName = freshProfile['lastName'] ?? '';
          final username = freshProfile['username'] ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            _userName = '$firstName $lastName'.trim();
          } else if (username.isNotEmpty) {
            _userName = username;
          }
          // Don't overwrite a valid name with 'Guest'
          _userEmail = freshProfile['email'] ?? _userEmail;
          _userProfilePicture =
              freshProfile['profilePicture'] ?? _userProfilePicture;
        });
      }
    } catch (e) {
      debugPrint('Error fetching fresh user profile: $e');
    }
  }

  UserRole _getUserRole() {
    switch (_userRole.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'developer':
        return UserRole.developer;
      default:
        return UserRole.user;
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: brandRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: brandRed,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Confirm Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    'Are you sure you want to logout?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // If user confirmed logout
    if (shouldLogout == true) {
      await _authApi.logout();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: brandRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: brandRed,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Delete account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete your account? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (shouldDelete == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AccountDeletionPendingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = _getUserRole();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient soft red radial glow behind avatar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.8,
                    colors: [
                      brandRed.withOpacity(0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding > 0 ? topPadding + 12 : 28,
                bottom: 24,
              ),
              child: Column(
                children: [
                  // Logo
                  const OrientationLogo(),
                  const SizedBox(height: 22),

                  // Circular Avatar with red ring and glow
                  _buildAvatar(),
                  const SizedBox(height: 14),

                  // Name
                  _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                  const SizedBox(height: 6),

                  // Email
                  if (_userEmail.isNotEmpty)
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // First Card Group (Account info + role-specific items)
                  _buildFirstCardGroup(userRole),
                  const SizedBox(height: 16),

                  // Second Card Group (About Us, Privacy, Terms)
                  _buildSecondCardGroup(),
                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(),

                  // Delete Account Text Button
                  _buildDeleteAccountButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E1E22),
        border: Border.all(
          color: brandRed,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: brandRed.withOpacity(0.38),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: _userProfilePicture.isNotEmpty
            ? Image.network(
                _userProfilePicture,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 48,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 48,
                ),
              ),
      ),
    );
  }



  Widget _buildFirstCardGroup(UserRole userRole) {
    final items = <Widget>[];

    // Account Information (all users)
    items.add(
      _buildCardRow(
        icon: Icons.person_outline,
        title: 'Account Information',
        onTap: () async {
          final isAuth = await AuthHelper.requireAuth(context);
          if (!isAuth) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountInfoScreen(),
            ),
          );
          if (result == true) {
            _loadUserData();
            widget.onProfileUpdated?.call();
          }
        },
      ),
    );

    // Join Us (for regular users)
    if (userRole == UserRole.user) {
      items.add(_buildDivider());
      items.add(
        _buildCardRow(
          icon: Icons.rocket_launch_outlined,
          title: 'Join Us',
          onTap: () async {
            final isAuth = await AuthHelper.requireAuth(context);
            if (!isAuth) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const JoinUsScreen(),
              ),
            );
          },
        ),
      );
    }

    // Admin Dashboard
    if (userRole == UserRole.admin) {
      items.add(_buildDivider());
      items.add(
        _buildCardRow(
          icon: Icons.dashboard_outlined,
          title: 'Admin Dashboard',
          onTap: () async {
            final isAuth = await AuthHelper.requireAuth(context);
            if (!isAuth) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
          },
        ),
      );
    }

    // Developer / Admin tools: Add Reel & Change Inventory
    if (userRole == UserRole.developer || userRole == UserRole.admin) {
      items.add(_buildDivider());
      items.add(
        _buildCardRow(
          icon: Icons.movie_creation_outlined,
          title: 'Add Reel',
          onTap: () async {
            final isAuth = await AuthHelper.requireAuth(context);
            if (!isAuth) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddReelScreen(),
              ),
            );
          },
        ),
      );
      items.add(_buildDivider());
      items.add(
        _buildCardRow(
          icon: Icons.inventory_2_outlined,
          title: 'Change Inventory',
          onTap: () async {
            final isAuth = await AuthHelper.requireAuth(context);
            if (!isAuth) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangeInventoryScreen(),
              ),
            );
          },
        ),
      );
    }

    return _buildCardContainer(items);
  }

  Widget _buildSecondCardGroup() {
    return _buildCardContainer([
      _buildCardRow(
        icon: Icons.info_outline,
        title: 'About Us',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AboutUsScreen(),
            ),
          );
        },
      ),
      _buildDivider(),
      _buildCardRow(
        icon: Icons.shield_outlined,
        title: 'Privacy Policy',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacyPolicyScreen(),
            ),
          );
        },
      ),
      _buildDivider(),
      _buildCardRow(
        icon: Icons.article_outlined,
        title: 'Terms and Conditions',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TermsConditionsScreen(),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildCardRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Circular icon container with red tint & subtle red border
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF221113),
                  border: Border.all(
                    color: brandRed.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: brandRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Trailing chevron
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.35),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      endIndent: 16,
      color: Colors.white.withOpacity(0.05),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.logout,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton(
        onPressed: _handleDeleteAccount,
        child: Text(
          'Delete account',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
