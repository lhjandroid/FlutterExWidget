import 'package:flutter/material.dart';

// 给布局加上中划线
class ExCenterLineWidget extends StatelessWidget {
  final Widget child; // 被划线的布局
  final Color color; // 线的颜色
  final double lineHeight; // 线的高度

  ExCenterLineWidget({this.child, this.color = Colors.black, this.lineHeight = 1}) : assert(child != null);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      child: child,
      painter: _CenterLinePainter(color, lineHeight),
    );
  }
}

// 绘制中划线
class _CenterLinePainter extends CustomPainter {
  Paint _paint;
  final Color color;
  final double lineHeight;

  _CenterLinePainter(this.color, this.lineHeight) {
    _paint = Paint();
    _paint.strokeWidth = lineHeight;
    _paint.color = color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
