import 'package:chatbotapp/features/vectors/screens/vector_provider.dart';
import 'package:chatbotapp/features/vectors/screens/widgets/vector_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VectorSearchScreen extends ConsumerStatefulWidget {
  const VectorSearchScreen({super.key});

  @override
  ConsumerState<VectorSearchScreen> createState() => _VectorSearchScreenState();
}

class _VectorSearchScreenState extends ConsumerState<VectorSearchScreen> {
  final _controller = TextEditingController();
  String? _lastQuery;

  void _search() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _lastQuery = query;
      ref.read(vectorProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vectorState = ref.watch(vectorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar por similitud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              _lastQuery = null;
              ref.read(vectorProvider.notifier).fetchVectors();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu consulta...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _search, child: const Text('Buscar')),
              ],
            ),
          ),
          Expanded(
            child: vectorState.when(
              data: (vectors) {
                if (_lastQuery == null) {
                  return const Center(child: Text('Realiza una búsqueda.'));
                }
                if (vectors.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron resultados.'),
                  );
                }
                return ListView.builder(
                  itemCount: vectors.length,
                  itemBuilder: (context, index) {
                    return VectorCard(data: vectors[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
