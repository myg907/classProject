import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'progress_screen.dart';
import 'login_screen.dart';

class WeekScreen extends StatefulWidget {
  final Week week;

  const WeekScreen({super.key, required this.week});

  @override
  _WeekScreenState createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _weeklyContentRef;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _weeklyContentRef = _firestore
        .collection('Weeks')
        .doc(widget.week.id)
        .collection('WeeklyContent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor:
            const Color.fromARGB(255, 93, 164, 157).withValues(alpha: 0.5),
        elevation: 0,
        title: Text(
          widget.week.label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 43, 113, 105),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
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
              child: const Text("Logout"),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/Login.jpg', // Change to your actual path
            fit: BoxFit.cover,
          ),
          // Semi-transparent overlay
          Container(color: Colors.black.withValues(alpha: 0.5)),

          // Content on top of background
          StreamBuilder<QuerySnapshot>(
            stream: _weeklyContentRef.orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final contentDocs = snapshot.data!.docs;
              if (contentDocs.isEmpty) {
                return const Center(
                  child: Text("No content available.",
                      style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contentDocs.length,
                itemBuilder: (context, index) {
                  final data =
                      contentDocs[index].data() as Map<String, dynamic>;
                  final type = data['type'];
                  final content = data['content'];
                  final status = data['status'];
                  final contentId = contentDocs[index].id;

                  return type == 'question'
                      ? _buildQuestionTile(content, status, contentId)
                      : _buildMeditationTile(content, status, contentId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Simplified code for handling question type content
  Widget _buildQuestionTile(String content, String status, String contentId) {
    TextEditingController _answerController = TextEditingController();

    // Fetch user's answer if available
    _firestore
        .collection('Weeks')
        .doc(widget.week.id)
        .collection('WeeklyContent')
        .doc(contentId)
        .collection('Answers')
        .doc(_userId) // Use the current user's UID
        .get()
        .then((doc) {
      if (doc.exists) {
        _answerController.text = doc['answer'];
      }
    });

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: const Text("Question"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            if (status != 'complete') ...[
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'Your answer'),
                maxLines: 3,
              ),
              ElevatedButton(
                onPressed: () async {
                  // Save the user's answer to Firestore under their UID
                  await _firestore
                      .collection('Weeks')
                      .doc(widget.week.id)
                      .collection('WeeklyContent')
                      .doc(contentId)
                      .collection('Answers')
                      .doc(_userId) // Use the current user's UID
                      .set({
                    'answer': _answerController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // Update status to 'complete'
                  await _firestore
                      .collection('Weeks')
                      .doc(widget.week.id)
                      .collection('WeeklyContent')
                      .doc(contentId)
                      .update({'status': 'complete'});
                },
                child: const Text('Submit Answer'),
              ),
            ],
          ],
        ),
        trailing: Icon(
          status == 'complete' ? Icons.check : Icons.radio_button_unchecked,
          color: status == 'complete' ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  // Simplified code for handling meditation type content
  Widget _buildMeditationTile(String content, String status, String contentId) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: const Text("Meditation"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            if (status != 'complete') ...[
              ElevatedButton(
                onPressed: () async {
                  // Mark meditation as complete when "Done" is clicked
                  await _firestore
                      .collection('Weeks')
                      .doc(widget.week.id)
                      .collection('WeeklyContent')
                      .doc(contentId)
                      .update({'status': 'complete'});
                },
                child: const Text('Done'),
              ),
            ],
          ],
        ),
        trailing: Icon(
          status == 'complete' ? Icons.check : Icons.radio_button_unchecked,
          color: status == 'complete' ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
