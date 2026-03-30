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
  String get sectionThisWeek => 'Esta Semana';

  @override
  String get sectionUpcoming => 'Próximas';

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
}
