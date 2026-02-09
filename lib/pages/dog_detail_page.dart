import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../widgets/navbar.dart';
import '../widgets/design_system.dart';

class DogDetailPage extends ConsumerWidget {
  final String dogId;
  const DogDetailPage({super.key, required this.dogId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dog = ref.watch(dogProvider(dogId));
    return Scaffold(
      appBar: const NavBar(),
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: dog.when(
          data: (d) {
            if (d.name.isEmpty && d.mainPhotoUrl.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(48),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/icon.png', height: 48, width: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text('Mitran Record not found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back Button
                      _BackButton(
                        label: 'Back to Directory',
                        onTap: () => context.go('/directory'),
                      ),
                      const SizedBox(height: 16),
                      // Image Gallery Card
                      Container(
                        height: 350,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: PageView(
                            children: [
                              if (d.mainPhotoUrl.isNotEmpty)
                                Image.network(d.mainPhotoUrl, fit: BoxFit.cover, width: double.infinity),
                              for (final p in d.photos)
                                Image.network(p, fit: BoxFit.cover, width: double.infinity),
                              if (d.mainPhotoUrl.isEmpty && d.photos.isEmpty)
                                Container(
                                  color: const Color(0xFFF8F7FC),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        gradient: AppGradients.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset('assets/icon.png', height: 64, width: 64),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and Adopt Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(d.area, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (d.readyForAdoption)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.favorite, color: Colors.white, size: 16),
                                        SizedBox(width: 6),
                                        Text('Adopt Me!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Status Chips
                            Wrap(spacing: 10, runSpacing: 8, children: [
                              _StatusChip(
                                icon: Icons.vaccines,
                                text: d.vaccinationStatus ? 'Vaccinated' : 'Not Vaccinated',
                                color: d.vaccinationStatus ? AppColors.success : AppColors.error,
                              ),
                              _StatusChip(
                                icon: Icons.medical_services,
                                text: d.sterilizationStatus ? 'Sterilized' : 'Not Sterilized',
                                color: d.sterilizationStatus ? AppColors.info : AppColors.warning,
                              ),
                            ]),
                            
                            const SizedBox(height: 24),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 20),
                            
                            // Details
                            _DetailRow(label: 'Temperament', value: d.temperament),
                            if (d.healthNotes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _DetailRow(label: 'Health Notes', value: d.healthNotes),
                            ],
                          ],
                        ),
                      ),
                      
                      // Adoption CTA Card
                      if (d.readyForAdoption) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.favorite_outline, color: AppColors.accent, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Interested in adopting?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('Contact ${d.addedBy.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _showContactDialog(context, d),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                ),
                                child: const Text('Contact'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, dynamic d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Contact Guardian', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContactRow(icon: Icons.person_outline, label: 'Name', value: d.addedBy.username),
            _ContactRow(icon: Icons.email_outlined, label: 'Email', value: d.addedBy.contactInfo.email),
            _ContactRow(icon: Icons.phone_outlined, label: 'Phone', value: d.addedBy.contactInfo.phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatusChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, color: AppColors.text, height: 1.4)),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BackButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}