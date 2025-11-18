import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../models/dog_filters.dart';
import '../models/dog_model.dart';
import '../widgets/navbar.dart';
import '../widgets/design_system.dart';

class DirectoryPage extends ConsumerWidget {
  const DirectoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogs = ref.watch(filteredDogsProvider);
    final filters = ref.watch(dogFiltersProvider);
    return Scaffold(
      appBar: const NavBar(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FadeSlideIn(
                child: ResponsiveContainer(
                  maxWidth: 1200,
                  child: GradientBorderCard(
                    child: Column(
                      children: [
                        AppSearchField(
                          hintText: 'Search by name, area, or Mitran ID',
                          onChanged: (v) => ref.read(searchTermProvider.notifier).state = v,
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          SelectableChip(
                            label: 'Vaccinated',
                            selected: filters.vaccinated,
                            onTap: () => ref.read(dogFiltersProvider.notifier).state = filters.copyWith(vaccinated: !filters.vaccinated),
                          ),
                          const SizedBox(width: 8),
                          SelectableChip(
                            label: 'Sterilized',
                            selected: filters.sterilized,
                            onTap: () => ref.read(dogFiltersProvider.notifier).state = filters.copyWith(sterilized: !filters.sterilized),
                          ),
                          const SizedBox(width: 8),
                          SelectableChip(
                            label: 'Ready for Adoption',
                            selected: filters.readyForAdoption,
                            onTap: () => ref.read(dogFiltersProvider.notifier).state = filters.copyWith(readyForAdoption: !filters.readyForAdoption),
                          ),
                          const Spacer(),
                          OutlineButtonX(
                            text: 'Clear Filters',
                            onPressed: () {
                              ref.read(searchTermProvider.notifier).state = '';
                              ref.read(dogFiltersProvider.notifier).state = const DogFilters(vaccinated: false, sterilized: false, readyForAdoption: false);
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FadeSlideIn(
                child: ResponsiveContainer(
                  maxWidth: 1200,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 4;
                      final w = constraints.maxWidth;
                      if (w < 600) {
                        crossAxisCount = 1;
                      } else if (w < 900) {
                        crossAxisCount = 2;
                      } else if (w < 1200) {
                        crossAxisCount = 3;
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3/4,
                        ),
                        itemCount: dogs.length,
                        itemBuilder: (context, index) {
                          final d = dogs[index];
                          return _DogCard(dog: d, onTap: () => context.go('/directory/${d.dogId}'));
                        },
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

class _DogCard extends StatelessWidget {
  final DogModel dog;
  final VoidCallback onTap;
  const _DogCard({required this.dog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GradientBorderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: dog.mainPhotoUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(dog.mainPhotoUrl, width: double.infinity, fit: BoxFit.cover))
                  : Container(height: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 8),
            Text(dog.name.isNotEmpty ? dog.name : 'Unknown', style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(dog.area, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              if (dog.vaccinationStatus) const StatusBadge(text: 'Vaccinated', color: AppColors.success),
              if (dog.sterilizationStatus) const StatusBadge(text: 'Sterilized', color: AppColors.info),
              if (dog.readyForAdoption) const StatusBadge(text: 'Ready for Adoption', color: AppColors.secondary),
            ]),
          ],
        ),
      ),
    );
  }
}