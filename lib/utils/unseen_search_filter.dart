import '../../models/unseen_model.dart';

class UnseenSearchFilter {
  List<UnSeenModel> filter({
    required List<UnSeenModel> unseens,
    required String searchQuery,
    required String selectedCategory,
  }) {
    List<UnSeenModel> result = unseens;

    if (selectedCategory.isNotEmpty) {
      result = result
          .where((u) => u.categories.contains(selectedCategory))
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((u) {
        return u.title.toLowerCase().contains(query) ||
            u.story.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }
}
