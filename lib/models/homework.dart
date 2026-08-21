import 'package:homework_app/models/attachment.dart';

class Homework {
  String id;
  String title;
  String subject;
  DateTime dueDate;
  bool hasDueDate;
  bool isCompleted;
  bool isDeleted;
  DateTime? deletedAt;
  List<int> notificationOffsets;
  bool isImportant;
  String description;
  List<Attachment> attachments;

  Homework({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.hasDueDate = true,
    this.isCompleted = false,
    this.isDeleted = false,
    this.deletedAt,
    bool enableNotification = true,
    int notificationOffset = 0,
    List<int>? notificationOffsets,
    this.isImportant = false,
    this.description = '',
    this.attachments = const [],
    String? id,
  }) : notificationOffsets = _normalizeNotificationOffsets(
         notificationOffsets ??
             (enableNotification ? <int>[notificationOffset] : const <int>[]),
       ),
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get enableNotification => notificationOffsets.isNotEmpty;

  /// Kept for compatibility with older code and persisted task data.
  int get notificationOffset =>
      notificationOffsets.isEmpty ? 0 : notificationOffsets.first;

  static List<int> _normalizeNotificationOffsets(Iterable<int> offsets) {
    final normalized = <int>[];
    for (final offset in offsets) {
      if (offset < 0 || normalized.contains(offset)) continue;
      normalized.add(offset);
      if (normalized.length == 2) break;
    }
    return normalized;
  }

  static List<int>? _notificationOffsetsFromJson(Map<String, dynamic> json) {
    final storedOffsets = json['notificationOffsets'];
    if (storedOffsets is! List) return null;

    return _normalizeNotificationOffsets(
      storedOffsets.whereType<num>().map((value) => value.toInt()),
    );
  }

  /// Añade un adjunto ya construido
  void addAttachment(Attachment attachment) {
    attachments = List.from(attachments)..add(attachment);
  }

  /// Crea y añade un adjunto a partir de la ruta, tipo y nombre de archivo
  Attachment addAttachmentFromPath({
    required String path,
    required String filename,
    required String type, // 'photo' o 'file'
    String? mimeType,
    int? size,
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}-${path.hashCode}';
    final attachment = Attachment(
      id: id,
      type: type,
      path: path,
      filename: filename,
      mimeType: mimeType,
      size: size,
    );
    addAttachment(attachment);
    return attachment;
  }

  /// Elimina un adjunto por id, devuelve true si se eliminó
  bool removeAttachmentById(String id) {
    final initial = attachments.length;
    attachments = attachments.where((a) => a.id != id).toList();
    return attachments.length < initial;
  }

  /// Filtra adjuntos por tipo ('photo' o 'file')
  List<Attachment> attachmentsByType(String type) =>
      attachments.where((a) => a.type == type).toList();

  /// Atajos
  List<Attachment> get photos => attachmentsByType('photo');
  List<Attachment> get files => attachmentsByType('file');

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'dueDate': dueDate.millisecondsSinceEpoch,
    'hasDueDate': hasDueDate,
    'isCompleted': isCompleted,
    'isDeleted': isDeleted,
    'deletedAt': deletedAt?.millisecondsSinceEpoch,
    'enableNotification': enableNotification,
    'notificationOffset': notificationOffset,
    'notificationOffsets': notificationOffsets,
    'isImportant': isImportant,
    'description': description,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'],
    subject: json['subject'],
    dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
    hasDueDate: json['hasDueDate'] ?? true,
    isCompleted: json['isCompleted'] ?? false,
    isDeleted: json['isDeleted'] ?? false,
    deletedAt: json['deletedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'])
        : null,
    enableNotification: json['enableNotification'] ?? true,
    notificationOffset: (json['notificationOffset'] as num?)?.toInt() ?? 0,
    notificationOffsets: _notificationOffsetsFromJson(json),
    isImportant: json['isImportant'] ?? false,
    description: json['description'] ?? '',
    attachments:
        (json['attachments'] as List?)
            ?.map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
  );
}
