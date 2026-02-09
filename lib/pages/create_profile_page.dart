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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Your Guardian Profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GradientBorderCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, Guardian!', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text(
                        'This is how you\'ll be known in the Mitran community. Your contact info will only be shared when you list a dog for adoption.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                        ),
                      ],
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 16),
                      Row(children: [
                        AccentButton(text: 'Upload Profile Picture', onPressed: _pickImage),
                        const SizedBox(width: 16),
                        if (_imageBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_imageBytes!, width: 64, height: 64, fit: BoxFit.cover),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      AppFormTextField(
                        controller: _phoneController,
                        labelText: 'Contact Phone (for adoption inquiries only)',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Contact phone is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: AppFormTextField(controller: _cityController, labelText: 'City')),
                          const SizedBox(width: 16),
                          Expanded(child: AppFormTextField(controller: _areaController, labelText: 'Area')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _userType,
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
                      const SizedBox(height: 32),
                      GradientButton(
                        text: 'Become a Guardian',
                        onPressed: _loading ? null : _submit,
                        fullWidth: true,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}