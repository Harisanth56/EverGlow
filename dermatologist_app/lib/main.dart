import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/navigator.dart';
import 'package:dermatologist_app/register.dart';
import 'package:dermatologist_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qvkmfkjfjagwhyuxxdcg.supabase.co',
    anonKey: 'sb_publishable_30oXT7RaDE6irskGVyeLfA_NapYI7v5',
  );

  // Set system UI colors globally
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      ));

  runApp(MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // While waiting for Supabase to initialize/load session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;

          // If session exists, user is logged in
          if (session != null) {
            return MainScreen();
          }

          // No session found, show Login/Welcome
          return const Welcome();
        },
      ),
    );
  }
}
