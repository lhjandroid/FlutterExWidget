import 'dart:math';

import 'package:flutter/material.dart';

import 'ex_text.dart';

/// 圆角矩形 + 三角提示布局
class ExRoundTriangleWidget extends StatelessWidget {
  /// 子布局
  final String data; // 文案
  final TextStyle textStyle;
  final double roundRadius; // 圆角半径
  final double triangleWidth; // 三角形的宽度
  final double triangleHeight; // 三角形的高度
  final double triangleDistance; // 三角形距离左边的距离
  final bool triangleFromLeft; // 从左边计算距离
  final LinearGradient gradient; // 渐变颜色

  ExRoundTriangleWidget(
      {this.data,
      this.textStyle,
      this.roundRadius,
      this.triangleWidth,
      this.triangleHeight,
      this.triangleDistance,
      this.triangleFromLeft,
      this.gradient});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ExRoundTrianglePainter(
          roundRadius: roundRadius ?? 12,
          triangleWidth: triangleWidth ?? 12,
          triangleHeight: triangleHeight ?? 12,
          triangleDistance: triangleDistance ?? 8,
          triangleFromLeft: triangleFromLeft ?? true,
          gradient: gradient),
      child: Container(
        height: (roundRadius ?? 12) * 2 + (triangleHeight ?? 12),
        margin: EdgeInsets.only(left: roundRadius ?? 12),
        alignment: Alignment.topLeft,
        child: Container(
          height: (roundRadius ?? 12) * 2,
          alignment: Alignment.center,
          child: ExText(data, textStyle),
        ),
      ),
    );
  }
}

/// 圆角矩形 带有三角指示器
class ExRoundTrianglePainter extends CustomPainter {
  Paint _paint;
  final double roundRadius; // 圆角半径
  final double triangleWidth; // 三角形的宽度
  final double triangleHeight; // 三角形的高度
  final double triangleDistance; // 三角形距离左边的距离
  final bool triangleFromLeft; // 从左边计算距离
  LinearGradient gradient; // 渐变颜色

  ExRoundTrianglePainter(
      {this.roundRadius = 12,
      this.triangleWidth = 12,
      this.triangleHeight = 12,
      this.triangleDistance = 16,
      this.triangleFromLeft = true,
      this.gradient}) {
    _paint = Paint()
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true //是否启动抗锯齿
      ..style = PaintingStyle.fill //绘画风格，默认为填充
      ..filterQuality = FilterQuality.high //颜色渲染模式的质量
      ..strokeWidth = 15.0; //画笔的宽度

    if (gradient == null) {
      gradient = LinearGradient(colors: [Color(0xFFFF6D2A), Color(0xFFFF0094)]);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    _paint.shader = gradient.createShader(rect);

    Path path = Path();
    // 左半圆
    path.addArc(new Rect.fromLTWH(0, 0, roundRadius * 2, roundRadius * 2), 90.0 * (pi / 180.0), 180.0 * (pi / 180.0));
    path.lineTo(size.width, 0);
    // 右半圆
    path.addArc(new Rect.fromLTWH(size.width - roundRadius, 0, roundRadius * 2, roundRadius * 2), 270.0 * (pi / 180.0),
        180.0 * (pi / 180.0));

    double reallyTriangleStartDistance; // 三角形的x轴的起始距离 根据triangleFromLeft计算 从右到左开始的
    double reallyTriangleCenterDistance; // 三角形的x轴的中见点距离 根据triangleFromLeft计算 从右到左开始的
    double reallyTriangleEndDistance; // 三角形的x轴的结束距离 根据triangleFromLeft计算 从右到左开始的
    if (triangleFromLeft) {
      reallyTriangleStartDistance = roundRadius + triangleDistance + triangleWidth;
      reallyTriangleCenterDistance = reallyTriangleStartDistance - triangleWidth / 2;
      reallyTriangleEndDistance = reallyTriangleCenterDistance - triangleWidth / 2;
    } else {
      reallyTriangleStartDistance = size.width - roundRadius - triangleDistance;
      reallyTriangleCenterDistance = reallyTriangleStartDistance - triangleWidth / 2;
      reallyTriangleEndDistance = reallyTriangleCenterDistance - triangleWidth / 2;
    }

    path.lineTo(reallyTriangleStartDistance, roundRadius * 2);
    // 三角形
    path.lineTo(reallyTriangleCenterDistance, roundRadius * 2 + triangleHeight);
    path.lineTo(reallyTriangleEndDistance, roundRadius * 2);

    path.lineTo(roundRadius, roundRadius * 2);

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
