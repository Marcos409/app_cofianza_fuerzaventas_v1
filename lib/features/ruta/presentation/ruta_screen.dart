import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ruta_viewmodel.dart';
import 'providers/ruta_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../cartera/domain/cartera_model.dart';

class RutaScreen extends ConsumerStatefulWidget {
  const RutaScreen({super.key});

  @override
  ConsumerState<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends ConsumerState<RutaScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(rutaNotifierProvider.notifier).loadData();
      ref.read(rutaNotifierProvider.notifier).requestLocationPermission();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rutaNotifierProvider);

    ref.listen<RutaState>(rutaNotifierProvider, (prev, next) {
      if (prev?.clientes != next.clientes ||
          prev?.rutaOptimizada != next.rutaOptimizada ||
          prev?.rutaPolylinePoints != next.rutaPolylinePoints) {
        _updateMapMarkers(next);
      }
      if (prev?.currentPosition != next.currentPosition) {
        _centerMapOnPosition(next);
      }
    });

    if (state.status == RutaStatus.initial ||
        state.status == RutaStatus.loading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: _buildAppBar(state),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final showMap = state.currentPosition != null ||
        state.clientes.any((c) => c.latVisita != null);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(state),
      body: Stack(
        children: [
          if (showMap)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCamera(state),
              markers: _markers,
              polylines: _polylines,
              polygons: state.polygons,
              myLocationEnabled: state.currentPosition != null,
              myLocationButtonEnabled: state.currentPosition != null,
              zoomControlsEnabled: false,
              compassEnabled: true,
            )
          else
            _buildSinGpsBody(),
          _buildBottomPanel(state),
        ],
      ),
      floatingActionButton: _buildFab(state),
    );
  }

  Widget _buildSinGpsBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'Mapa sin ubicación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activa el GPS para ver tu posición en el mapa y optimizar la ruta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(rutaNotifierProvider.notifier)
                    .requestLocationPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Activar GPS'),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(RutaState state) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ruta de Hoy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (state.zonaActual != null)
            Text(
              state.zonaActual!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
    );
  }

  void _updateMapMarkers(RutaState state) {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    final displayList = state.rutaOptimizada.isNotEmpty
        ? state.rutaOptimizada
        : state.clientes;

    for (var i = 0; i < displayList.length; i++) {
      final cliente = displayList[i];
      final lat = cliente.latVisita;
      final lng = cliente.lngVisita;
      if (lat == null || lng == null) continue;

      final isVisitado = cliente.estadoVisita == EstadoVisita.visitado;
      final color = _markerColor(cliente, isVisitado);

      markers.add(
        Marker(
          markerId: MarkerId(cliente.id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title: cliente.nombreCliente,
            snippet: cliente.tipoGestion.label,
            onTap: () => _showClienteInfo(cliente),
          ),
          onTap: () => _showClienteInfo(cliente),
        ),
      );
    }

    if (state.rutaPolylinePoints != null && state.rutaPolylinePoints!.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta'),
          points: state.rutaPolylinePoints!,
          color: AppColors.secondary,
          width: 4,
          geodesic: true,
        ),
      );
    } else if (state.rutaOptimizada.length > 1 && state.currentPosition != null) {
      final points = <LatLng>[
        LatLng(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
        ),
        for (final c in state.rutaOptimizada)
          if (c.latVisita != null && c.lngVisita != null)
            LatLng(c.latVisita!, c.lngVisita!),
      ];

      if (points.length > 1) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('ruta_fallback'),
            points: points,
            color: AppColors.secondary,
            width: 4,
            geodesic: true,
          ),
        );
      }
    }

    _markers = markers;
    _polylines = polylines;
  }

  double _markerColor(CarteraModel cliente, bool isVisitado) {
    if (isVisitado) return BitmapDescriptor.hueViolet;
    if (cliente.scorePrioridad >= 70) return BitmapDescriptor.hueRed;
    if (cliente.scorePrioridad >= 40) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueGreen;
  }

  CameraPosition _initialCamera(RutaState state) {
    if (state.currentPosition != null) {
      return CameraPosition(
        target: LatLng(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
        ),
        zoom: 14,
      );
    }

    if (state.clientes.isNotEmpty) {
      final first = state.clientes.first;
      if (first.latVisita != null && first.lngVisita != null) {
        return CameraPosition(
          target: LatLng(first.latVisita!, first.lngVisita!),
          zoom: 12,
        );
      }
    }

    return const CameraPosition(
      target: LatLng(-12.046374, -77.042793),
      zoom: 12,
    );
  }

  void _centerMapOnPosition(RutaState state) {
    if (state.currentPosition == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
        ),
        14,
      ),
    );
  }

  Widget _buildBottomPanel(RutaState state) {
    final displayList = state.rutaOptimizada.isNotEmpty
        ? state.rutaOptimizada
        : state.clientes;
    final noVisitados =
        state.clientes.where((c) => c.estadoVisita != EstadoVisita.visitado).length;
    final visitados = state.clientes.length - noVisitados;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '$noVisitados pendientes · $visitados visitados',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (noVisitados > 0 && state.currentPosition != null)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(rutaNotifierProvider.notifier).optimizeRoute();
                    },
                    icon: const Icon(Icons.route, size: 18),
                    label: const Text('Optimizar ruta'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
            if (displayList.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayList.length.clamp(0, 5),
                  itemBuilder: (context, index) {
                    final c = displayList[index];
                    final isVisitado =
                        c.estadoVisita == EstadoVisita.visitado;
                    return GestureDetector(
                      onTap: () => _showClienteInfo(c),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8, top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isVisitado
                              ? AppColors.surface
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isVisitado
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isVisitado
                                        ? AppColors.success
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.nombreCliente,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab(RutaState state) {
    final displayList = state.rutaOptimizada.isNotEmpty
        ? state.rutaOptimizada
        : state.clientes;
    final firstUnvisited = displayList.isNotEmpty &&
            displayList.first.estadoVisita != EstadoVisita.visitado
        ? displayList.first
        : null;

    if (firstUnvisited == null ||
        firstUnvisited.latVisita == null ||
        firstUnvisited.lngVisita == null) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: () => _lanzarNavegacion(
        firstUnvisited.latVisita!,
        firstUnvisited.lngVisita!,
        firstUnvisited.nombreCliente,
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.directions),
      label: const Text('Navegar'),
    );
  }

  void _showClienteInfo(CarteraModel cliente) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente.nombreCliente,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cliente.documentoCensurado,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Badge(
                    backgroundColor:
                        _badgeColor(cliente.scorePrioridad).withValues(alpha: 0.15),
                    textStyle: TextStyle(
                      color: _badgeColor(cliente.scorePrioridad),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    label: Text(cliente.tipoGestion.label),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    textStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                    label: Text(
                      _prioridadLabel(cliente.scorePrioridad),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                cliente.direccionCliente,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _capturarUbicacion(cliente);
                      },
                      icon: const Icon(Icons.gps_fixed, size: 18),
                      label: const Text('Actualizar ubicación'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (cliente.latVisita != null && cliente.lngVisita != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _lanzarNavegacion(
                            cliente.latVisita!,
                            cliente.lngVisita!,
                            cliente.nombreCliente,
                          );
                        },
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Ir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _capturarUbicacion(CarteraModel cliente) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (_) {
        placemarks = [];
      }

      final direccion = placemarks.isNotEmpty
          ? '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}'
          : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      if (!mounted) return;

      final dirController = TextEditingController(text: direccion);

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Ubicación capturada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'GPS señal obtenida',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  controller: dirController,
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dirController.dispose();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Descartar'),
              ),
              ElevatedButton(
                onPressed: () {
                  dirController.dispose();
                  Navigator.of(ctx).pop();
                  ref.read(rutaNotifierProvider.notifier)
                      .actualizarUbicacionCliente(
                    clienteId: cliente.clienteId,
                    lat: position.latitude,
                    lng: position.longitude,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación GPS'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _lanzarNavegacion(
    double lat,
    double lng,
    String nombre,
  ) async {
    final wazeUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    final mapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($nombre)');
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri);
    } else if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir ninguna app de navegación'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _badgeColor(int score) {
    if (score >= 70) return AppColors.priorityHigh;
    if (score >= 40) return AppColors.priorityMedium;
    return AppColors.priorityNormal;
  }

  String _prioridadLabel(int score) {
    if (score >= 70) return 'ALTA';
    if (score >= 40) return 'MEDIA';
    return 'NORMAL';
  }
}
