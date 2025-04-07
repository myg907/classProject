import 'package:flutter/material.dart';
import 'progress_screen.dart';

class WeekScreen extends StatelessWidget {
  final Week week;

  const WeekScreen({required this.week, super.key});

  @override
  Widget build(BuildContext context) {
    // Use week.id to fetch WeeklyContent from Firestore here
    return Scaffold(
      appBar: AppBar(title: Text(week.label)),
      body: Center(child: Text("Contents for ${week.label}")),
    );
  }
}
