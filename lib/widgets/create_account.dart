import 'home_screen.dart';
import 'package:flicks_new/main.dart';
import 'package:flutter/material.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Account"),
      ),
      body: SafeArea(child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Enter user name",
              enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
              color: Colors.black12
                )
              ),
            ),
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter Email",
              enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
              color: Colors.black12
                )
              ),
            ),
          ),
          TextFormField(
            controller: _mobileController,
            decoration: InputDecoration(
              hintText: "Enter Mobile number",
              enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
              color: Colors.black12
                )
              ),
            ),
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: "Enter a password",
              enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
              color: Colors.black12
                )
              ),
            ),
          ),
          ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(navigatorKey: navigatorKey),
                ),
              );
              
          },
          icon: Icon(Icons.save),
          label: Text("Save User Details")),
          SizedBox(
          height: 3,
          child: Container(
          color: Colors.purple,
            ),
          ),
        ],
      )),
    );
  }
}