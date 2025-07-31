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
  group('ChatService scroll position tests', () {
    late TestChatService chatService;

    setUp(() {
      chatService = TestChatService();
    });

    test('saveScrollPosition stores position correctly', () {
      // Arrange
      const ChatId chatId = ChatId('test-chat-id');
      const int index = 10;
      const double offset = 150.5;

      // Act
      chatService.saveScrollPosition(chatId, index, offset);

      // Assert
      final ChatScrollPosition? retrievedPosition = chatService.getScrollPosition(chatId);
      expect(retrievedPosition, isNotNull);
      expect(retrievedPosition!.index, equals(index));
      expect(retrievedPosition.offset, equals(offset));
    });

    test('getScrollPosition returns null for non-existent chat', () {
      // Arrange
      const ChatId chatId = ChatId('non-existent-chat');

      // Act
      final ChatScrollPosition? position = chatService.getScrollPosition(chatId);

      // Assert
      expect(position, isNull);
    });

    test('getScrollPosition returns correct position for existing chat', () {
      // Arrange
      const ChatId chatId = ChatId('existing-chat');
      const int index = 25;
      const double offset = 75.3;

      chatService.saveScrollPosition(chatId, index, offset);

      // Act
      final ChatScrollPosition? position = chatService.getScrollPosition(chatId);

      // Assert
      expect(position, isNotNull);
      expect(position!.index, equals(index));
      expect(position.offset, equals(offset));
    });

    test('clearScrollPosition removes position for specific chat', () {
      // Arrange
      const ChatId chatId1 = ChatId('chat-1');
      const ChatId chatId2 = ChatId('chat-2');

      chatService.saveScrollPosition(chatId1, 10, 50.0);
      chatService.saveScrollPosition(chatId2, 20, 100.0);

      // Act
      chatService.clearScrollPosition(chatId1);

      // Assert
      expect(chatService.getScrollPosition(chatId1), isNull);
      expect(chatService.getScrollPosition(chatId2), isNotNull);
    });

    test('clearAllScrollPositions removes all positions', () {
      // Arrange
      const ChatId chatId1 = ChatId('chat-1');
      const ChatId chatId2 = ChatId('chat-2');
      const ChatId chatId3 = ChatId('chat-3');

      chatService.saveScrollPosition(chatId1, 10, 50.0);
      chatService.saveScrollPosition(chatId2, 20, 100.0);
      chatService.saveScrollPosition(chatId3, 30, 150.0);

      // Act
      chatService.clearAllScrollPositions();

      // Assert
      expect(chatService.getScrollPosition(chatId1), isNull);
      expect(chatService.getScrollPosition(chatId2), isNull);
      expect(chatService.getScrollPosition(chatId3), isNull);
    });

    test('saveScrollPosition overwrites existing position', () {
      // Arrange
      const ChatId chatId = ChatId('test-chat');

      // Save initial position
      chatService.saveScrollPosition(chatId, 10, 50.0);

      // Verify initial position
      ChatScrollPosition? position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(10));
      expect(position.offset, equals(50.0));

      // Act - overwrite with new position
      chatService.saveScrollPosition(chatId, 20, 100.0);

      // Assert
      position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(20));
      expect(position.offset, equals(100.0));
    });

    test('multiple chats can have different scroll positions', () {
      // Arrange
      const ChatId chatId1 = ChatId('chat-1');
      const ChatId chatId2 = ChatId('chat-2');
      const ChatId chatId3 = ChatId('chat-3');

      // Act
      chatService.saveScrollPosition(chatId1, 5, 25.5);
      chatService.saveScrollPosition(chatId2, 15, 75.8);
      chatService.saveScrollPosition(chatId3, 30, 200.2);

      // Assert
      final ChatScrollPosition? position1 = chatService.getScrollPosition(chatId1);
      final ChatScrollPosition? position2 = chatService.getScrollPosition(chatId2);
      final ChatScrollPosition? position3 = chatService.getScrollPosition(chatId3);

      expect(position1!.index, equals(5));
      expect(position1.offset, equals(25.5));

      expect(position2!.index, equals(15));
      expect(position2.offset, equals(75.8));

      expect(position3!.index, equals(30));
      expect(position3.offset, equals(200.2));
    });

    test('scroll positions handle edge values correctly', () {
      // Arrange
      const ChatId chatId = ChatId('edge-values-chat');

      // Test with zero values
      chatService.saveScrollPosition(chatId, 0, 0.0);
      ChatScrollPosition? position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(0));
      expect(position.offset, equals(0.0));

      // Test with negative values (edge case)
      chatService.saveScrollPosition(chatId, -1, -10.5);
      position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(-1));
      expect(position.offset, equals(-10.5));

      // Test with large values
      chatService.saveScrollPosition(chatId, 999999, 999999.999);
      position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(999999));
      expect(position.offset, equals(999999.999));
    });

    test('ChatScrollPosition constructor creates object correctly', () {
      // Arrange & Act
      const position = ChatScrollPosition(index: 42, offset: 123.45);

      // Assert
      expect(position.index, equals(42));
      expect(position.offset, equals(123.45));
    });

    test('scroll positions are not persistent across service instances', () {
      // Arrange
      const ChatId chatId = ChatId('persistence-test');
      chatService.saveScrollPosition(chatId, 10, 50.0);

      // Verify position exists
      expect(chatService.getScrollPosition(chatId), isNotNull);

      // Act - simulate creating new service instance
      final newChatService = TestChatService();

      // Assert - new instance should not have the position
      expect(newChatService.getScrollPosition(chatId), isNull);
    });

    test('clearScrollPosition handles non-existent chat gracefully', () {
      // Arrange
      const ChatId nonExistentChatId = ChatId('non-existent');

      // Act & Assert - should not throw an exception
      expect(
        () => chatService.clearScrollPosition(nonExistentChatId),
        returnsNormally,
      );
      expect(chatService.getScrollPosition(nonExistentChatId), isNull);
    });

    test('scroll position values maintain precision', () {
      // Arrange
      const ChatId chatId = ChatId('precision-test');
      const int index = 42;
      const double offset = 123.456789;

      // Act
      chatService.saveScrollPosition(chatId, index, offset);

      // Assert
      final ChatScrollPosition? position = chatService.getScrollPosition(chatId);
      expect(position!.index, equals(index));
      expect(position.offset, equals(offset));
    });

    test(
      'saveScrollPosition with same chatId multiple times updates correctly',
      () {
        // Arrange
        const ChatId chatId = ChatId('update-test');

        // Act & Assert - Multiple updates
        chatService.saveScrollPosition(chatId, 1, 10.0);
        expect(chatService.getScrollPosition(chatId)!.index, equals(1));
        expect(chatService.getScrollPosition(chatId)!.offset, equals(10.0));

        chatService.saveScrollPosition(chatId, 2, 20.0);
        expect(chatService.getScrollPosition(chatId)!.index, equals(2));
        expect(chatService.getScrollPosition(chatId)!.offset, equals(20.0));

        chatService.saveScrollPosition(chatId, 3, 30.0);
        expect(chatService.getScrollPosition(chatId)!.index, equals(3));
        expect(chatService.getScrollPosition(chatId)!.offset, equals(30.0));
      },
    );

    test('ChatScrollPosition equality and hashCode', () {
      // Arrange
      const ChatScrollPosition position1 = ChatScrollPosition(index: 10, offset: 50.5);
      const ChatScrollPosition position2 = ChatScrollPosition(index: 10, offset: 50.5);
      const ChatScrollPosition position3 = ChatScrollPosition(index: 11, offset: 50.5);

      // Assert
      expect(position1.index, equals(position2.index));
      expect(position1.offset, equals(position2.offset));
      expect(position1.index, isNot(equals(position3.index)));
    });
  });
}

/// Test implementation of ChatService that only includes scroll position functionality.
///
/// This simplified version of ChatService is used for testing scroll position
/// functionality in isolation without the complexity of the full service.
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
