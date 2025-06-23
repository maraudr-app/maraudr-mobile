import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../association/bloc/association_selector_bloc.dart';
import '../../association/bloc/association_selector_event.dart';
import '../../association/bloc/association_selector_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BlocBuilder<AssociationSelectorBloc, AssociationSelectorState>(
              builder: (context, state) {
                if (state is AssociationSelectorLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AssociationSelectorLoaded) {
                  // Ensure there's a selected ID and associations list is not empty
                  if (state.selectedId == null || state.associations.isEmpty) {
                    return const SizedBox.shrink(); // Or show an error/message
                  }

                  return DropdownButton<String>(
                    isExpanded: true,
                    // Now, state.selectedId should always be non-null if associations exist
                    value: state.selectedId,
                    hint: const Text("Sélectionnez une association"),
                    items: state.associations.map((assoc) {
                      return DropdownMenuItem(
                        value: assoc['id'] as String,
                        child: Text(assoc['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AssociationSelectorBloc>().add(SelectAssociation(value));
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => context.go('/stock'),
              icon: const Icon(Icons.inventory),
              label: const Text('Ajouter un item à votre stock'),
              style: buttonStyle,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/geo'),
              icon: const Icon(Icons.location_on),
              label: const Text('Envoyer une signalisation'),
              style: buttonStyle,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}