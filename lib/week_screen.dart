import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'progress_screen.dart';
import 'survey_screen.dart';
import 'package:video_player/video_player.dart';

class WeekScreen extends StatefulWidget {
  final Week week;

  const WeekScreen({super.key, required this.week});

  @override
  _WeekScreenState createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoInitialized = {};

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

  String? _getPreviousWeekId(String currentWeekId) {
    final match = RegExp(r'week(\d+)').firstMatch(currentWeekId.toLowerCase());
    if (match != null) {
      final currentWeekNum = int.tryParse(match.group(1) ?? '');
      if (currentWeekNum != null && currentWeekNum > 1) {
        return 'week\${currentWeekNum - 1}';
      }
    }
    return null;
  }

  Future<bool> _isSurveyRequiredAndIncomplete(String weekId) async {
    final surveyId = {
      'week1': 'week1_start',
      'week4': 'week4_start',
      'week6': 'week6_start',
      'week8': 'week8_complete',
    }[weekId];

    if (surveyId == null) return false;

    final progressDoc = await _firestore
        .collection('Users')
        .doc(_userId)
        .collection('SurveyProgress')
        .doc(surveyId)
        .get();

    if (progressDoc.exists) return false;

    final surveyDoc =
        await _firestore.collection('Surveys').doc(surveyId).get();
    if (!surveyDoc.exists) return false;

    // Show modal survey screen
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SurveyScreen(surveyId: surveyId),
    );

    return completed != true;
  }

  Future<void> _initializeVideo(String sessionId, String videoPath) async {
    if (_videoInitialized.containsKey(sessionId) &&
        _videoInitialized[sessionId]!) return;

    final controller = VideoPlayerController.asset('assets/videos/$videoPath');

    try {
      await controller.initialize();
      setState(() {
        _videoControllers[sessionId] = controller;
        _videoInitialized[sessionId] = true;
      });
    } catch (e) {
      print("Error initializing video for $sessionId: $e");
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
            child: // Button to logout with its respective alert dialog
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
                      title: Text("Confirm Logout",
                          style: TextStyle(fontFamily: 'Poppins')),
                      content: Text(
                          "Are you sure you want to log out? Don't miss your progress!",
                          style: TextStyle(fontFamily: 'Poppins')),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text("Cancel",
                              style: TextStyle(
                                  color: Colors.black, fontFamily: 'Poppins')),
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
                          child: Text("Yes",
                              style: TextStyle(
                                  color: Colors.red, fontFamily: 'Poppins')),
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

                return FutureBuilder<List<bool>>(
                  future: Future.wait(contentDocs.map((doc) async {
                    final progress = await _firestore
                        .collection('Users')
                        .doc(_userId)
                        .collection('Progress')
                        .doc(doc.id)
                        .get();
                    return (progress.data()?['response'] ?? '')
                        .toString()
                        .isNotEmpty;
                  })),
                  builder: (context, completeSnapshot) {
                    final allComplete = completeSnapshot.hasData &&
                        completeSnapshot.data!.every((x) => x);

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: contentDocs.length,
                            itemBuilder: (context, index) {
                              final doc = contentDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final description =
                                  data['description'] ?? 'No description';
                              final question = data['question'] ?? '';
                              final videoAsset = data['video'] ?? '';
                              final sessionId = doc.id;
                              _initializeVideo(sessionId, videoAsset);
                              return _buildContentCard(
                                  description, question, sessionId, videoAsset);
                            },
                          ),
                        ),
                        if (allComplete)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.15),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              onPressed: () async {
                                await _firestore
                                    .collection('Users')
                                    .doc(_userId)
                                    .collection('WeekProgress')
                                    .doc(widget.week.id)
                                    .set({'status': 'completed'});
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ProgressScreen()),
                                  );
                                }
                              },
                              child: const Text("Mark Week as Complete",
                                  style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ),
                      ],
                    );
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
      String description, String question, String sessionId, String videoPath) {
    final _responseController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    final sessionDoc = _firestore
        .collection('Users')
        .doc(_userId)
        .collection('Progress')
        .doc(sessionId);

    return FutureBuilder<DocumentSnapshot>(
      future: sessionDoc.get(),
      builder: (context, snapshot) {
        final previousAnswer =
            (snapshot.data?.data() as Map<String, dynamic>?)?['response'] ?? '';
        final hasSubmitted = previousAnswer.toString().trim().isNotEmpty;

        if (hasSubmitted) {
          _responseController.text = previousAnswer.toString().trim();
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: const Color.fromARGB(255, 113, 193, 205).withOpacity(0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller != null && controller.value.isInitialized)
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            controller.value.isPlaying
                                ? controller.pause()
                                : controller.play();
                          });
                        },
                        child: VideoPlayer(controller),
                      ),
                    ),
                  const SizedBox(height: 12),
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
                    style: TextStyle(
                        color: hasSubmitted ? Colors.grey : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Your Response",
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: hasSubmitted ? Colors.grey[200] : Colors.white,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white
                            .withAlpha(38), // semi-transparent white
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () async {
                        final isBlocked = await _isSurveyRequiredAndIncomplete(
                            widget.week.id);
                        if (!mounted) return;
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

                        final prevWeekId = _getPreviousWeekId(widget.week.id);
                        if (prevWeekId != null) {
                          final prevDoc = await _firestore
                              .collection('Users')
                              .doc(_userId)
                              .collection('WeekProgress')
                              .doc(prevWeekId)
                              .get();

                          final prevStatus = prevDoc.data()?['status'] ?? '';
                          if (prevStatus != 'completed') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Cannot submit this week until previous week is complete."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }

                        if (formKey.currentState!.validate()) {
                          final responseText = responseController.text.trim();

                          await sessionDoc.set({
                            'response': responseText,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          setState(() {}); // Refresh UI
                        }
                      },
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  if (hasSubmitted)
                    const Text("\u2714 Response submitted",
                        style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
