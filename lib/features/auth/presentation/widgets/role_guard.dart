import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/staff_session.dart';
import '../../domain/repositories/staff_auth_repository.dart';
import '../bloc/staff_auth_bloc.dart';
import '../bloc/staff_auth_event.dart';
import '../bloc/staff_auth_state.dart';
import '../pages/staff_login_screen.dart';

/// Wraps a widget with role-based access control.
///
/// Shows login screen if unauthenticated, or access-denied if role insufficient.
class RoleGuard extends StatelessWidget {
  final String requiredRoute;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          StaffAuthBloc(repository: getIt<StaffAuthRepository>())
            ..add(const StaffAuthCheckSession()),
      child: BlocBuilder<StaffAuthBloc, StaffAuthState>(
        builder: (context, state) {
          return switch (state) {
            StaffAuthInitial() => const _LoadingView(),
            StaffAuthCheckingSession() => const _LoadingView(),
            StaffAuthUnauthenticated() => StaffLoginScreen(
                onLoginSuccess: () =>
                    context.read<StaffAuthBloc>().add(const StaffAuthCheckSession()),
              ),
            StaffAuthAuthenticating() => const _LoadingView(),
            StaffAuthAuthenticated(:final session) =>
              _GuardedContent(
                session: session,
                requiredRoute: requiredRoute,
                child: child,
              ),
            StaffAuthError(:final message) => _ErrorView(message: message),
          };
        },
      ),
    );
  }
}

class _GuardedContent extends StatelessWidget {
  final StaffSession session;
  final String requiredRoute;
  final Widget child;

  const _GuardedContent({
    required this.session,
    required this.requiredRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!session.canAccess(requiredRoute)) {
      return _AccessDeniedView(
        role: session.role,
        route: requiredRoute,
        onLogout: () =>
            context.read<StaffAuthBloc>().add(const StaffAuthLogout()),
      );
    }
    return child;
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context
                    .read<StaffAuthBloc>()
                    .add(const StaffAuthCheckSession()),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  final String role;
  final String route;
  final VoidCallback onLogout;

  const _AccessDeniedView({
    required this.role,
    required this.route,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              const Text(
                'Anda tidak memiliki akses ke halaman ini',
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Role: $role\nRoute: $route',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onLogout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
