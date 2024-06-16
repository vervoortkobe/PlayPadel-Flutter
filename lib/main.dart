import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intro_mobile_project/registerpage.dart';
import 'homepage.dart';
import 'loginpage.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayPadel App',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (context) => LoginPage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => Registerpage(),
        '/home': (context) => const HomePageController(),
        '/logout': (context) => LoginPage(),
      },
    );
  }
}
