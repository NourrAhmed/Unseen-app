import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

// Helper widget to display images (handles both URLs and base64)
class UnseenImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const UnseenImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 string after "base64,"
        final base64String = imageUrl.split(',')[1];
        final Uint8List bytes = base64Decode(base64String);
        
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }
    } else {
      // Regular network URL (for when you upgrade to Storage later)
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    }
  }
}

// Example usage in your HomePage or wherever you display unseens:
// Replace Image.network(photo.url) with UnseenImage(imageUrl: photo.url)

// Example for a list of unseens:
class UnseenCard extends StatelessWidget {
  final String title;
  final String story;
  final List<String> photoUrls;

  const UnseenCard({
    Key? key,
    required this.title,
    required this.story,
    required this.photoUrls,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display first image if available
          if (photoUrls.isNotEmpty)
            UnseenImage(
              imageUrl: photoUrls.first,
              height: 200,
              width: double.infinity,
            ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(story),
                
                // Show all images in a horizontal scroll if multiple
                if (photoUrls.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: UnseenImage(
                            imageUrl: photoUrls[index],
                            width: 80,
                            height: 80,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}