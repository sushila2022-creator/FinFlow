import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../utils/app_theme.dart';

/// Reusable Card Widget with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.shadow,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
        borderRadius: borderRadius ?? BorderRadiusRadius.lg,
        boxShadow: shadow ?? DesignSystem.shadowSm,
        border: border,
        gradient: gradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadiusRadius.lg,
          splashColor: AppTheme.accentColor.withValues(alpha: 0.1),
          highlightColor: AppTheme.accentColor.withValues(alpha: 0.05),
          child: Padding(
            padding: padding ?? EdgeInsetsSpacing.allMd,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Reusable Gap Widget for consistent spacing
class Gap extends StatelessWidget {
  final double size;

  const Gap(this.size, {super.key});

  static Gap get xs => const Gap(DesignSystem.spacingXs);
  static Gap get sm => const Gap(DesignSystem.spacingSm);
  static Gap get md => const Gap(DesignSystem.spacingMd);
  static Gap get lg => const Gap(DesignSystem.spacingLg);
  static Gap get xl => const Gap(DesignSystem.spacingXl);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size);
  }
}

/// Reusable Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: DesignSystem.titleMedium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionText!,
              style: DesignSystem.labelLarge.copyWith(
                color: AppTheme.accentColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Reusable Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? actionButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsetsSpacing.allXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            Gap.lg,
            Text(
              title,
              style: DesignSystem.titleMedium.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            Gap.sm,
            Text(
              description,
              style: DesignSystem.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[Gap.lg, actionButton!],
          ],
        ),
      ),
    );
  }
}

/// Reusable Loading Indicator
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.accentColor,
        ),
      ),
    );
  }
}

/// Responsive Layout Builder Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(
          context,
          DesignSystem.isMobile(context),
          DesignSystem.isTablet(context),
          DesignSystem.isDesktop(context),
        );
      },
    );
  }
}
