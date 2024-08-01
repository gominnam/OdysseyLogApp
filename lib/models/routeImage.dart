class RouteImage {
  final int id;
  final String presignedUrl;

  RouteImage({required this.id, required this.presignedUrl});

  factory RouteImage.fromJson(Map<String, dynamic> json) {
    return RouteImage(
      id: json['id'] ?? '',
      presignedUrl: json['presignedUrl'] ?? '',
    );
  }
}