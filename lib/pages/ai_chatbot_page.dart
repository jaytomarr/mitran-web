import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../screens/chat_screen.dart';

class AiChatbotPage extends StatelessWidget {
  const AiChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Health Chat', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('Ask about dog health, behavior, nutrition, or first aid. Our AI is here to help.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  const Expanded(child: ChatScreen(embedded: true)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}