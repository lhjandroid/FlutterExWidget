import 'package:flutter/material.dart';

/// 特殊字符标识Text
class ExRichText2 extends StatelessWidget {
  // 原字符串
  final String text;
  final String flag;

  // 正常文字样式
  final TextStyle style;

  // span样式
  final TextStyle spanStyle;

  final double height; // 文本高度 默认1.1更居中 但随着字体变大 这个值应该趋于1.0 允许手动调节

  ExRichText2({this.text, this.flag, this.style, this.spanStyle,this.height = 1.1});

  @override
  Widget build(BuildContext context) {
    // 没有文字返回Container
    if ((text?.length ?? 0) == 0) {
      return Container();
    }
    // 如果传的匹配字段为空则返回常规text控件
    if ((flag?.length ?? 0) == 0) {
      return Text(
        text,
        style: style,
        strutStyle: StrutStyle.fromTextStyle(style,height: height,forceStrutHeight: true,leading: 0),
      );
    }
    // 分割特殊符号
    List data = text.split(flag);
    List<InlineSpan> spans = List();
    // 如果至少有一对flag
    if (data.length > 2) {
      int index = 0;
      data.forEach((element) {
        TextSpan span;
        if (index % 2 == 0) { // 偶数不特殊标识
          span = TextSpan(text: element, style: style);
        } else {
          if (index == data.length - 1) {
            // 如果是奇数但是最后一项也按普通文案处理 eg:111#_$222#_$333#_$444
            span = TextSpan(text: element, style: style);
          } else {
            span = TextSpan(text: element, style: spanStyle);
          }
        }
        spans.add(span);
        index ++;
      });
      return RichText(text: TextSpan(
          children: spans
      ),strutStyle: StrutStyle.fromTextStyle(style,height: height,forceStrutHeight: true,leading: 0),);
    }

    // 如果只有单个flag则过滤掉flag返回默认样式
    return Text(
      text.replaceAll(flag, ''),
      style: style,
      strutStyle: StrutStyle.fromTextStyle(style,height: height,forceStrutHeight: true,leading: 0),
    );

  }
}
