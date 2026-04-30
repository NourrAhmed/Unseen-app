import 'package:flutter_test/flutter_test.dart';
import 'package:unseenapp/utils/saved_unseen_filter.dart';
import 'package:unseenapp/models/unseen_model.dart';
import 'package:unseenapp/models/location_model.dart';

void main() {
  group('SavedUnseenFilter', () {
    test('returns only unseens whose IDs are saved', () {
      // Arrange
      final filter = SavedUnseenFilter();

      final allUnseens = [
        UnSeenModel(
          unseenId: '1',
          title: 'Place 1',
          story: '',
          location: LocationModel(latitude: 0, longitude: 0, address: ''),
          photos: [],
          categories: [],
          creatorId: 'user1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UnSeenModel(
          unseenId: '2',
          title: 'Place 2',
          story: '',
          location: LocationModel(latitude: 0, longitude: 0, address: ''),
          photos: [],
          categories: [],
          creatorId: 'user2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final savedIds = ['2'];

      // Act
      final result = filter.filterSavedUnseens(allUnseens, savedIds);

      // Assert
      expect(result.length, 1);
      expect(result.first.unseenId, '2');
    });
  });
}
