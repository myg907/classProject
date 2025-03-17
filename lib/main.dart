import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(title: "Breathe In Stand Down", home: HomeScreen()));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Breathe In Stand Down")),
      body: Column(
        children: [
          OutlinedButton(
              child: Text("Screen One"),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AboutScreen()));
              }),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Screen One")),
      body: Center(
        child: Text(
          "This screen was created by Melissa Gomez",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
