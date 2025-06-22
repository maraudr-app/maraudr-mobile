import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/geo/screens/geo_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/stock/screens/stock_screen.dart';

final GoRouter goRouter = GoRouter(
  initialLocation: '/login',
  routes: [
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
  ],
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is Authenticated;
    final loggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !loggingIn) return '/login';
    if (isLoggedIn && loggingIn) return '/home';
    return null;
  },
);
