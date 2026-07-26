import 'package:hive/hive.dart';
import 'keys.dart';

class HiveHelp {
  static dynamic read(String key) {
    try {
      if (!Hive.isBoxOpen(Keys.hiveinit)) return null;
      return Hive.box(Keys.hiveinit).get(key);
    } catch (_) {
      return null;
    }
  }

  static void write(String key, dynamic value) {
    try {
      if (!Hive.isBoxOpen(Keys.hiveinit)) return;
      Hive.box(Keys.hiveinit).put(key, value);
    } catch (_) {}
  }

  static Future<void> remove(String key) async {
    try {
      if (!Hive.isBoxOpen(Keys.hiveinit)) return;
      await Hive.box(Keys.hiveinit).delete(key);
    } catch (_) {}
  }

  static void cleanall() {
    try {
      if (!Hive.isBoxOpen(Keys.hiveinit)) return;
      Hive.box(Keys.hiveinit).clear();
    } catch (_) {}
  }
}
