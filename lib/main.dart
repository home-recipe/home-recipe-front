import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/main_navigation.dart';
import 'screens/my_page.dart';
import 'screens/recipe_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '냉장고 프로젝트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
