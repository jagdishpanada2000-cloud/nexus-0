import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  bool _isSearching = false;
  
  final List<String> _categories = [
    'All',
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Science',
    'Mathematics',
    'Languages',
    'Arts',
    'Health',
    'Music',
    'Other'
  ];
  
  final List<String> _levels = [
    'All',
    'Beginner',
    'Intermediate', 
    'Advanced'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _buildCoursesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'Discover Courses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Add filter/sort options
              _showFilterBottomSheet();
            },
            icon: Icon(
              Icons.tune,
              color: Colors.orange.shade400,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search courses, topics, instructors...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[500],
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[500],
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
              _isSearching = value.isNotEmpty;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ..._categories.map((category) => _buildFilterChip(
                category,
                _selectedCategory == category,
                () => setState(() => _selectedCategory = category),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade400 : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange.shade400 : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getCourseStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredCourses = _filterCourses(docs);

        if (filteredCourses.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            final course = filteredCourses[index].data() as Map<String, dynamic>;
            return _buildCourseCard(course, filteredCourses[index].id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getCourseStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterCourses(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final course = doc.data() as Map<String, dynamic>;
      final title = (course['title'] ?? '').toString().toLowerCase();
      final description = (course['description'] ?? '').toString().toLowerCase();
      final instructor = (course['instructorName'] ?? '').toString().toLowerCase();
      final category = course['category'] ?? '';
      
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          instructor.contains(_searchQuery);
      
      // Category filter
      bool matchesCategory = _selectedCategory == 'All' ||
          category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.school_outlined,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No courses found' : 'No courses available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching 
                ? 'Try adjusting your search or filters'
                : 'Check back later for new courses',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _isSearching = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, String courseId) {
    final title = course['title'] ?? 'Untitled Course';
    final description = course['description'] ?? 'No description available';
    final instructorName = course['instructorName'] ?? 'Unknown Instructor';
    final category = course['category'] ?? 'Other';
    final level = course['level'] ?? 'Beginner';
    final price = course['price'] ?? 0.0;
    final rating = course['averageRating'] ?? 0.0;
    final studentsCount = course['enrolledStudents']?.length ?? 0;
    final imageUrl = course['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showCourseDetails(course, courseId),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey[800],
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(category);
                        },
                      ),
                    )
                  : _buildPlaceholderImage(category),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Level
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Course Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Instructor
                  Text(
                    'by $instructorName',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom Row - Rating, Students, Price
                  Row(
                    children: [
                      // Rating
                      if (rating > 0) ...[
                        Icon(
                          Icons.star,
                          color: Colors.orange.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      
                      // Students Count
                      Icon(
                        Icons.people_outline,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$studentsCount students',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Price
                      Text(
                        price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: price == 0 ? Colors.green[400] : Colors.orange.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String category) {
    IconData icon;
    Color color;
    
    switch (category.toLowerCase()) {
      case 'programming':
        icon = Icons.code;
        color = Colors.blue;
        break;
      case 'design':
        icon = Icons.palette;
        color = Colors.purple;
        break;
      case 'business':
        icon = Icons.business;
        color = Colors.green;
        break;
      case 'marketing':
        icon = Icons.trending_up;
        color = Colors.red;
        break;
      case 'science':
        icon = Icons.science;
        color = Colors.teal;
        break;
      case 'mathematics':
        icon = Icons.calculate;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.school;
        color = Colors.orange;
    }
    
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Icon(
        icon,
        size: 48,
        color: color.withOpacity(0.7),
      ),
    );
  }

  void _showCourseDetails(Map<String, dynamic> course, String courseId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCourseDetailsSheet(course, courseId),
    );
  }

  Widget _buildCourseDetailsSheet(Map<String, dynamic> course, String courseId) {
    final title = course['title'] ?? 'Untitled Course';
    final description = course['description'] ?? 'No description available';
    final instructorName = course['instructorName'] ?? 'Unknown Instructor';
    final price = course['price'] ?? 0.0;
    final requirements = List<String>.from(course['requirements'] ?? []);
    final whatYoullLearn = List<String>.from(course['whatYoullLearn'] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Title and close button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Instructor
                    Text(
                      'by $instructorName',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    const Text(
                      'About this course',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    
                    if (whatYoullLearn.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'What you\'ll learn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...whatYoullLearn.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    if (requirements.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Requirements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...requirements.map(
                        (requirement) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.grey[500],
                                size: 8,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  requirement,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Enroll button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    top: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: price == 0 ? Colors.green[400] : Colors.orange.shade400,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (price > 0)
                          Text(
                            'One-time payment',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _enrollInCourse(courseId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enroll Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Level',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    children: _levels.map((level) => _buildFilterChip(
                          level,
                          _selectedLevel == level,
                          () => setState(() => _selectedLevel = level),
                        )).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                              _selectedLevel = 'All';
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[600]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade400,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enrollInCourse(String courseId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add user to enrolled students
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
        'enrolledStudents': FieldValue.arrayUnion([user.uid]),
      });

      // Add course to user's enrolled courses
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });

      Navigator.pop(context); // Close the details sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully enrolled in course!'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enroll: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}