// screens/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/join_panel.dart';
import 'screens/quiz_control_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tendria que estar en un env para mas seguridad
  await Supabase.initialize(
    url: 'https://vjimqdckjabewzprhpzd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqaW1xZGNramFiZXd6cHJocHpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3Njg5NTMsImV4cCI6MjA1NDM0NDk1M30.tf_3Yc0_y_tMrSHckyn74sB2lntQVrwvgHiGSXln7uo',
  );

  runApp(const KahootApp());
}

class KahootApp extends StatelessWidget {
  const KahootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kahoot with Supabase',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const KahootHome(),
    );
  }
}

class KahootHome extends StatelessWidget {
  const KahootHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kahoot with Supabase'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Kahoot!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HostScreen()),
                );
              },
              child: const Text('Host Quiz'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JoinScreen()),
                );
              },
              child: const Text('Join Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
