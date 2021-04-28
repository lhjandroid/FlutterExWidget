import 'dart:ui';

import 'package:flutter/material.dart';

/// 价格展示模块 修正控件底部有间距 导致不居中的问题 主要针对 ¥1234这种情况 不针对汉字 但如果需要可以借鉴此写法
class ExPrice extends StatelessWidget {
  final String price; // 价格字符串
  final TextStyle textStyle; // 价格Style
  final String priceUnit; // 价格前面的符号
  final TextStyle priceUnitStyle; // 左边价格符号样式
  final bool isLeft; // 价格符号是否在左边
  static Map<double, FontSizeInfo> fontSizeMap = {}; // 不同字号对应的distance 防止多次计算 提升性能
  static Map<UnitSize, UnitSizeInfo> unitSizeMap = {}; // 价格相关字符信息 防止多次计算 提升性能

  ExPrice(this.price, this.textStyle, {this.priceUnit = '¥', this.priceUnitStyle, this.isLeft = true})
      : assert(price != null);

  @override
  Widget build(BuildContext context) {
    // print('${DateTime.now()}');
    // 价格信息
    FontSizeInfo fontSizeInfo = fontSizeMap[textStyle.fontSize];
    // 价格符号信息
    UnitSizeInfo priceUnitSizeInfo = unitSizeMap[UnitSize(priceUnitStyle.fontSize, priceUnit)];

    double toBaseLineHeight; // 价格的基准线高度
    double bottomDistance; // 价格基准线距离文字底部空白区域的高度
    double ascDistance; // 控件顶部距离文字顶部空白区域高度
    double priceUnitHeight; // 价格的文字高度
    double priceUnitWidth; // 文字宽度

    // 价格内容区域
    TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: price,
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        strutStyle: StrutStyle.fromTextStyle(textStyle, height: 1, forceStrutHeight: true),
        locale: Localizations.localeOf(context, nullOk: true),
        maxLines: 1,
        textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false))
      ..layout(maxWidth: double.infinity, minWidth: 0);
    if (fontSizeInfo != null) {
      // baseLine高度
      toBaseLineHeight = fontSizeInfo.toBaseLineHeight;
      // 字符底部空白高度，绘制时需要偏移这个距离
      bottomDistance = fontSizeInfo.bottomDistance;
      // 顶部空白距离
      ascDistance = fontSizeInfo.ascDistance;
    } else {
      List<LineMetrics> list = textPainter.computeLineMetrics();
      if (list?.isNotEmpty ?? false) {
        // baseLine高度
        toBaseLineHeight = list[0].ascent;
        // 顶部空白距离
        ascDistance = toBaseLineHeight - list[0].unscaledAscent;
      } else {
        toBaseLineHeight = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        ascDistance = 0;
      }
    }
    Size size = textPainter.size;
    // 需要偏移的距离
    bottomDistance = size.height - toBaseLineHeight;
    // 存入次fontSize对应的数据 防止下次再计算提升性能
    if (fontSizeInfo == null) {
      fontSizeMap[textStyle.fontSize] = FontSizeInfo(toBaseLineHeight, bottomDistance, ascDistance);
    }

    // 价格符号相关
    if (priceUnitSizeInfo == null) {
      TextPainter priceUnitPainter = getTextPainter(context, priceUnit, priceUnitStyle);
      priceUnitWidth = priceUnitPainter.size.width;
      List<LineMetrics> list = priceUnitPainter.computeLineMetrics();
      if (list?.isNotEmpty ?? false) {
        double priceToBaseLineHeight = list[0].ascent;
        double priceAscDistance = priceToBaseLineHeight - list[0].unscaledAscent;
        priceUnitHeight = priceToBaseLineHeight - priceAscDistance + 1;
      } else {
        priceUnitHeight = priceUnitPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        ascDistance = 0;
      }
      unitSizeMap[UnitSize(priceUnitStyle.fontSize, priceUnit)] = UnitSizeInfo(priceUnitHeight, priceUnitWidth);
      // fontSizeMap[priceUnitStyle.fontSize] = FontSizeInfo(priceUnitHeight, 0, 0)
      //   ..width = (priceUnitPainter.size?.width ?? 0);
    } else {
      // priceUnitHeight = priceUnitSizeInfo.toBaseLineHeight;
      // priceUnitWidth = priceUnitSizeInfo.width;
      priceUnitHeight = priceUnitSizeInfo.priceUnitHeight;
      priceUnitWidth = priceUnitSizeInfo.priceUnitHeight;
    }

    // print('${DateTime.now()}');
    return CustomPaint(
      painter: ExPricePainter(context, price, priceUnit, textStyle, priceUnitStyle, bottomDistance, priceUnitHeight,
          priceUnitWidth, this.isLeft),
      // 文字高度应该是到基准线高度
      size: Size(size.width + priceUnitWidth, toBaseLineHeight - ascDistance - bottomDistance + 1),
    );
  }
}

