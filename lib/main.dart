
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/settings/enviroment.dart';
import 'package:restaurapp/framework/preferences_service.dart';

import 'app.dart';
String enviromentSelect = Enviroment.testing.value;

void main() async{ 
  WidgetsFlutterBinding.ensureInitialized();
 
  print('=========ENVIROMENT SELECTED: $enviromentSelect');                                         
  await dotenv.load(fileName: enviromentSelect);
  await PreferencesUser().initiPrefs();

  runApp(const App());
}
