import 'package:hive/hive.dart';
import 'keys.dart';

class HiveHelp {
  static var box = Hive.box(Keys.hiveinit);
  static dynamic read(String key) {
    return box.get(key);
  }

  static void write(String key, dynamic value) {
    box.put(key, value);
  }

  static Future<void> remove(String key) async {
    box.delete(key);
  }

  static void cleanall() {
    box.clear();
  }
}
