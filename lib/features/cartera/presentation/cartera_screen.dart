import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'providers/cartera_provider.dart';
import '../../../shared/widgets/cliente_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../domain/cartera_model.dart';

class CarteraScreen extends ConsumerStatefulWidget {
  const CarteraScreen({super.key});

  @override
  ConsumerState<CarteraScreen> createState() => _CarteraScreenState();
}

class _CarteraScreenState extends ConsumerState<CarteraScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carteraProvider.notifier).loadClientes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carteraProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          if (state.status == CarteraStatus.data) _buildSummaryBar(state),
          if (state.status == CarteraStatus.data) _buildFilterChips(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  AppBar _buildAppBar(CarteraState state) {
    return AppBar(
      title: Text(
        _showSearch ? 'Buscar cliente' : AppStrings.carteraTitle,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search_outlined),
          onPressed: () {
            setState(() => _showSearch = !_showSearch);
            if (!_showSearch) {
              _searchController.clear();
              ref.read(carteraProvider.notifier).search('');
            }
          },
        ),
        if (state.status == CarteraStatus.data)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(carteraProvider.notifier).loadClientes(),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o DNI...',
          prefixIcon: const Icon(Icons.search_outlined, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(carteraProvider.notifier).search('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        ),
        onChanged: (q) => ref.read(carteraProvider.notifier).search(q),
      ),
    );
  }

  Widget _buildSummaryBar(CarteraState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${state.totalClientes} clientes · ${state.visitados} visitados · ${state.pendientes} pendientes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (state.ultimaActualizacion != null)
                Text(
                  'Actualizado: ${_formatTime(state.ultimaActualizacion!)}',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progreso,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.progreso == 1.0
                    ? AppColors.success
                    : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(CarteraState state) {
    final filtros = FiltroCartera.values;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filtros.map((f) {
            final isActive = state.filtroActual == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_filtroLabel(f)),
                selected: isActive,
                onSelected: (_) {
                  ref.read(carteraProvider.notifier).setFilter(f);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color:
                      isActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(CarteraState state) {
    switch (state.status) {
      case CarteraStatus.initial:
      case CarteraStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando cartera...'),
            ],
          ),
        );

      case CarteraStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Error al cargar',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(carteraProvider.notifier).loadClientes(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );

      case CarteraStatus.data:
        final list = state.filteredClientes;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  state.queryBusqueda.isNotEmpty
                      ? 'No se encontraron clientes para "${state.queryBusqueda}"'
                      : 'Sin clientes disponibles',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: list.length,
          onReorder: (oldIndex, newIndex) {
            ref.read(carteraProvider.notifier).reordenar(oldIndex, newIndex);
          },
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final cliente = list[index];
            return ClienteCard(
              key: ValueKey(cliente.id),
              cliente: cliente,
              onTap: () => context.push('/ficha/${cliente.clienteId}'),
              onMarcarVisita: () => _mostrarOpcionesVisita(cliente),
            );
          },
        );
    }
  }

  Future<void> _mostrarOpcionesVisita(CarteraModel cliente) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {}

    if (!mounted) return;

    final opciones = EstadoVisita.values;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String? observacion;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
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
                            const SizedBox(height: 2),
                            Text(
                              cliente.documentoCensurado,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (position != null)
                        Icon(Icons.gps_fixed,
                            size: 18, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final id = cliente.clienteId;
                        Navigator.of(ctx).pop();
                        this.context.push('/ficha/$id');
                      },
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Ver ficha del cliente'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Resultado de la visita:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: opciones.map((estado) {
                      final isSelected = estado == cliente.estadoVisita;
                      return ChoiceChip(
                        label: Text(
                          estado.label,
                          style: TextStyle(fontSize: 13),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _confirmarVisita(
                              ctx,
                              cliente.id,
                              estado,
                              observacion,
                              position,
                            );
                          }
                        },
                        selectedColor: _estadoColor(estado)
                            .withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? _estadoColor(estado)
                              : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Observación (máx. 200 caracteres)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      counterText: '',
                    ),
                    maxLines: 2,
                    maxLength: 200,
                    onChanged: (v) => observacion = v,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarVisita(
    BuildContext ctx,
    String clienteId,
    EstadoVisita estado,
    String? observacion,
    Position? position,
  ) {
    Navigator.of(ctx).pop();
    ref.read(carteraProvider.notifier).marcarVisita(
      id: clienteId,
      estado: estado,
      observacion: observacion,
      lat: position?.latitude,
      lng: position?.longitude,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${estado.label} registrado'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _filtroLabel(FiltroCartera filtro) {
    switch (filtro) {
      case FiltroCartera.todos:
        return 'Todos';
      case FiltroCartera.renovaciones:
        return 'Renovaciones';
      case FiltroCartera.nuevas:
        return 'Nuevas';
      case FiltroCartera.mora:
        return 'En Mora';
      case FiltroCartera.visitados:
        return 'Visitados';
    }
  }

  Color _estadoColor(EstadoVisita estado) {
    switch (estado) {
      case EstadoVisita.visitado:
        return AppColors.success;
      case EstadoVisita.noEncontrado:
        return AppColors.warning;
      case EstadoVisita.reagendado:
        return AppColors.info;
      case EstadoVisita.negocioCerrado:
        return AppColors.textSecondary;
      case EstadoVisita.pendiente:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
