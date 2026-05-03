import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'package:http/http.dart' as http;  
import 'screens/admin/admin_dashboard.dart';
// ─────────────────────────────────────────────────────────────────────────────
// ⚠️  REPLACE THESE with your actual values before running
// ─────────────────────────────────────────────────────────────────────────────
const String supabaseUrl = 'https://monrxrqxdetvfuloeymi.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vbnJ4cnF4ZGV0dmZ1bG9leW1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwMTM5MDksImV4cCI6MjA5MjU4OTkwOX0.E4Iu1XttUlb9KE6q1mhmYVVCNyiladRm3xDjh9tsQUI';
const String ngrokApiUrl = 'https://dharshhhhhh-cyber-api.hf.space';
// ─────────────────────────────────────────────────────────────────────────────
// Admin credentials — hardcoded
const String geminiApiKey    = 'AIzaSyCsREai4l9qAMeAwz7G5BnTX7U5jPwUaRY';   // ← from aistudio.google.com (free)
// ─────────────────────────────────────────────────────────────────────────────
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  _wakeUpApi();
  runApp(const MyApp());
}
 
// Wake up HuggingFace space on app start
Future<void> _wakeUpApi() async {
  try {
    await http.get(Uri.parse('$ngrokApiUrl/health'))
        .timeout(const Duration(seconds: 60));
    print('✅ API is awake');
  } catch (_) {}
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeChat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F8EF7)),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminDashboard(),
      },
    );
  }
}
 