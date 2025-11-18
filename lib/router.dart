import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/landing_page.dart';
import 'pages/create_profile_page.dart';
import 'pages/hub_page.dart';
import 'pages/directory_page.dart';
import 'pages/dog_detail_page.dart';
import 'pages/ai_care_page.dart';
import 'pages/ai_chatbot_page.dart';
import 'pages/ai_disease_scan_page.dart';
import 'pages/profile_page.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final authed = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;
      final isProtected = loc == '/hub' || loc == '/profile' || loc == '/ai-care' || loc.startsWith('/ai-care/') || loc.startsWith('/directory');

      if (!authed) {
        if (isProtected) return '/';
        return null;
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final hasProfile = userSnap.exists;

      if (!hasProfile) {
        if (loc != '/create-profile') return '/create-profile';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingPage()),
      GoRoute(path: '/create-profile', builder: (context, state) => const CreateProfilePage()),
      GoRoute(path: '/hub', builder: (context, state) => const HubPage()),
      GoRoute(path: '/directory', builder: (context, state) => const DirectoryPage()),
      GoRoute(path: '/directory/:dogId', builder: (context, state) {
        final dogId = state.pathParameters['dogId']!;
        return DogDetailPage(dogId: dogId);
      }),
      GoRoute(path: '/ai-care', builder: (context, state) => const AiCarePage()),
      GoRoute(path: '/ai-care/chatbot', builder: (context, state) => const AiChatbotPage()),
      GoRoute(path: '/ai-care/disease-scan', builder: (context, state) => const AiDiseaseScanPage()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    ],
  );
}
