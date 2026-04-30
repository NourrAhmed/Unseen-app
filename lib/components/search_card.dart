import 'package:flutter/material.dart';
import '../models/unseen_model.dart';
import '../widgets/unseen_image.dart';

class SearchCard extends StatefulWidget {
  final UnSeenModel unseen;
  final String username;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToggle;

  const SearchCard({
    Key? key,
    required this.unseen,
    required this.username,
    this.isSaved = false,
    this.onTap,
    this.onSaveToggle,
  }) : super(key: key);

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (widget.unseen.photos.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: UnseenImage(
                  imageUrl: widget.unseen.photos.first.url,
                  height: 200,
                  width: double.infinity,
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and Save Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF2E2952),
                            child: Text(
                              widget.username.isNotEmpty 
                                  ? widget.username[0].toUpperCase() 
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.username,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2952),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onSaveToggle,
                        icon: Icon(
                          widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: const Color(0xFF2E2952),
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    widget.unseen.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2952),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Story
                  if (widget.unseen.story.isNotEmpty)
                    Text(
                      widget.unseen.story,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF2E2952),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.unseen.location.address ?? 
                          '${widget.unseen.location.latitude.toStringAsFixed(2)}, ${widget.unseen.location.longitude.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Categories
                  if (widget.unseen.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: widget.unseen.categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E3F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E2952),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}