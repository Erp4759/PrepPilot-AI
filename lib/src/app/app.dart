import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PrepPilotApp extends StatelessWidget {
  const PrepPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrepPilot AI',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('PrepPilot AI'))),
    );
  }
}
