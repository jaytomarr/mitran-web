import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/session_manager.dart';
import '../services/chatbot_api.dart';
import '../widgets/design_system.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return AppBar(
      title: const Text('The Mitran Hub'),
      actions: [
        TextButton(
          style: ButtonStyle(foregroundColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.hovered) ? AppColors.primary : null)),
          onPressed: () => context.go('/hub'),
          child: const Text('The Mitran Hub'),
        ),
        TextButton(
          style: ButtonStyle(foregroundColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.hovered) ? AppColors.primary : null)),
          onPressed: () => context.go('/directory'),
          child: const Text('Mitran Directory'),
        ),
        TextButton(
          style: ButtonStyle(foregroundColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.hovered) ? AppColors.primary : null)),
          onPressed: () => context.go('/ai-care'),
          child: const Text('Mitran AI Care'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (v) {
            if (v == 'profile') context.go('/profile');
            if (v == 'logout') {
              SessionManager(ChatbotApi()).clearSession();
              FirebaseAuth.instance.signOut().then((_) {
                context.go('/');
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text('My Guardian Profile')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
      leading: IconButton(onPressed: () => context.go('/hub'), icon: const Icon(Icons.pets)),
      bottom: user == null ? null : null,
    );
  }
}