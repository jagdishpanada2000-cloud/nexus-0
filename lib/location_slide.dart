import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/user_account/user_account.dart';

class LocationSlide extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String accountType;

  const LocationSlide({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.accountType,
  });

  @override
  State<LocationSlide> createState() => _LocationSlideState();
}

class _LocationSlideState extends State<LocationSlide>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final _pinCodeController = TextEditingController();

  String selectedCountry = "";
  String selectedState = "";
  String selectedCity = "";
  bool isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sample data - In production, you'd fetch this from an API
  final Map<String, List<String>> countryStates = {
    "India": ["Maharashtra", "Gujarat", "Rajasthan", "Punjab", "Delhi", "Karnataka", "Tamil Nadu", "Kerala"],
    "United States": ["California", "Texas", "New York", "Florida", "Illinois"],
    "United Kingdom": ["England", "Scotland", "Wales", "Northern Ireland"],
    "Canada": ["Ontario", "Quebec", "British Columbia", "Alberta"],
  };

  final Map<String, List<String>> stateCities = {
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Thane", "Nashik", "Aurangabad"],
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar"],
    "Delhi": ["New Delhi", "Central Delhi", "South Delhi", "North Delhi"],
    "Karnataka": ["Bangalore", "Mysore", "Hubli", "Mangalore"],
    "California": ["Los Angeles", "San Francisco", "San Diego", "Sacramento"],
    "Texas": ["Houston", "Dallas", "Austin", "San Antonio"],
    "England": ["London", "Manchester", "Birmingham", "Liverpool"],
    "Ontario": ["Toronto", "Ottawa", "Hamilton", "London"],
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    selectedCountry = "India"; // Default country
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinCodeController.dispose();
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

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePinCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN code is required';
    }
    if (value.length < 5) {
      return 'Please enter a valid PIN code';
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

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Create Firebase Auth account
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final user = userCred.user;
      if (user == null) throw Exception("User creation failed");

      await user.updateDisplayName(widget.name);

      // Prepare user data for Firestore
      final userData = {
        "uid": user.uid,
        "name": widget.name,
        "email": widget.email,
        "phone": widget.phone,
        "accountType": widget.accountType,
        "location": {
          "country": selectedCountry,
          "state": selectedState,
          "city": selectedCity,
          "pinCode": _pinCodeController.text.trim(),
        },
        "createdAt": FieldValue.serverTimestamp(),
        "lastLoginAt": FieldValue.serverTimestamp(),
        "isActive": true,
        "profileComplete": true,
        "followers": 0,
        "following": 0,
        "posts": 0,
      };

      // Save to users collection
      await _db.collection('users').doc(user.uid).set(userData);

      if (!mounted) return;
      _showSnackBar("Account created successfully!");

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      _redirectToMainApp();

    } catch (e) {
      String message = "Registration failed. Please try again.";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            message = "Email is already registered.";
            break;
          case 'weak-password':
            message = "Password is too weak.";
            break;
          case 'invalid-email':
            message = "Invalid email address.";
            break;
        }
      }
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _redirectToMainApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserAccount()),
      (route) => false,
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.grey.shade900,
        initialValue: selectedCountry.isNotEmpty ? selectedCountry : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(Icons.public, color: Colors.orange.shade300, size: 22),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.orange.shade300),
        hint: const Text("Select Country", style: TextStyle(color: Colors.grey)),
        items: countryStates.keys.map((country) {
          return DropdownMenuItem<String>(
            value: country,
            child: Text(country, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedCountry = value!;
            selectedState = "";
            selectedCity = "";
          });
        },
        validator: (value) => _validateRequired(value, "Country"),
      ),
    );
  }

  Widget _buildStateDropdown() {
    final states = selectedCountry.isNotEmpty ? countryStates[selectedCountry] ?? [] : <String>[];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.grey.shade900,
        initialValue: selectedState.isNotEmpty ? selectedState : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(Icons.location_on, color: Colors.orange.shade300, size: 22),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.orange.shade300),
        hint: const Text("Select State", style: TextStyle(color: Colors.grey)),
        items: states.map((state) {
          return DropdownMenuItem<String>(
            value: state,
            child: Text(state, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: selectedCountry.isEmpty ? null : (value) {
          setState(() {
            selectedState = value!;
            selectedCity = "";
          });
        },
        validator: (value) => _validateRequired(value, "State"),
      ),
    );
  }

  Widget _buildCityDropdown() {
    final cities = selectedState.isNotEmpty ? stateCities[selectedState] ?? [] : <String>[];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.grey.shade900,
        initialValue: selectedCity.isNotEmpty ? selectedCity : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(Icons.location_city, color: Colors.orange.shade300, size: 22),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.orange.shade300),
        hint: const Text("Select City", style: TextStyle(color: Colors.grey)),
        items: cities.map((city) {
          return DropdownMenuItem<String>(
            value: city,
            child: Text(city, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: selectedState.isEmpty ? null : (value) {
          setState(() {
            selectedCity = value!;
          });
        },
        validator: (value) => _validateRequired(value, "City"),
      ),
    );
  }

  Widget _buildAccountSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                "Account Summary",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Name", widget.name),
          _buildSummaryRow("Email", widget.email),
          _buildSummaryRow("Phone", widget.phone),
          _buildSummaryRow("Privacy", widget.accountType == "public" ? "Public Account" : "Private Account"),
          if (selectedCountry.isNotEmpty)
            _buildSummaryRow("Country", selectedCountry),
          if (selectedState.isNotEmpty)
            _buildSummaryRow("State", selectedState),
          if (selectedCity.isNotEmpty)
            _buildSummaryRow("City", selectedCity),
          if (_pinCodeController.text.isNotEmpty)
            _buildSummaryRow("PIN Code", _pinCodeController.text),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            ": ",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.orange.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                color: Colors.white,
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Complete Setup",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Indicator - Final Step (2 of 2)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Header
                    const Text(
                      "Where are you located?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This helps us connect you with nearby learners and opportunities",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Location Form
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCountryDropdown(),
                            const SizedBox(height: 16),
                            
                            _buildStateDropdown(),
                            const SizedBox(height: 16),
                            
                            _buildCityDropdown(),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _pinCodeController,
                              decoration: _inputDecoration(
                                "PIN Code / Postal Code",
                                icon: Icons.local_post_office,
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              validator: _validatePinCode,
                              onChanged: (value) => setState(() {}),
                            ),

                            const SizedBox(height: 24),

                            // Account Summary
                            _buildAccountSummary(),
                          ],
                        ),
                      ),
                    ),

                    // Create Account Button
                    const SizedBox(height: 24),
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
                                    "Creating your account...",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildGradientButton(
                            text: "Create Account",
                            onPressed: _createAccount,
                          ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}