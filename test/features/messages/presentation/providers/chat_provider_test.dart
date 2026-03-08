import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/messages/presentation/providers/chat_provider.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late MockChatRepository mockChatRepository;
  late ProviderContainer container;

  setUp(() {
    mockChatRepository = MockChatRepository();

    sl.allowReassignment = true;
    sl.registerLazySingleton<ChatRepository>(() => mockChatRepository);

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('ChatProvider Tests', () {
    final tContact = ChatContact(
      id: '1',
      name: 'Dr. Test',
      role: 'doctor',
      unread: 0,
      email: 'doc@test.com',
    );
    final tMessage = Message(
      id: '1',
      senderId: 'pat1',
      receiverId: 'doc1',
      content: 'Hello',
      timestamp: DateTime.now(),
      isRead: false,
      type: 'TEXT',
    );

    test('initial state should be ChatInitial', () {
      final state = container.read(chatNotifierProvider);
      expect(state, isA<ChatInitial>());
    });

    test('loadContacts should emit loading and then ContactsLoaded', () async {
      // arrange
      when(
        mockChatRepository.getContacts(),
      ).thenAnswer((_) async => [tContact]);

      // act
      final notifier = container.read(chatNotifierProvider.notifier);
      final future = notifier.loadContacts();

      expect(container.read(chatNotifierProvider), isA<ChatLoading>());

      await future;

      final finalState = container.read(chatNotifierProvider);
      expect(finalState, isA<ContactsLoaded>());
      if (finalState is ContactsLoaded) {
        expect(finalState.contacts, equals([tContact]));
      }
    });

    test('loadMessages should emit MessagesLoaded', () async {
      // arrange
      when(
        mockChatRepository.getMessages(any),
      ).thenAnswer((_) async => [tMessage]);

      // act
      await container.read(chatNotifierProvider.notifier).loadMessages('doc1');

      // assert
      final finalState = container.read(chatNotifierProvider);
      expect(finalState, isA<MessagesLoaded>());
      if (finalState is MessagesLoaded) {
        expect(finalState.messages, equals([tMessage]));
        expect(finalState.activeChatUserId, equals('doc1'));
      }
    });

    test('sendMessage should call repository', () async {
      // arrange
      when(
        mockChatRepository.sendMessage(any),
      ).thenAnswer((_) async => Future.value());

      // act
      await container.read(chatNotifierProvider.notifier).sendMessage(tMessage);

      // assert
      verify(mockChatRepository.sendMessage(tMessage)).called(1);
    });
  });
}
