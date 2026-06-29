import 'dart:convert';
import '../network/api_client.dart';
import '../cache/local_cache.dart';
import '../storage/local_db.dart';
import 'notification_service.dart';

class SyncService {
  static const String syncTaskName = 'syncNocturna';

  static Future<void> executeSyncTask() async {
    try {
      final userDataStr = await LocalDb.instance.getUserData();
      if (userDataStr == null) return;

      final asesorId = _extractAsesorId(userDataStr);
      if (asesorId == null) return;

      final api = ApiClient.instance;
      final cache = LocalCache.instance;

      // Sincronizar cartera diaria desde el backend
      try {
        final response = await api.get<List>(
          '/cartera/diaria',
          params: {'asesor_id': asesorId},
        );
        await cache.cacheList('cartera_cache', asesorId, response, 'id');
      } catch (_) {}

      final count = (await cache.getCachedList('cartera_cache', asesorId))
          .length;

      await NotificationService.instance.showNotification(
        id: DateTime.now().millisecond,
        title: 'Cartera sincronizada',
        body: 'Tu cartera de mañana está lista: $count clientes.',
        payload: 'cartera',
      );
    } catch (_) {}
  }

  static String? _extractAsesorId(String userDataJson) {
    try {
      final map = jsonDecode(userDataJson) as Map<String, dynamic>;
      final id = map['id'];
      if (id != null) return id.toString();
      return map['user_id']?.toString();
    } catch (_) {
      return null;
    }
  }
}
