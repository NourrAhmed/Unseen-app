import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unseen_model.dart';
import '../viewmodels/user_vm.dart';
import '../widgets/unseen_image.dart';
import 'map_view.dart';

class ViewUnseen extends StatefulWidget {
  final UnSeenModel unseen;

  const ViewUnseen({Key? key, required this.unseen}) : super(key: key);

  @override
  State<ViewUnseen> createState() => _ViewUnseenState();
}

class _ViewUnseenState extends State<ViewUnseen> {
  String _username = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final userVM = context.read<UserViewModel>();
      final username = await userVM.getUsernameById(widget.unseen.creatorId);
      if (mounted) {
        setState(() {
          _username = username;
        });
      }
    } catch (e) {
      print('Error loading username: $e');
      if (mounted) {
        setState(() {
          _username = 'Unknown User';
        });
      }
    }
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapView(
          latitude: widget.unseen.location.latitude,
          longitude: widget.unseen.location.longitude,
          address: widget.unseen.location.address,
          title: widget.unseen.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "UnSeen",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Image
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey[300],
              child: widget.unseen.photos.isNotEmpty
                  ? UnseenImage(
                      imageUrl: widget.unseen.photos.first.url,
                      width: double.infinity,
                      height: 220,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            // Content Area
            Container(
              color: const Color(0xC9D8D3E7),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Subtitle
                  Text(
                    widget.unseen.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    widget.unseen.location.address ?? 
                    '${widget.unseen.location.latitude.toStringAsFixed(4)}, ${widget.unseen.location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category Buttons
                  if (widget.unseen.categories.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: widget.unseen.categories.map((category) {
                        return _categoryBubble(category);
                      }).toList(),
                    ),

                  const SizedBox(height: 30),

                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF2E2A68)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2E2952),
                          ),
                          child: Center(
                            child: Text(
                              _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Story Box
                  Container(
                    padding: const EdgeInsets.all(15),
                    constraints: const BoxConstraints(
                      minHeight: 170,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF2E2A68)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Story",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.unseen.story.isNotEmpty 
                              ? widget.unseen.story 
                              : 'No story provided.',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Visit on Map Button
                  Center(
                    child: GestureDetector(
                      onTap: _openMap,
                      child: Container(
                        width: 240,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2A68),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.place, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Visit on map",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A68),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
