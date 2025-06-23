import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/association/bloc/association_selector_event.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/router.dart';
import 'features/association/bloc/association_selector_bloc.dart';
import 'features/association/data/association_repository.dart';

void main() {
  runApp(MaraudrApp());
}

class MaraudrApp extends StatelessWidget {
  MaraudrApp({super.key});

  final AuthRepository _authRepository = AuthRepository();
  final AssociationRepository _associationRepository = AssociationRepository();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _associationRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(_authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => AssociationSelectorBloc(_associationRepository)..add(LoadAssociations()),
          ),
        ],
        child: const AppRouter(),
      ),
    );
  }
}
