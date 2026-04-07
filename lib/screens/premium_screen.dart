import 'package:flutter/material.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:finflow/services/iap_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  PremiumScreenState createState() => PremiumScreenState();
}

class PremiumScreenState extends State<PremiumScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isIAPInitializing = false;
  String? _errorMessage;
  ProductDetails? _selectedProduct;

  final IAPService _iapService = IAPService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeIAP();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check premium status when app resumes
    if (state == AppLifecycleState.resumed) {
      _checkPremiumStatus();
    }
  }

  Future<void> _initializeIAP() async {
    setState(() {
      _isIAPInitializing = true;
    });

    try {
      // Initialize IAP service
      final bool isAvailable = await _iapService.initialize();

      if (isAvailable) {
        // Fetch products
        await _iapService.fetchProducts();

        // Select the monthly product by default
        final monthlyProduct = _iapService.getProductById(
          IAPService.premiumMonthlyProductId,
        );
        if (monthlyProduct != null) {
          setState(() {
            _selectedProduct = monthlyProduct;
          });
        }
      } else {
        setState(() {
          _errorMessage = _iapService.connectionError ?? 'IAP not available';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize purchases: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isIAPInitializing = false;
      });
    }
  }

  Future<void> _checkPremiumStatus() async {
    // Refresh user data from Firestore
    await Provider.of<UserProvider>(context, listen: false).refreshUser();
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _iapService.purchaseProduct(product);

      if (!success && mounted) {
        setState(() {
          _errorMessage = _iapService.statusMessage ?? 'Purchase failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Purchase error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _iapService.restorePurchases();

      if (success && mounted) {
        // Wait a bit for the restore to complete and check status
        await Future.delayed(const Duration(seconds: 2));
        await _checkPremiumStatus();
      } else if (mounted) {
        setState(() {
          _errorMessage = _iapService.statusMessage ?? 'Restore failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Restore error: ${e.toString()}';
        });
      }
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
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    // Check if user is already premium
    final bool isPremium = currentUser?.isPremium == true;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B45),
        title: Text(
          isPremium ? 'Premium Status' : 'Upgrade to Premium',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.premiumGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'You are Premium!' : 'Go Premium',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isPremium
                              ? 'Enjoy all premium features!'
                              : 'Unlock all features and take control of your finances',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current Status
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPremium
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isPremium ? Icons.check_circle : Icons.lock,
                        color: isPremium ? Colors.white : Colors.black87,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium
                                ? 'You are a Premium User'
                                : 'Current Plan: Free',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          Text(
                            isPremium
                                ? 'Enjoy all premium features!'
                                : 'Upgrade to unlock premium features',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDarkMode
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // IAP initializing indicator
            if (_isIAPInitializing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Premium Features (only show when not premium and IAP is ready)
            if (!_isIAPInitializing && !isPremium) ...[
              // Product Selection
              Text(
                'CHOOSE YOUR PLAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Monthly plan card
              _buildProductCard(
                product: _iapService.products.firstWhere(
                  (p) => p.id == IAPService.premiumMonthlyProductId,
                  orElse: () => ProductDetails(
                    id: IAPService.premiumMonthlyProductId,
                    title: 'Premium Monthly',
                    description: 'Monthly subscription',
                    price: '\$4.99',
                    rawPrice: 4.99,
                    currencyCode: 'USD',
                    currencySymbol: '\$',
                  ),
                ),
                isSelected:
                    _selectedProduct?.id == IAPService.premiumMonthlyProductId,
                onTap: () {
                  setState(() {
                    _selectedProduct = _iapService.getProductById(
                      IAPService.premiumMonthlyProductId,
                    );
                  });
                },
                isDarkMode: isDarkMode,
              ),

              // Yearly plan card (if available)
              if (_iapService.products.any(
                (p) => p.id == IAPService.premiumYearlyProductId,
              ))
                _buildProductCard(
                  product: _iapService.products.firstWhere(
                    (p) => p.id == IAPService.premiumYearlyProductId,
                  ),
                  isSelected:
                      _selectedProduct?.id == IAPService.premiumYearlyProductId,
                  onTap: () {
                    setState(() {
                      _selectedProduct = _iapService.getProductById(
                        IAPService.premiumYearlyProductId,
                      );
                    });
                  },
                  isDarkMode: isDarkMode,
                  badge: 'BEST VALUE',
                ),

              const SizedBox(height: 24),

              // Premium Features List
              Text(
                'PREMIUM FEATURES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureCard(
                icon: Icons.sms,
                title: 'Smart SMS Scan',
                description:
                    'Automatically detect and import bank transaction SMS',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Advanced Analytics',
                description: 'Detailed spending insights and trend analysis',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.backup,
                title: 'Cloud Backup',
                description: 'Automatic backup and sync across devices',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.notifications,
                title: 'Smart Notifications',
                description: 'Personalized financial alerts and reminders',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.category,
                title: 'Unlimited Categories',
                description: 'Create unlimited custom categories and tags',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.security,
                title: 'Enhanced Security',
                description: 'Biometric authentication and data encryption',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 32),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                  onPressed: _isLoading || _selectedProduct == null
                      ? null
                      : () => _purchaseProduct(_selectedProduct!),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'Subscribe - ${_selectedProduct?.price ?? 'Loading...'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Restore Purchases Button
              TextButton.icon(
                onPressed: _isLoading ? null : _restorePurchases,
                icon: const Icon(Icons.restore, size: 18),
                label: Text(
                  'Restore Purchases',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDarkMode
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Benefits Summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What You Get:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow(
                        '✓',
                        'All premium features unlocked',
                        isDarkMode,
                      ),
                      _buildBenefitRow('✓', 'Cancel anytime', isDarkMode),
                      _buildBenefitRow('✓', 'Priority support', isDarkMode),
                      _buildBenefitRow('✓', 'Regular updates', isDarkMode),
                    ],
                  ),
                ),
              ),
            ],

            // Show when already premium
            if (isPremium) ...[
              const SizedBox(height: 24),
              _buildFeatureCard(
                icon: Icons.sms,
                title: 'Smart SMS Scan',
                description:
                    'Automatically detect and import bank transaction SMS',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Advanced Analytics',
                description: 'Detailed spending insights and trend analysis',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.backup,
                title: 'Cloud Backup',
                description: 'Automatic backup and sync across devices',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.notifications,
                title: 'Smart Notifications',
                description: 'Personalized financial alerts and reminders',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.category,
                title: 'Unlimited Categories',
                description: 'Create unlimited custom categories and tags',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
              _buildFeatureCard(
                icon: Icons.security,
                title: 'Enhanced Security',
                description: 'Biometric authentication and data encryption',
                isPremium: true,
                isDarkMode: isDarkMode,
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required ProductDetails product,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF1A3A4A) : const Color(0xFFFFF8E1))
              : (isDarkMode ? const Color(0xFF1A2A3A) : Colors.white),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDarkMode
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              product.price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFFD700) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isPremium,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPremium
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isPremium ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDarkMode
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isPremium)
              Icon(
                Icons.check_circle,
                color: const Color(0xFFFFD700),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String icon, String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
