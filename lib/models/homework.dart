import 'dart:convert';

import 'package:homework_app/models/attachment.dart';

class Homework {
  String id;
  String title;
  String subject;
  DateTime dueDate;
  bool isCompleted;
  bool enableNotification;
  int notificationOffset;
  bool isImportant;
  String description;
  List<Attachment> attachments;

  Homework({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.enableNotification = true,
    this.notificationOffset = 0,
    this.isImportant = false,
    this.description = '',
    this.attachments = const [],
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

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
    'isCompleted': isCompleted,
    'enableNotification': enableNotification,
    'notificationOffset': notificationOffset,
    'isImportant': isImportant,
    'description': description,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'],
    subject: json['subject'],
    dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
    isCompleted: json['isCompleted'] ?? false,
    enableNotification: json['enableNotification'] ?? true,
    notificationOffset: json['notificationOffset'] ?? 0,
    isImportant: json['isImportant'] ?? false,
    description: json['description'] ?? '',
    attachments: (json['attachments'] as List?)
            ?.map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
  );
}
