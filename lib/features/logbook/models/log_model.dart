import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id;
  final String title;
  final String date;
  final String description;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
      title: map['title'],
      date: map['date'],
      description: map['description'],
      category: map['category'] ?? 'Lainnya',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'date': date,
      'description': description,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogModel &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.description == description &&
        other.category == category;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ date.hashCode ^ description.hashCode ^ category.hashCode;
}