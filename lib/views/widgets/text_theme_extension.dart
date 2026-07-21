import 'package:flutter/material.dart';

extension CustomThemeContext on BuildContext {
  TextTheme get t {
    return Theme.of(this).textTheme;
  }
}
