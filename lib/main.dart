import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/tenant_page.dart';
import 'pages/landlord_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TenantApp());
}

class TenantApp extends StatelessWidget {
  const TenantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTenant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(user.uid),
            builder: (context, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Colors.indigoAccent[200],
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('images/logo_white.png', width: 110, height: 110,),
                        const Text('MyTenant', style: TextStyle(fontFamily: 'Pacifico', fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),),
                        const SizedBox(height : 30.0),
                        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),),
                      ],
                    ),
                  ),
                );
              }

              final userData = dataSnapshot.data;

              if (userData == null || userData.isEmpty) {
                return const Scaffold(body: Center(child: Text("User data not found or failed to load.")));
              }

              final role = userData['role'] as String?;

              if (role == 'Tenant') {
                return TenantPage(userData: userData);
              } else if (role == 'Landlord') {
                return LandlordPage(userData: userData);
              } else {
                return const Scaffold(body: Center(child: Text("Invalid user role. Please contact support.")));
              }
            },
          );

        } else {
          return const LoginPage();
        }
      },
    );
  }
}