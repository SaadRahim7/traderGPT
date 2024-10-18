import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  void _login() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signIn(emailController.text.trim(), passwordController.text.trim());
      // Navigate to Dashboard
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to sign in. Please check your credentials.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Implement UI similar to your web login page
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                if (errorMessage.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(errorMessage, style: TextStyle(color: Colors.red)),
                ],
                SizedBox(height: 16),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: Text('Login'),
                      ),
                TextButton(
                  onPressed: () {
                    // Navigate to Sign Up Screen
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                  },
                  child: Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
