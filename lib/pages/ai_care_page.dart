import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import 'package:go_router/go_router.dart';

class AiCarePage extends StatefulWidget {
  const AiCarePage({super.key});

  @override
  State<AiCarePage> createState() => _AiCarePageState();
}

class _AiCarePageState extends State<AiCarePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mitran AI Care', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 16),
                    Wrap(spacing: 24, runSpacing: 24, children: [
                      _AiOption(
                        title: 'AI Health Chat',
                        description: 'Ask about dog health, behavior, nutrition, or first aid',
                        icon: Icons.chat_bubble_outline,
                        onTap: () => context.go('/ai-care/chatbot'),
                      ),
                      _AiOption(
                        title: 'AI Disease Scan',
                        description: 'Upload a photo for a preliminary analysis',
                        icon: Icons.medical_information_outlined,
                        onTap: () => context.go('/ai-care/disease-scan'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  const _AiOption({required this.title, required this.description, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 120,
      child: Card(
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.25),
        surfaceTintColor: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(description, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}