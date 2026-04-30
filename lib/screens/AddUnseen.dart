import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../viewmodels/unseen_vm.dart';
import '../viewmodels/user_vm.dart';
import '../viewmodels/category_vm.dart';
import '../models/unseen_model.dart';
import '../models/photo_model.dart';
import '../models/location_model.dart';
import '../models/category_model.dart';
import 'LocationPickerScreen.dart';

class AddUnseen extends StatefulWidget {
  const AddUnseen({Key? key}) : super(key: key);

  @override
  State<AddUnseen> createState() => _AddUnseenState();
}

class _AddUnseenState extends State<AddUnseen> {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  String _locationText = 'Getting location...';
  double _latitude = 0;
  double _longitude = 0;
  String _selectedCategory = '';
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      await context.read<CategoryViewModel>().fetchCategories();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationText = 'Location service disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationText = 'Location permission denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _locationText = 'Error getting location');
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(
        () =>
            _images = picked.take(3).map((xfile) => File(xfile.path)).toList(),
      );
    }
  }

  Future<List<PhotoModel>> _convertImagesToBase64(String userId) async {
    List<PhotoModel> photos = [];
    for (int i = 0; i < _images.length; i++) {
      var file = _images[i];
      List<int> imageBytes = await file.readAsBytes();
      if (imageBytes.length > 500000) continue;
      String base64Image = base64Encode(imageBytes);
      String dataUrl = 'data:image/jpeg;base64,$base64Image';
      photos.add(
        PhotoModel(
          url: dataUrl,
          uploadedAt: DateTime.now(),
          uploadedBy: userId,
        ),
      );
    }
    return photos;
  }

  Future<void> _post() async {
    if (_isPosting) return;

    setState(() => _isPosting = true);

    try {
      final userVM = context.read<UserViewModel>();
      final unseenVM = context.read<UnSeenViewModel>();
      final user = userVM.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
        return;
      }

      List<PhotoModel> photos = [];
      if (_images.isNotEmpty) {
        photos = await _convertImagesToBase64(user.userId);
      }

      final location = LocationModel(
        latitude: _latitude,
        longitude: _longitude,
        address: _locationText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unseen = UnSeenModel(
        unseenId: '',
        title: _titleController.text,
        story: _storyController.text,
        location: location,
        photos: photos,
        categories: _selectedCategory.isNotEmpty ? [_selectedCategory] : [],
        creatorId: user.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unseenWithId = await unseenVM.addUnSeenToFirestore(unseen);
      await userVM.addUserUnseen(unseenWithId.unseenId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unseen added successfully!')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Add UnSeen',
          style: TextStyle(
            color: Color(0xFF2E2952),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isPosting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2E2952),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _post,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Color(0xFF2E2952),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo upload
              GestureDetector(
                onTap: _isPosting ? null : _pickImages,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E3F3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF9E9E9E),
                      width: 2,
                    ),
                  ),
                  child:
                      _images.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Color(0xFF2E2952),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to add photos',
                                  style: TextStyle(
                                    color: Color(0xFF2E2952),
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Max 3 images, 500KB each',
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                            itemCount: _images.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  _images[index],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                ),
              ),

              const SizedBox(height: 16),

              // Location
              const Text(
                'Location',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E3F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF2E2952),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationText,
                            style: const TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap:
                                _isPosting
                                    ? null
                                    : () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => LocationPickerScreen(
                                                initialLatitude: _latitude,
                                                initialLongitude: _longitude,
                                              ),
                                        ),
                                      );

                                      if (result != null && mounted) {
                                        setState(() {
                                          _latitude =
                                              result['latitude'] as double;
                                          _longitude =
                                              result['longitude'] as double;
                                          _locationText =
                                              '${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}';
                                        });
                                      }
                                    },
                            child: const Text(
                              'Tap to Change',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Title',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                enabled: !_isPosting,
                decoration: InputDecoration(
                  hintText: 'Give your UnSeen a name',
                  filled: true,
                  fillColor: const Color(0xFFE8E3F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // Story
              const Text(
                'Your story',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _storyController,
                enabled: !_isPosting,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share what makes this place special to you',
                  filled: true,
                  fillColor: const Color(0xFFE8E3F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // Categories
              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children:
                    categories.map((CategoryModel category) {
                      final isSelected = _selectedCategory == category.name;
                      return GestureDetector(
                        onTap:
                            _isPosting
                                ? null
                                : () {
                                  setState(() {
                                    _selectedCategory =
                                        isSelected ? '' : category.name;
                                  });
                                },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFF2E2952)
                                    : const Color(0xFFE8E3F3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : const Color(0xFF2E2952),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 20),

              if (_isPosting)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF2E2952)),
                      SizedBox(height: 8),
                      Text(
                        'Creating your UnSeen...',
                        style: TextStyle(
                          color: Color(0xFF2E2952),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
