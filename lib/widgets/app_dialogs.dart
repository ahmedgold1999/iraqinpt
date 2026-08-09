import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class AppDialogs {
  /// حوار تنبيه أو تأكيد بنمط iOS الفاخر
  static Future<T?> showConfirmDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'نعم، استمر',
    String cancelText = 'إلغاء',
    bool isDanger = false,
    VoidCallback? onConfirm,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDanger ? AppColors.errorLight : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    size: 28,
                    color: isDanger ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: cancelText,
                        variant: AppButtonVariant.outlined,
                        height: 44,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: confirmText,
                        variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
                        height: 44,
                        onPressed: () {
                          Navigator.of(ctx).pop(true);
                          if (onConfirm != null) onConfirm();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// نافذة منبثقة سفلية (iOS Bottom Sheet)
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // iOS Grabber indicator
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        );
      },
    );
  }
}
