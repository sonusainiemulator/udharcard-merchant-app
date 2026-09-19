import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'keys.dart';

Future initHive() async {
  try {
    await Hive.initFlutter();
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    await Hive.openBox(Keys.hiveinit);
  } catch (e) {
    debugPrint("initHive primary error: $e");
    try {
      await Hive.initFlutter();
      await Hive.openBox(Keys.hiveinit);
    } catch (err) {
      debugPrint("initHive fallback error: $err");
      try {
        await Hive.deleteBoxFromDisk(Keys.hiveinit);
        await Hive.openBox(Keys.hiveinit);
      } catch (_) {}
    }
  }
}

