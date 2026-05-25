import 'package:admin_app/homepage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://qvkmfkjfjagwhyuxxdcg.supabase.co',
    anonKey: 'sb_publishable_30oXT7RaDE6irskGVyeLfA_NapYI7v5',
  );
  runApp(MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen()
    );
  }
}
