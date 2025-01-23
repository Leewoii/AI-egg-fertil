import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter your email and password.');
      return;
    }

    try {
      // Authenticate user with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        if (!user.emailVerified) {
          // Email is not verified
          _showVerificationDialog(user);
          return;
        }

        // Save email in SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);

        // Notify success
        _showInfoDialog('Login successful.');

        // Navigate to dashboard
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'email': email},
        );
      } else {
        _showErrorDialog('Invalid email or password.');
      }
    } catch (e) {
      _showErrorDialog('Error logging in: $e');
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog('Please enter your email to reset the password.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showInfoDialog(
          'Password reset email sent! Please check your inbox.');
    } catch (e) {
      _showErrorDialog('Error sending password reset email: $e');
    }
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Not Verified'),
        content: const Text(
            'Your email is not verified. Please check your inbox and verify your account.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Resend Email'),
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                Navigator.of(context).pop(); // Close dialog
                _showInfoDialog('Verification email has been resent.');
              } catch (e) {
                _showErrorDialog('Error resending email: $e');
              }
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Adjust layout when keyboard is shown
      body: SingleChildScrollView( // Allow scrolling to avoid overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 70.0,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Email',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _resetPassword, // Call reset password function
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
