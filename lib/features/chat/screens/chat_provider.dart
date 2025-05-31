import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';

final chatRepositoryProvider = FutureProvider<ChatRepository>((ref) async {
  final repository = ChatRepository();
  await repository.init(); // <- ahora sí esperas la inicialización
  ref.onDispose(() => repository.close());
  return repository;
});

final chatsListProvider =
    NotifierProvider<ChatsListNotifier, AsyncValue<List<Chat>>>(
      ChatsListNotifier.new,
    );

class ChatsListNotifier extends Notifier<AsyncValue<List<Chat>>> {
  @override
  AsyncValue<List<Chat>> build() {
    _loadChats();
    return const AsyncValue.loading();
  }

  Future<void> _loadChats() async {
    state = const AsyncValue.loading();
    try {
      final repository = await ref.watch(
        chatRepositoryProvider.future,
      ); // ✅ cambio aquí
      final chats = await repository.getAllChats();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> createNewChat(String initialMessage) async {
    try {
      final repository = await ref.watch(
        chatRepositoryProvider.future,
      ); // ✅ cambio aquí
      final chatId = await repository.createChat(
        initialMessage.length > 20
            ? '${initialMessage.substring(0, 20)}...'
            : initialMessage,
      );
      await _loadChats();
      return chatId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateChatTitle(int chatId, String newTitle) async {
    try {
      final repository = await ref.watch(chatRepositoryProvider.future); // ✅
      await repository.updateChatTitle(chatId, newTitle);
      await _loadChats();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteChat(int chatId) async {
    try {
      final repository = await ref.watch(chatRepositoryProvider.future); // ✅
      await repository.deleteChat(chatId);
      await _loadChats();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}


final chatProvider =
    NotifierProvider.family<ChatNotifier, AsyncValue<List<ChatMessage>>, int>(
      () => ChatNotifier(),
    );

class ChatNotifier extends FamilyNotifier<AsyncValue<List<ChatMessage>>, int> {
  @override
  AsyncValue<List<ChatMessage>> build(int arg) {
    _loadMessages(arg);
    return const AsyncValue.loading();
  }

  Future<void> _loadMessages(int chatId) async {
    state = const AsyncValue.loading();
    try {
      final repository = await ref.watch(chatRepositoryProvider.future); // ✅
      final messages = await repository.getMessagesForChat(chatId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(int chatId, String message) async {
    try {
      final repository = await ref.watch(chatRepositoryProvider.future); // ✅

      final userMessage = ChatMessage(
        chatId: chatId,
        content: message,
        isUserMessage: true,
        timestamp: DateTime.now(),
      );
      await repository.insertMessage(userMessage);

      final response = await repository.generateRAGResponse(message);
      final botMessage = ChatMessage(
        chatId: chatId,
        content: response,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      await repository.insertMessage(botMessage);

      await _loadMessages(chatId);
      await ref.read(chatsListProvider.notifier)._loadChats();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearChat(int chatId) async {
    try {
      final repository = await ref.watch(chatRepositoryProvider.future); // ✅
      await repository.clearChatMessages(chatId);
      await _loadMessages(chatId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
