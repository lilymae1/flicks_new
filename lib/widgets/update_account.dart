import 'package:flicks_new/Theme/colours.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/DatabaseServices.dart'; 
import '../Theme/themeData.dart';

class UpdateDetailsPage extends StatefulWidget {
  @override
  _UpdateDetailsPageState createState() => _UpdateDetailsPageState();
}

class _UpdateDetailsPageState extends State<UpdateDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userID'); // Ensure you stored 'userID' at login

    if (userId != null) {
      _userId = userId;
      final userMap = await DatabaseServices.retrieveSingleRecord(userId);
      if (userMap != null) {
        setState(() {
          _nameController.text = userMap['userName'] ?? '';
          _emailController.text = userMap['email'] ?? '';
          _mobileController.text = userMap['mobileNo'].toString();
          _passwordController.text = userMap['password'] ?? '';
        });
      }
    }
  }

  Future<void> _updateUserDetails() async {
    if (_formKey.currentState!.validate() && _userId != null) {
      final updatedData = {
        'userName': _nameController.text,
        'email': _emailController.text,
        'mobileNo': int.tryParse(_mobileController.text) ?? 0,
        'password': _passwordController.text,
      };

      await DatabaseServices.updateStudentRecord(_userId!, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details updated successfully')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Update Your Details',
        style: FlicksTheme.pageHeader(),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                ),
                SizedBox(height: 60),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (val) => val!.isEmpty ? 'Enter your email' : null,
                ),
                SizedBox(height: 60),
                TextFormField(
                  controller: _mobileController,
                  decoration: InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter your mobile number' : null,
                ),
                SizedBox(height: 60),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (val) => val!.isEmpty ? 'Enter your password' : null,
                ),
                SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _updateUserDetails,
                  child: Row(
                  mainAxisSize: MainAxisSize.min, // Keep the button tight around content
                  children: const [
                  Icon(Icons.edit,color: FlicksColours.Yellow, size: 20), // You can use Icons.edit or Icons.refresh as alternatives
                  SizedBox(width: 8), // Spacing between icon and text
                  Text('Update'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

}
