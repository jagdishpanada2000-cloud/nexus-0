import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'courses_screen.dart'; // Import the new courses screen
import 'screens/user_account/user_account.dart';
import 'login_register.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String userRole = 'student'; // Default role
  bool isLoadingUserData = true;

  // Updated screens list with the new CoursesScreen
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CoursesScreen(), // New courses screen with search functionality
    const UserAccount(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final userData = doc.data()!;
          setState(() {
            userRole = userData['role'] ?? 'student';
            isLoadingUserData = false;
          });
        } else {
          setState(() {
            isLoadingUserData = false;
          });
        }
      } else {
        setState(() {
          isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        isLoadingUserData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting ||
            isLoadingUserData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        }

        // If not authenticated, show login screen
        if (!snapshot.hasData) {
          return const LoginRegisterPage();
        }

        // User is authenticated, show main app
        return Scaffold(
          backgroundColor: Colors.black,
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: _currentIndex == 0
                          ? Icons.home
                          : Icons.home_outlined,
                      label: 'Home',
                      isSelected: _currentIndex == 0,
                      onTap: () => _onItemTapped(0),
                    ),
                    _buildNavItem(
                      icon: _currentIndex == 1
                          ? Icons.search
                          : Icons.search_outlined,
                      label: 'Search',
                      isSelected: _currentIndex == 1,
                      onTap: () => _onItemTapped(1),
                    ),
                    _buildNavItem(
                      icon: _currentIndex == 2
                          ? Icons.school
                          : Icons.school_outlined,
                      label: 'Courses',
                      isSelected: _currentIndex == 2,
                      onTap: () => _onItemTapped(2),
                    ),
                    _buildNavItem(
                      icon: _currentIndex == 3
                          ? Icons.person
                          : Icons.person_outline,
                      label: 'Account', // Remove the () here
                      isSelected: _currentIndex == 3,
                      onTap: () => _onItemTapped(3),
                      isProfile: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

 

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isProfile = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isProfile && isSelected
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange.shade400,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade800,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: isSelected ? Colors.orange.shade400 : Colors.grey,
                    size: isProfile ? 28 : 26,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange.shade400 : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
