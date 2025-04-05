import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  runApp(const MaterialApp(title: "Breathe In Stand Down", home: SplashScreen()));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

//Class Definition that it's used in the progress screen
class Week {
  final int order;
  final String label;
  final String status;

  // Constructor that initializes all fields
  const Week(this.order, this.label, this.status);
}


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
            child: const Text(
              "The purpose of this app is to aid active-duty service members struggling with alcoholism, assisting in their intervention to help them stay on track with their progress.",
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
  ProgressScreen({super.key});

  static const List<String> statuses = [
    "Available but incomplete",
    "Partially completed (in progress)",
    "Available but not started",
    "Locked",
    "Unavailable"
  ];

  final List<Week> weeks = List.generate(
    10,
    (index) => Week(
      index + 1,
      "Week ${index + 1}",
      statuses[Random().nextInt(statuses.length)], // Now accessible
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Progress Screen")),
      body: ListView.builder(
        itemCount: weeks.length,
        itemBuilder: (context, index) {
          final week = weeks[index];

          return ListTile(
            title: Text(week.label),
            subtitle: Text(week.status),
            leading: _getStatusIcon(week.status),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeekScreen(week: week),
                ),
              );
            },
          );
        },
      ),
    );
  }
  //Icons to use for the week description
  Widget _getStatusIcon(String status) {
    switch (status) {
      case "Available but incomplete":
        return const Icon(Icons.check_circle_outline, color: Colors.orange);
      case "Partially completed (in progress)":
        return const Icon(Icons.hourglass_top_outlined, color: Colors.blue);
      case "Available but not started":
        return const Icon(Icons.circle_outlined, color: Colors.grey);
      case "Locked":
        return const Icon(Icons.lock, color: Colors.red);
      case "Unavailable":
        return const Icon(Icons.block, color: Colors.black);
      default:
        return const Icon(Icons.help_outline);
    }
  }
}

class WeekScreen extends StatelessWidget {
  final Week week;

  const WeekScreen({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(week.label)),
      body: Center(
        child: Text(
          week.label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: "Poppins"),
        ),
      ),
    );
  }
}

