import 'package:flutter_test/flutter_test.dart';
import 'package:unseenapp/utils/unseen_search_filter.dart';
import 'package:unseenapp/models/unseen_model.dart';
import 'package:unseenapp/models/location_model.dart';

void main() {
  group('UnseenSearchFilter', () {
    test('filters by category only', () {
      // Arrange
      final filter = UnseenSearchFilter();

      final unseens = [
        UnSeenModel(
          unseenId: '1',
          title: 'Beach',
          story: 'Sunny place',
          location: LocationModel(latitude: 0, longitude: 0, address: ''),
          photos: [],
          categories: ['Nature'],
          creatorId: 'u1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UnSeenModel(
          unseenId: '2',
          title: 'Museum',
          story: 'History',
          location: LocationModel(latitude: 0, longitude: 0, address: ''),
          photos: [],
          categories: ['Culture'],
          creatorId: 'u2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      final result = filter.filter(
        unseens: unseens,
        searchQuery: '',
        selectedCategory: 'Nature',
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.unseenId, '1');
    });

    test('filters by search query in title or story', () {
      final filter = UnseenSearchFilter();

      final unseens = [
        UnSeenModel(
          unseenId: '1',
          title: 'Hidden Beach',
          story: 'Nice water',
          location: LocationModel(latitude: 0, longitude: 0, address: ''),
          photos: [],
          categories: [],
          creatorId: 'u1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UnSeenModel(
          unseenId: '2',
          title: 'Mountain',
          story: 'Cold weather',
          location: LocationModel(latitude: 0, longitude: 0, address: ''),
          photos: [],
          categories: [],
          creatorId: 'u2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final result = filter.filter(
        unseens: unseens,
        searchQuery: 'beach',
        selectedCategory: '',
      );

      expect(result.length, 1);
      expect(result.first.unseenId, '1');
    });
  });
}
