import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../association/bloc/association_selector_bloc.dart';
import '../../association/bloc/association_selector_event.dart';
import '../../association/bloc/association_selector_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Maraudr",
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            BlocBuilder<AssociationSelectorBloc, AssociationSelectorState>(
              builder: (context, state) {
                if (state is AssociationSelectorLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AssociationSelectorLoaded &&
                    state.associations.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Choisir une association",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: state.selectedId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: state.associations.map((assoc) {
                          return DropdownMenuItem(
                            value: assoc['id'] as String,
                            child: Text(assoc['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<AssociationSelectorBloc>()
                                .add(SelectAssociation(value));
                          }
                        },
                      ),
                    ],
                  );
                } else if (state is AssociationSelectorError) {
                  return Text(
                    'Erreur : ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isPortrait = constraints.maxWidth < 600;
                  final crossAxisCount = isPortrait ? 1 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isPortrait ? 3.2 : 2.8,
                    children: [
                      _ActionCard(
                        label: 'Stock +',
                        subtitle: 'Ajouter un article',
                        icon: LucideIcons.packagePlus,
                        onTap: () => context.go('/stock'),
                      ),
                      _ActionCard(
                        label: 'Stock -',
                        subtitle: 'Enlever un article',
                        icon: LucideIcons.packageMinus,
                        onTap: () => context.go('/stock/remove'),
                      ),
                      _ActionCard(
                        label: 'Signalement',
                        subtitle: 'Envoyer une position',
                        icon: LucideIcons.mapPin,
                        onTap: () => context.go('/geo'),
                      ),
                      _ActionCard(
                        label: 'Déconnexion',
                        subtitle: 'Se déconnecter',
                        icon: LucideIcons.logOut,
                        color: Colors.redAccent,
                        onTap: () =>
                            context.read<AuthBloc>().add(AuthLogoutRequested()),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: effectiveColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
