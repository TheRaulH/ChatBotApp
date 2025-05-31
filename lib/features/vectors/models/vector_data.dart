import 'dart:convert';

class VectorData {
  final String id;
  final String question;
  final String answer;
  final List<double> embedding;

  VectorData({
    required this.id,
    required this.question,
    required this.answer,
    required this.embedding,
  });

  factory VectorData.fromJson(Map<String, dynamic> json) {
    // Verifica si el embedding es un String y lo parsea a List<double>
    dynamic embeddingData = json['embedding'];
    List<double> embeddingList;

    if (embeddingData is String) {
      // Conversión segura con verificación de tipos
      final decodedList = jsonDecode(embeddingData) as List;
      embeddingList = decodedList.cast<double>(); // Conversión explícita
    } else if (embeddingData is List) {
      // Conversión directa con verificación
      embeddingList = embeddingData.cast<double>();
    } else {
      throw Exception(
        'Formato de embedding no soportado: ${embeddingData.runtimeType}',
      );
    }

    return VectorData(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      embedding: embeddingList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'embedding': embedding,
    };
  }
}
