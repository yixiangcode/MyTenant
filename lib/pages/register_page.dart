import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

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
              SizedBox(height: 16),

              // Confirm Password Input
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Confirm Password",
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

              // Register Button
              ElevatedButton(
                onPressed: () {
                  // TODO: 实现注册逻辑，例如验证输入，发送到后端
                  // 注册成功后可以返回登录页
                  Navigator.pop(context);
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

              // Back to Login Link
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 返回上一个页面（即登录页）
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