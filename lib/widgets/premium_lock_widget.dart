import 'package:flutter/material.dart';

class PremiumLockWidget extends StatelessWidget {
  final Widget child;
  final String featureName;
  final bool enabled;
  final VoidCallback? onUnlockedTap;

  const PremiumLockWidget({
    super.key,
    required this.child,
    required this.featureName,
    this.enabled = true,
    this.onUnlockedTap,
  });

  @override
  Widget build(BuildContext context) {
    // ALL FEATURES UNLOCKED FOR EVERYONE
    if (onUnlockedTap != null) {
      return InkWell(onTap: onUnlockedTap, child: child);
    }
    return child;
  }
}
