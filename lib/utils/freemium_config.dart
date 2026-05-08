import 'package:flutter/material.dart';

/// Freemium Configuration & Feature Gates
class FreemiumConfig {
  // FREE FOR ALL USERS - ALL FEATURES ENABLED
  static const int maxFreeSmsTransactions = 999999;
  static const bool freeUsersCanExportCsv = true;
  static const bool freeUsersGetAiInsights = true;
  static const bool freeUsersGetAdvancedReports = true;
  static const bool freeUsersHaveSecureBackup = true;
  static const bool freeUsersSeeAds = false;

  // Premium features
  static const List<FeatureItem> premiumFeatures = [
    FeatureItem(
      icon: Icons.sms,
      title: 'Unlimited SMS Scanning',
      description: 'Scan unlimited bank transactions automatically',
    ),
    FeatureItem(
      icon: Icons.psychology,
      title: 'AI Powered Insights',
      description: 'Smart spending analysis and personalized recommendations',
    ),
    FeatureItem(
      icon: Icons.bar_chart,
      title: 'Advanced Reports',
      description: 'Detailed monthly/yearly financial reports with trends',
    ),
    FeatureItem(
      icon: Icons.cloud_done,
      title: 'Secure Cloud Backup',
      description: 'Automatic encrypted backup of all your financial data',
    ),
    FeatureItem(
      icon: Icons.block,
      title: '100% Ad Free',
      description: 'No banner ads, no interstitial ads - clean experience',
    ),
    FeatureItem(
      icon: Icons.priority_high,
      title: 'Priority Support',
      description: 'Get faster responses and dedicated assistance',
    ),
  ];

  // Pricing
  static const String monthlyPrice = '₹99/month';
  static const String yearlyPrice = '₹799/year';
  static const String yearlySaving = 'Save 33%';
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
