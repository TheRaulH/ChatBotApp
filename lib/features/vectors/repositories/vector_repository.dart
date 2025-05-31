import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vector_data.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class VectorRepository {
  final supabase = Supabase.instance.client;
  final openaiKey = dotenv.env['OPENAI_API_KEY']!;

  Future<List<double>> generateEmbedding(String text) async {
    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/embeddings'),
      headers: {
        'Authorization': 'Bearer $openaiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'input': text, 'model': 'text-embedding-ada-002'}),
    );

    final data = jsonDecode(res.body);
    return List<double>.from(data['data'][0]['embedding']);
  }

  Future<void> insertVector(String question, String answer) async {
    final embedding = await generateEmbedding('$question $answer');
    await supabase.from('faq_vectors').insert({
      'question': question,
      'answer': answer,
      'embedding': embedding,
    });
  }

  Future<List<VectorData>> getAllVectors() async {
    final res = await supabase.from('faq_vectors').select().order('created_at');
    print('Fetched vectors: $res');
    return (res as List).map((item) => VectorData.fromJson(item)).toList();
  }

  Future<void> deleteVector(String id) async {
    await supabase.from('faq_vectors').delete().eq('id', id);
  }

  Future<List<VectorData>> searchSimilar(String query) async {
    try {
      final embedding = await generateEmbedding(query);
      print('Embedding length: ${embedding.length}');

      final res = await supabase.rpc(
        'search_faq_vectors',
        params: {'query_embedding': embedding},
      );

      print('Search results length: ${res.length}');

      print('Search results: $res');
      return (res as List).map((item) => VectorData.fromJson(item)).toList();
    } catch (e) {
      print('Error details: ${e.toString()}');
      throw Exception('Search failed: ${e}');
    }
  }
}
