import 'package:chatbotapp/features/chat/screens/home_screen.dart';
import 'package:chatbotapp/features/vectors/screens/vector_provider.dart';
import 'package:chatbotapp/features/vectors/screens/widgets/vector_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VectorScreen extends ConsumerWidget {
  VectorScreen({super.key});

  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar nuevo vector'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Pregunta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'Respuesta'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final question = _questionController.text.trim();
                final answer = _answerController.text.trim();
                if (question.isNotEmpty && answer.isNotEmpty) {
                  await ref
                      .read(vectorProvider.notifier)
                      .addVector(question, answer);
                  _questionController.clear();
                  _answerController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vectorState = ref.watch(vectorProvider);

    return Scaffold(
      appBar: AppBar(
         
        title: const Text('Gestión de Vectores'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(vectorProvider.notifier).fetchVectors();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
             context.go("/search");
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: vectorState.when(
        data: (vectors) {
          if (vectors.isEmpty) {
            return const Center(child: Text('No hay vectores disponibles.'));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
