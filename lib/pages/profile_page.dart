import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    Future<Map<String, dynamic>?> getUserInformation() async {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return userInfo.data() as Map<String, dynamic>?;
    }

    return Scaffold(
      backgroundColor: Colors.purple[50],

      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),

      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'avatar',
              child: CircleAvatar(
                backgroundImage: AssetImage('images/logo.png'),
                radius: 70.0,
              ),
            ),
            Text(
              'Cheng Yi Xiang',
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tenant',
              style: TextStyle(
                fontFamily: 'Source Sans Pro',
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20.0),

            FutureBuilder<Map<String, dynamic>?>(
              future: getUserInformation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: CircularProgressIndicator(), // Loading
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const Text('Loading error');
                }

                final userData = snapshot.data!;
                final name = userData['name'] as String? ?? 'N/A';
                final email = userData['email'] as String? ?? 'N/A';
                final role = userData['role'] as String? ?? 'Unknown';
                final contactNumber = userData['contactNumber'] as String? ?? "N/A";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.badge, color: Colors.deepPurple),
                        title: Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          name,
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.mail, color: Colors.deepPurple),
                        title: Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          email,
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.person, color: Colors.deepPurple),
                        title: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          contactNumber,
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.person, color: Colors.deepPurple),
                        title: Text("Role", style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          role,
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 40.0),

            ElevatedButton(onPressed: (){

            }, child: Text("Edit Profile")),
          ],
        ),
      ),
    );
  }
}
