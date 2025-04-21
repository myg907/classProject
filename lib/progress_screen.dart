import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:term_project_proj_gomez/firestore_search.dart';
import 'cloud_storage.dart';
import 'week_screen.dart';
import 'login_screen.dart';

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

  final List<Widget> pages = [
    const ProgressContentScreen(),
    const SearchScreen(), 
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search Week'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


class ProgressContentScreen extends StatelessWidget {
  const ProgressContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Progress Screen",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 43, 113, 105),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Login.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
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
                            style: TextStyle(color: Colors.white),
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
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            color: Colors.white.withOpacity(0.85),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                week.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 43, 113, 105),
                                ),
                              ),
                              subtitle: Text(
                                _formatStatusLabel(week.status),
                                style: const TextStyle(color: Colors.black87),
                              ),
                              leading: _getStatusIcon(week.status),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WeekScreen(week: week),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(38),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case "available":
        return "Available";
      case "completed":
        return "Completed";
      case "locked":
        return "Locked";
      case "in progress":
        return "In Progress";
      default:
        return status;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "available":
        return const Icon(Icons.check_circle_outline, color: Colors.blueGrey);
      case "in progress":
        return const Icon(Icons.hourglass_top_outlined, color: Colors.blueGrey);
      case "completed":
        return const Icon(Icons.check_circle, color: Colors.blueGrey);
      case "locked":
        return const Icon(Icons.lock, color: Colors.blueGrey);
      default:
        return const Icon(Icons.help_outline);
    }
  }
}

