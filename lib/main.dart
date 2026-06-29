import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'app/app.dart';
import 'core/cache/local_cache.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/firebase_messaging_service.dart';

final DateTime _appStarted = DateTime.now();

String _ts() {
  final now = DateTime.now();
  return '[${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}]';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =============================================
  // runApp() inmediatamente - UI primero
  // =============================================
  print('${_ts()} [MAIN] runApp() — mostrando login primero');
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
  print('${_ts()} [MAIN] runApp() ejecutado, UI mostrandose');

  // =============================================
  // Todo lo demás en background
  // =============================================
  print('${_ts()} [MAIN] Inicializando servicios en background...');
  unawaited(_initAllServices());
}

Future<void> _initAllServices() async {
  // 1. Inicializar cache local (SQLite)
  print('${_ts()} [BG] === Cache local SQLite ===');
  try {
    await LocalCache.instance.database;
    print('${_ts()} [BG] Cache local OK');
  } catch (e) {
    print('${_ts()} [BG] ERROR cache local: $e');
  }

  // 2. NotificationService
  print('${_ts()} [BG] NotificationService...');
  try {
    await NotificationService.instance.initialize();
    print('${_ts()} [BG] NotificationService OK');
  } catch (e) {
    print('${_ts()} [BG] NotificationService ERROR: $e');
  }

  // 4. FirebaseMessagingService
  print('${_ts()} [BG] FirebaseMessagingService...');
  try {
    await FirebaseMessagingService.instance.initialize();
    print('${_ts()} [BG] FirebaseMessagingService OK');
  } catch (e) {
    print('${_ts()} [BG] FirebaseMessagingService ERROR: $e');
  }

  // 5. Workmanager
  print('${_ts()} [BG] Workmanager...');
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    print('${_ts()} [BG] Workmanager OK');

    await Workmanager().registerPeriodicTask(
      'syncNocturna',
      SyncService.syncTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      initialDelay: _nextSyncDelay(),
    );
    print('${_ts()} [BG] Sync nocturna registrada');
  } catch (e) {
    print('${_ts()} [BG] Workmanager ERROR: $e');
  }

  print('${_ts()} [BG] Todos los servicios inicializados (${DateTime.now().difference(_appStarted).inMilliseconds}ms)');
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == SyncService.syncTaskName) {
      await SyncService.executeSyncTask();
    }
    return true;
  });
}

Duration _nextSyncDelay() {
  final now = DateTime.now();
  final scheduled = DateTime(now.year, now.month, now.day, 22, 0);
  if (now.isAfter(scheduled)) {
    return scheduled.add(const Duration(hours: 24)).difference(now);
  }
  return scheduled.difference(now);
}
