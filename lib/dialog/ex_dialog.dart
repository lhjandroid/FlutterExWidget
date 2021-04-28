import 'package:flutter/material.dart';

/// 显示指定大小dialog onClickOutSide点击弹窗以外的透明区域 onClickContent点击child区域
Future<T> showCustomSizeDialog<T>(BuildContext context,
    {Widget child, Function onClickOutSide, Function onClickContent}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      return Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClickOutSide,
          child: GestureDetector(
            child: Center(
              child: child,
            ),
            onTap: onClickContent ?? () {}, // 默认点击内容区域不透传事件
          ),
        ),
      );
    },
  );
}