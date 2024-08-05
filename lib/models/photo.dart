
class Photo {
  // final String order;
  final String? path;
  final String? presignedUrl;

  Photo({
    // required this.order,
    this.path,
    this.presignedUrl,
  });

  Photo.fromJson(Map<String, dynamic> json)
    // : order = json['order'],
    : path = json['path']
    , presignedUrl = json['presignedUrl'];

  Map<String, dynamic> toJson() => {
    // 'order': order,
  };
}