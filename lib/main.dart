import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/app.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(HiveBoxes.users);
  runApp(const App());
}
