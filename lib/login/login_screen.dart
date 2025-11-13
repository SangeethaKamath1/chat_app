import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import 'controllers/auth_controller.dart';

import '../routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please login to your account",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              /// Username

              CustomTextField(
                controller: authController.usernameController,
                label: "Username",
              ),
              const SizedBox(height: 20),

              /// Password (reactive for hide/show)
              CustomTextField(
                controller: authController.passwordController,
                label: "Password",
                isPassword: true,
                obscureText: authController.isPasswordHidden,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 30),

              /// Login Button
              Obx(() => authController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Login",
                      onPressed: authController.login,
                    )),

              const SizedBox(height: 20),

              /// Navigation to Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Get.offNamed(AppRoutes.register),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
