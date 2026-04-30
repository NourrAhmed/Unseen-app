import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_vm.dart';
import 'HomePage.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _createAccount() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<UserViewModel>();
      String? error;

      try {
        
        print('Registering user...');
        error = await vm.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
          _phoneController.text.trim(),
        );
      } catch (e) {
        error = e.toString();
      }

      print('Register error: $error');

      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      } else {
        print('Navigation triggered');
        if (!mounted) return;
        // Option 1: Named route
        Navigator.pushReplacementNamed(context, '/main');

        // Option 2: Direct route (uncomment if named route fails)
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (_) => const HomePage()),
        // );
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2952),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Image.asset('assets/Logo.png', width: 120, height: 120),
                  ),
                  const SizedBox(height: 40),
                  const Text('Username', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFE8E8E8),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your username';
                      if (value.length < 3) return 'Username must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Email', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFE8E8E8),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!value.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Password', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFE8E8E8),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Phone number', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFE8E8E8),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your phone number';
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Phone number must contain only digits';
                      if (value.length < 11) return 'Please enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _createAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8E8E8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Create an account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
