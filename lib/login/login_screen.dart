import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../src/theme/controller/chat_theme_controller.dart';
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

               Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: chatConfigController.config.primaryColor,
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
                    child:  Text(
                      "Register",
                      style: TextStyle(
                        color: chatConfigController.config.primaryColor,
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
