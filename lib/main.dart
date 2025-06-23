import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maraudr_app/core/theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/router.dart';

void main() {
  runApp(MaraudrApp());
}

class MaraudrApp extends StatelessWidget {
  MaraudrApp({super.key});

  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(_authRepository)..add(AuthCheckRequested()),
          ),
        ],
        child: const AppRouter(),
      ),
    );
  }
}
