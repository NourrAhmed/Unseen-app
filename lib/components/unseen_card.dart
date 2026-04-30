import 'package:flutter/material.dart';
import '../widgets/unseen_image.dart';

class UnseenCard extends StatelessWidget {
  final String title;
  final String? imagePath;  
  final String? imageUrl;   
  final VoidCallback? onDelete;
  final bool showActions; 

  const UnseenCard({
    Key? key,
    required this.title,
    this.imagePath,
    this.imageUrl,
    this.onDelete,
    this.showActions = false, 
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
          
          // Title + icons row
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2E2A68),
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Show delete icon only if showActions is true
                  if (showActions)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        size: 22,
                        color: Color(0xFF2E2A68),
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