import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(title: "Firebase Example", home: LoginScreen()));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? email;
  String? password;
  String? error;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                  decoration:
                      const InputDecoration(hintText: 'Enter your email'),
                  maxLength: 64,
                  onChanged: (value) => email = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null; // Returning null means "no issues"
                  }),
              TextFormField(
                  decoration:
                      const InputDecoration(hintText: "Enter a password"),
                  obscureText: true,
                  onChanged: (value) => password = value,
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Your password must contain at least 8 characters.';
                    }
                    return null; // Returning null means "no issues"
                  }),
              const SizedBox(height: 16),
              ElevatedButton(
                  child: const Text('Login'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // This calls all validators() inside the form for us.
                      tryLogin();
                    }
                  }),
              if (error != null)
                Text(
                  "Error: $error",
                  style: TextStyle(color: Colors.red[800], fontSize: 12),
                )
            ],
          ),
        ),
      ),
    );
  }

  // Note the async keyword
  void tryLogin() async {
    try {
      // The await keyword blocks execution to wait for
      // signInWithEmailAndPassword to complete its asynchronous execution and
      // return a result.
      //
      // FirebaseAuth with raise an exception if the email or password
      // are determined to be invalid, e.g., the email doesn't exist.
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password!);
      print("Logged in ${credential.user}");
      error = null; // clear the error message if exists.
      setState(() {}); // Trigger a rebuild

      // We need this next check to use the Navigator in an async method.
      // It basically makes sure LoginScreen is still visible.
      if (!mounted) return;

      // pop the navigation stack so people cannot "go back" to the login screen
      // after logging in.
      Navigator.of(context).pop();
      // Now go to the HomeScreen.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ));
    } on FirebaseAuthException catch (e) {
      // Exceptions are raised if the Firebase Auth service
      // encounters an error. We need to display these to the user.      
      if (e.code == 'user-not-found') {
        error = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        error = 'Wrong password provided for that user.';
      } else {
        error = 'An error occurred: ${e.message}';
      }


      // Call setState to redraw the widget, which will display
      // the updated error text.
      setState(() {});
    }
  }
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
            child: Text(
              "Welcome ${FirebaseAuth.instance.currentUser?.email} The purpose of this app is to aid active-duty service members struggling with alcoholism, assisting in their intervention to help them stay on track with their progress.",
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
           ElevatedButton(
              onPressed: () {
                // signOut() doesn't return anything, so we don't need to await
                // for it to finish unless we really want to.
                FirebaseAuth.instance.signOut();

                // This navigator call clears the Navigation stack and takes
                // them to the login screen because we don't want users
                // "going back" in our app after they log out.
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false);
              },
              child: const Text("Logout"),
            ) 
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

