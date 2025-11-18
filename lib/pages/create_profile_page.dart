import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/contact_info.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/design_system.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  String _userType = 'Volunteer';
  Uint8List? _imageBytes;
  bool _usernameAvailable = true;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _imageBytes = result.files.single.bytes);
    }
  }

  Future<void> _checkUsername(String value) async {
    if (value.trim().isEmpty) return;
    final available = await FirestoreService().isUsernameAvailable(value.trim());
    setState(() => _usernameAvailable = available);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final model = UserModel(
        userId: user.uid,
        email: user.email ?? '',
        username: _usernameController.text.trim(),
        profilePictureUrl: '',
        contactInfo: ContactInfo(phone: _phoneController.text.trim(), email: user.email ?? ''),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        userType: _userType,
        postIds: const [],
        dogIds: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await FirestoreService().createUserProfile(model);
      if (_imageBytes != null) {
        try {
          final imageUrl = await FirestoreService().uploadProfilePictureBytes(_imageBytes!, user.uid);
          await FirestoreService().updateUserProfile(user.uid, {'profilePictureUrl': imageUrl});
        } catch (_) {
          // Image upload failure should not block profile creation; user can update later
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile created')));
      context.go('/hub');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Guardian Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 4),
                const Text('This is how you\'ll be known in the Mitran community. Your contact info will only be shared when you list a dog for adoption.'),
                const SizedBox(height: 12),
                AppFormTextField(
                  controller: _usernameController,
                  labelText: 'Public Username (e.g., "DelhiDogGuardian")',
                  onChanged: _checkUsername,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username required';
                    if (!_usernameAvailable) return 'Username not available';
                    if (v.trim().length < 3 || v.trim().length > 20) return '3-20 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(children: [
                  AccentButton(text: 'Upload Profile Picture', onPressed: _pickImage),
                  const SizedBox(width: 12),
                  if (_imageBytes != null)
                    SizedBox(width: 64, height: 64, child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
                ]),
                const SizedBox(height: 12),
                AppFormTextField(
                  controller: _phoneController,
                  labelText: 'Contact Phone (for adoption inquiries only)',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Contact phone is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppFormTextField(controller: _cityController, labelText: 'City'),
                const SizedBox(height: 12),
                AppFormTextField(controller: _areaController, labelText: 'Area'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _userType,
                  items: const [
                    DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer')),
                    DropdownMenuItem(value: 'Feeder', child: Text('Feeder')),
                    DropdownMenuItem(value: 'NGO Member', child: Text('NGO Member')),
                    DropdownMenuItem(value: 'Citizen', child: Text('Citizen')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _userType = v ?? 'Volunteer'),
                  decoration: const InputDecoration(labelText: 'User Type'),
                ),
                const SizedBox(height: 20),
                GradientButton(text: 'Become a Guardian', onPressed: _loading ? null : _submit, fullWidth: true, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}