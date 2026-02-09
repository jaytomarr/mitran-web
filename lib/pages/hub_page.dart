import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/navbar.dart';
import '../widgets/design_system.dart';
import '../providers/providers.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: const NavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Share Post Card
                  _SharePostCard(
                    controller: _controller,
                    loading: _loading,
                    onPost: _createPost,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Posts List
                  posts.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.forum_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('No posts yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text('Be the first to share an update!', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: items.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PostCard(post: p),
                        )).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) {
                      final msg = e.toString();
                      final isPerm = msg.contains('permission-denied');
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.error.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                            const SizedBox(height: 16),
                            Text(
                              isPerm ? 'Missing Firestore permissions.' : 'Error loading posts',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            GradientButton(
                              text: 'Retry',
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  try { await user.getIdToken(true); } catch (_) {}
                                }
                                ref.invalidate(postsProvider);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SharePostCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onPost;

  const _SharePostCard({
    required this.controller,
    required this.loading,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Share an Update',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "What's happening, Guardian?",
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
              filled: true,
              fillColor: const Color(0xFFF8F7FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GradientButton(
              text: 'Post',
              onPressed: loading ? null : onPost,
              loading: loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMM d').format(post.timestamp);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag + Author Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Tag chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
              ),
              // Author chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      backgroundImage: post.author.profilePictureUrl.isNotEmpty
                          ? NetworkImage(post.author.profilePictureUrl)
                          : null,
                      child: post.author.profilePictureUrl.isEmpty
                          ? Text(
                              post.author.username.isNotEmpty ? post.author.username[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.author.username.length > 12 
                          ? '${post.author.username.substring(0, 12)}...' 
                          : post.author.username,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                  ],
                ),
              ),
              // Time
              Text(
                timeStr,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Content
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}