import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maraudr_app/core/theme.dart';
import 'package:maraudr_app/features/stock/screens/remove_stock_screen.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/geo/screens/geo_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/stock/screens/stock_screen.dart';
import '../splash_screen.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authBloc = context.read<AuthBloc>();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/stock',
          builder: (context, state) => const StockScreen(),
        ),
        GoRoute(
          path: '/geo',
          builder: (context, state) => const GeoScreen(),
        ),
        GoRoute(
          path: '/stock/remove',
          builder: (context, state) => const RemoveStockScreen(),
        ),
      ],
      redirect: (context, state) {
        final authState = authBloc.state;
        final loggingIn = state.matchedLocation == '/login';

        print('🔁 Redirection GoRouter, état : ${authState.runtimeType}');

        if (authState is AuthInitial || authState is AuthLoading) return null;
        if (authState is Authenticated) return loggingIn ? '/home' : null;
        return loggingIn ? null : '/login';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: lightTheme,
      darkTheme: darkTheme,
    );
  }
}


class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
