import 'package:flutter/material.dart';

/// 修正不同手机上leading和不居中的问题
@Deprecated('此控件如果被包裹在有背景的Container时不能让文字居中，在一些特殊机型上请使用 ExRichText2')
class ExText extends StatelessWidget {
  final String data; // 展示文案
  final TextStyle textStyle; // 文字样式 由于字体大小和颜色是必须的 所以此处为必穿参数
  final int maxLines; //最大行数
  final TextOverflow overflow; //裁剪模式

  ExText(
    this.data,
    this.textStyle, {
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: TextAlign.center,
      style: textStyle,
      strutStyle: StrutStyle(
        fontSize: textStyle.fontSize,
        fontWeight: textStyle.fontWeight,
        leading: 0,
        height: 1.1,
        // 1.1更居中
        forceStrutHeight: true, // 关键属性 强制改为文字高度
      ),
      textHeightBehavior: TextHeightBehavior(
          // 基线 发现不设置也能行
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false),
    );
  }
}
