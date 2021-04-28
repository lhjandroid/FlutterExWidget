import 'package:flutter/material.dart';

import 'ex_multi_child_layout_delegate.dart';
import 'ex_warp_height_custom_multi_child_layout.dart';

/// 能够设置 左上右下位置icon的布局 auth lihj
class ExIconWidget extends StatelessWidget {
  // 主显示内容
  final Widget content;
  final Widget leftIcon;
  final Widget topIcon;
  final Widget rightIcon;
  final Widget bottomIcon;

  // 最大宽度
  final double maxWidth;

  // 最大高度
  final double maxHeight;

  // icon和主控件之间的间距
  final EdgeInsetsGeometry contentPadding;

  // 横向超出时是否截断
  final bool needClipContent;

  ExIconWidget(
      {this.content,
        this.leftIcon,
        this.topIcon,
        this.rightIcon,
        this.bottomIcon,
        this.contentPadding,
        this.needClipContent = true,
        @required this.maxWidth,
        @required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ExeWarpHeightCustomMultiChildLayout(
        delegate: ExIconWidgetDelegate(maxWidth: maxWidth, maxHeihgt: maxHeight, needClipContent: needClipContent),
        children: [
          LayoutId(
              id: ExIconWidgetId.left,
              child: leftIcon ??
                  SizedBox(
                    width: 1,
                    height: 1,
                  )),
          LayoutId(
              id: ExIconWidgetId.top,
              child: topIcon ??
                  SizedBox(
                    width: 1,
                    height: 1,
                  )),
          LayoutId(
            id: ExIconWidgetId.content,
            child: content,
          ),
          LayoutId(
              id: ExIconWidgetId.right,
              child: rightIcon ??
                  SizedBox(
                    width: 1,
                    height: 1,
                  )),
          LayoutId(
              id: ExIconWidgetId.bottom,
              child: bottomIcon ??
                  SizedBox(
                    width: 1,
                    height: 1,
                  )),
        ],
      ),
    );
  }
}


