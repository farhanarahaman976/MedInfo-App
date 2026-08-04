class HealthTip {
  final String id;
  final String title;
  final String titleBangla;
  final String body;
  final String bodyBangla;
  final int order; 

  const HealthTip({
    this.id = '',
    required this.title,
    required this.titleBangla,
    required this.body,
    required this.bodyBangla,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleBangla': titleBangla,
      'body': body,
      'bodyBangla': bodyBangla,
      'order': order,
    };
  }

  factory HealthTip.fromMap(Map<String, dynamic> map, String id) {
    return HealthTip(
      id: id,
      title: map['title'] ?? '',
      titleBangla: map['titleBangla'] ?? '',
      body: map['body'] ?? '',
      bodyBangla: map['bodyBangla'] ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }
}