import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(title: "Breathe In Stand Down", home: SplashScreen()));
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, 
        toolbarHeight: 70,
        elevation: 0.5, 
        //bottom: PreferredSize(preferredSize: const Size.fromHeight(10.0), child: Container(height: 1.0, color: Colors.grey,)),
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
            child: const Text(
              "The purpose of this app is to give aid for active-duty service members with alcoholism, helping on their intervention as a way to keep them in track of their progress.",
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

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Progress Screen")),
      body: Center(
        child: Text(
          "This screen was created by Melissa Gomez",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
