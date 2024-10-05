import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  User? currentUser;
  String _profilePictureUrl = "";
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _loadUserProfile();
  }

  // Function to load user profile (including profile picture) from Firestore
  Future<void> _loadUserProfile() async {
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        setState(() {
          _profilePictureUrl = userDoc.data()?['profilePictureUrl'];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _profilePictureUrl = ""; // Reset URL to show selected image immediately
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  // Function to upload the profile image to Firebase Storage and save URL to Firestore
  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() {
      _isUploading = true; // Show loading indicator
    });

    try {
      // Upload the image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profilePictures')
          .child('${currentUser!.uid}.jpg');

      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot storageSnapshot = await uploadTask;

      // Get the image URL after upload
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      // Save the image URL in Firestore under user's profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'profilePictureUrl': downloadUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );

      setState(() {
        _profilePictureUrl = downloadUrl;
        _profileImage = null; // Clear the selected image
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_profileImage);
    print(_profilePictureUrl);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 136, 217, 255),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfilePicture(),
              const SizedBox(height: 16),
              _buildUploadButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build the profile picture section
  Widget _buildProfilePicture() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 80,
          backgroundImage: _profileImage != null
              ? FileImage(_profileImage!)
              : _profilePictureUrl.isEmpty
                  ? const AssetImage('assets/profile_placeholder.jpeg')
                      as ImageProvider
                  : NetworkImage(_profilePictureUrl),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _pickImage,
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.camera_alt, color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }

  // Widget to build the upload button
  Widget _buildUploadButton() {
    return Column(
      children: [
        _isUploading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _uploadProfilePicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Upload Profile Picture'),
              ),
        const SizedBox(height: 16),
        if (_profileImage != null)
          Text(
            'Selected image: ${_profileImage!.path.split('/').last}',
            style: const TextStyle(color: Colors.white),
          ),
      ],
    );
  }
}
