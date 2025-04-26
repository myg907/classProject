import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:term_project_proj_gomez/firestore_search.dart';
import 'cloud_storage.dart';
import 'week_screen.dart';
import 'login_screen.dart';
import 'survey_screen.dart';

class Week {
  final String id;
  final int order;
  final String label;
  final String status;

  Week({
    required this.id,
    required this.order,
    required this.label,
    required this.status,
  });

  factory Week.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Week(
      id: doc.id,
      order: data['order'] ?? 0,
      label: data['label'] ?? 'Untitled Week',
      status: data['status'] ?? 'unknown',
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int currentPage = 0;

  late final GlobalKey<ProgressContentScreenState> _progressKey;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _progressKey = GlobalKey<ProgressContentScreenState>();
    pages = [
      ProgressContentScreen(
        key: _progressKey,
        onReset: () async {
          await resetUserProgress(context);
          setState(() {}); // rebuild screen after reset
        },
      ),
      const SearchScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> resetUserProgress(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Reset week document statuses in global Weeks collection (optional)
      final weeksSnapshot =
          await firestore.collection('Weeks').orderBy('order').get();
      for (int i = 0; i < weeksSnapshot.docs.length; i++) {
        final weekDoc = weeksSnapshot.docs[i];
        final newStatus =
            (i < 6) ? 'availableNotStarted' : 'locked'; // optional fallback
        await weekDoc.reference.update({'status': newStatus});
      }

      // 2. Delete Progress responses (session-level) for the user
      final progressRef =
          firestore.collection('Users').doc(userId).collection('Progress');
      final progressDocs = await progressRef.get();
      for (final doc in progressDocs.docs) {
        await doc.reference.delete();
      }

      // 3. Reset WeekProgress statuses per user
      final weekProgressRef =
          firestore.collection('Users').doc(userId).collection('WeekProgress');
      final weekProgressDocs = await weekProgressRef.get();
      for (final doc in weekProgressDocs.docs) {
        // You can also choose to delete the document instead of updating it
        await doc.reference.delete();
      }

      // 4. Delete SurveyProgress for the user
      final surveyProgressRef = firestore
          .collection('Users')
          .doc(userId)
          .collection('SurveyProgress');
      final surveyProgressDocs = await surveyProgressRef.get();
      for (final doc in surveyProgressDocs.docs) {
        await doc.reference.delete();
      }

      // 5. Show confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Progress has been fully reset."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to reset: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // make scaffold transparent
      extendBody: true, 
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Login.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Your actual pages
          pages[currentPage],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedItemColor: Color.fromARGB(255, 73, 126, 120),
        unselectedItemColor: const Color.fromARGB(255, 251, 249, 249),
        currentIndex: currentPage,
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search Week'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class ProgressContentScreen extends StatefulWidget {
  final Future<void> Function() onReset;

  const ProgressContentScreen({super.key, required this.onReset});

  @override
  State<ProgressContentScreen> createState() => ProgressContentScreenState();
}

class ProgressContentScreenState extends State<ProgressContentScreen> {
  void _refresh() {
    setState(() {}); // forces rebuild of the UI
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowSurveyIfNeeded();
    });
  }

  Future<String> getUserWeekStatus(
      String weekId, int order, String userId) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Get week info and releaseDate
    final weekDoc = await firestore.collection('Weeks').doc(weekId).get();
    final releaseDate = (weekDoc['releaseDate'] as Timestamp).toDate();
    final now = DateTime.now();

    // 2. Check if releaseDate has passed
    if (now.isBefore(releaseDate)) {
      return "locked"; // not available yet
    }

    // 3. If WeekProgress exists, return that value directly
    final userWeekDoc = await firestore
        .collection('Users')
        .doc(userId)
        .collection('WeekProgress')
        .doc(weekId)
        .get();

    final weekStatus = userWeekDoc.data()?['status'];
    if (weekStatus != null) {
      return weekStatus; // "availableNotStarted", "inProgress", "completed"
    }

    // 4. If user has not interacted with the week at all (no progress), return seed
    return "availableIncomplete"; // default for weeks 1–6
  }

  Future<void> _checkAndShowSurveyIfNeeded() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final surveyChecks = [
      {"id": "week1_start", "week": "week1", "trigger": "start"},
      {
        "id": "week4_start",
        "week": "week4",
        "trigger": "start",
        "prereq": "week3"
      },
      {
        "id": "week6_start",
        "week": "week6",
        "trigger": "start",
        "prereq": "week5"
      },
      {"id": "week8_complete", "week": "week8", "trigger": "complete"},
    ];

