class LastList {
  int idMusic;
  String idSetList;

  LastList({required this.idMusic, required this.idSetList});

  LastList.initEmpty({this.idMusic = -1, this.idSetList = ''});

  void setNewLast({required int idMusic, required String idSetList}) {
    this.idMusic = idMusic;
    this.idSetList = idSetList;
  }

  bool isCheckpoint({
    required int currentMusic,
    required String currentSetList,
  }) {
    return idMusic == currentMusic && idSetList == currentSetList;
  }

  bool get isEmpty => idMusic == -1;
}
