class Setlist {
  String tag;
  String title;
  String subtitle;
  int qntTotal;
  int nowPlaying;

  Setlist({
    this.tag = '/Todas',
    this.title = 'Todas',
    this.subtitle = '=---=',
    this.qntTotal = 0,
    this.nowPlaying = 0,
  });

  Setlist copyWith({
    String? tag,
    String? title,
    String? subtitle,
    int? qntTotal,
    int? nowPlaying,
  }) {
    return Setlist(
      tag: tag ?? this.tag,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      qntTotal: qntTotal ?? this.qntTotal,
      nowPlaying: nowPlaying ?? this.nowPlaying,
    );
  }

  factory Setlist.fromMap(Map<String, dynamic> map) {
    return Setlist(
      tag: map['tag'],
      title: map['title'],
      subtitle: map['subtitle'],
      qntTotal: map['qntTotal'],
      nowPlaying: map['nowPlaying'],
    );
  }
}
