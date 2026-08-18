import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/repositories/customer_auth_repository.dart';
import '../bloc/customer_auth_bloc.dart';
import '../bloc/customer_auth_event.dart';
import '../bloc/customer_auth_state.dart';

/// Customer authentication screen with OTP flow.
///
/// Flow:
/// 1. Enter phone number
/// 2. Request OTP
/// 3. Enter 6-digit OTP code
/// 4. Verify → authenticated
class CustomerAuthScreen extends StatelessWidget {
  const CustomerAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerAuthBloc(
        repository: getIt<CustomerAuthRepository>(),
      )..add(const CustomerAuthCheckSession()),
      child: const _CustomerAuthView(),
    );
  }
}

class _CustomerAuthView extends StatelessWidget {
  const _CustomerAuthView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Pelanggan', style: AppTextStyles.titleLarge),
      ),
      body: BlocConsumer<CustomerAuthBloc, CustomerAuthState>(
        listener: (context, state) {
          if (state is CustomerAuthError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return switch (state) {
            CustomerAuthInitial() => const _PhoneInputForm(),
            CustomerAuthChecking() => const Center(child: CircularProgressIndicator()),
            CustomerAuthUnauthenticated() => const _PhoneInputForm(),
            CustomerAuthOtpSent(:final phone, :final devCode) =>
              _OtpInputForm(phone: phone, devCode: devCode),
            CustomerAuthVerifying() => const Center(child: CircularProgressIndicator()),
            CustomerAuthAuthenticated(:final customer) =>
              _AuthenticatedView(customerName: customer.name),
            CustomerAuthError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context
                    .read<CustomerAuthBloc>()
                    .add(const CustomerAuthReset()),
              ),
          };
        },
      ),
    );
  }
}

class _PhoneInputForm extends StatefulWidget {
  const _PhoneInputForm();

  @override
  State<_PhoneInputForm> createState() => _PhoneInputFormState();
}

class _PhoneInputFormState extends State<_PhoneInputForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    var phone = input.trim();
    if (phone.startsWith('0')) {
      phone = '+62${phone.substring(1)}';
    } else if (phone.startsWith('62')) {
      phone = '+$phone';
    } else if (!phone.startsWith('+')) {
      phone = '+62$phone';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_android, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Masuk dengan Nomor HP',
                style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Kami akan mengirimkan kode OTP via SMS untuk verifikasi.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                hintText: '08xxxxxxxxxx',
                prefixText: '',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Masukkan nomor HP';
                }
                if (value.trim().length < 8) {
                  return 'Nomor HP tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final phone = _normalizePhone(_controller.text);
                  context
                      .read<CustomerAuthBloc>()
                      .add(CustomerAuthRequestOtp(phone: phone));
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Kirim Kode OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpInputForm extends StatefulWidget {
  final String phone;
  final String? devCode;

  const _OtpInputForm({required this.phone, this.devCode});

  @override
  State<_OtpInputForm> createState() => _OtpInputFormState();
}

class _OtpInputFormState extends State<_OtpInputForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Auto-fill dev code for testing
    if (widget.devCode != null) {
      _controller.text = widget.devCode!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sms, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Verifikasi OTP', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Masukkan 6-digit kode yang dikirim ke:\n${widget.phone}',
              style: AppTextStyles.bodyMedium,
            ),
            if (widget.devCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Dev mode — kode: ${widget.devCode}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                hintText: '------',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Masukkan 6 digit kode';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<CustomerAuthBloc>().add(CustomerAuthVerifyOtp(
                        phone: widget.phone,
                        code: _controller.text,
                      ));
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Verifikasi'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context
                  .read<CustomerAuthBloc>()
                  .add(CustomerAuthRequestOtp(phone: widget.phone)),
              child: const Text('Kirim ulang kode'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedView extends StatelessWidget {
  final String customerName;
  const _AuthenticatedView({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text('Selamat datang,', style: AppTextStyles.bodyMedium),
            Text(customerName, style: AppTextStyles.titleLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context
                  .read<CustomerAuthBloc>()
                  .add(const CustomerAuthSignOut()),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
