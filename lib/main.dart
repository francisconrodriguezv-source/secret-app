import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase antes de que arranque cualquier feature de la app.
  // En Android usa `android/app/google-services.json` (agregado al build por
  // el plugin `com.google.gms.google-services`). Si algún día se agrega iOS
  // o Web, habrá que pasar `options: DefaultFirebaseOptions.currentPlatform`.
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const CozyLoveApp());
}
