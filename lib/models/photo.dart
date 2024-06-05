
class Photo {
  final String order;
  final String temporaryId;

  Photo({
    required this.order,
    required this.temporaryId,
  });

  Photo.fromJson(Map<String, dynamic> json)
    : order = json['order'],
      temporaryId = json['temporaryId'];

  Map<String, dynamic> toJson() => {
    'order': order,
    'temporaryId': temporaryId,
  };
}