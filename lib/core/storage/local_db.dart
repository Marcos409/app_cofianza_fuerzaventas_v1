import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDb {
  static const _prefix = 'app_cfv';

  static final LocalDb instance = LocalDb._();
  LocalDb._();

  Database? _database;

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'fuerza_ventas.db');

    return openDatabase(
      path,
      version: 12,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cartera (
            id TEXT PRIMARY KEY,
            asesor_id TEXT NOT NULL,
            cliente_id TEXT NOT NULL,
            agencia_id TEXT,
            fecha_asignacion TEXT NOT NULL,
            tipo_gestion TEXT NOT NULL,
            prioridad TEXT DEFAULT 'normal',
            score_prioridad INTEGER DEFAULT 0,
            estado_visita TEXT DEFAULT 'pendiente',
            resultado_visita TEXT,
            observacion_visita TEXT,
            timestamp_visita TEXT,
            lat_visita REAL,
            lng_visita REAL,
            orden_manual INTEGER DEFAULT 0,
            pendiente_sync INTEGER DEFAULT 0,
            nombre_cliente TEXT NOT NULL,
            documento_cliente TEXT NOT NULL,
            direccion_cliente TEXT NOT NULL,
            telefono_cliente TEXT,
            monto_credito REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS visitas_pendientes (
            id TEXT PRIMARY KEY,
            cartero_id TEXT,
            resultado TEXT,
            observacion TEXT,
            timestamp_visita TEXT,
            lat REAL,
            lng REAL,
            pendiente_sync INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS solicitudes (
            id TEXT PRIMARY KEY,
            cliente_id TEXT NOT NULL,
            tipo_credito TEXT NOT NULL,
            monto_solicitado REAL NOT NULL,
            plazo_meses INTEGER NOT NULL,
            estado TEXT NOT NULL DEFAULT 'borrador',
            datos_json TEXT,
            pendiente_sync INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS documentos (
            id TEXT PRIMARY KEY,
            solicitud_id TEXT NOT NULL,
            tipo_documento TEXT NOT NULL,
            ruta_archivo TEXT,
            pendiente_sync INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tabla TEXT NOT NULL,
            registro_id TEXT NOT NULL,
            operacion TEXT NOT NULL,
            payload TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ficha_cache (
            cliente_id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            documento TEXT NOT NULL,
            direccion TEXT NOT NULL,
            telefono TEXT,
            email TEXT,
            tipo_negocio TEXT,
            antiguedad_negocio INTEGER,
            lat REAL,
            lng REAL,
            calificacion_sbs TEXT DEFAULT 'normal',
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS creditos_cache (
            cliente_id TEXT NOT NULL,
            credito_id TEXT NOT NULL,
            monto REAL NOT NULL,
            plazo_meses INTEGER NOT NULL,
            tea REAL NOT NULL,
            estado TEXT NOT NULL,
            porcentaje_puntual REAL DEFAULT 100,
            fecha_apertura TEXT,
            fecha_cierre TEXT,
            PRIMARY KEY (cliente_id, credito_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS pagos_cache (
            cliente_id TEXT NOT NULL,
            mes INTEGER NOT NULL,
            anio INTEGER NOT NULL,
            monto_pagado REAL NOT NULL,
            status TEXT NOT NULL,
            PRIMARY KEY (cliente_id, anio, mes)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ofertas_cache (
            cliente_id TEXT PRIMARY KEY,
            oferta_id TEXT NOT NULL,
            monto_maximo REAL NOT NULL,
            plazo_sugerido_meses INTEGER NOT NULL,
            tea_referencial REAL NOT NULL,
            score_confianza INTEGER NOT NULL,
            vigente INTEGER DEFAULT 1,
            fecha_vencimiento TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS pre_evaluaciones_pendientes (
            id TEXT PRIMARY KEY,
            asesor_id TEXT,
            datos_json TEXT NOT NULL,
            pendiente_sync INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS campanas_cache (
            id TEXT PRIMARY KEY,
            cliente_id TEXT NOT NULL,
            nombre_cliente TEXT NOT NULL,
            tipo TEXT NOT NULL,
            monto_ofertado REAL NOT NULL,
            fecha_vencimiento TEXT NOT NULL,
            activa INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS solicitudes_borrador (
            id TEXT PRIMARY KEY,
            cliente_id TEXT,
            cliente_nombre TEXT,
            paso_actual INTEGER DEFAULT 0,
            datos_json TEXT,
            monto_solicitado REAL DEFAULT 0,
            asesor_id TEXT,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS solicitudes_enviadas (
            id TEXT PRIMARY KEY,
            asesor_id TEXT NOT NULL,
            datos_json TEXT,
            estado TEXT DEFAULT 'enviado',
            pendiente_sync INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS solicitudes_documentos (
            id TEXT PRIMARY KEY,
            solicitud_id TEXT NOT NULL,
            tipo_documento TEXT NOT NULL,
            estado TEXT DEFAULT 'pendiente',
            storage_url TEXT,
            tamanio_kb INTEGER,
            nitidez_score REAL,
            local_path TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS consultas_buro (
            id TEXT PRIMARY KEY,
            asesor_id TEXT NOT NULL,
            cliente_id TEXT NOT NULL,
            dni_consultado TEXT NOT NULL,
            calificacion_sbs TEXT,
            entidades_con_deuda INTEGER DEFAULT 0,
            deuda_total_pen REAL DEFAULT 0,
            mayor_deuda REAL DEFAULT 0,
            dias_mayor_mora INTEGER DEFAULT 0,
            resultado_json TEXT,
            en_lista_negra INTEGER DEFAULT 0,
            motivo_bloqueo TEXT,
            firma_consentimiento_base64 TEXT,
            solicitud_id TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS transmision_estado (
            solicitud_id TEXT PRIMARY KEY,
            paso_completado INTEGER DEFAULT 0,
            documentos_subidos TEXT,
            expediente_generado TEXT,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS solicitudes_notas_internas (
            id TEXT PRIMARY KEY,
            solicitud_id TEXT NOT NULL,
            asesor_id TEXT NOT NULL,
            contenido TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS acciones_cobranza_pendientes (
            id TEXT PRIMARY KEY,
            asesor_id TEXT NOT NULL,
            cliente_id TEXT NOT NULL,
            credito_id TEXT NOT NULL,
            tipo_gestion TEXT NOT NULL,
            resultado TEXT NOT NULL,
            monto_pagado REAL,
            fecha_compromiso TEXT,
            monto_compromiso REAL,
            observaciones TEXT,
            lat REAL,
            lng REAL,
            timestamp_gestion TEXT NOT NULL,
            pendiente_sync INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS posicion_cache (
            cliente_id TEXT PRIMARY KEY,
            deuda_total REAL NOT NULL DEFAULT 0,
            cuentas_vigentes INTEGER NOT NULL DEFAULT 0,
            cuentas_mora INTEGER NOT NULL DEFAULT 0,
            dias_mayor_mora INTEGER NOT NULL DEFAULT 0,
            ultimo_pago TEXT,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS cartera_vencida_cache (
            id TEXT PRIMARY KEY,
            cliente_id TEXT NOT NULL,
            credito_id TEXT NOT NULL,
            nombre_cliente TEXT NOT NULL,
            documento_cliente TEXT NOT NULL,
            telefono TEXT,
            direccion TEXT,
            dias_mora INTEGER NOT NULL DEFAULT 0,
            monto_vencido REAL NOT NULL DEFAULT 0,
            saldo_actual REAL NOT NULL DEFAULT 0,
            ultimo_contacto TEXT,
            cuotas_pagadas INTEGER,
            total_cuotas INTEGER,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ficha_cache (
              cliente_id TEXT PRIMARY KEY,
              nombre TEXT NOT NULL,
              documento TEXT NOT NULL,
              direccion TEXT NOT NULL,
              telefono TEXT,
              email TEXT,
              tipo_negocio TEXT,
              antiguedad_negocio INTEGER,
              lat REAL,
              lng REAL,
              calificacion_sbs TEXT DEFAULT 'normal',
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS creditos_cache (
              cliente_id TEXT NOT NULL,
              credito_id TEXT NOT NULL,
              monto REAL NOT NULL,
              plazo_meses INTEGER NOT NULL,
              tea REAL NOT NULL,
              estado TEXT NOT NULL,
              porcentaje_puntual REAL DEFAULT 100,
              fecha_apertura TEXT,
              fecha_cierre TEXT,
              PRIMARY KEY (cliente_id, credito_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pagos_cache (
              cliente_id TEXT NOT NULL,
              mes INTEGER NOT NULL,
              anio INTEGER NOT NULL,
              monto_pagado REAL NOT NULL,
              status TEXT NOT NULL,
              PRIMARY KEY (cliente_id, anio, mes)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ofertas_cache (
              cliente_id TEXT PRIMARY KEY,
              oferta_id TEXT NOT NULL,
              monto_maximo REAL NOT NULL,
              plazo_sugerido_meses INTEGER NOT NULL,
              tea_referencial REAL NOT NULL,
              score_confianza INTEGER NOT NULL,
              vigente INTEGER DEFAULT 1,
              fecha_vencimiento TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pre_evaluaciones_pendientes (
              id TEXT PRIMARY KEY,
              asesor_id TEXT,
              datos_json TEXT NOT NULL,
              pendiente_sync INTEGER DEFAULT 1,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS campanas_cache (
              id TEXT PRIMARY KEY,
              cliente_id TEXT NOT NULL,
              nombre_cliente TEXT NOT NULL,
              tipo TEXT NOT NULL,
              monto_ofertado REAL NOT NULL,
              fecha_vencimiento TEXT NOT NULL,
              activa INTEGER DEFAULT 1
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS solicitudes_borrador (
              id TEXT PRIMARY KEY,
              cliente_id TEXT,
              cliente_nombre TEXT,
              paso_actual INTEGER DEFAULT 0,
              datos_json TEXT,
              monto_solicitado REAL DEFAULT 0,
              asesor_id TEXT,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS solicitudes_enviadas (
              id TEXT PRIMARY KEY,
              asesor_id TEXT NOT NULL,
              datos_json TEXT,
              estado TEXT DEFAULT 'enviado',
              pendiente_sync INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS solicitudes_documentos (
              id TEXT PRIMARY KEY,
              solicitud_id TEXT NOT NULL,
              tipo_documento TEXT NOT NULL,
              estado TEXT DEFAULT 'pendiente',
              storage_url TEXT,
              tamanio_kb INTEGER,
              nitidez_score REAL,
              local_path TEXT,
              created_at TEXT
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS consultas_buro (
              id TEXT PRIMARY KEY,
              asesor_id TEXT NOT NULL,
              cliente_id TEXT NOT NULL,
              dni_consultado TEXT NOT NULL,
              calificacion_sbs TEXT,
              entidades_con_deuda INTEGER DEFAULT 0,
              deuda_total_pen REAL DEFAULT 0,
              mayor_deuda REAL DEFAULT 0,
              dias_mayor_mora INTEGER DEFAULT 0,
              resultado_json TEXT,
              en_lista_negra INTEGER DEFAULT 0,
              motivo_bloqueo TEXT,
              firma_consentimiento_base64 TEXT,
              solicitud_id TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS transmision_estado (
              solicitud_id TEXT PRIMARY KEY,
              paso_completado INTEGER DEFAULT 0,
              documentos_subidos TEXT,
              expediente_generado TEXT,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS solicitudes_notas_internas (
              id TEXT PRIMARY KEY,
              solicitud_id TEXT NOT NULL,
              asesor_id TEXT NOT NULL,
              contenido TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS acciones_cobranza_pendientes (
              id TEXT PRIMARY KEY,
              asesor_id TEXT NOT NULL,
              cliente_id TEXT NOT NULL,
              credito_id TEXT NOT NULL,
              tipo_gestion TEXT NOT NULL,
              resultado TEXT NOT NULL,
              monto_pagado REAL,
              fecha_compromiso TEXT,
              monto_compromiso REAL,
              observaciones TEXT,
              lat REAL,
              lng REAL,
              timestamp_gestion TEXT NOT NULL,
              pendiente_sync INTEGER DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cartera_vencida_cache (
              id TEXT PRIMARY KEY,
              cliente_id TEXT NOT NULL,
              credito_id TEXT NOT NULL,
              nombre_cliente TEXT NOT NULL,
              documento_cliente TEXT NOT NULL,
              telefono TEXT,
              direccion TEXT,
              dias_mora INTEGER NOT NULL DEFAULT 0,
              monto_vencido REAL NOT NULL DEFAULT 0,
              saldo_actual REAL NOT NULL DEFAULT 0,
              ultimo_contacto TEXT,
              cuotas_pagadas INTEGER,
              total_cuotas INTEGER,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS visitas_pendientes (
              id TEXT PRIMARY KEY,
              cartero_id TEXT,
              resultado TEXT,
              observacion TEXT,
              timestamp_visita TEXT,
              lat REAL,
              lng REAL,
              pendiente_sync INTEGER DEFAULT 1
            )
          ''');
          await db.execute('ALTER TABLE cartera RENAME TO cartera_old');
          await db.execute('''
            CREATE TABLE cartera (
              id TEXT PRIMARY KEY,
              asesor_id TEXT NOT NULL,
              cliente_id TEXT NOT NULL,
              agencia_id TEXT,
              fecha_asignacion TEXT NOT NULL,
              tipo_gestion TEXT NOT NULL,
              prioridad TEXT DEFAULT 'normal',
              score_prioridad INTEGER DEFAULT 0,
              estado_visita TEXT DEFAULT 'pendiente',
              resultado_visita TEXT,
              observacion_visita TEXT,
              timestamp_visita TEXT,
              lat_visita REAL,
              lng_visita REAL,
              orden_manual INTEGER DEFAULT 0,
              pendiente_sync INTEGER DEFAULT 0,
              nombre_cliente TEXT NOT NULL,
              documento_cliente TEXT NOT NULL,
              direccion_cliente TEXT NOT NULL,
              telefono_cliente TEXT,
              monto_credito REAL
            )
          ''');
          await db.execute('DROP TABLE IF EXISTS cartera_old');
        }
        if (oldVersion < 12) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS posicion_cache (
              cliente_id TEXT PRIMARY KEY,
              deuda_total REAL NOT NULL DEFAULT 0,
              cuentas_vigentes INTEGER NOT NULL DEFAULT 0,
              cuentas_mora INTEGER NOT NULL DEFAULT 0,
              dias_mayor_mora INTEGER NOT NULL DEFAULT 0,
              ultimo_pago TEXT,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('cartera');
    await db.delete('visitas_pendientes');
    await db.delete('solicitudes');
    await db.delete('documentos');
    await db.delete('sync_queue');
    await db.delete('ficha_cache');
    await db.delete('creditos_cache');
    await db.delete('pagos_cache');
    await db.delete('ofertas_cache');
    await db.delete('pre_evaluaciones_pendientes');
    await db.delete('campanas_cache');
    await db.delete('solicitudes_borrador');
    await db.delete('solicitudes_enviadas');
    await db.delete('solicitudes_documentos');
    await db.delete('consultas_buro');
    await db.delete('transmision_estado');
    await db.delete('solicitudes_notas_internas');
    await db.delete('acciones_cobranza_pendientes');
    await db.delete('cartera_vencida_cache');
    await db.delete('posicion_cache');
  }

  // Secure Storage methods
  Future<void> saveToken(String token) =>
      _secureStorage.write(key: '$_prefix/auth_token', value: token);

  Future<String?> getToken() =>
      _secureStorage.read(key: '$_prefix/auth_token');

  Future<void> deleteToken() =>
      _secureStorage.delete(key: '$_prefix/auth_token');

  Future<void> saveSession(String sessionJson) =>
      _secureStorage.write(key: '$_prefix/session', value: sessionJson);

  Future<String?> getSession() =>
      _secureStorage.read(key: '$_prefix/session');

  Future<void> deleteSession() =>
      _secureStorage.delete(key: '$_prefix/session');

  Future<void> saveUserData(String userDataJson) =>
      _secureStorage.write(key: '$_prefix/user_data', value: userDataJson);

  Future<String?> getUserData() =>
      _secureStorage.read(key: '$_prefix/user_data');

  Future<void> saveAttempts(int count) =>
      _secureStorage.write(key: '$_prefix/login_attempts', value: count.toString());

  Future<int> getAttempts() async {
    final v = await _secureStorage.read(key: '$_prefix/login_attempts');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> saveBlockTime(DateTime time) =>
      _secureStorage.write(key: '$_prefix/block_until', value: time.toIso8601String());

  Future<DateTime?> getBlockTime() async {
    final v = await _secureStorage.read(key: '$_prefix/block_until');
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> saveLastActivity(DateTime time) =>
      _secureStorage.write(key: '$_prefix/last_activity', value: time.toIso8601String());

  Future<DateTime?> getLastActivity() async {
    final v = await _secureStorage.read(key: '$_prefix/last_activity');
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await clearDatabase();
  }
}
