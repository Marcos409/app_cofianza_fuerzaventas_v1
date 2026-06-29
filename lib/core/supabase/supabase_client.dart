// ════════════════════════════════════════════════════════════
// 🔧 SUPABASE_COMENTADO: Desarrollando solo con PostgreSQL local - Junio 2026
// ════════════════════════════════════════════════════════════
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class SupabaseService {
//   static final SupabaseService instance = SupabaseService._();
//   SupabaseService._();
//
//   Future<void> initialize() async {
//     await Supabase.initialize(
//       url: const String.fromEnvironment(
//         'SUPABASE_URL',
//         defaultValue: 'https://hclshbuowoykwdzhkmkj.supabase.co',
//       ),
//       publishableKey: const String.fromEnvironment(
//         'SUPABASE_ANON_KEY',
//         defaultValue: 'sb_publishable_bQx2okkLJlKTT5euRnQYWA_fHbj-KrG',
//       ),
//     );
//   }
//
//   GoTrueClient get auth => Supabase.instance.client.auth;
//   SupabaseClient get client => Supabase.instance.client;
// }
// ════════════════════════════════════════════════════════════
// Stub para que el código compile sin Supabase activo:
class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();
  Future<void> initialize() async {}
}
// ════════════════════════════════════════════════════════════
