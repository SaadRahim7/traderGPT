import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers and variables
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  void _signUp() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      setState(() {
        errorMessage = 'Passwords do not match.';
        isLoading = false;
      });
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signUp(emailController.text.trim(), passwordController.text.trim());
      // Navigate to Dashboard
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to sign up. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Implement UI similar to your web signup page
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo and App Name
                Image.asset('assets/logo.png', height: 150),
                SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
                if (errorMessage.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(errorMessage, style: TextStyle(color: Colors.red)),
                ],
                SizedBox(height: 16),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        child: Text('Sign Up'),
                      ),
                TextButton(
                  onPressed: () {
                    // Navigate back to Login Screen
                    Navigator.pop(context);
                  },
                  child: Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
