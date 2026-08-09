import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final dynamic icon;
  final double? width;
  final double height;
  final bool isPill;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50.0,
    this.isPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Color getBackgroundColor() {
      if (isDisabled) return AppColors.disabled;
      switch (variant) {
        case AppButtonVariant.primary:
          return AppColors.primary;
        case AppButtonVariant.secondary:
          return AppColors.primaryLight;
        case AppButtonVariant.outlined:
        case AppButtonVariant.text:
          return Colors.transparent;
        case AppButtonVariant.danger:
          return AppColors.error;
      }
    }

    Color getTextColor() {
      if (isDisabled) return AppColors.disabledText;
      switch (variant) {
        case AppButtonVariant.primary:
        case AppButtonVariant.danger:
          return Colors.white;
        case AppButtonVariant.secondary:
        case AppButtonVariant.outlined:
        case AppButtonVariant.text:
          return AppColors.primary;
      }
    }

    BorderSide? getBorderSide() {
      if (variant == AppButtonVariant.outlined) {
        return BorderSide(
          color: isDisabled ? AppColors.disabled : AppColors.primary,
          width: 1.5,
        );
      }
      return BorderSide.none;
    }

    final borderRadius = isPill ? AppRadius.borderFull : AppRadius.borderLg;

    Widget renderIcon() {
      if (icon is IconData) {
        return Icon(icon as IconData, color: getTextColor(), size: 20);
      } else if (icon is FaIconData) {
        return FaIcon(icon as FaIconData, color: getTextColor(), size: 20);
      } else if (icon is Widget) {
        return icon as Widget;
      }
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: getBackgroundColor(),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(getBorderSide() ?? BorderSide.none),
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  renderIcon(),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: getTextColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
