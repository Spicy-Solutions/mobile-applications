class Multimedia {
  final int id;
  final int hotelId;
  final String url;
  final String type; // "MAIN, DETAIL, LOGO"
  final int position;

  Multimedia({
    required this.id,
    required this.hotelId,
    required this.url,
    required this.type,
    required this.position,
  });

  factory Multimedia.fromJson(Map<String, dynamic> json) {
    return Multimedia(
      id: json['id'],
      hotelId: json['hotelId'],
      url: json['url'],
      type: json['type'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotelId': hotelId,
      'url': url,
      'type': type,
      'position': position,
    };
  }
}