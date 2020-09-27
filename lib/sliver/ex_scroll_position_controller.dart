import 'package:flutter/material.dart';
import 'package:flutter_ex_widget/sliver/ex_scroll_position.dart';

/// 记录开始和结束位置
class ExScrollPositionController extends ValueNotifier<ExScrollPosition> {

  ExScrollPositionController({ExScrollPosition value})
      : super(value ?? ExScrollPosition.empty);

  // 获取开始位置
  int get startPosition => value.reaStartPosition;

  // 获取结束位置
  int get endPosition => value.reaEdnPosition;
}
