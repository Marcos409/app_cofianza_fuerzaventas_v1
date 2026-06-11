import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/network_monitor.dart';
import '../../../core/storage/local_db.dart';
import '../domain/cliente_mora.dart';
import '../domain/accion_cobranza.dart';

class CobranzaRepository {
  final SupabaseClient _supabase;
  final LocalDb _localDb;
  final NetworkMonitor _networkMonitor;
  StreamSubscription<bool>? _connectivitySub;
  bool _online = true;

  CobranzaRepository(this._supabase, this._localDb, this._networkMonitor) {
    _init();
  }

  Future<void> _init() async {
    _online = await _networkMonitor.isConnected;
    _connectivitySub = _networkMonitor.connectivityStream.listen((online) {
      _online = online;
      if (online) _sincronizarPendientes();
    });
  }

  Future<List<ClienteMora>> getMorosos(String asesorId) async {
    if (_online) {
      try {
        final response = await _supabase
            .from('cartera_vencida')
            .select()
            .eq('asesor_id', asesorId)
            .gt('dias_mora', 0)
            .order('dias_mora', ascending: false);

        final list = response as List;
        final morosos = list
            .map((m) => ClienteMora.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        _cacheLocal(morosos);
        return morosos;
      } catch (_) {
        return _getLocales();
      }
    }
    return _getLocales();
  }

  Future<void> registrarAccion(AccionCobranza accion) async {
    final db = await _localDb.database;
    await db.insert('acciones_cobranza_pendientes', accion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (_online) {
      try {
        await _supabase.from('acciones_cobranza').insert(accion.toMap());
        await db.update(
          'acciones_cobranza_pendientes',
          {'pendiente_sync': 0},
          where: 'id = ?',
          whereArgs: [accion.id],
        );

        if (accion.resultado == 'pago_parcial' && accion.montoPagado != null) {
          await _supabase.functions.invoke(
            'registrar-pago',
            body: {
              'credito_id': accion.creditoId,
              'monto_pagado': accion.montoPagado,
            },
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _sincronizarPendientes() async {
    final db = await _localDb.database;
    final pendientes = await db.query(
      'acciones_cobranza_pendientes',
      where: 'pendiente_sync = 1',
    );
    for (final row in pendientes) {
      try {
        await _supabase.from('acciones_cobranza').insert(row);
        await db.update(
          'acciones_cobranza_pendientes',
          {'pendiente_sync': 0},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (_) {}
    }
  }

  Future<void> _cacheLocal(List<ClienteMora> morosos) async {
    final db = await _localDb.database;
    await db.delete('cartera_vencida_cache');
    final now = DateTime.now().toIso8601String();
    for (final m in morosos) {
      final map = m.toMap();
      map['updated_at'] = now;
      await db.insert('cartera_vencida_cache', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<ClienteMora>> _getLocales() async {
    final db = await _localDb.database;
    final rows = await db.query(
      'cartera_vencida_cache',
      orderBy: 'dias_mora DESC',
    );
    if (rows.isEmpty) throw Exception('Sin datos locales de mora');
    return rows.map((m) => ClienteMora.fromMap(m)).toList();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
