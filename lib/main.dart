import 'package:call_break_points/views/game_screen.dart';
import 'package:call_break_points/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'theme/app_themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Call Break Points',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomePage()),
        GetPage(name: '/game-detail', page: () => GameScreen()),
      ],
      home: HomePage(),
    );
  }
}
