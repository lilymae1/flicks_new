import 'package:flicks_new/Theme/colours.dart';

import 'home_screen.dart';
import 'package:flicks_new/main.dart';
import 'package:flutter/material.dart';
import '../services/DatabaseServices.dart'; // Make sure this import path is correct
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // To work with file paths
import 'package:permission_handler/permission_handler.dart'; // For permissions
import '../Theme/themeData.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _accountScreenState();
}

class _accountScreenState extends State<CreateAccount> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _profilePicturePath; // Variable to hold the profile picture path

  // Request permissions for camera and gallery
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  // Pick Image function
  Future<void> _pickImage(ImageSource source) async {
    try {
      await _requestPermissions(); // Request necessary permissions

      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,       // Resize image to reduce memory usage
        maxHeight: 600,
        imageQuality: 75,    // Compress quality (0-100, where 100 is original)
      );

      if (image != null && await File(image.path).exists()) {
        final compressedPath = image.path;

        // Update the profile picture path after picking the image
        setState(() {
          _profilePicturePath = compressedPath;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image not selected or unavailable.')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _saveUser() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String mobileText = _mobileController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || mobileText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    int? mobileNo = int.tryParse(mobileText);
    if (mobileNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid mobile number.")),
      );
      return;
    }

    try {
      int newUserId = await DatabaseServices.addUserDetails(name, email, mobileNo, password);

      // Save the profile picture path to the database
      if (_profilePicturePath != null) {
        await DatabaseServices.addOrUpdateProfilePicture(newUserId, _profilePicturePath!);
      }

      // Save login info to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', name);
      await prefs.setInt('userID', newUserId);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(navigatorKey: navigatorKey),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving user: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Picture Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: ClipOval(
                    child: _profilePicturePath != null
                        ? Image.file(
                            File(_profilePicturePath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/default_profile.png', // Default fallback
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Show bottom sheet to choose between camera and gallery
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.camera),
                            title: Text("Take a photo"),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.image),
                            title: Text("Choose from gallery"),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Change Profile Picture'),
              ),

              // Name Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Enter user name",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Email Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Enter Email",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Mobile Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  child: TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter Mobile number",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Password Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Enter a password",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _saveUser,
                  icon: Icon(Icons.save, color: FlicksColours.Yellow, size: 20),
                  label: Text("Save User Details"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
