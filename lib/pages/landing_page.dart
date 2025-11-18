import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 12,
        leadingWidth: 56,
        leading: const Icon(Icons.pets),
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Mitran'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ElevatedButton(onPressed: () => _showJoinDialog(context), child: const Text('Get Started')),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Become a Friend, Be a Guardian',
                          style: Theme.of(context).textTheme.displayMedium,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '“Mitran” means friend. Welcome to a network of compassionate Guardians working to give our stray friends a safer, healthier life.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(onPressed: () => _showJoinDialog(context), child: const Text('Join the Community')),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Wrap(
                      spacing: 28,
                      runSpacing: 28,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: 340,
                          height: 220,
                          child: Card(
                            elevation: 12,
                            shadowColor: Colors.black.withOpacity(0.25),
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [const Icon(Icons.qr_code_2, size: 32), const SizedBox(width: 12), Text('Give Them an Identity', style: Theme.of(context).textTheme.titleLarge)]),
                                  const SizedBox(height: 12),
                                  Text('Scan Mitran QR collars to create digital records. Track health, vaccinations, and sterilization to make every dog visible.', style: Theme.of(context).textTheme.bodyMedium),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 340,
                          height: 220,
                          child: Card(
                            elevation: 12,
                            shadowColor: Colors.black.withOpacity(0.25),
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [const Icon(Icons.groups, size: 32), const SizedBox(width: 12), Text('Your Community & AI Tools', style: Theme.of(context).textTheme.titleLarge)]),
                                  const SizedBox(height: 12),
                                  Text('Share updates in The Mitran Hub, get AI-powered health advice from Mitran AI Care, and help find loving homes.', style: Theme.of(context).textTheme.bodyMedium),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 340,
                          height: 220,
                          child: Card(
                            elevation: 12,
                            shadowColor: Colors.black.withOpacity(0.25),
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [const Icon(Icons.pets, size: 32), const SizedBox(width: 12), Text('Mitran Directory', style: Theme.of(context).textTheme.titleLarge)]),
                                  const SizedBox(height: 12),
                                  Text('Browse the central, searchable database of registered dogs and see status at a glance.', style: Theme.of(context).textTheme.bodyMedium),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool loading = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Join the Network'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome to Mitran. Sign in with Google to join the Guardian network. New members will set up their profile first.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                        setState(() {
                          loading = true;
                          error = null;
                        });
                        try {
                          final router = GoRouter.of(context);
                          final nav = Navigator.of(ctx);
                          final cred = await AuthService().signInWithGoogle();
                          final uid = cred.user!.uid;
                          final profile = await FirestoreService().getUserProfile(uid);
                          nav.pop();
                          if (profile == null) {
                            router.go('/create-profile');
                          } else {
                            router.go('/hub');
                          }
                        } catch (e) {
                          setState(() => error = e.toString());
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                      child: Text(loading ? 'Connecting…' : 'Sign in with Google'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ],
            );
          },
        );
      },
    );
  }
}