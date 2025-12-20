import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],

      appBar: AppBar(
        title: const Text('About', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50.0),
            CircleAvatar(
                backgroundImage: AssetImage('images/logo_black.png'),
                radius: 70.0,
            ),

            Text(
              'MyTenant',
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 30.0),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.topic_rounded, color: Colors.deepPurple),
                title: Text(
                  "Subject",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'BTIS3204 Final Year Project II',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.0),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.badge_rounded, color: Colors.deepPurple),
                title: Text(
                  "Title",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Tenant and Asset Management System',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.0),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(
                  Icons.subject_rounded,
                  color: Colors.deepPurple,
                ),
                title: Text(
                  "Abstract",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'This app helps asset owners to record asset rent, utility bills, and asset condition. Tenants can scan rental contracts or utility bills, and the system will use AI to extract and save the details. The app will send rent or bill payment reminders when due. Tenants also can report problems by uploading photos. The app uses AI to detect the issue and suggest possible causes. It will also list nearby professionals who can fix the problem, and users can contact them directly.',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
        
            SizedBox(height: 8.0),
        
            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.assignment_ind_rounded, color: Colors.deepPurple),
                title: Text(
                  "Student Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'Cheng Yi Xiang',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
        
            SizedBox(height: 8.0),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.badge_rounded, color: Colors.deepPurple),
                title: Text(
                  "Student ID",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'B230031A',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
        
            SizedBox(height: 8.0),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.mail_rounded, color: Colors.deepPurple),
                title: Text(
                  "Email",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'b230031a@sc.edu.my',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
        
            SizedBox(height: 8.0),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.supervised_user_circle_rounded, color: Colors.deepPurple),
                title: Text(
                  "Supervisor",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'Ts. So Yong Quay',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.0),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: Icon(Icons.api_rounded, color: Colors.deepPurple),
                title: Text(
                  "Version",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
        
            SizedBox(height: 40.0),
          ],
        ),
      )
    );
  }
}
