import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/storage/local_db.dart';
import 'core/storage/seed_data.dart';
import 'core/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.instance.initialize();

  final db = await LocalDb.instance.database;
  await SeedData.seed(db);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
