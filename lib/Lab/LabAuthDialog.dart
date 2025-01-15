import 'package:doctordesktop/Lab/LabScreen.dart';
import 'package:flutter/material.dart';

class LabAuthDialog extends StatefulWidget {
  @override
  _LabAuthDialogState createState() => _LabAuthDialogState();
}

class _LabAuthDialogState extends State<LabAuthDialog> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String correctUserId = "lab";
  final String correctPassword = "lab123";

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _authenticate(BuildContext context) {
    String userId = _userIdController.text;
    String password = _passwordController.text;

    if (userId == correctUserId && password == correctPassword) {
      Navigator.pop(context); // Close the dialog box
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LabPatientsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid User ID or Password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Lab Login'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _userIdController,
            decoration: InputDecoration(labelText: 'User ID'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _authenticate(context);
          },
          child: Text('Login'),
        ),
      ],
    );
  }
}
