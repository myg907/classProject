import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State variable that will refer to the profile image location.
  String? imageFile;

  // Get a reference to the storage bucket in the cloud
  var storageRef = FirebaseStorage.instance.ref();

  @override
  void initState() {
    super.initState();
    _getFileUrl();
  }

  // Load the user's profile if it exists
  _getFileUrl() async {
    try {
      ListResult result = await storageRef.child('profilepics').listAll();
      String uid = FirebaseAuth.instance.currentUser!.uid;
      for (Reference ref in result.items) {
        print(ref.name);
        if (ref.name.startsWith("$uid")) {
          imageFile = await ref.getDownloadURL();
          setState(() {});
        }
      }
    } on FirebaseException catch (e) {
      print("BAD");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Column(
        children: [
          if (imageFile == null) const Icon(Icons.account_circle, size: 72),
          // if (imageFile != null) Image.file(File(imageFile!), width: 250),
          if (imageFile != null) Image.network(imageFile!, width: 250),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () => _getImage(ImageSource.camera),
                  child: const Text("Camera")),
              ElevatedButton(
                  onPressed: () => _getImage(ImageSource.gallery),
                  child: const Text("Gallery")),
            ],
          )
        ],
      ),
    );
  }

  _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      print(image.path);

      // setState(() => imageFile = image.path);

      // Goal: rename the file to the user's ID.jpg
      // Extract the image file extension
      String fileExtension = '';
      int period = image.path.lastIndexOf('.');
      if (period > -1) {
        fileExtension = image.path.substring(period);
      }

      // Specify a filename that will be something like
      // <ourbucket>/profilepics/SOAIHFiug8sair.jpg (user's uid)
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final profileImageRef =
          storageRef.child("profilepics/${uid}$fileExtension");

      try {
        // upload the image file
        await profileImageRef.putFile(File(image.path));

        //Get a public url that we can download the image from
        imageFile = await profileImageRef.getDownloadURL();
        setState(() {});
      } on FirebaseException catch (e) {
        // Caught an exception from Firebase
        print("Failed with error ${e.message}");
      }
    }
  }
}
