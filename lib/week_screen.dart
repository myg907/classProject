import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'progress_screen.dart';
import 'survey_screen.dart';

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

  Future<bool> _isSurveyRequiredAndIncomplete(String weekId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final surveyId = {
      'week1': 'week1_start',
      'week4': 'week4_start',
      'week6': 'week6_start',
      'week8': 'week8_complete',
    }[weekId];

    if (surveyId == null) return false;

    final progressDoc = await firestore
        .collection('Users')
        .doc(userId)
        .collection('SurveyProgress')
        .doc(surveyId)
        .get();

    if (progressDoc.exists) return false;

    final surveyDoc = await firestore.collection('Surveys').doc(surveyId).get();

    if (!surveyDoc.exists) return false;

    // Show modal survey screen
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SurveyScreen(surveyId: surveyId),
    );

    return completed != true; // true if STILL incomplete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "This Week",
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 181, 184, 184),
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
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color.fromARGB(255, 236, 237, 238),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Login.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
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
                  itemCount: contentDocs.length,
                  itemBuilder: (context, index) {
                    final doc = contentDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final description = data['description'] ?? 'No description';
                    final question = data['question'] ?? '';
                    final contentId = doc.id;

                    return _buildContentCard(description, question, contentId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(
      String description, String question, String sessionId) {
    final TextEditingController _responseController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    final sessionDoc = _firestore
        .collection('Users')
        .doc(_userId)
        .collection('Progress')
        .doc(sessionId);

    return FutureBuilder<DocumentSnapshot>(
      future: sessionDoc.get(),
      builder: (context, snapshot) {
        final responseData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final previousAnswer = responseData['response'] ?? '';
        final hasSubmitted = previousAnswer.toString().trim().isNotEmpty;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.white.withValues(alpha: 0.85),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(question, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _responseController,
                    maxLines: 4,
                    enabled: !hasSubmitted,
                    decoration: const InputDecoration(
                      labelText: "Your Response",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a response';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!hasSubmitted)
                    ElevatedButton(
                      onPressed: () async {
                        // 1. Check if the survey must be completed before allowing submission
                        final isBlocked = await _isSurveyRequiredAndIncomplete(
                            widget.week.id);

                        if (isBlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Cannot submit response until survey is complete."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // 2. Continue with normal validation + submission logic
                        if (_formKey.currentState!.validate()) {
                          final responseText = _responseController.text.trim();

                          await sessionDoc.set({
                            'response': responseText,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          // Unlock the next week
                          final nextWeekId = _getNextWeekId(widget.week.id);
                          if (nextWeekId != null) {
                            final nextWeekRef =
                                _firestore.collection('Weeks').doc(nextWeekId);
                            final nextDoc = await nextWeekRef.get();

                            if (nextDoc.exists &&
                                (nextDoc['status'] == 'unavailable')) {
                              await nextWeekRef
                                  .update({'status': 'available but locked'});
                            }
                          }

                          // Check if all sessions in this week are submitted
                          final weekContentSnapshot =
                              await _weeklyContentRef.get();
                          int submittedCount = 0;

                          for (final session in weekContentSnapshot.docs) {
                            final sessionProgress = await _firestore
                                .collection('Users')
                                .doc(_userId)
                                .collection('Progress')
                                .doc(session.id)
                                .get();

                            final response =
                                sessionProgress.data()?['response'] ?? '';
                            if (response.toString().trim().isNotEmpty) {
                              submittedCount++;
                            }
                          }

                          final weekProgressRef = _firestore
                              .collection('Users')
                              .doc(_userId)
                              .collection('WeekProgress')
                              .doc(widget.week.id);

                          if (submittedCount ==
                              weekContentSnapshot.docs.length) {
                            await weekProgressRef.set({'status': 'completed'});
                          } else {
                            await weekProgressRef.set({'status': 'inProgress'});
                          }

                          setState(() {}); // Refresh UI
                        }
                      },
                      child: const Text("Submit"),
                    ),
                  if (hasSubmitted)
                    const Text("✔ Response submitted",
                        style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _getNextWeekId(String currentWeekId) {
    final match = RegExp(r'week(\d+)').firstMatch(currentWeekId.toLowerCase());
    if (match != null) {
      final currentWeekNum = int.tryParse(match.group(1) ?? '');
      if (currentWeekNum != null) {
        return 'week${currentWeekNum + 1}';
      }
    }
    return null;
  }
}
