import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 根据字段文字个数文本对齐
class ExAlignLengthText extends StatelessWidget {
  // 原字符串
  final String text;

  final int alignTextLength;

  final TextStyle style;

  ExAlignLengthText({this.text, this.alignTextLength, this.style});

  @override
  Widget build(BuildContext context) {
    // 没有文字返回Container
    if ((text?.length ?? 0) == 0) {
      return Container();
    } else if ((text?.length ?? 0) == 1) {
      // 只有一个字符时也不处理
      return Text(
        text,
        style: style,
      );
    }
    // 如果文本长度大于对齐个数也不处理
    if ((alignTextLength ?? 0) <= 1 || (text?.length ?? 0) >= alignTextLength) {
      return Text(
        text,
        style: style,
      );
    }
    TextPainter painter = TextPainter(
        locale: Localizations.localeOf(context, nullOk: true),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        text: TextSpan(
            text: '哈',
            style: TextStyle(
              fontSize: style.fontSize,
            )));
    painter.layout(maxWidth: 20);
    // 计算出一共需要多少空白长度 并除以能够插入的位置数
    double space = (alignTextLength - text.length) * painter.width / (text.length - 1);
    int length = text.length;
    List<InlineSpan> spans = List();
    for (int i = 0; i < length; i++) {
      spans.add(TextSpan(text: text.substring(i, i + 1), style: style));
      if (i != length - 1) {
        spans.add(WidgetSpan(
            child: SizedBox(
          width: space,
          height: 1,
        )));
      }
    }
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