class ExPricePainter extends CustomPainter {
  // 价格字符串
  final String price;
  final String priceUnitText; // 价格符号
  final TextStyle textStyle;
  final TextStyle priceStyle;
  final BuildContext context;
  final double distance;
  final double priceUnitHeight; // 价格的文字高度
  final double priceUnitWidth; // 价格文字宽度
  final bool isLeft; // 价格符号是否在左边

  ExPricePainter(this.context, this.price, this.priceUnitText, this.textStyle, this.priceStyle, this.distance,
      this.priceUnitHeight, this.priceUnitWidth, this.isLeft);

  @override
  void paint(Canvas canvas, Size size) {
    // print('ExPricePainter size: ${size.height}');
    // print('nowtime:${DateTime.now()}');
    TextPainter textPainter = TextPainter(
        text: TextSpan(text: price, style: textStyle),
        textDirection: TextDirection.ltr,
        locale: Localizations.localeOf(context, nullOk: true),
        maxLines: 1,
        textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false));
    textPainter..layout(maxWidth: double.infinity, minWidth: 0);
    textPainter.paint(canvas, Offset(isLeft ? (priceUnitWidth ?? 0) : 0, -distance));
    // 价格符号
    TextPainter priceUnit = TextPainter(
      text: TextSpan(
        text: priceUnitText,
        style: priceStyle,
      ),
      textDirection: TextDirection.ltr,
      locale: Localizations.localeOf(context, nullOk: true),
      maxLines: 1,
      textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
    );
    priceUnit
      ..layout(maxWidth: double.infinity, minWidth: 0)
      ..paint(
        canvas,
        Offset(
          isLeft ? 0 : (size.width - priceUnitWidth),
          size.height - priceUnitHeight - ((priceUnitText == '¥') ? 0 : 1), // 汉字比¥要高
        ),
      );
    // ..paint(canvas, Offset(isLeft ? 0 : (size.width - priceUnitWidth), size.height - priceUnit.size.height));
    // print('nowtime:${DateTime.now()}');
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 获取文本的宽度和高度
TextPainter getTextPainter(BuildContext context, String text, TextStyle textStyle) {
  TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
      strutStyle: StrutStyle.fromTextStyle(textStyle, height: 1, forceStrutHeight: true),
      locale: Localizations.localeOf(context, nullOk: true),
      maxLines: 1,
      textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false))
    ..layout(maxWidth: double.infinity, minWidth: 0);
  return textPainter;
}

/// 不同文字对应的偏移信息
class FontSizeInfo {
  double toBaseLineHeight; // 顶部到baseLine的高度
  double bottomDistance; // baseLine距离底部的空白距离
  double ascDistance; // 文字距离顶部的空白距离
  double width; // 文字宽度

  FontSizeInfo(this.toBaseLineHeight, this.bottomDistance, this.ascDistance); // 数字底部的空白高度

}

/// 价格符号对应的偏移信息
class UnitSizeInfo {
  double priceUnitWidth; // 符号宽度
  double priceUnitHeight;

  UnitSizeInfo(this.priceUnitWidth, this.priceUnitHeight); // 符号高度

}

/// 价格符号结构 按照size和字符决定
class UnitSize {
  double fontSize;
  String unit;

  UnitSize(this.fontSize, this.unit); // 符号 如¥ 元 折等

}
