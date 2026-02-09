import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../widgets/design_system.dart';

class AiCarePage extends StatelessWidget {
  const AiCarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 20),
                        Text('Mitran AI Care', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        const Text(
                          'Advanced AI tools to help Guardians care for their community dogs.',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AiOption(
                                title: 'AI Health Chat',
                                description: 'Ask specific questions about dog health, behavior, nutrition, or immediate first aid advice.',
                                icon: Icons.chat_bubble_outline,
                                color: AppColors.primary,
                                onTap: () => context.go('/ai-care/chatbot'),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _AiOption(
                                title: 'AI Disease Scan',
                                description: 'Upload a photo of a skin condition or injury for a preliminary AI analysis and guidance.',
                                icon: Icons.medical_information_outlined,
                                color: AppColors.accent,
                                onTap: () => context.go('/ai-care/disease-scan'),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _AiOption(
                              title: 'AI Health Chat',
                              description: 'Ask specific questions about dog health, behavior, nutrition, or immediate first aid advice.',
                              icon: Icons.chat_bubble_outline,
                              color: AppColors.primary,
                              onTap: () => context.go('/ai-care/chatbot'),
                            ),
                            const SizedBox(height: 16),
                            _AiOption(
                              title: 'AI Disease Scan',
                              description: 'Upload a photo of a skin condition or injury for a preliminary AI analysis and guidance.',
                              icon: Icons.medical_information_outlined,
                              color: AppColors.accent,
                              onTap: () => context.go('/ai-care/disease-scan'),
                            ),
                          ],
                        );
                      }
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

class _AiOption extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AiOption({
    required this.title, 
    required this.description, 
    required this.icon, 
    required this.color, 
    required this.onTap
  });

  @override
  State<_AiOption> createState() => _AiOptionState();
}

class _AiOptionState extends State<_AiOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isHovered ? widget.color : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.color.withOpacity(0.12) : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, size: 28, color: widget.color),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: _isHovered ? widget.color : AppColors.textSecondary.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 8),
              Text(widget.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}