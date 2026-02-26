enum ModeShuffleEnum { shuffleOff, shuffleNormal, shuffleOptional }

enum ModeOrderEnum { titleAZ, titleZA, dataAZ, dataZA, manual, up }

enum ModeLoopEnum { off, all, one }

enum ButtonTypes { prev, next, shuffle, repeat }

enum ExtraButtonTypes { nextBtn, prevBtn, modal }

enum SwapBtns { playlist, up, checkpoint }

T enumNext<T extends Enum>(T value, List<T> values) {
  final limit = values.length;
  final nextIndex = (value.index + 1) % limit;
  return values[nextIndex];
}

T enumFromInt<T extends Enum>(int i, List<T> values) {
  return values[i - 1];
}

int enumToInt<T extends Enum>(T value) {
  return value.index + 1;
}
