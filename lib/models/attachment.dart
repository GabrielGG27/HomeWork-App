class Attachment {
  final String id;
  final String type; // 'photo' or 'file'
  final String path; // local path or remote URL
  final String filename;
  final String? mimeType;
  final int? size; // bytes, optional
  final int createdAtMs;

  Attachment({
    required this.id,
    required this.type,
    required this.path,
    required this.filename,
    this.mimeType,
    this.size,
    int? createdAtMs,
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'path': path,
    'filename': filename,
    'mimeType': mimeType,
    'size': size,
    'createdAtMs': createdAtMs,
  };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'],
    type: json['type'],
    path: json['path'],
    filename: json['filename'],
    mimeType: json['mimeType'],
    size: json['size'],
    createdAtMs: json['createdAtMs'],
  );

  Attachment copyWith({
    String? id,
    String? type,
    String? path,
    String? filename,
    String? mimeType,
    int? size,
    int? createdAtMs,
  }) => Attachment(
    id: id ?? this.id,
    type: type ?? this.type,
    path: path ?? this.path,
    filename: filename ?? this.filename,
    mimeType: mimeType ?? this.mimeType,
    size: size ?? this.size,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
}
