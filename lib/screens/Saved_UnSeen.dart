import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../viewmodels/user_vm.dart';
import '../viewmodels/unseen_vm.dart';
import '../models/unseen_model.dart';
import 'View_UnSeen.dart';
import '../components/saved_card.dart';
import 'Settings.dart';

class Saved extends StatefulWidget {
  const Saved({super.key});

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  final Color textColor = const Color(0xFF2E2A68);
  bool _isLoading = false;
  List<UnSeenModel> _savedUnseens = [];
  Map<String, String> _creatorUsernames = {}; 

  @override
  void initState() {
    super.initState();
    _loadSavedUnseens();
  }

  Future<void> _loadSavedUnseens() async {
    setState(() => _isLoading = true);

    try {
      final userVM = context.read<UserViewModel>();
      final unseenVM = context.read<UnSeenViewModel>();

      // Fetch all unseens
      await unseenVM.fetchUnSeens();

      // Get current user's saved unseen IDs (from savedUnseens array)
      if (userVM.currentUser != null) {
        final savedIds = userVM.currentUser!.savedUnseens;
        final allUnseens = unseenVM.unseens;

        print('📋 User saved IDs: $savedIds');
        print('📋 Total unseens: ${allUnseens.length}');

        // Filter to get only saved unseens
        _savedUnseens = allUnseens
            .where((unseen) => savedIds.contains(unseen.unseenId))
            .toList();

        print('📋 Filtered saved unseens: ${_savedUnseens.length}');

        // Fetch usernames for each creator
        for (var unseen in _savedUnseens) {
          if (!_creatorUsernames.containsKey(unseen.creatorId)) {
            print('🔍 Fetching username for creatorId: ${unseen.creatorId}');
            final username = await userVM.getUsernameById(unseen.creatorId);
            _creatorUsernames[unseen.creatorId] = username;
            print('✅ Got username: $username for ${unseen.creatorId}');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading saved unseens: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unsaveUnseen(UnSeenModel unseen) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Saved'),
        content: Text('Remove "${unseen.title}" from your saved unseens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userVM = context.read<UserViewModel>();

      // Remove from user's saved list
      await userVM.removeSavedUnseen(unseen.unseenId);

      // Reload the list
      await _loadSavedUnseens();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved')),
        );
      }
    } catch (e) {
      print('❌ Error removing saved unseen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Settings()),
                  );
                  
                  // If settings returned true (changes were made), reload user data
                  if (result == true && mounted) {
                    await context.read<UserViewModel>().loadUser();
                    setState(() {}); // Rebuild to show new profile picture
                  }
                },
              ),
            ),

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
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD8D3E7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),

                  // Selected Tab (Saved UnSeens)
                  Container(
                    width: (screenWidth * 0.75) / 2 - 8,
                    height: 37,
                    margin: EdgeInsets.only(
                        left: ((screenWidth * 0.75) / 2), top: 5),
                    decoration: ShapeDecoration(
                      color: const Color(0xB52E2A68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // My UnSeens (Tap to go back)
                  Positioned(
                    left: 20,
                    top: 13,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "My UnSeens",
                        style: TextStyle(
                          color: Color(0xFF2E2A68),
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),

                  // Saved UnSeens (Selected)
                  Positioned(
                    right: 20,
                    top: 13,
                    child: const Text(
                      "Saved UnSeens",
                      style: TextStyle(
                        color: Color(0xFFD8D3E7),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Cards Grid
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E2A68),
                      ),
                    ),
                  )
                : _savedUnseens.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bookmark_border,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No saved unseens yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Save unseens to view them here',
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 115 / 150,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedUnseens.length,
                        itemBuilder: (context, index) {
                          final unseen = _savedUnseens[index];
                          final username = _creatorUsernames[unseen.creatorId] ??
                              'Loading...';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewUnseen(unseen: unseen),
                                ),
                              );
                            },
                            child: SavedCard(
                              title: unseen.title,
                              username: '@$username',
                              imageUrl: unseen.photos.isNotEmpty
                                  ? unseen.photos.first.url
                                  : null,
                              onUnsave: () => _unsaveUnseen(unseen),
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