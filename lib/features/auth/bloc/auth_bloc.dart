import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {

    on<AuthCheckRequested>((event, emit) async {
      final token = await authRepository.getToken();
      print('📦 AuthCheckRequested → token: $token');
      if (token != null) {
        emit(Authenticated(token));
      } else {
        emit(Unauthenticated());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await authRepository.login(event.email, event.password);
        print('🟢 État Authenticated émis');
        emit(Authenticated(token));
      } catch (e) {
        print('🔴 AuthFailure émis : $e');
        emit(AuthFailure(e.toString()));
        emit(Unauthenticated());
      }
    });


    on<AuthLogoutRequested>((event, emit) async {
      await authRepository.clearToken();
      emit(Unauthenticated());
    });
  }
}
