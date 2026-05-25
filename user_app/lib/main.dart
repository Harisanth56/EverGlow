import 'package:flutter/material.dart';
import 'package:user_app/navigator.dart';
import 'package:user_app/welcome.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,         // Makes status bar blend completely
    statusBarIconBrightness: Brightness.light,  // White icons for dark themes (Wi-Fi, Battery, etc.)
    statusBarBrightness: Brightness.dark,      // Required for iOS white status bar icons
  ));

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use a StreamBuilder to listen to Auth State Changes
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
            return const IndexPage();
          }

          // No session found, show Login/Welcome
          return const Welcome();
        },
      ),
    );
  }
}
