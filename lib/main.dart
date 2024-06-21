import 'package:flutter/material.dart';
import 'package:entreganet/pages/inicio.dart';
import 'package:entreganet/pages/home.dart';
import 'package:entreganet/pages/mensajes.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: '/inicio',
      routes: {
        "/inicio": (context) => const Inicio(),
        "/home": (context) => const MyHomePage(),
        "/mensajes": (context) => const Mensajes(),
      },
    );
  }
}
