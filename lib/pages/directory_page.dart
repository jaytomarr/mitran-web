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
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header Card
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/icon.png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mitran Directory',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Find community dogs',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Search
                        TextField(
                          onChanged: (v) =>
                              ref.read(searchTermProvider.notifier).state = v,
                          decoration: InputDecoration(
                            hintText: 'Search by name, area, or Mitran ID',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F7FC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Filters
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(
                              label: 'Vaccinated',
                              selected: filters.vaccinated,
                              onTap: () =>
                                  ref
                                      .read(dogFiltersProvider.notifier)
                                      .state = filters.copyWith(
                                    vaccinated: !filters.vaccinated,
                                  ),
                            ),
                            _FilterChip(
                              label: 'Sterilized',
                              selected: filters.sterilized,
                              onTap: () =>
                                  ref
                                      .read(dogFiltersProvider.notifier)
                                      .state = filters.copyWith(
                                    sterilized: !filters.sterilized,
                                  ),
                            ),
                            _FilterChip(
                              label: 'Ready for Adoption',
                              selected: filters.readyForAdoption,
                              onTap: () =>
                                  ref
                                      .read(dogFiltersProvider.notifier)
                                      .state = filters.copyWith(
                                    readyForAdoption: !filters.readyForAdoption,
                                  ),
                            ),
                            if (filters.vaccinated ||
                                filters.sterilized ||
                                filters.readyForAdoption)
                              TextButton.icon(
                                onPressed: () {
                                  ref.read(searchTermProvider.notifier).state =
                                      '';
                                  ref
                                      .read(dogFiltersProvider.notifier)
                                      .state = const DogFilters(
                                    vaccinated: false,
                                    sterilized: false,
                                    readyForAdoption: false,
                                  );
                                },
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear all'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dogs Grid
                  dogs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  gradient: AppGradients.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No dogs found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try adjusting your filters',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 4;
                            double aspectRatio = 0.75;
                            final w = constraints.maxWidth;
                            if (w < 500) {
                              crossAxisCount = 2;
                              aspectRatio = 0.65;
                            } else if (w < 750) {
                              crossAxisCount = 2;
                              aspectRatio = 0.75;
                            } else if (w < 1000) {
                              crossAxisCount = 3;
                            }
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: aspectRatio,
                                  ),
                              itemCount: dogs.length,
                              itemBuilder: (context, index) {
                                final d = dogs[index];
                                return _DogCard(
                                  dog: d,
                                  onTap: () =>
                                      context.go('/directory/${d.dogId}'),
                                );
                              },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DogCard extends StatefulWidget {
  final DogModel dog;
  final VoidCallback onTap;
  const _DogCard({required this.dog, required this.onTap});

  @override
  State<_DogCard> createState() => _DogCardState();
}

class _DogCardState extends State<_DogCard> {
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
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: widget.dog.mainPhotoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            widget.dog.mainPhotoUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/icon.png',
                              height: 24,
                              width: 24,
                            ),
                          ),
                        ),
                ),
              ),
              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dog.name.isNotEmpty
                            ? widget.dog.name
                            : 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.dog.area,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (widget.dog.vaccinationStatus)
                            _IconChip(
                              icon: Icons.vaccines,
                              color: AppColors.success,
                              tooltip: 'Vaccinated',
                            ),
                          if (widget.dog.sterilizationStatus)
                            _IconChip(
                              icon: Icons.medical_services,
                              color: AppColors.info,
                              tooltip: 'Sterilized',
                            ),
                          if (widget.dog.readyForAdoption)
                            _IconChip(
                              icon: Icons.favorite,
                              color: AppColors.accent,
                              tooltip: 'Ready for Adoption',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  const _IconChip({
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
