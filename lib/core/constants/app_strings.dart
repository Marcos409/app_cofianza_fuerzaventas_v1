class AppStrings {
  AppStrings._();

  // Generales
  static const String appName = 'Confianza';
  static const String appSubtitle = 'Fuerza de Ventas';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String retry = 'Reintentar';
  static const String save = 'Guardar';
  static const String saveDraft = 'Guardar borrador';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String confirm = 'Confirmar';
  static const String noData = 'No hay datos';
  static const String search = 'Buscar...';
  static const String next = 'Siguiente';
  static const String back = 'Atrás';
  static const String finish = 'Finalizar';
  static const String yes = 'Sí';
  static const String no = 'No';

  // Auth
  static const String loginTitle = 'Iniciar Sesión';
  static const String codigoEmpleado = 'Código de empleado';
  static const String codigoEmpleadoHint = 'Ingresa tu código';
  static const String password = 'Contraseña';
  static const String passwordHint = 'Ingresa tu contraseña';
  static const String loginButton = 'Ingresar';
  static const String forgotPassword = '¿Problemas para ingresar?';
  static const String logout = 'Cerrar sesión';
  static const String logoutConfirm = '¿Estás seguro de que deseas cerrar sesión?';
  static const String sessionExpired = 'Sesión expirada';
  static const String blockMessage = 'Demasiados intentos. Intenta de nuevo en @minutes minutos.';
  static const String invalidCredentials = 'Credenciales incorrectas. Intentos restantes: @attempts';
  static const String accountBlocked = 'Cuenta bloqueada temporalmente por seguridad.';
  static const String pendingSyncWarning = 'Tienes @count solicitudes sin sincronizar. ¿Cerrar de todas formas?';

  // Offline
  static const String offlineBanner = 'Trabajando sin conexión – Los datos se guardarán localmente';
  static const String offline = 'Sin conexión';
  static const String pendingSync = 'Pendiente de sincronización';

  // Cartera
  static const String carteraTitle = 'Cartera de Clientes';

  // Solicitud
  static const String solicitudTitle = 'Nueva Solicitud';
  static const String stepPersonal = 'Datos personales';
  static const String stepAddress = 'Dirección';
  static const String stepDocuments = 'Documentos';
  static const String stepReview = 'Revisión';

  // Ficha del cliente
  static const String fichaTitle = 'Ficha del Cliente';
  static const String posicionTitle = 'Posición en el Sistema';
  static const String historialTitle = 'Historial Crediticio';
  static const String ofertaTitle = 'Oferta Vigente';
  static const String sinOferta = 'Sin oferta vigente. Puede iniciar solicitud nueva.';
  static const String btnLlamar = 'Llamar';
  static const String btnRegistrarVisita = 'Registrar visita';
  static const String btnIniciarSolicitud = 'Iniciar solicitud';
  static const String btnUsarOferta = 'Usar esta oferta';
  static const String comportamientoTitle = 'Comportamiento de Pagos';
  static const String deudaTotal = 'Deuda total';
  static const String cuentasVigentes = 'Cuotas al día';
  static const String cuentasMora = 'Cuotas en mora';
  static const String diasMayorMora = 'Días mayor mora';
  static const String ultimoPago = 'Último pago';
  static const String pctPuntual = '% Puntual';
  static const String promedioMora = 'Prom. mora (días)';
  static const String montoTotalPagado = 'Total pagado';
  static const String nivelConfianza = 'Confianza';
  static const String vigenciaOferta = 'Vigencia';

  // Prospección
  static const String prospeccionTitle = 'Pre-evaluación';
  static const String campanasTitle = 'Campañas Activas';
  static const String sinCampanas = 'No hay campañas activas en este momento.';
  static const String btnPreEvaluar = 'Pre-evaluar';
  static const String btnIniciarSolicitudFormal = 'Iniciar solicitud formal';
  static const String btnInformarCliente = 'Informar al cliente';
  static const String btnGestionarAhora = 'Gestionar ahora';
  static const String evaluating = 'Evaluando...';
  static const String aptoMsg = 'Puede continuar la evaluación';
  static const String revisarMsg = 'Requiere análisis adicional';
  static const String noProcedeMsg = 'No cumple condiciones';
  static const String documentoField = 'Número de documento';
  static const String documentoHint = '8 dígitos';
  static const String nombresField = 'Nombres';
  static const String apellidosField = 'Apellidos';
  static const String fechaNacimientoField = 'Fecha de nacimiento';
  static const String tipoNegocioField = 'Tipo de negocio';
  static const String ingresosField = 'Ingresos estimados mensuales';
  static const String montoSolicitadoField = 'Monto solicitado';
  static const String destinoField = 'Destino del crédito';
  static const String destinoHint = '¿Para qué usará el crédito?';
  static const String antiguedadAnios = 'Años';
  static const String antiguedadMeses = 'Meses';
  static const String registarDesercion = 'Registrar deserción';
  static const String motivoDesercionField = 'Motivo de deserción';
  static const String institucionMigro = 'Institución a la que migró';
  static const String probabilidadRetorno = 'Probabilidad de retorno';
  static const String observaciones = 'Observaciones';

  static const List<String> tiposNegocio = [
    'Bodega / Tienda',
    'Ropa y calzado',
    'Comida rápida / Restaurante',
    'Servicios profesionales',
    'Transporte',
    'Agricultura / Ganadería',
    'Manufactura / Taller',
    'Tecnología / Celulares',
    'Salud / Farmacia',
    'Otro',
  ];

  // Simulador
  static const String simuladorTitle = 'Simulador de Crédito';
  static const String btnCrearSolicitudConDatos =
      'Crear solicitud con estos datos';

  // Mis solicitudes
  static const String misSolicitudesTitle = 'Mis solicitudes';
  static const String expedienteLabel = 'Expediente';
  static const String enviadasLabel = 'Enviadas';
  static const String aprobadasLabel = 'Aprobadas';
  static const String desembolsadasLabel = 'Desembolsadas';
  static const String montoTotalLabel = 'Monto total';
  static const String tasaAprobacionLabel = 'Tasa de aprobación';
  static const String nuevaSolicitudLabel = 'Nueva solicitud';
}
