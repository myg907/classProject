import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'week_screen.dart';
import 'progress_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final peopleRef = FirebaseFirestore.instance.collection('Weeks');

  List<QueryDocumentSnapshot> searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Weeks")),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Enter a week label", // clearer hint
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                print('Week searched for is: $value');

                peopleRef
                    .where("label", isEqualTo: value)  // <-- CORRECT field name
                    .get()
                    .then((result) {
                  setState(() => searchResults = result.docs);
                }).catchError((error) {
                  print('Error searching: $error');
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(child: _getBodyContent()),
          ],
        ),
      ),
    );
  }

  Widget _getBodyContent() {
    if (_controller.text.isEmpty) {
      return const Center(child: Text('Enter a search term to see results.'));
    }

    if (searchResults.isEmpty) {
      return const Center(child: Text('Your search did not find anything.'));
    }

    return ListView.builder(
  itemCount: searchResults.length,
  itemBuilder: (context, index) {
    final doc = searchResults[index];

    return ListTile(
      tileColor: index % 2 == 0 ? Colors.blue[100] : Colors.blueAccent,
      leading: const Icon(Icons.bookmark, size: 32),
      title: Text("${doc.get('label')}"),
      subtitle: Text("Order: ${doc.get('order')}"),
      trailing: Text("${doc.get('status')}"),
      onTap: () {
        final week = Week.fromDocument(doc);
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

  }
}

