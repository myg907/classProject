import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_screen.dart';

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
      order: data['order'],
      label: data['label'] ,
      status: data['status'] ,
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Progress Screen")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Weeks')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final weeks = snapshot.data!.docs
              .map((doc) => Week.fromDocument(doc))
              .toList();

          if (weeks.isEmpty) {
            return const Center(child: Text("No weeks found."));
          }

          return ListView.builder(
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
          );
        },
      ),
    );
  }

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
