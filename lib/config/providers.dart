import 'package:chatbotapp/config/sqlite_config.dart';
import 'package:chatbotapp/config/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

final sqliteProvider = Provider<Future<Database>>((ref) async {
  return await SQLiteConfig.database;
});
