import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'week_screen.dart';
import 'progress_screen.dart';
import 'dart:developer';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Search Weeks",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 181, 184, 184),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Login.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: .5)),
          Padding(
            padding: const EdgeInsets.only(
              top: kToolbarHeight + 24,
              left: 8,
              right: 8,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Enter a week label",
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() => searchResults = []);
                      return;
                    }

                    peopleRef
                        .where("label", isEqualTo: value)
                        .get()
                        .then((result) {
                      setState(() => searchResults = result.docs);
                    }).catchError((error) {
                      log('Error searching: $error');
                    });
                  },
                ),
                const SizedBox(height: 20),
                Expanded(child: _getBodyContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBodyContent() {
    if (_controller.text.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term to see results. Please start your search with a capital letter.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Your search did not find anything.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final doc = searchResults[index];
        return Card(
          color: Colors.white.withValues(alpha: .8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.bookmark, size: 32, color: Colors.teal),
            title: Text(doc.get('label')),
            subtitle: Text("Order: ${doc.get('order')}"),
            trailing: Text(doc.get('status')),
            onTap: () {
              final week = Week.fromDocument(doc);
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
  }
}
