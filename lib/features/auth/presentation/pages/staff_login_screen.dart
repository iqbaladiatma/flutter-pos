import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/repositories/staff_auth_repository.dart';
import '../bloc/staff_auth_bloc.dart';
import '../bloc/staff_auth_event.dart';
import '../bloc/staff_auth_state.dart';

/// Staff login screen with phone + PIN input.
class StaffLoginScreen extends StatelessWidget {
  final void Function()? onLoginSuccess;

  const StaffLoginScreen({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffAuthBloc(repository: getIt<StaffAuthRepository>()),
      child: _StaffLoginView(onLoginSuccess: onLoginSuccess),
    );
  }
}

class _StaffLoginView extends StatefulWidget {
  final void Function()? onLoginSuccess;
  const _StaffLoginView({this.onLoginSuccess});

  @override
  State<_StaffLoginView> createState() => _StaffLoginViewState();
}

class _StaffLoginViewState extends State<_StaffLoginView> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffAuthBloc, StaffAuthState>(
      listener: (context, state) {
        if (state is StaffAuthError) {
          SnackbarHelper.showError(context, state.message);
        }
        if (state is StaffAuthAuthenticated) {
          SnackbarHelper.showSuccess(context, 'Selamat datang, ${state.session.name}');
          widget.onLoginSuccess?.call();
        }
      },
      builder: (context, state) {
        final isLoading = state is StaffAuthAuthenticating;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Title
                      const Icon(
                        Icons.point_of_sale,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PostSA POS',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login Staf',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      // Phone field
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'No. HP',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'No. HP wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // PIN field
                      TextFormField(
                        controller: _pinCtrl,
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePin
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscurePin = !_obscurePin),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: _obscurePin,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'PIN wajib diisi';
                          }
                          if (value.length < 4) {
                            return 'PIN minimal 4 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Login button
                      FilledButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login', style: AppTextStyles.titleMedium),
                      ),
                      const SizedBox(height: 16),
                      // Demo hint
                      const Text(
                        'Demo: Gunakan no. HP staf + PIN yang diatur oleh admin',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<StaffAuthBloc>().add(StaffAuthLogin(
          phone: _phoneCtrl.text.trim(),
          pin: _pinCtrl.text.trim(),
        ));
  }
}
