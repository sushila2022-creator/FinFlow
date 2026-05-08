import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/screens/premium_screen.dart';
import 'package:finflow/utils/freemium_config.dart';

class UpgradePromptWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool showBorder;

  const UpgradePromptWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.showBorder = true,
  });

  factory UpgradePromptWidget.smsLimit({
    int remaining = 0,
    int total = FreemiumConfig.maxFreeSmsTransactions,
  }) {
    return UpgradePromptWidget(
      icon: Icons.sms_failed,
      title: 'SMS Scan Limit Reached',
      description:
          'You\'ve used $remaining of $total free scans. Upgrade to Premium for unlimited scanning.',
    );
  }

  factory UpgradePromptWidget.featureLocked({required String featureName}) {
    return UpgradePromptWidget(
      icon: Icons.lock_outline,
      title: '$featureName is Premium Only',
      description:
          'Upgrade to Premium to unlock $featureName and all other advanced features.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.premiumGradient,
          borderRadius: BorderRadius.circular(16),
          border: showBorder
              ? Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UsageCounterWidget extends StatelessWidget {
  final int current;
  final int max;
  final String label;

  const UsageCounterWidget({
    super.key,
    required this.current,
    required this.max,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / max).clamp(0.0, 1.0);
    final isNearLimit = percentage > 0.7;
    final isAtLimit = percentage >= 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAtLimit
            ? Colors.red.withValues(alpha: 0.1)
            : isNearLimit
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAtLimit
              ? Colors.red.withValues(alpha: 0.3)
              : isNearLimit
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$current / $max',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isAtLimit
                      ? Colors.red
                      : isNearLimit
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isAtLimit
                  ? Colors.red
                  : isNearLimit
                  ? Colors.orange
                  : Theme.of(context).primaryColor,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
