import 'package:flutter/material.dart';
import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';

void showBarqSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final fontFamily =
      Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
  final bg = isError
      ? AppColors.error
      : isSuccess
          ? AppColors.success
          : null;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(
        message,
        style: TextStyle(fontFamily: fontFamily, fontSize: 14),
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: duration,
    ));
}
