import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/chatbot_api.dart';
import '../widgets/design_system.dart';

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
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: _ProfileNavBar(),
      ),
      body: profile.when(
        data: (p) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ResponsiveContainer(
                  maxWidth: 1000,
                  child: GradientBorderCard(
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      foregroundImage: p.profilePictureUrl.isNotEmpty ? NetworkImage(p.profilePictureUrl) : null,
                      child: Text(p.username.isNotEmpty ? p.username[0].toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.username, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Email: ${p.email}', overflow: TextOverflow.ellipsis),
                          Text('Phone: ${p.contactInfo.phone}', overflow: TextOverflow.ellipsis),
                          Text('City: ${p.city}', overflow: TextOverflow.ellipsis),
                          Text('Area: ${p.area}', overflow: TextOverflow.ellipsis),
                          Text('Type: ${p.userType}', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlineButtonX(text: 'Edit Profile', onPressed: () => _showEditor(context, p)),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          SessionManager(ChatbotApi()).clearSession();
                        } catch (_) {}
                        try {
                          final router = GoRouter.of(context);
                          await AuthService().signOut();
                          router.go('/');
                        } catch (_) {}
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'My Posts'),
                  Tab(text: 'My Mitrans'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(myPosts),
                    _buildDogsTab(myDogs),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildPostsTab(AsyncValue<List<dynamic>> posts) {
    return posts.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text("You haven't posted anything yet"));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return ListTile(title: Text(p.author.username), subtitle: Text(p.content));
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildDogsTab(AsyncValue<List<dynamic>> dogs) {
    return dogs.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text("You haven't added any dogs yet"));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final d = items[index];
            return ListTile(title: Text(d.name), subtitle: Text(d.area));
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
          title: const Text('Edit Profile'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormTextField(controller: _usernameController, labelText: 'Username'),
                  const SizedBox(height: 8),
                  Row(children: [
                    AccentButton(text: 'Upload New Picture', onPressed: _pickImage),
                  ]),
                  const SizedBox(height: 8),
                  AppFormTextField(controller: _phoneController, labelText: 'Contact Phone'),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 8),
                  AppFormTextField(controller: _cityController, labelText: 'City'),
                  const SizedBox(height: 8),
                  AppFormTextField(controller: _areaController, labelText: 'Area'),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _imageBytes = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            GradientButton(text: 'Save Changes', onPressed: _loading ? null : () => _save(context, current), loading: _loading),
          ],
        );
      },
    );
  }
}

class _ProfileNavBar extends StatelessWidget {
  const _ProfileNavBar();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('My Guardian Profile'),
      actions: [
        TextButton(onPressed: () => context.go('/hub'), child: const Text('The Mitran Hub')),
        TextButton(onPressed: () => context.go('/directory'), child: const Text('Mitran Directory')),
        TextButton(onPressed: () => context.go('/ai-care'), child: const Text('Mitran AI Care')),
        const SizedBox(width: 8),
      ],
    );
  }
}