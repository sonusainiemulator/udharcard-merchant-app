import 'package:flutter/material.dart';

extension MediaqueryCustomExtension on BuildContext {
  Size get mQuery {
    return MediaQuery.sizeOf(this);
  }
}
