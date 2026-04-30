import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../viewmodels/user_vm.dart';
import '../viewmodels/unseen_vm.dart';
import '../models/unseen_model.dart';
import 'Saved_UnSeen.dart';
import 'View_UnSeen.dart';
import '../components/unseen_card.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Color textColor = const Color(0xFF2E2A68);
  bool _isLoadingUnseens = false;
  List<UnSeenModel> _userUnseens = [];

  @override
  void initState() {
    super.initState();
    _loadUserUnseens();
  }

  Future<void> _loadUserUnseens() async {
    setState(() => _isLoadingUnseens = true);
    
    try {
      final userVM = context.read<UserViewModel>();
      final unseenVM = context.read<UnSeenViewModel>();
      
      // Fetch all unseens
      await unseenVM.fetchUnSeens();
      
      // Filter to show only current user's unseens
      if (userVM.currentUser != null) {
        final allUnseens = unseenVM.unseens;
        _userUnseens = allUnseens
            .where((unseen) => unseen.creatorId == userVM.currentUser!.userId)
            .toList();
      }
    } catch (e) {
      print('Error loading user unseens: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUnseens = false);
      }
    }
  }

  Future<void> _deleteUnseen(UnSeenModel unseen) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete UnSeen'),
        content: Text('Are you sure you want to delete "${unseen.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final unseenVM = context.read<UnSeenViewModel>();
      final userVM = context.read<UserViewModel>();
      
      // Delete from Firestore
      await unseenVM.deleteUnSeen(unseen.unseenId);
      
      // Remove from user's list
      await userVM.removeUserUnseen(unseen.unseenId);
      
      // Reload the list
      await _loadUserUnseens();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UnSeen deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting unseen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting unseen: $e')),
        );
      }
    }
  }

  Widget _buildProfileImage(String? profileImageUrl, String username) {
    // If there's a profile image URL and it's a base64 data URL
    if (profileImageUrl != null && profileImageUrl.startsWith('data:image')) {
      try {
        final base64String = profileImageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 115,
            height: 112,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        print('Error decoding profile image: $e');
      }
    }
    
    // Default: show initial letter
    return Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final userVM = context.watch<UserViewModel>();
    final currentUser = userVM.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Settings Icon
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Color(0xFF2E2A68),
                  size: 28,
                ),
                onPressed: () async {
                  // Navigate to settings and wait for result
                  final result = await Navigator.pushNamed(context, '/settings');
                  
                  // If settings returned true (changes were made), reload user data
                  if (result == true && mounted) {
                    await context.read<UserViewModel>().loadUser();
                    setState(() {}); // Rebuild to show new profile picture
                  }
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Profile Picture
            Container(
              width: 115,
              height: 112,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2E2A68),
              ),
              clipBehavior: Clip.hardEdge,
              child: _buildProfileImage(
                currentUser?.profileImageUrl,
                currentUser?.username ?? 'U',
              ),
            ),
            const SizedBox(height: 16),

            // Username
            Text(
              currentUser != null ? '@${currentUser.username}' : '@user',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30),

            // Segmented Control
            SizedBox(
              width: screenWidth * 0.75,
              height: 48,
              child: Stack(
                children: [
                  // Background
                  Container(
                    width: screenWidth * 0.75,
                    height: 48,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD8D3E7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  // Selected Tab (My UnSeens)
                  Container(
                    width: (screenWidth * 0.75) / 2 - 8,
                    height: 38,
                    margin: const EdgeInsets.only(left: 8, top: 5),
                    decoration: ShapeDecoration(
                      color: const Color(0xB52E2A68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 23,
                    top: 13,
                    child: const Text(
                      'My UnSeens',
                      style: TextStyle(
                        color: Color(0xFFD8D3E7),
                        fontSize: 15,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 13,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Scaffold(
                              body: Saved(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Saved UnSeens',
                        style: TextStyle(
                          color: Color(0xFF2E2A68),
                          fontSize: 15,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Grid of Cards
            _isLoadingUnseens
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E2A68),
                      ),
                    ),
                  )
                : _userUnseens.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.explore_off,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No unseens yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create your first unseen!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 115 / 150,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userUnseens.length,
                        itemBuilder: (context, index) {
                          final unseen = _userUnseens[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewUnseen(unseen: unseen),
                                ),
                              );
                            },
                            child: UnseenCard(
                              title: unseen.title,
                              imageUrl: unseen.photos.isNotEmpty 
                                  ? unseen.photos.first.url 
                                  : null,
                              showActions: true,
                              onDelete: () => _deleteUnseen(unseen),
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}