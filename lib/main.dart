import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'login.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  windowManager.setMaximizable(false);
  windowManager.setResizable(false);

  runApp(MyApp());
}

