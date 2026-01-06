class Setlist {
  String tag;
  String title;
  String subtitle;
  int qntTotal;
  int indexPlaying;

  Setlist({
    this.tag = '/Todas',
    this.title = 'Todas',
    this.subtitle = '=---=',
    this.qntTotal = 0,
    this.indexPlaying = 0,
  });

  Setlist copyWith({
    String? tag,
    String? title,
    String? subtitle,
    int? qntTotal,
    int? indexPlaying,
  }) {
    return Setlist(
      tag: tag ?? this.tag,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      qntTotal: qntTotal ?? this.qntTotal,
      indexPlaying: indexPlaying ?? this.indexPlaying,
    );
  }

  factory Setlist.fromMap(Map<String, dynamic> map) {
    return Setlist(
      tag: map['tag'],
      title: map['title'],
      subtitle: map['subtitle'],
      qntTotal: map['qntTotal'],
      indexPlaying: map['indexPlaying'],
    );
  }
}
