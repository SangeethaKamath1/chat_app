import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../login/controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../src/theme/controller/chat_theme_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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

              /// Title
               Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: chatConfigController.config.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please fill the form to register",
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
             
              const SizedBox(height: 30),

              /// Register Button
              Obx(() => authController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Register",
                      onPressed: authController.register, // you’ll define this in controller
                    )),

              const SizedBox(height: 20),

              /// Navigation to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Get.offNamed(AppRoutes.login),
                    child:  Text(
                      "Login",
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
