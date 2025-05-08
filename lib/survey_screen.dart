import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SurveyScreen extends StatefulWidget {
  final String surveyId;

  const SurveyScreen({super.key, required this.surveyId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorText;
  String? _surveyUrl;
  String? _expectedCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurveyData();
  }

  Future<void> _fetchSurveyData() async {
    final doc = await FirebaseFirestore.instance
        .collection('Surveys')
        .doc(widget.surveyId)
        .get();

    if (doc.exists) {
      setState(() {
        _surveyUrl = doc['surveyURL'];
        _expectedCode = doc['expectedCode'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _surveyUrl = null;
        _expectedCode = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitCode() async {
    final input = _codeController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _errorText = 'Please enter a code.';
      });
      return;
    }

    if (input != _expectedCode) {
      setState(() {
        _errorText = 'Incorrect code. Please try again.';
      });
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('SurveyProgress')
        .doc(widget.surveyId)
        .set({'completed': true, 'timestamp': FieldValue.serverTimestamp()});
    if (!mounted) return;
    Navigator.of(context).pop(true); // modal returns "true" for completed
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Complete Survey",
          style: TextStyle(fontSize: 22, fontFamily: 'Poppins')),
      content: _isLoading
          ? const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Week survey question goes here.\n\nLink:",
                    style: TextStyle(fontFamily: 'Poppins')),
                if (_surveyUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        _surveyUrl!,
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                TextField(
                  cursorColor: Colors.green,
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Enter Completion Code',
                    labelStyle:
                        TextStyle(color: const Color.fromARGB(255, 13, 30, 13)),
                    errorText: _errorText,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // allow dismiss
          child: const Text("Dismiss",
              style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
        ),
        ElevatedButton(
          onPressed: _submitCode,
          child: const Text("Submit",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.black,
              )),
        ),
      ],
    );
  }
}
