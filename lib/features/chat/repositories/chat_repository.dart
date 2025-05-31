import 'package:chatbotapp/features/vectors/repositories/vector_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatRepository {
  static const _databaseName = 'chat_database.db';
  static const _databaseVersion = 2;
  static const chatsTable = 'chats';
  static const messagesTable = 'messages';

  late Database _db;

  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $chatsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $messagesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        is_user_message INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES $chatsTable (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $chatsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        ALTER TABLE $messagesTable ADD COLUMN chat_id INTEGER NOT NULL DEFAULT 1
      ''');

      // Crear un chat por defecto para los mensajes existentes
      await db.insert(chatsTable, {
        'title': 'Chat inicial',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Operaciones para Chats
  Future<int> createChat(String title) async {
    final chat = Chat(title: title, createdAt: DateTime.now());
    return await _db.insert(chatsTable, chat.toMap());
  }

  Future<List<Chat>> getAllChats() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      chatsTable,
      orderBy: 'updated_at DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => Chat.fromMap(maps[i]));
  }

  Future<int> updateChatTitle(int chatId, String newTitle) async {
    return await _db.update(
      chatsTable,
      {'title': newTitle, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<int> deleteChat(int chatId) async {
    await _db.delete(messagesTable, where: 'chat_id = ?', whereArgs: [chatId]);
    return await _db.delete(chatsTable, where: 'id = ?', whereArgs: [chatId]);
  }

  // Operaciones para Mensajes
  Future<int> insertMessage(ChatMessage message) async {
    // Actualizar la fecha de modificación del chat
    await _db.update(
      chatsTable,
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [message.chatId],
    );

    return await _db.insert(messagesTable, message.toMap());
  }

  Future<List<ChatMessage>> getMessagesForChat(int chatId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      messagesTable,
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<void> clearChatMessages(int chatId) async {
    await _db.delete(messagesTable, where: 'chat_id = ?', whereArgs: [chatId]);
  }

  Future<String> generateRAGResponse(String prompt, {int topK = 3}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no está configurada en .env');
    }

    // 1. Buscar información relevante usando embeddings
    final vectorRepo = VectorRepository();
    final similarVectors = await vectorRepo.searchSimilar(prompt);

    // 2. Construir el contexto con los resultados más relevantes
    String context = '';
    if (similarVectors.isNotEmpty) {
      final topResults = similarVectors.take(topK).toList();
      context = 'Información relevante encontrada:\n';
      for (var i = 0; i < topResults.length; i++) {
        context +=
            '${i + 1}. Pregunta: ${topResults[i].question}\n'
            '   Respuesta: ${topResults[i].answer}\n\n';
      }
    } else {
      context =
          'No se encontró información relevante en la base de conocimientos.\n';
    }

    // 3. Construir el prompt aumentado con el contexto
    final augmentedPrompt = '''
    Contexto de conocimiento extraído de la base de datos (puede ser útil o no):

    $context

    Instrucciones importantes para responder:
    - Si el contexto es útil, úsalo para dar una respuesta clara y precisa.
    - Si el contexto no ayuda o no es relevante, responde igual usando tu conocimiento general.
    - No expliques si el contexto fue útil o no. Solo responde la pregunta.
    - Sé directo, concreto y breve.

    Pregunta: $prompt

    Respuesta:
    ''';


    // 4. Generar la respuesta usando Gemini
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": "Tu eres un asistente llamado CoddyKIA es un chatbot inteligente diseñado para responder preguntas basadas en su base de conocimiento."},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': augmentedPrompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          "maxOutputTokens": 800,
          'topK': 40,
          'topP': 0.95
          },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Error al generar respuesta: ${response.statusCode}');
    }
  }

  Future<void> close() async {
    await _db.close();
  }
}
