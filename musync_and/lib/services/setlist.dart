class Setlist {
  String tag;
  String title;
  String subtitle;

  Setlist({this.tag = '/Todas', this.title = 'Todas', this.subtitle = '=---='});

  Setlist copyWith({String? tag, String? title, String? subtitle}) {
    return Setlist(
      tag: tag ?? this.tag,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  factory Setlist.fromMap(Map<String, dynamic> map) {
    return Setlist(
      tag: map['tag'],
      title: map['title'],
      subtitle: map['subtitle'],
    );
  }
}
