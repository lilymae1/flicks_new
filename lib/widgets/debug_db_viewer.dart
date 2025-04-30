import 'package:flutter/material.dart';
import '../services/DatabaseServices.dart';

class DebugDBViewer extends StatefulWidget {
  const DebugDBViewer({super.key});

  @override
  State<DebugDBViewer> createState() => _DebugDBViewerState();
}

class _DebugDBViewerState extends State<DebugDBViewer> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DatabaseServices.getAllStudentRecords();
    setState(() {
      _users = users;
    });
  }

  Future<void> _addUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = int.tryParse(_mobileController.text.trim()) ?? 0;
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || mobile == 0 || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields properly.")),
      );
      return;
    }

    await DatabaseServices.addUserDetails(name, email, mobile, password);
    _clearForm();
    _loadUsers();
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User DB Viewer")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Add New User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Mobile Number"),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.add),
                label: const Text("Add User"),
              ),
              const Divider(height: 32, thickness: 2),
              const Text("All Users", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _users.isEmpty
                  ? const Text("No users found.")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          title: Text(user['userName'] ?? 'No Name'),
                          subtitle: Text("Email: ${user['email']} | Mobile: ${user['mobileNo']}"),
                          trailing: Text("ID: ${user['userID']}"),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

