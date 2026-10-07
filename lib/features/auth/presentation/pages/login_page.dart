import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:sales_odoo_app/features/auth/presentation/widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => sl<AuthCubit>(),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              context.go('/home');
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                'assets/images/login_image.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              // Dark Overlay
              Container(color: Colors.black.withValues(alpha: 0.6)),
              // Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: max(0, constraints.maxHeight - 48),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome back',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                SizedBox(
                                  height: max(
                                    32.0,
                                    constraints.maxHeight * 0.15,
                                  ),
                                ),
                                const LoginForm(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
