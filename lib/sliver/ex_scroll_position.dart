class ExScrollPosition {

  // 回调给外部的开始位置
  final int reaStartPosition;
  // 回调给外部的结束位置
  final int reaEdnPosition;

  const ExScrollPosition({this.reaStartPosition, this.reaEdnPosition});

  static const ExScrollPosition empty = ExScrollPosition();
}