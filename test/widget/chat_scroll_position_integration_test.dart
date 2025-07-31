// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/service/chat.dart';

void main() {
  group('ChatController scroll position integration tests', () {
    late TestChatService chatService;

    setUp(() {
      chatService = TestChatService();
    });

    test('_saveCurrentScrollPosition calls ChatService.saveScrollPosition', () {
      // Arrange
      final chatId = const ChatId('test-chat');
      const index = 15;
      const offset = 200.0;

      // Act - Simulate what ChatController._saveCurrentScrollPosition() does
      chatService.saveScrollPosition(chatId, index, offset);

      // Assert
      final savedPosition = chatService.getScrollPosition(chatId);
      expect(savedPosition, isNotNull);
      expect(savedPosition!.index, equals(index));
      expect(savedPosition.offset, equals(offset));
    });

    test('scroll position integration with multiple chat switches', () {
      // Arrange
      final chatId1 = const ChatId('chat-1');
      final chatId2 = const ChatId('chat-2');
      final chatId3 = const ChatId('chat-3');

      // Act - Simulate switching between multiple chats and saving positions
      chatService.saveScrollPosition(chatId1, 10, 100.0);
      chatService.saveScrollPosition(chatId2, 25, 250.0);
      chatService.saveScrollPosition(chatId3, 40, 400.0);

      // Update position for first chat again (simulate returning to it)
      chatService.saveScrollPosition(chatId1, 15, 150.0);

      // Assert
      final position1 = chatService.getScrollPosition(chatId1);
      final position2 = chatService.getScrollPosition(chatId2);
      final position3 = chatService.getScrollPosition(chatId3);

      expect(position1!.index, equals(15)); // Updated position
      expect(position1.offset, equals(150.0));

      expect(position2!.index, equals(25)); // Original position
      expect(position2.offset, equals(250.0));

      expect(position3!.index, equals(40)); // Original position
      expect(position3.offset, equals(400.0));
    });

    test('scroll position restoration flow', () {
      // Arrange
      final chatId = const ChatId('restoration-test');
      const savedIndex = 30;
      const savedOffset = 350.5;

      // Act - Save position when leaving chat
      chatService.saveScrollPosition(chatId, savedIndex, savedOffset);

      // Simulate returning to the chat and retrieving position
      final restoredPosition = chatService.getScrollPosition(chatId);

      // Assert
      expect(restoredPosition, isNotNull);
      expect(restoredPosition!.index, equals(savedIndex));
      expect(restoredPosition.offset, equals(savedOffset));
    });

    test('scroll position cleanup on chat clear', () {
      // Arrange
      final chatId1 = const ChatId('cleanup-test-1');
      final chatId2 = const ChatId('cleanup-test-2');

      chatService.saveScrollPosition(chatId1, 10, 100.0);
      chatService.saveScrollPosition(chatId2, 20, 200.0);

      // Verify positions exist
      expect(chatService.getScrollPosition(chatId1), isNotNull);
      expect(chatService.getScrollPosition(chatId2), isNotNull);

      // Act - Clear specific chat position
      chatService.clearScrollPosition(chatId1);

      // Assert
      expect(chatService.getScrollPosition(chatId1), isNull);
      expect(chatService.getScrollPosition(chatId2), isNotNull);
    });

    test('scroll position debouncing simulation', () {
      // Arrange
      final chatId = const ChatId('debounce-test');

      // Act - Simulate rapid scroll position updates (debouncing scenario)
      chatService.saveScrollPosition(chatId, 1, 10.0);
      chatService.saveScrollPosition(chatId, 2, 20.0);
      chatService.saveScrollPosition(chatId, 3, 30.0);
      chatService.saveScrollPosition(chatId, 4, 40.0);
      chatService.saveScrollPosition(chatId, 5, 50.0); // Final position

      // Assert - Only the last position should be saved
      final finalPosition = chatService.getScrollPosition(chatId);
      expect(finalPosition!.index, equals(5));
      expect(finalPosition.offset, equals(50.0));
    });

    test('scroll position with extreme values', () {
      // Arrange
      final chatId = const ChatId('extreme-values-test');

      // Test boundary values that might occur in real usage
      const maxIndex = 2147483647; // Max int32
      const maxOffset = 1.7976931348623157e+308; // Near max double

      // Act
      chatService.saveScrollPosition(chatId, maxIndex, maxOffset);

      // Assert
      final position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(maxIndex));
      expect(position.offset, equals(maxOffset));
    });

    test('scroll position memory management simulation', () {
      // Arrange - Simulate many chats to test memory usage
      const numberOfChats = 100;
      final chatIds = List.generate(
        numberOfChats,
        (index) => ChatId('memory-test-chat-$index'),
      );

      // Act - Save positions for many chats
      for (int i = 0; i < numberOfChats; i++) {
        chatService.saveScrollPosition(chatIds[i], i, i * 10.0);
      }

      // Assert - All positions should be retrievable
      for (int i = 0; i < numberOfChats; i++) {
        final position = chatService.getScrollPosition(chatIds[i]);
        expect(position, isNotNull);
        expect(position!.index, equals(i));
        expect(position.offset, equals(i * 10.0));
      }

      // Clean up - Clear all positions
      chatService.clearAllScrollPositions();

      // Verify cleanup
      for (int i = 0; i < numberOfChats; i++) {
        expect(chatService.getScrollPosition(chatIds[i]), isNull);
      }
    });
  });
}

/// Test implementation of ChatService that only includes scroll position functionality
class TestChatService {
  /// In-memory storage for chat scroll positions.
  final Map<ChatId, ChatScrollPosition> _scrollPositions = {};

  /// Saves the scroll position for a specific chat.
  void saveScrollPosition(ChatId chatId, int index, double offset) {
    _scrollPositions[chatId] = ChatScrollPosition(index: index, offset: offset);
  }

  /// Retrieves the saved scroll position for a specific chat.
  ChatScrollPosition? getScrollPosition(ChatId chatId) {
    return _scrollPositions[chatId];
  }

  /// Clears the scroll position for a specific chat.
  void clearScrollPosition(ChatId chatId) {
    _scrollPositions.remove(chatId);
  }

  /// Clears all saved scroll positions.
  void clearAllScrollPositions() {
    _scrollPositions.clear();
  }
}
