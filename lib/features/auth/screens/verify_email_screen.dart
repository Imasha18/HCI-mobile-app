import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_routes.dart';
import '../../../services/api_client.dart';
import '../../cook/providers/cook_provider.dart';
import '../../customer/providers/customer_provider.dart';
import '../../rider/providers/rider_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.role = 'customer',
  });

  final String email;
  final String? role;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  Timer? _cooldownTimer;
  int _resendCooldown = 60;
  bool _isResending = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    if (mounted) {
      setState(() {
        _resendCooldown = seconds;
      });
    } else {
      _resendCooldown = seconds;
    }

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient().dio.post(
        '/auth/resend-verification',
        data: {'email': widget.email.trim().toLowerCase()},
      );

      if (!mounted) return;
      final msg = response.data['message']?.toString() ??
          'A new verification code has been sent to your email!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCooldown(60);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiClient.messageFrom(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to resend code: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final isCook = widget.role == 'cook';
    final isRider = widget.role == 'rider';

    try {
      if (isCook) {
        final success = await ref
            .read(cookProvider.notifier)
            .verifyEmail(widget.email, code);
        if (!mounted) return;
        if (success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.cookDashboard,
            (_) => false,
          );
        } else {
          final err = ref.read(cookProvider).error;
          setState(() {
            _errorMessage = err ?? 'Verification failed. Please try again.';
          });
        }
      } else if (isRider) {
        final success = await ref
            .read(riderProvider.notifier)
            .verifyEmail(widget.email, code);
        if (!mounted) return;
        if (success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.riderDashboard,
            (_) => false,
          );
        } else {
          final err = ref.read(riderProvider).error;
          setState(() {
            _errorMessage = err ?? 'Verification failed. Please try again.';
          });
        }
      } else {
        final success = await ref
            .read(customerProvider.notifier)
            .verifyEmail(widget.email, code);
        if (!mounted) return;
        if (success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (_) => false,
          );
        } else {
          final err = ref.read(customerProvider).error;
          setState(() {
            _errorMessage = err ?? 'Verification failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verification error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final riderState = ref.watch(riderProvider);
    final isRider = widget.role == 'rider';
    final isLoading = _isVerifying ||
        (isRider ? riderState.isLoading : customerState.isLoading);
    final providerError = isRider ? riderState.error : customerState.error;
    final displayError = _errorMessage ?? providerError;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 64,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(height: 20),
          Text(
            'Check your inbox',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a 6-digit verification code to:\n${widget.email}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Verification code',
              hintText: '123456',
              counterText: '',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => isLoading ? null : _verify(),
          ),
          const SizedBox(height: 16),
          if (displayError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                displayError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          FilledButton(
            onPressed: isLoading ? null : _verify,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify Email'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Didn't receive code? ",
                style: TextStyle(color: Colors.grey),
              ),
              if (_resendCooldown > 0)
                Text(
                  'Resend in ${_resendCooldown}s',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
              else
                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Resend Code',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
