import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/navbar.dart';
import '../widgets/design_system.dart';
import '../providers/providers.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class HubPage extends ConsumerStatefulWidget {
  const HubPage({super.key});

  @override
  ConsumerState<HubPage> createState() => _HubPageState();
}

class _HubPageState extends ConsumerState<HubPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _createPost() async {
    final content = _controller.text.trim();
    if (content.isEmpty || content.length > 500) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profile = await FirestoreService().getUserProfile(user.uid);
      final post = PostModel(
        postId: '',
        content: content,
        author: PostAuthor(
          userId: user.uid,
          username: (profile?.username ?? user.displayName ?? 'Guardian'),
          profilePictureUrl: (profile?.profilePictureUrl ?? user.photoURL ?? ''),
        ),
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await FirestoreService().createPost(post, user.uid);
      _controller.clear();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authReady = ref.watch(authReadyProvider);
    final AsyncValue<List<PostModel>> posts = authReady.isLoading
        ? const AsyncValue<List<PostModel>>.loading()
        : ref.watch(postsProvider);
    return Scaffold(
      appBar: const NavBar(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FadeSlideIn(
                child: ResponsiveContainer(
                  maxWidth: 800,
                  child: GradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(controller: _controller, maxLength: 500, labelText: "What's happening, Guardian? Share an update or ask a question."),
                        const SizedBox(height: 8),
                        GradientButton(text: 'Post', onPressed: _loading ? null : _createPost, loading: _loading),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FadeSlideIn(
                child: ResponsiveContainer(
                  maxWidth: 800,
                  child: posts.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No posts yet'));
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final p = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.12),
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      foregroundImage: p.author.profilePictureUrl.isNotEmpty ? NetworkImage(p.author.profilePictureUrl) : null,
                                      child: Text(p.author.username.isNotEmpty ? p.author.username[0].toUpperCase() : '?'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(p.author.username, style: Theme.of(context).textTheme.titleMedium)),
                                    Text('${p.timestamp.hour}:${p.timestamp.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(p.content, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) {
                  final msg = e.toString();
                  final isPerm = msg.contains('permission-denied');
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPerm
                              ? 'Missing or insufficient Firestore permissions.'
                              : msg,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              try {
                                await user.getIdToken(true);
                              } catch (_) {}
                            }
                            ref.invalidate(postsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}