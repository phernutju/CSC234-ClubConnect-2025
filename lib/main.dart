import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TestAuthScreen());
  }
}

class TestAuthScreen extends StatefulWidget {
  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final _auth = AuthService();

  final emailController = TextEditingController();
  final passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Auth Test")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController),
            TextField(controller: passController, obscureText: true),

            ElevatedButton(
              onPressed: () async {
                await _auth.signUp(
                  email: emailController.text,
                  password: passController.text,
                  displayName: "TestUser",
                );
                print("Signed up");
              },
              child: Text("Sign Up"),
            ),

            ElevatedButton(
              onPressed: () async {
                await _auth.signIn(
                  email: emailController.text,
                  password: passController.text,
                );
                print("Signed in");
              },
              child: Text("Sign In"),
            ),

            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                print("Signed out");
              },
              child: Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
