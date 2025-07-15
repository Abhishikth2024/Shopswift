import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'my_listing_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGoogleSignIn;
  const ProfileScreen({super.key, required this.isGoogleSignIn});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  final FirebaseService firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await firebaseService.getUserData(user!.uid);
      final data = doc.data();
      if (data != null) {
        firstNameController.text = data['firstName'] ?? '';
        lastNameController.text = data['lastName'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = user!.email ?? '';
      }
    }
  }

  Future<void> _saveChanges() async {
    if (user == null) return;

    try {
      final updates = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
      };

      await firebaseService.updateUserData(user!.uid, updates);

      if (!widget.isGoogleSignIn &&
          emailController.text.trim() != user!.email) {
        await user!.verifyBeforeUpdateEmail(emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verify your new email before it updates.")),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleChangePassword();
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleChangePassword() async {
    if (user == null || user!.email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No authenticated user.')));
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPasswordController.text.trim(),
      );

      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'wrong-password' => 'Current password is incorrect.',
        'weak-password' => 'New password is too weak.',
        'requires-recent-login' => 'Please re-login and try again.',
        _ => 'Password change failed: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    }

    currentPasswordController.clear();
    newPasswordController.clear();
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: 'Enter your $label',
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildEditableField("First Name", firstNameController),
          const SizedBox(height: 16),
          _buildEditableField("Last Name", lastNameController),
          const SizedBox(height: 16),
          _buildEditableField(
            "Phone Number",
            phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            "Email",
            emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !widget.isGoogleSignIn,
          ),
          const SizedBox(height: 24),
          if (!widget.isGoogleSignIn) ...[
            ElevatedButton(
              onPressed: () => _showChangePasswordDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Change Password'),
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListingsTab() {
    return const MyListingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Your Profile'),
          backgroundColor: const Color.fromARGB(255, 211, 211, 211),
          foregroundColor: Colors.black,
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.list), text: 'My Listings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildProfileTab(context), _buildMyListingsTab()],
        ),
      ),
    );
  }
}
