class Channel {
  const Channel({required this.name, required this.url});

  final String name;
  final String url;

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(name: json['name'] as String, url: json['url'] as String);
  }
}
