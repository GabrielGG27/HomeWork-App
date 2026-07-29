// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'App de Tareas';

  @override
  String get pending => 'Pendientes';

  @override
  String get completed => 'Completadas';

  @override
  String get subjects => 'Materias';

  @override
  String get allAssignments => 'Todas las Tareas';

  @override
  String get important => 'Importantes';

  @override
  String get noSavedSubjects => 'Sin materias guardadas';

  @override
  String get newButton => 'Nueva';

  @override
  String get deleteAssignment => 'Eliminar';

  @override
  String get trash => 'Papelera';

  @override
  String get restore => 'Restaurar';

  @override
  String get deleteForever => 'Eliminar permanentemente';

  @override
  String get confirmDeleteForeverTitle => '¿Eliminar permanentemente?';

  @override
  String get confirmDeleteForeverMessage =>
      'Esto eliminará permanentemente esta tarea. Esta acción no se puede deshacer.';

  @override
  String get emptyTrash => 'Vaciar papelera';

  @override
  String get emptyTrashTitle => '¿Vaciar la papelera?';

  @override
  String get emptyTrashMessage =>
      'Esto eliminará permanentemente todas las tareas en la papelera. Esta acción no se puede deshacer.';

  @override
  String get autoDeleteMessage =>
      'Las tareas en la papelera se eliminarán permanentemente después de 30 días.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get update => 'Actualizar';

  @override
  String get title => 'Título';

  @override
  String get subject => 'Materia';

  @override
  String get description => 'Descripción';

  @override
  String get dueDate => 'Fecha de Entrega';

  @override
  String get dueTime => 'Hora de Entrega';

  @override
  String get receiveNotification => 'Recibir notificación';

  @override
  String get notificationOffset => 'Antelación';

  @override
  String get markAsImportant => 'Marcar como importante';

  @override
  String get deleteSubject => 'Eliminar Materia';

  @override
  String deleteSubjectConfirmation(String subject) {
    return '¿Eliminar la materia \"$subject\"? Esta acción eliminará la materia de la lista. Las tareas no se borrarán automáticamente.';
  }

  @override
  String get clearCompletedTitle => '¿Borrar tareas completadas?';

  @override
  String get clearCompletedMessage =>
      'Todas las tareas marcadas como completadas se moverán a la papelera. Podrás restaurarlas desde allí.';

  @override
  String get clearCompletedButton => 'Borrar tareas completadas';

  @override
  String get noPendingAssignments => 'No hay tareas pendientes';

  @override
  String get noCompletedAssignments => 'No hay tareas completadas';

  @override
  String get sectionOverdue => 'Tareas Atrasadas';

  @override
  String get sectionToday => 'Hoy';

  @override
  String get sectionTomorrow => 'Mañana';

  @override
  String get sectionNext7Days => 'Próximos 7 días';

  @override
  String get sectionLater => 'Más adelante';

  @override
  String get createNewSubject => 'Crear nueva materia...';

  @override
  String get selectIcon => 'Seleccionar Ícono:';

  @override
  String get subjectName => 'Nombre de Materia';

  @override
  String get enterTitleValidator => 'Ingrese un título';

  @override
  String get selectSubjectValidator => 'Seleccione o cree una materia';

  @override
  String get language => 'Idioma';

  @override
  String get atDueTime => 'A la hora de entrega';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutos antes';
  }

  @override
  String get hourBefore => '1 hora antes';

  @override
  String hoursBefore(int hours) {
    return '$hours horas antes';
  }

  @override
  String get dayBefore => '1 día antes';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get rateApp => 'Calificar aplicación';

  @override
  String get hasDueDate => 'Fecha de Entrega';

  @override
  String get sectionNoDate => 'Sin Fecha';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsDescription =>
      'Idioma, tema y preferencias de la aplicación';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get removeAds => 'Quitar Anuncios';

  @override
  String get removeAdsPermanently => 'Eliminar anuncios permanentemente';

  @override
  String get storeNotAvailable => 'Tienda no disponible';

  @override
  String get productNotFound => 'Producto no encontrado en la tienda';

  @override
  String get supportAndMore => 'Soporte y Más';

  @override
  String get premiumActive => 'Premium Activo ✅';

  @override
  String get adsRemoved => 'Anuncios eliminados';

  @override
  String get processingPurchase => 'Procesando compra...';

  @override
  String get restoringPurchases => 'Restaurando compras...';

  @override
  String get skip => 'Omitir';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get onboardingWelcomeTitle => 'Tus tareas, bajo control';

  @override
  String get onboardingWelcomeDescription =>
      'Organiza tus deberes escolares en un solo lugar y ten claro qué sigue.';

  @override
  String get onboardingSubjectsTitle => 'Organiza por materia';

  @override
  String get onboardingSubjectsDescription =>
      'Crea materias con sus propios íconos para encontrar cada tarea fácilmente.';

  @override
  String get onboardingRemindersTitle => 'No olvides una entrega';

  @override
  String get onboardingRemindersDescription =>
      'Agrega fechas y recordatorios opcionales. El permiso de notificaciones se solicita solo cuando decidas usarlos.';

  @override
  String get onboardingProgressTitle => 'Observa tu progreso';

  @override
  String get onboardingProgressDescription =>
      'Cambia entre tareas pendientes y completadas, y destaca el trabajo más importante.';

  @override
  String onboardingProgress(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get viewIntroduction => 'Ver introducción';

  @override
  String get viewIntroductionDescription =>
      'Repite la bienvenida y el recorrido por la app';

  @override
  String get skipWalkthrough => 'Omitir recorrido';

  @override
  String get walkthroughDialogLabel => 'Recorrido por la aplicación';

  @override
  String get walkthroughTabsTitle => 'Controla cada tarea';

  @override
  String get walkthroughTabsDescription =>
      'Cambia entre tus trabajos pendientes y las tareas que ya completaste.';

  @override
  String get walkthroughNewTaskTitle => 'Crea una tarea';

  @override
  String get walkthroughNewTaskDescription =>
      'Pulsa Nueva para agregar su materia, fecha, recordatorio, importancia y notas.';

  @override
  String get walkthroughMenuTitle => 'Todo está a tu alcance';

  @override
  String get walkthroughMenuDescription =>
      'Usa el menú para filtrar por materia, ver tareas importantes, abrir la papelera o cambiar la configuración.';
}
