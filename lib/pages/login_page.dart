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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(tag: 'logo', child: Image.asset('images/logo.png', width: 120, height: 120,)),
              const SizedBox(height: 20),
              const Text(
                "Welcome to MyTenant",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() {
                    _isLoading = true;
                    errorMessage = "";
                  });

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
                      final userData = userDoc.data() as Map<String, dynamic>?;

                      if (userRole == "Tenant"){
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => TenantPage(userData: userData!)),
                        );
                      }else if(userRole == "Landlord"){
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LandlordPage(userData: userData!)),
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Login Successfully.",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),

                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          margin: const EdgeInsets.all(25),
                          elevation: 8.0,
                        ),
                      );
                    }
                  } catch (e){
                    setState(() {
                      errorMessage = e.toString();
                    });
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.indigo,
                  disabledBackgroundColor: Colors.indigo.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text(
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