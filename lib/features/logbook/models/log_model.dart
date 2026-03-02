class LogModel {
  final String title;
  final String date;
  final String description;
  final String category;

  LogModel({
    required this.title,
    required this.date,
    required this.description,
    required this.category,
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      date: map['date'],
      description: map['description'],
      category: map['category'] ?? 'Lainnya',
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
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
        other.title == title &&
        other.date == date &&
        other.description == description &&
        other.category == category;
  }

  @override
  int get hashCode => title.hashCode ^ date.hashCode ^ description.hashCode ^ category.hashCode;
}