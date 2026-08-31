class TaskMetadata {
  const TaskMetadata({
    this.category = '',
    this.tags = const <String>[],
    this.isFavorite = false,
    this.createdAt,
  });

  final String category;
  final List<String> tags;
  final bool isFavorite;
  final DateTime? createdAt;

  TaskMetadata copyWith({
    String? category,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return TaskMetadata(
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory TaskMetadata.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return TaskMetadata(
      category: json['category'] as String? ?? '',
      tags: rawTags is List ? rawTags.whereType<String>().toList() : const <String>[],
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
