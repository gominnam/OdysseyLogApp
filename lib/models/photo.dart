
class Photo {
  final String? path;
  String? url;
  String? presignedUrl;

  Photo({
    this.path,
    this.presignedUrl,
    this.url,
  });

  Photo.fromJson(Map<String, dynamic> json)
    : path = json['path']
    , url = json['url']
    , presignedUrl = json['presignedUrl'];

  Map<String, dynamic> toJson() => {
    'path': path,
    'url': url,
    'presignedUrl': presignedUrl,
  };

  @override
  String toString() {
    return 'Photo(path: $path, url: $url, presignedUrl: $presignedUrl)';
  }  
}