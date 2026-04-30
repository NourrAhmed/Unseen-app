import 'package:flutter/material.dart';
import '../widgets/unseen_image.dart';

class SavedCard extends StatelessWidget {
  final String title;
  final String username;
  final String? imagePath;  // For asset images
  final String? imageUrl;   // For base64/network images from Firestore
  final VoidCallback? onUnsave;

  const SavedCard({
    Key? key,
    required this.title,
    required this.username,
    this.imagePath,
    this.imageUrl,
    this.onUnsave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double cardWidth = (MediaQuery.of(context).size.width - 48) / 2;
    final double cardHeight = cardWidth * 1.1;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2E2A68), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFD9D9D9),
      ),
      child: Column(
        children: [
          // Top image
          Container(
            height: cardHeight * 0.65,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: _buildImage(),
            ),
          ),
          
          // Title + username + bookmark icon
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF2E2A68),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Color(0xFF2E2A68),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onUnsave,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.bookmark,
                        size: 22,
                        color: Color(0xFF2E2A68),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Priority: imageUrl (from Firestore) > imagePath (from assets)
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return UnseenImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF5F5F5),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Color(0xFF2E2A68),
                size: 40,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(
            Icons.image,
            size: 40,
            color: Color(0xFF2E2A68),
          ),
        ),
      );
    }
  }
}