    for (final survey in surveyChecks) {
      final surveyId = survey['id']!;
      final weekId = survey['week']!;
      final trigger = survey['trigger']!;
      final prereqWeek = survey['prereq'];

      // 1. Skip if already completed
      final progressDoc = await firestore
          .collection('Users')
          .doc(userId)
          .collection('SurveyProgress')
          .doc(surveyId)
          .get();

      if (progressDoc.exists) continue;

      // 2. Check trigger condition
      final weekStatusDoc = await firestore
          .collection('Users')
          .doc(userId)
          .collection('WeekProgress')
          .doc(weekId)
          .get();

      final weekStatus = weekStatusDoc.data()?['status'];

      if (trigger == 'start') {
        if (weekStatus != 'availableIncomplete' &&
            weekStatus != 'in progress') {
          continue;
        }

        // Check prerequisite completion (if any)
        if (prereqWeek != null) {
          final prereqDoc = await firestore
              .collection('Users')
              .doc(userId)
              .collection('WeekProgress')
              .doc(prereqWeek)
              .get();

          if (prereqDoc.data()?['status'] != 'completed') continue;
        }
      } else if (trigger == 'complete') {
        if (weekStatus != 'completed') continue;
      }

      // 3. Show modal and exit loop if triggered
      final currentContext = context;
      if (!currentContext.mounted) return;

      final completed = await showDialog<bool>(
        context: currentContext,
        barrierDismissible: false,
        builder: (_) => SurveyScreen(surveyId: surveyId),
      );

      if (!currentContext.mounted) return;

      if (completed == true) {
        setState(() {});
      }

      break;
    }
  }

  void navigateToWeekScreen(Week week) {
    final currentContext = context;
    if (!currentContext.mounted) return;

    Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (_) => WeekScreen(week: week),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Your Progress",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 181, 184, 184),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Login.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(50)),
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Weeks')
                        .orderBy('order')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No weeks found.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final weeks = snapshot.data!.docs
                          .map((doc) => Week.fromDocument(doc))
                          .toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: weeks.length,
                        itemBuilder: (context, index) {
                          final week = weeks[index];

                          return FutureBuilder<String>(
                            future:
                                getUserWeekStatus(week.id, week.order, userId),
                            builder: (context, statusSnapshot) {
                              final status = statusSnapshot.data ?? "loading";

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.white.withAlpha(180),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  title: Text(
                                    week.label,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 43, 113, 105),
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatStatusLabel(status),
                                    style:
                                        const TextStyle(color: Colors.black87),
                                  ),
                                  leading: _getStatusIcon(status),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () async {
                                    if (status != "locked") {
                                      final weekProgressRef = FirebaseFirestore
                                          .instance
                                          .collection('Users')
                                          .doc(userId)
                                          .collection('WeekProgress')
                                          .doc(week.id);

                                      final existingProgress =
                                          await weekProgressRef.get();

                                      if (!existingProgress.exists) {
                                        await weekProgressRef.set(
                                            {'status': 'availableNotStarted'});
                                        _refresh(); // this triggers the status update immediately
                                      }
                                      navigateToWeekScreen(week);
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Button to logout with its respective alert dialog 
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Confirm Logout", style: TextStyle(fontFamily: 'Poppins')),
                                  content: Text("Are you sure you want to log out?", style: TextStyle(fontFamily: 'Poppins')),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: Text("Cancel", style: TextStyle(color: Colors.black, fontFamily: 'Poppins')),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Perform sign out and navigate
                                        FirebaseAuth.instance.signOut();
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      },
                                      child: Text("Yes", style: TextStyle(color: Colors.red,fontFamily: 'Poppins')),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                        // reset button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(38), // Alpha 0.15 equivale a 38/255
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () async {
                            bool? confirmReset = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Reset", style: TextStyle(fontFamily: 'Poppins')),
                                  content: const Text("Are you sure you want to reset your progress?", style: TextStyle(fontFamily: 'Poppins')),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false); // Cancel
                                      },
                                      child: const Text("Cancel", style: TextStyle(color: Colors.black, fontFamily: 'Poppins')),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true); // Confirm
                                      },
                                      child: const Text("Yes, reset", style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmReset == true) {
                              await widget.onReset();
                              _refresh();
                            }
                          },
                          child: const Text(
                            "Reset Progress",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),

                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case "available":
    case "availableincomplete":
      return "Available";
    case "availablenotstarted":
      return "Available (Not Started)";
    case "inprogress":
      return "In Progress";
    case "completed":
      return "Completed";
    case "locked":
      return "Locked";
    default:
      return status;
  }
}

Widget _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case "available":
    case "availableincomplete":
    case "availablenotstarted":
      return const Icon(Icons.check_circle_outline, color: Colors.blueGrey);
    case "inprogress":
      return const Icon(Icons.hourglass_top_outlined, color: Colors.blueGrey);
    case "completed":
      return const Icon(Icons.check_circle, color: Colors.green);
    case "locked":
      return const Icon(Icons.lock, color: Colors.blueGrey);
    default:
      return const Icon(Icons.help_outline);
  }
}
