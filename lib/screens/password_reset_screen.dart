import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password (optional)',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() => _errorMessage = null);
                final prefs = await SharedPreferences.getInstance();
                final username = _usernameController.text.trim();

                if (username.isEmpty) {
                  setState(() => _errorMessage = 'Username cannot be empty');
                  return;
                }

                if (prefs.containsKey(username)) {
                  // Simulate password reset
                  final newPassword = _newPasswordController.text.isNotEmpty
                      ? _newPasswordController.text
                      : 'TempPass${DateTime.now().millisecondsSinceEpoch}'; // Unique temp password
                  await prefs.setString(username, newPassword);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset successful!')),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login', // Adjust to your login route name
                    (route) => false,
                  );
                } else {
                  setState(() {
                    _errorMessage = 'Username not found';
                  });
                }
              },
              child: const Text('Reset Password'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
