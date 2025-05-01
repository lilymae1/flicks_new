import 'package:flicks_new/Theme/colours.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import '../services/DatabaseServices.dart';
import '../Theme/themeData.dart';
import 'dart:io'; // To work with file paths
import 'package:permission_handler/permission_handler.dart';

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
  String? _profilePicturePath; // Variable to hold the profile picture path

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userID'); // Ensure you stored 'userID' at login

    if (userId != null) {
      _userId = userId;
      final userMap = await DatabaseServices.retrieveSingleRecord(userId);
      if (userMap != null) {
        final profilePath = await DatabaseServices.getProfilePicturePath(userId);

        setState(() {
          _nameController.text = userMap['userName'] ?? '';
          _emailController.text = userMap['email'] ?? '';
          _mobileController.text = userMap['mobileNo'].toString();
          _passwordController.text = userMap['password'] ?? '';
          _profilePicturePath = profilePath;
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
        'profilePicture': _profilePicturePath ?? '', // Update the profile picture path
      };

      await DatabaseServices.updateStudentRecord(_userId!, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details updated successfully')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      await _requestPermissions(); // Ask for necessary permissions

      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,       // Resize image to reduce memory usage
        maxHeight: 600,
        imageQuality: 75,    // Compress quality (0-100, where 100 is original)
      );

      if (image != null && await File(image.path).exists()) {
        final compressedPath = image.path;

        if (_userId != null) {
          // Save to database (on background thread)
          await DatabaseServices.addOrUpdateProfilePicture(_userId!, compressedPath);
        }

        // Update state only after DB operation to avoid blocking UI
        if (mounted) {
          setState(() {
            _profilePicturePath = compressedPath;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image not selected or unavailable.')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
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
                  // Profile Picture Section
                  Center(
                    child: ClipOval(
                      child: _profilePicturePath != null
                          ? Image.file(
                              File(_profilePicturePath!),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/default_profile.png', // Default profile image
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Button to change profile picture
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

                  SizedBox(height: 40),
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                  ),
                  SizedBox(height: 20),
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (val) => val!.isEmpty ? 'Enter your email' : null,
                  ),
                  SizedBox(height: 20),
                  // Mobile Number field
                  TextFormField(
                    controller: _mobileController,
                    decoration: InputDecoration(labelText: 'Mobile Number'),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Enter your mobile number' : null,
                  ),
                  SizedBox(height: 20),
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (val) => val!.isEmpty ? 'Enter your password' : null,
                  ),
                  SizedBox(height: 40),
                  // Update Button
                  ElevatedButton(
                    onPressed: _updateUserDetails,
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Keep the button tight around content
                      children: const [
                        Icon(Icons.edit, color: FlicksColours.Yellow, size: 20),
                        SizedBox(width: 8),
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

