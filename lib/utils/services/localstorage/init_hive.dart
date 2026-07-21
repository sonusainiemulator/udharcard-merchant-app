import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'keys.dart';

Future initHive() async {
  await Hive.initFlutter();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  await Hive.openBox(Keys.hiveinit);
}
