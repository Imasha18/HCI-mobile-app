class NotificationModel {
  const NotificationModel({
    required this.title,
    this.body = '',
    this.read = false,
  });
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        title: json['title'] as String? ?? 'Update',
        body: json['body'] as String? ?? '',
        read: json['read'] as bool? ?? false,
      );
  final String title;
  final String body;
  final bool read;
}
