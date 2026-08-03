import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/bottom_nav_controller.dart';
import '../../routes/routes_name.dart';
import '../../themes/themes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final String? title;
  final double? toolberHeight;
  final double? prefferSized;
  final Color? bgColor;
  final bool? isReverseIconBgColor;
  final bool? isTitleMarginTop;
  final double? fontSize;
  final Widget? titleWidget;
  final void Function()? onBackPressed;
  const CustomAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.titleWidget,
    this.toolberHeight,
    this.prefferSized,
    this.isReverseIconBgColor = false,
    this.isTitleMarginTop = false,
    this.bgColor,
    this.onBackPressed,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: toolberHeight ?? 62.h,
      backgroundColor: bgColor,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      title:
          titleWidget ??
          Padding(
            padding: EdgeInsets.zero,
            child: Text(
              title ?? "",
              style: t.bodyLarge?.copyWith(
                fontSize: fontSize ?? 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      leading:
          leading ??
          IconButton(
            onPressed:
                onBackPressed ??
                () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else if (Get.key.currentState?.canPop() ?? false) {
                    Get.back();
                  } else {
                    try {
                      if (Get.isRegistered<BottomNavController>()) {
                        final bottomNav = Get.find<BottomNavController>();
                        if (bottomNav.selectedIndex != 0) {
                          bottomNav.changeScreen(0);
                          return;
                        }
                      }
                    } catch (_) {}
                    try {
                      Get.offAllNamed(RoutesName.bottomNavBar);
                    } catch (_) {
                      Get.back();
                    }
                  }
                },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: AppThemes.getIconBlackColor(),
            ),
          ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(prefferSized ?? 62.h);
}
