import 'package:flutter/material.dart';
import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/barq_logo.png', width: 28, height: 28),
            const SizedBox(width: AppDimens.sm),
            const Text('Barq Driver'),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: 72,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: AppDimens.xl),
            Text(
              'Ready to deliver',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Text(
              'Your dashboard is coming soon.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
