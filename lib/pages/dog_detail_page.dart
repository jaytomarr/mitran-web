import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      body: SafeArea(
        child: dog.when(
          data: (d) {
            if (d.name.isEmpty && d.mainPhotoUrl.isEmpty) {
              return Center(child: Text('Mitran Record not found'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeSlideIn(
                child: ResponsiveContainer(
                  maxWidth: 1000,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView(
                      children: [
                        if (d.mainPhotoUrl.isNotEmpty) Image.network(d.mainPhotoUrl, fit: BoxFit.cover),
                        for (final p in d.photos) Image.network(p, fit: BoxFit.cover),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(d.name, style: Theme.of(context).textTheme.headlineMedium, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  GradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(spacing: 8, children: [
                          StatusBadge(text: d.vaccinationStatus ? 'Vaccinated' : 'Not Vaccinated', color: d.vaccinationStatus ? AppColors.success : AppColors.error),
                          StatusBadge(text: d.sterilizationStatus ? 'Sterilized' : 'Not Sterilized', color: d.sterilizationStatus ? AppColors.info : AppColors.warning),
                          if (d.readyForAdoption) const StatusBadge(text: 'Ready for Adoption', color: AppColors.secondary),
                        ]),
                        const SizedBox(height: 8),
                        Text('Area: ${d.area}', overflow: TextOverflow.ellipsis),
                        Text('Temperament: ${d.temperament}', overflow: TextOverflow.ellipsis),
                        if (d.healthNotes.isNotEmpty) Text('Health Notes: ${d.healthNotes}', overflow: TextOverflow.fade),
                        const SizedBox(height: 12),
                        if (d.readyForAdoption)
                          AccentButton(
                            text: 'Interested in Adopting?',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Contact Information'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Contact person: ${d.addedBy.username}'),
                                      Text('Email: ${d.addedBy.contactInfo.email}'),
                                      Text('Phone: ${d.addedBy.contactInfo.phone}'),
                                    ],
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}