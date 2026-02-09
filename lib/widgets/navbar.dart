import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/session_manager.dart';
import '../services/chatbot_api.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'design_system.dart';

class NavBar extends StatefulWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  UserModel? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await FirestoreService().getUserProfile(user.uid);
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isWide = MediaQuery.of(context).size.width > 800;
    
    // Use Firestore profile picture, fallback to Firebase Auth photo
    final photoUrl = _userProfile?.profilePictureUrl.isNotEmpty == true 
        ? _userProfile!.profilePictureUrl 
        : user?.photoURL;
    
    return AppBar(
      toolbarHeight: 80,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 24,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Row(
        children: [
          // Logo
          InkWell(
            onTap: () => context.go('/hub'),
            borderRadius: BorderRadius.circular(50),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/icon.png', height: 24, width: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mitran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isWide) ...[
          _NavLink(text: 'Hub', route: '/hub'),
          _NavLink(text: 'Directory', route: '/directory'),
          _NavLink(text: 'AI Care', route: '/ai-care'),
          const SizedBox(width: 8),
        ],
        PopupMenuButton<String>(
          offset: const Offset(0, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl))
                  : const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
          ),
          onSelected: (v) {
            if (v == 'profile') context.go('/profile');
            if (v == 'hub' && !isWide) context.go('/hub');
            if (v == 'directory' && !isWide) context.go('/directory');
            if (v == 'ai-care' && !isWide) context.go('/ai-care');
            if (v == 'logout') {
              SessionManager(ChatbotApi()).clearSession();
              FirebaseAuth.instance.signOut().then((_) {
                context.go('/');
              });
            }
          },
          itemBuilder: (context) => [
            if (!isWide) ...[
              const PopupMenuItem(value: 'hub', child: Row(children: [Icon(Icons.home_outlined, size: 20), SizedBox(width: 12), Text('Hub')])),
              const PopupMenuItem(value: 'directory', child: Row(children: [Icon(Icons.list_alt_outlined, size: 20), SizedBox(width: 12), Text('Directory')])),
              const PopupMenuItem(value: 'ai-care', child: Row(children: [Icon(Icons.smart_toy_outlined, size: 20), SizedBox(width: 12), Text('AI Care')])),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem(
              value: 'profile',
              child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 12), Text('My Profile')]),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(children: [Icon(Icons.logout, size: 20, color: AppColors.error), SizedBox(width: 12), Text('Logout', style: TextStyle(color: AppColors.error))]),
            ),
          ],
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final String route;
  const _NavLink({required this.text, required this.route});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isActive = currentRoute.startsWith(route);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => context.go(route),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
          textStyle: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: Text(text),
      ),
    );
  }
}