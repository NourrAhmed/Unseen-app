import 'package:flutter_test/flutter_test.dart';
import 'package:unseenapp/utils/unseen_validator.dart';

void main() {
  group('UnseenValidator', () {
    test('isTitleValid should return false for empty title', () {
      // Arrange
      final validator = UnseenValidator();

      // Act
      final result = validator.isTitleValid('');

      // Assert
      expect(result, false);
    });

    test('isTitleValid should return false for whitespace title', () {
      final validator = UnseenValidator();

      final result = validator.isTitleValid('   ');

      expect(result, false);
    });

    test('isTitleValid should return true for non-empty title', () {
      final validator = UnseenValidator();

      final result = validator.isTitleValid('My UnSeen Place');

      expect(result, true);
    });
  });
}
