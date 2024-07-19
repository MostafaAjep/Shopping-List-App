import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/grocery_list_page.dart';
import 'package:shopping_app/theme/theming.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Groceries',
      theme: theme,
      home: const GroceryListPage(),
    );
  }
}
