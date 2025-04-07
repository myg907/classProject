import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'progress_screen.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Appbar styling
        centerTitle: true, 
        toolbarHeight: 70,
        elevation: 0.5, 
        //Title stuff
        title: Text("Breathe In, Stand Down", 
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold, 
          fontSize: 27,
          color: const Color.fromARGB(255, 14, 90, 84),
          ))),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), // Adjust padding as needed
            child: Text(
              "Welcome ${FirebaseAuth.instance.currentUser?.email}! The purpose of this app is to aid active-duty service members struggling with alcoholism, assisting in their intervention to help them stay on track with their progress.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                color: Color.fromARGB(255, 38, 77, 97),
                height: 1.7,
              ),
              textAlign: TextAlign.center, // Center-align the text
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            child: Text(
              "Go to your progress!",
              style: TextStyle(fontFamily: 'Poppins', color: const Color.fromARGB(255, 8, 67, 82)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProgressScreen()),
              );
            },
          ),
           
        ],
      )
    );
  }
}