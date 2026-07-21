import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'helpers.dart';

class PopApp {
  static DateTime? currentBackPressTime;

  static  onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Helpers.showToast(
        msg: "Press again to exit",
        bgColor: Colors.white,
        textColor: Colors.black,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
       SystemNavigator.pop();
    }
  }
}
