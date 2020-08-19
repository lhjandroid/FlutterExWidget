import 'dart:math';
import 'package:flutter/material.dart';
import 'ex_flow.dart';

class TagDelegate extends ExFlowDelegate {
  // 最大行数 0表示无限大
  int maxLines = 0;

  // item 之间的间隔
  final double itemSpace;

  // 行高
  final double lineHeight;

  // 是否需要丢弃大于控件宽度的item 默认不需要
  bool needLoseItemWhenItemWidthBig = false;

  double height = 0;
  double maxItemHeight = 0;

  TagDelegate(
      {this.itemSpace,
        this.lineHeight,
        this.maxLines = 0,
        this.needLoseItemWhenItemWidthBig = false});

  @override
  void paintChildren(FlowPaintingContext context) {
    // 布局宽度
    var parentW = context.size.width;
    //x坐标
    double offsetX = 0;
    //y坐标
    double offsetY = 0;

    Size childSize;
    // 已经绘制了多少行
    int lines = 1;
    for (int i = 0; i < context.childCount; i++) {
      // 超过屏幕宽度时换行
      childSize = context.getChildSize(i);
      if (offsetX + childSize.width < parentW) {
        // 绘制当前child
        context.paintChild(i,
            transform: Matrix4.translationValues(offsetX, offsetY, 0));
        // x坐标
        offsetX = offsetX + childSize.width + itemSpace;
        maxItemHeight = max(maxItemHeight, childSize.height);
      } else {
        lines++;
        // 最大行数有设定时才进行逻辑判断
        if (maxLines != 0 && lines > maxLines) {
          break;
        }
        // 重新设置x的值
        offsetX = 0;
        // 计算y值
        offsetY = offsetY + childSize.height + lineHeight;
        // 换行后如果 换行的第一项大于父控件宽度 根据 needLoseItemWhenItemWidthBig 判断是否要舍弃该item
        bool itemWidthBigThanParent = (childSize.width + itemSpace > parentW);
        if (itemWidthBigThanParent) {
          if (needLoseItemWhenItemWidthBig) {
            continue;
          } else {
            break;
          }
        }
        // 绘制当前child
        context.paintChild(i,
            transform: Matrix4.translationValues(offsetX, offsetY, 0));
        offsetX = childSize.width + itemSpace;
        maxItemHeight = max(maxItemHeight, childSize.height);
      }
    }
    height = offsetY;
  }

  @override
  bool shouldRepaint(ExFlowDelegate oldDelegate) {
    return true;
  }

  @override
  bool shouldRelayout(ExFlowDelegate oldDelegate) {
    return true;
  }

  @override
  double getItemSpace() {
    return itemSpace;
  }

  @override
  double getLineHeight() {
    return lineHeight;
  }

  @override
  bool isNeedLoseItemWhenItemWidthBig() {
    return needLoseItemWhenItemWidthBig;
  }

  @override
  int getMaxLines() {
    return maxLines;
  }
}