import 'package:flutter/material.dart';
import 'tenant_page.dart';
import 'landlord_page.dart';
import 'register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class LoginPage extends StatelessWidget {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

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
              Image.asset(
                'images/logo.png',
                width: 120,
                height: 120,
              ),
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

              // Login Button
              ElevatedButton(
                onPressed: () async{

                  if(emailCtrl.text.trim() == "tenant" || emailCtrl.text.trim() == "t"){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => TenantPage()),
                    );
                  }else if(emailCtrl.text.trim() == "landlord" || emailCtrl.text.trim() == "l"){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LandlordPage()),
                    );
                  }

                  try{
                    var userRegistered = await _auth.signInWithEmailAndPassword(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
                    if (userRegistered != null){
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => TenantPage()),
                      );
                    }
                  }catch (e){
                    print(e);
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