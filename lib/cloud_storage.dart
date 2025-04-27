import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'dart:developer';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? imageFile;
  final storageRef = FirebaseStorage.instance.ref();

  @override
  void initState() {
    super.initState();
    _getFileUrl();
  }

  Future<void> _getFileUrl() async {
    try {
      ListResult result = await storageRef.child('profilepics').listAll();
      String uid = FirebaseAuth.instance.currentUser!.uid;
      for (Reference ref in result.items) {
        if (ref.name.startsWith(uid)) {
          final url = await ref.getDownloadURL();
          setState(() {
            imageFile = url;
          });
          break;
        }
      }
    } on FirebaseException catch (e) {
      log('Error fetching profile image: ${e.message}');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        String extension = image.path.split('.').last;
        final profileImageRef = storageRef.child("profilepics/$uid.$extension");

        await profileImageRef.putFile(File(image.path));
        final url = await profileImageRef.getDownloadURL();

        setState(() {
          imageFile = url;
        });
      } on FirebaseException catch (e) {
        log('Failed uploading image: ${e.message}');
      }
    }
  }

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
          "Your Profile",
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
          Container(color: Colors.black.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.only(
                top: kToolbarHeight + 24), // a little below the AppBar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (imageFile == null)
                  const Icon(Icons.account_circle,
                      size: 120, color: Colors.white)
                else
                  ClipOval(
                    child: Image.network(
                      imageFile!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () => _getImage(ImageSource.camera),
                      child: const Text("Camera",
                          style: TextStyle(fontFamily: 'Poppins')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () => _getImage(ImageSource.gallery),
                      child: const Text("Gallery",
                          style: TextStyle(fontFamily: 'Poppins')),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .15),
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
                          content: Text("Are you sure you want to log out?",
                              style: TextStyle(fontFamily: 'Poppins')),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text("Cancel",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins')),
                            ),
                            TextButton(
                              onPressed: () {
                                // Perform sign out and navigate
                                FirebaseAuth.instance.signOut();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: Text("Yes",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontFamily: 'Poppins')),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
