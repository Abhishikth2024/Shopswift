import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'admin/admin_panel_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();
  bool isLoading = false;

  void login() async {
    setState(() => isLoading = true);
    try {
      final user = await auth.signInWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = userDoc.data();
        final isBanned = (data?['banned'] ?? false) == true;

        if (isBanned) {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your account has been banned."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
          return;
        }

        final isAdmin = data?['isAdmin'] == true;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                isAdmin ? const AdminPanelScreen() : const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => isLoading = false);
  }

  void googleLogin() async {
    final user = await auth.signInWithGoogle();
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      final isBanned = (data?['banned'] ?? false) == true;

      if (isBanned) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your account has been banned."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final isAdmin = data?['isAdmin'] == true;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isAdmin
              ? const AdminPanelScreen()
              : const HomeScreen(isGoogleSignIn: true),
        ),
      );
    }
  }

  void guestLogin() async {
    final user = await auth.signInAnonymously();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(isGoogleSignIn: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 120),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF500),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isLoading ? 'Logging in...' : 'Sign In'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: const Text('Create an account'),
                ),
                const Divider(height: 30),
                ElevatedButton.icon(
                  onPressed: googleLogin,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD80000),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: guestLogin,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continue as Guest'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
