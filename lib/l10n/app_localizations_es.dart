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
  String get confirmDeleteTaskTitle => '¿Eliminar tarea?';

  @override
  String get confirmDeleteTaskMessage => 'Esta tarea se moverá a la papelera.';

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
  String get minuteBefore => '1 minuto antes';

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
  String daysBefore(int days) {
    return '$days días antes';
  }

  @override
  String reminderNumber(int number) {
    return 'Recordatorio $number';
  }

  @override
  String get addReminder => 'Agregar otro recordatorio';

  @override
  String get removeReminder => 'Quitar recordatorio';

  @override
  String get customReminder => 'Tiempo personalizado…';

  @override
  String get timeAmount => 'Cantidad';

  @override
  String get minutes => 'Minutos';

  @override
  String get hours => 'Horas';

  @override
  String get days => 'Días';

  @override
  String get enterPositiveNumber => 'Ingresa un número mayor que cero';

  @override
  String get remindersMustBeDifferent =>
      'Elige un tiempo diferente para cada recordatorio';

  @override
  String get reminderMustBeFuture =>
      'Uno o más recordatorios quedarían en el pasado. Cambia la fecha, la hora de entrega o la antelación.';

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
  String get viewIntroduction => 'Ver guía para crear una tarea';

  @override
  String get viewIntroductionDescription =>
      'Repite paso a paso la creación y organización de una tarea';

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

  @override
  String get walkthroughTaskTitleTitle => 'Ponle un título a tu tarea';

  @override
  String get walkthroughTaskTitleDescription =>
      'Usa un nombre corto y claro para reconocerla fácilmente.';

  @override
  String get walkthroughTaskSubjectTitle => 'Elige o crea una materia';

  @override
  String get walkthroughTaskSubjectDescription =>
      'Las materias mantienen juntas las tareas relacionadas. Aquí puedes crear la primera.';

  @override
  String get walkthroughTaskScheduleTitle => 'Planea la entrega';

  @override
  String get walkthroughTaskScheduleDescription =>
      'Elige la fecha y hora de entrega, y decide si quieres recibir un recordatorio.';

  @override
  String get walkthroughTaskSaveTitle => 'Crea tu primera tarea';

  @override
  String get walkthroughTaskSaveDescription =>
      'Completa el título y la materia obligatorios, luego pulsa Guardar. El recorrido terminará cuando se cree la tarea.';

  @override
  String get walkthroughCreateTaskPrompt =>
      'Ahora completa el formulario y guarda tu primera tarea.';

  @override
  String get walkthroughCompleteTitle => '¡Recorrido completado!';

  @override
  String get walkthroughCompleteDescription =>
      'Tu primera tarea está lista. Ya conoces todo lo necesario para mantenerte organizado.';

  @override
  String get firstTaskIntroTitle => 'Crea tu primera tarea';

  @override
  String get firstTaskIntroDescription =>
      'HomeWork App se encarga de organizarla por ti.';

  @override
  String get firstTaskDetailsTitle => 'Añade detalles si los necesitas';

  @override
  String get firstTaskDetailsDescription =>
      'Puedes escribir instrucciones, notas o cualquier información adicional. Este paso es opcional.';

  @override
  String get firstTaskScheduleTitle => 'Elige cuándo debes terminarla';

  @override
  String get firstTaskScheduleDescription =>
      'Asigna una fecha y hora. HomeWork App colocará la tarea automáticamente en la sección correspondiente.';

  @override
  String get firstTaskReminderTitle => 'Recibe un aviso antes de la entrega';

  @override
  String get firstTaskReminderDescription =>
      'Los recordatorios son opcionales. Actívalos para elegir cuándo debe avisarte HomeWork App. Puedes agregar hasta dos y usar una antelación personalizada.';

  @override
  String get firstTaskImportanceTitle => 'Destaca lo más importante';

  @override
  String get firstTaskImportanceDescription =>
      'Las tareas importantes aparecen primero dentro de su sección. Activarlo es opcional.';

  @override
  String get firstTaskSaveTitle => 'Guarda tu primera tarea';

  @override
  String get firstTaskSaveDescription =>
      'Todo está listo. Pulsa Guardar para verla organizada en la lista.';

  @override
  String get firstTaskCompletedTitle =>
      '¡Felicidades! Creaste tu primera tarea.';

  @override
  String get firstTaskCompletedDescription =>
      'Ahora relájate: HomeWork App organizará tus tareas por ti.';

  @override
  String get starterSubjectMath => 'Matemáticas';

  @override
  String get starterSubjectSpanish => 'Español';

  @override
  String get starterSubjectGeography => 'Geografía';

  @override
  String get starterSubjectHistory => 'Historia';

  @override
  String get starterSubjectBiology => 'Biología';

  @override
  String get demoTaskToday => 'Resolver ejercicios de álgebra';

  @override
  String get demoTaskTomorrow => 'Leer el siguiente capítulo';

  @override
  String get demoTaskWeek => 'Preparar exposición de geografía';

  @override
  String get demoTaskHistory => 'Entregar resumen de historia';

  @override
  String get demoTaskBiology => 'Estudiar las células';

  @override
  String get done => 'Listo';

  @override
  String get privacyOptions => 'Opciones de privacidad';

  @override
  String get privacyOptionsDescription =>
      'Revisa o cambia tu consentimiento para anuncios';

  @override
  String get privacyOptionsError =>
      'No se pudieron abrir las opciones de privacidad. Inténtalo de nuevo.';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get pickImage => 'Elegir imagen';

  @override
  String get attachFile => 'Adjuntar archivo';

  @override
  String couldNotSaveImage(String error) {
    return 'No se pudo guardar la imagen: $error';
  }

  @override
  String couldNotSaveFile(String error) {
    return 'No se pudo guardar el archivo: $error';
  }
}
