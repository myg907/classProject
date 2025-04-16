import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'progress_screen.dart';

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
            const Color.fromARGB(255, 93, 164, 157).withOpacity(0.5),
        elevation: 0,
        title: Text(
          widget.week.label,
          style: const TextStyle(
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
                backgroundColor: Colors.white.withOpacity(0.15),
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
                  color: Color.fromARGB(255, 8, 67, 82),
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
          Container(color: Colors.black.withOpacity(0.5)),
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
    final _formKey = GlobalKey<FormState>(); // ✅ Moved here
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
          color: Colors.white.withOpacity(0.85),
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

                          setState(() {}); // Refresh the UI
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
