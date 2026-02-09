import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import '../services/chatbot_api.dart';
import '../widgets/design_system.dart';
import '../widgets/navbar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  String _userType = 'Volunteer';
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _save(BuildContext ctx, UserModel current) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nav = Navigator.of(ctx);
      final messenger = ScaffoldMessenger.of(ctx);
      final user = FirebaseAuth.instance.currentUser!;
      String imageUrl = current.profilePictureUrl;
      if (_imageBytes != null) {
        if (current.profilePictureUrl.isNotEmpty) {
          await FirestoreService().deleteImageFromUrl(current.profilePictureUrl);
        }
        imageUrl = await FirestoreService().uploadProfilePictureBytes(_imageBytes!, user.uid);
      }
      final phoneVal = _phoneController.text.trim().isEmpty ? current.contactInfo.phone : _phoneController.text.trim();
      final updates = {
        'username': _usernameController.text.trim(),
        'profilePictureUrl': imageUrl,
        'contactInfo': {
          'phone': phoneVal,
          'email': user.email ?? '',
        },
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'userType': _userType,
      };
      await FirestoreService().updateUserProfile(user.uid, updates);
      await FirestoreService().updateUserDataInPosts(user.uid, updates['username'] as String, imageUrl);
      ref.invalidate(userProfileProvider(user.uid));
      setState(() {
        _imageBytes = null;
      });
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profile = ref.watch(userProfileProvider(uid));
    final myPosts = ref.watch(userPostsProvider(uid));
    final myDogs = ref.watch(userDogsProvider(uid));
    
    return Scaffold(
      appBar: const NavBar(),
      backgroundColor: const Color(0xFFF8F7FC),
      body: profile.when(
        data: (p) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.primary,
                            ),
                            child: p.profilePictureUrl.isNotEmpty
                                ? ClipOval(child: Image.network(p.profilePictureUrl, fit: BoxFit.cover))
                                : Center(
                                    child: Text(
                                      p.username.isNotEmpty ? p.username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
                                const SizedBox(height: 8),
                                _InfoRow(icon: Icons.email_outlined, text: p.email),
                                _InfoRow(icon: Icons.phone_outlined, text: p.contactInfo.phone),
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  _Badge(text: p.city, color: AppColors.primary),
                                  _Badge(text: p.area, color: AppColors.info),
                                  _Badge(text: p.userType, color: AppColors.accent),
                                ]),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showEditor(context, p),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tabs Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: const [
                              Tab(text: 'My Posts'),
                              Tab(text: 'My Mitrans'),
                            ],
                          ),
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildPostsTab(myPosts),
                                _buildDogsTab(myDogs),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildPostsTab(AsyncValue<List<dynamic>> posts) {
    return posts.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 40, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("You haven't posted anything yet", style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(p.author.username.isNotEmpty ? p.author.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text(p.author.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildDogsTab(AsyncValue<List<dynamic>> dogs) {
    return dogs.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/icon.png', height: 40, width: 40),
                ),
                const SizedBox(height: 12),
                const Text("You haven't added any dogs yet", style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final d = items[index];
            return InkWell(
              onTap: () => context.go('/directory/${d.dogId}'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset('assets/icon.png', height: 20, width: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(d.area, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  void _showEditor(BuildContext context, UserModel current) {
    _imageBytes = null;
    _usernameController.text = current.username;
    _phoneController.text = current.contactInfo.phone;
    _cityController.text = current.city;
    _areaController.text = current.area;
    _userType = current.userType;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FormField(controller: _usernameController, label: 'Username'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload New Picture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormField(controller: _phoneController, label: 'Contact Phone'),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                  const SizedBox(height: 16),
                  _FormField(controller: _cityController, label: 'City'),
                  const SizedBox(height: 16),
                  _FormField(controller: _areaController, label: 'Area'),
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
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      filled: true,
                      fillColor: const Color(0xFFF8F7FC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _imageBytes = null);
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _loading ? null : () => _save(context, current),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _FormField({required this.controller, required this.label});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F7FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}