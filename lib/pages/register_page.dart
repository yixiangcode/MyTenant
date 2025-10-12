import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController roleCtrl = TextEditingController();

  String errorMessage = "";

  Future<void> registerTenant(String uid) async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty || roleCtrl.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': emailCtrl.text,
      'name': '${roleCtrl.text}101',
      'contactNumber': 'Unknown',
      'role': roleCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    emailCtrl.clear();
    passCtrl.clear();
    roleCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 100, color: Colors.indigo),
              SizedBox(height: 20),
              Text(
                "Create a New Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),


              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: roleCtrl,
                decoration: InputDecoration(
                  hintText: "Role: Tenant/Landlord",
                  prefixIcon: Icon(Icons.people),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 30),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 20),

              // Register Button
              ElevatedButton(
                onPressed: () async{
                  try{
                    final userRegistered = await _auth.createUserWithEmailAndPassword(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
                    final uid = userRegistered.user?.uid;

                    if (uid != null){
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Register Successful")),
                      );
                      registerTenant(uid);
                      Navigator.pop(context);
                    }
                  }catch(e){
                    setState(() {
                      errorMessage = e.toString();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.indigo,
                ),
                child: Text("Register", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 20),


              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.indigo, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}