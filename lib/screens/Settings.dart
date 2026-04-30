import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../viewmodels/user_vm.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUpdating = false;
  File? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userVM = context.read<UserViewModel>();
    if (userVM.currentUser != null) {
      _usernameController.text = userVM.currentUser!.username;
      _phoneController.text = userVM.currentUser!.phone;
    }
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    
    try {
      // Show options dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose image source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        
        print('📸 Image picked: ${bytes.length} bytes');
        
        // Check file size (limit to 500KB like in AddUnseen)
        if (bytes.length > 500000) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image too large. Please select a smaller image (max 500KB)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            _selectedImage = file;
            _base64Image = base64Encode(bytes);
          });
          print('✅ Image stored in state');
        }
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final userVM = context.read<UserViewModel>();
      
      print('🔄 Updating profile...');
      print('📝 Username: ${_usernameController.text.trim()}');
      print('📞 Phone: ${_phoneController.text.trim()}');
      print('🖼️ Has new image: ${_base64Image != null}');
      
      // Update username and phone
      await userVM.updateUserProfile(
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // Upload profile picture if selected (as base64)
      if (_base64Image != null) {
        final dataUrl = 'data:image/jpeg;base64,$_base64Image';
        print('📤 Uploading profile picture (${dataUrl.length} characters)');
        await userVM.updateProfilePicture(dataUrl);
        print('✅ Profile picture uploaded successfully');
      }

      // Reload user data to see the changes
      await userVM.loadUser();
      print('✅ Profile updated and reloaded');

      return;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code}');
      String message = 'Failed to update profile';
      if (e.code == 'network-request-failed') {
        message = 'No internet connection';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      rethrow;
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both password fields'),
          backgroundColor: Colors.orange,
        ),
      );
      throw Exception('Password fields empty');
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      throw Exception('Password too short');
    }

    setState(() => _isUpdating = true);

    try {
      final userVM = context.read<UserViewModel>();
      await userVM.changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();

      return;
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password';
      
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log out and log in again to change password';
          break;
        case 'network-request-failed':
          message = 'No internet connection';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      rethrow;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    
    bool profileSuccess = false;
    bool passwordSuccess = false;
    bool hasPasswordChange = _oldPasswordController.text.isNotEmpty && 
                             _newPasswordController.text.isNotEmpty;

    try {
      await _updateProfile();
      profileSuccess = true;

      if (hasPasswordChange && mounted) {
        await _changePassword();
        passwordSuccess = true;
      }

      if (mounted) {
        String message = 'Profile updated successfully';
        if (hasPasswordChange && passwordSuccess) {
          message = 'Profile and password updated successfully';
        }
        
        // Clear the selected image state
        setState(() {
          _selectedImage = null;
          _base64Image = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        // Small delay to show the snackbar, then pop
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate changes were made
        }
      }
    } catch (e) {
      print('❌ Error in _saveChanges: $e');
      // Errors are already shown in individual methods
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileImage(UserViewModel userVM) {
    final currentUser = userVM.currentUser;
    
    print('🖼️ Building profile image...');
    print('   - Has selected image: ${_selectedImage != null}');
    print('   - Has base64 image: ${_base64Image != null}');
    print('   - Profile URL from user: ${currentUser?.profileImageUrl}');
    
    // Show selected image first
    if (_selectedImage != null) {
      print('   ✅ Showing selected image');
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      );
    }
    
    // Show existing profile picture from Firestore
    if (currentUser?.profileImageUrl != null && currentUser!.profileImageUrl!.isNotEmpty) {
      print('   ✅ Showing profile image from Firestore');
      // Handle base64 data URL
      if (currentUser.profileImageUrl!.startsWith('data:image')) {
        try {
          final base64String = currentUser.profileImageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          print('   ✅ Decoded base64 image: ${bytes.length} bytes');
          return ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            ),
          );
        } catch (e) {
          print('   ❌ Error decoding base64: $e');
        }
      }
    }
    
    // Show initial letter if no image
    print('   ℹ️ Showing default initial');
    return Center(
      child: Text(
        currentUser?.username.isNotEmpty == true
            ? currentUser!.username[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final currentUser = userVM.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture with tap functionality
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2E2A68),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: _buildProfileImage(userVM),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Color(0xFF2E2A68),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    GestureDetector(
                      onTap: _pickImage,
                      child: const Text(
                        'Edit picture',
                        style: TextStyle(
                          color: Color(0xFF2E2A68),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Email (Read-only)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E3F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: double.infinity,
                      child: Text(
                        currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Username
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Username',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8E3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Phone Number
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Phone number',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8E3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                          return 'Phone number must contain only digits';
                        }
                        if (value.trim().length < 11) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Old Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Old password',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8E3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: 'Leave blank to keep current password',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // New Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New password',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8E3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: 'Minimum 6 characters',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2A68),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isUpdating ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E2A68), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Color(0xFF2E2A68),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}