import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_navigation_screen.dart';

import 'account_type_slide.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAutoLogin();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _animationController.forward();
  }

  Future<void> _checkAutoLogin() async {
    final user = _auth.currentUser;
    if (user != null) {
      _redirectAfterLogin();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.orange.shade300, size: 22)
          : null,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade900.withOpacity(0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _proceedToAccountSetup() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountTypeSlide(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCred.user != null) {
        await _db.collection('users').doc(userCred.user!.uid).update({
          "lastLoginAt": DateTime.now().millisecondsSinceEpoch,
        });

        _showSnackBar("Welcome back!");
        _redirectAfterLogin();
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed.";
      switch (e.code) {
        case 'user-not-found':
          message = "No account found for this email.";
          break;
        case 'wrong-password':
          message = "Incorrect password.";
          break;
        case 'invalid-email':
          message = "Please enter a valid email address.";
          break;
        case 'user-disabled':
          message = "This account has been disabled.";
          break;
        case 'too-many-requests':
          message = "Too many failed attempts. Try again later.";
          break;
        case 'network-request-failed':
          message = "Network error. Check your connection.";
          break;
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar(
        "An unexpected error occurred: ${e.toString()}",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      final userDoc = await _db
          .collection("users")
          .doc(userCred.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _db.collection("users").doc(userCred.user!.uid).set({
          "name": userCred.user!.displayName ?? "Google User",
          "email": userCred.user!.email,
          "profileImageUrl": userCred.user!.photoURL,
          "accountType": "public",
          "createdAt": FieldValue.serverTimestamp(),
          "lastLoginAt": FieldValue.serverTimestamp(),
          "isActive": true,
          "loginProvider": "google",
          "followers": 0,
          "following": 0,
          "posts": 0,
        });
      } else {
        await _db.collection("users").doc(userCred.user!.uid).update({
          "lastLoginAt": FieldValue.serverTimestamp(),
        });
      }

      _showSnackBar("Signed in with Google successfully!");
      _redirectAfterLogin();
    } catch (e) {
      _showSnackBar("Google Sign-In failed. Please try again.", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email address first.", isError: true);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar("Password reset email sent! Check your inbox.");
    } on FirebaseAuthException catch (e) {
      String message = "Failed to send reset email.";
      if (e.code == 'user-not-found') {
        message = "No account found for this email.";
      }
      _showSnackBar(message, isError: true);
    }
  }

  void _redirectAfterLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isSecondary
            ? null
            : LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade400],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: isSecondary
            ? Border.all(color: Colors.orange.shade400, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSecondary ? Colors.orange.shade400 : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Enhanced Logo Section
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade600,
                                  Colors.orange.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.shade400.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "KnowMate",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade400,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Excellence in Education",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),

                      Text(
                        isLogin ? "Welcome Back" : "Create Account",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin
                            ? "Sign in to continue learning"
                            : "Join our learning community",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      if (!isLogin) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            "Full Name",
                            icon: Icons.person,
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration(
                          "Email Address",
                          icon: Icons.email,
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: !showPassword,
                        decoration:
                            _inputDecoration(
                              "Password",
                              icon: Icons.lock,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () => setState(
                                  () => showPassword = !showPassword,
                                ),
                              ),
                            ),
                        style: const TextStyle(color: Colors.white),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),

                      if (!isLogin) ...[
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !showConfirmPassword,
                          decoration:
                              _inputDecoration(
                                "Confirm Password",
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade400,
                                  ),
                                  onPressed: () => setState(
                                    () => showConfirmPassword = !showConfirmPassword,
                                  ),
                                ),
                              ),
                          style: const TextStyle(color: Colors.white),
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          decoration: _inputDecoration(
                            "Phone Number",
                            icon: Icons.phone,
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (isLogin) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) =>
                                  setState(() => rememberMe = value!),
                              activeColor: Colors.orange.shade400,
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Colors.orange.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Main Action Button
                      isLoading
                          ? Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey.shade800,
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.orange,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Please wait...",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildGradientButton(
                              text: isLogin ? "Sign In" : "Continue",
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                if (isLogin) {
                                  await _loginUser();
                                } else {
                                  _proceedToAccountSetup();
                                }
                              },
                            ),

                      const SizedBox(height: 20),

                      // Google Sign In (only for login)
                      if (isLogin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade600),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isLoading ? null : _signInWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/google.png',
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                          Icons.g_mobiledata,
                                          size: 24,
                                          color: Colors.red,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Toggle Login/Register
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              isLogin = !isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              text: isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: isLogin ? "Sign Up" : "Sign In",
                                  style: TextStyle(
                                    color: Colors.orange.shade400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}