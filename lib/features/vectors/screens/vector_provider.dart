import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vector_data.dart';
import '../repositories/vector_repository.dart';

final vectorProvider =
    StateNotifierProvider<VectorNotifier, AsyncValue<List<VectorData>>>(
      (ref) => VectorNotifier(),
    );

class VectorNotifier extends StateNotifier<AsyncValue<List<VectorData>>> {
  final _repo = VectorRepository();

  VectorNotifier() : super(const AsyncValue.loading()) {
    fetchVectors();
  }

  Future<void> fetchVectors() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getAllVectors();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addVector(String question, String answer) async {
    try {
      await _repo.insertVector(question, answer);
      await fetchVectors(); // O simplemente actualizar localmente si quieres evitar un fetch completo
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteVector(String id) async {
    try {
      await _repo.deleteVector(id);
      await fetchVectors();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final results = await _repo.searchSimilar(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clearSearch() {
    fetchVectors(); // o mantener una copia original para restaurar
  }
}
