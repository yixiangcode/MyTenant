import 'package:flutter/material.dart';
import 'tenant_page.dart';
import 'landlord_page.dart';
import 'register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  String errorMessage = "";

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
              Hero(tag: 'logo', child: Image.asset('images/logo.png', width: 120, height: 120,)),
              SizedBox(height: 20),
              Text(
                "Welcome to MyTenant",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),

              // Email Input
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

              // Password Input
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

              // Login Button
              ElevatedButton(
                onPressed: () async{

                  // For testing purpose, quick login
                  if(emailCtrl.text.trim() == "tenant" || emailCtrl.text.trim() == "t"){
                    emailCtrl.text = "admin@tenant.com";
                    passCtrl.text = "123456";

                  }else if(emailCtrl.text.trim() == "landlord" || emailCtrl.text.trim() == "l"){
                    emailCtrl.text = "admin@landlord.com";
                    passCtrl.text = "123456";
                  }

                  try{
                    var userRegistered = await _auth.signInWithEmailAndPassword(email: emailCtrl.text.trim(), password: passCtrl.text.trim());

                    final uid = userRegistered.user!.uid;

                    if (userRegistered != null){

                      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                      String? userRole = (userDoc.data() as Map<String, dynamic>?)?['role'] as String?;

                      if (userRole == "Tenant"){
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => TenantPage()),
                        );
                      }else if(userRole == "Landlord"){
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LandlordPage()),
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Login Successful")),
                      );
                    }
                  }catch (e){
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
                child: Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text(
                  "Don't have an account? Register now",
                  style: TextStyle(color: Colors.indigo, fontSize: 14),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}