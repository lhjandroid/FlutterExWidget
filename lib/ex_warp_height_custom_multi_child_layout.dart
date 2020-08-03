import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ex_multi_child_layout_delegate.dart';

/// 高度可以warp的控件
class ExeWarpHeightCustomMultiChildLayout extends MultiChildRenderObjectWidget {

  ExeWarpHeightCustomMultiChildLayout({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  }) : assert(delegate != null),
        super(key: key, children: children);

  /// The delegate that controls the layout of the children.
  final ExMultiChildLayoutDelegate delegate;

  @override
  RenderCustomMultiChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomMultiChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }

}
