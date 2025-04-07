import 'package:flutter/material.dart';
import 'progress_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// class WeekScreen extends StatelessWidget {
//   final Week week;

//   const WeekScreen({super.key, required this.week});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(week.label)),
//       body: Center(
//         child: Text(
//           week.label,
//           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: "Poppins"),
//         ),
//       ),
//     );
//   }
// }
// for the Week class

class WeekScreen extends StatelessWidget {
  final Week week;

  const WeekScreen({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final weeklyContentRef = FirebaseFirestore.instance
        .collection('Weeks')
        .doc(week.id)
        .collection('WeeklyContent')
        .orderBy('order');

    return Scaffold(
      appBar: AppBar(title: Text(week.label)),
      body: StreamBuilder<QuerySnapshot>(
        stream: weeklyContentRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final contentDocs = snapshot.data!.docs;

          if (contentDocs.isEmpty) {
            return const Center(child: Text("No content available."));
          }

          return ListView.builder(
            itemCount: contentDocs.length,
            itemBuilder: (context, index) {
              final data = contentDocs[index].data() as Map<String, dynamic>;
              final type = data['type'];
              final content = data['content'];
              final status = data['status'];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(type == 'question' ? "Question" : "Meditation"),
                  subtitle: Text(content),
                  trailing: Icon(
                    status == 'complete' ? Icons.check : Icons.radio_button_unchecked,
                    color: status == 'complete' ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
