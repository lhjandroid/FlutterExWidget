import 'dart:math';
import 'dart:ui' as ui show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 扩展的Flow组建 可以定义最大行数 item间距和行高的控件
class ExFlow extends MultiChildRenderObjectWidget {

  ExFlow({
    Key key,
    this.delegate,
    List<Widget> children = const <Widget>[],
  }) : assert(delegate != null),
        super(key: key, children: RepaintBoundary.wrapAll(children));
  // https://github.com/dart-lang/sdk/issues/29277

  ExFlow.unwrapped({
    Key key,
    this.delegate,
    List<Widget> children = const <Widget>[],
  }) : assert(delegate != null),
        super(key: key, children: children);

  /// The delegate that controls the transformation matrices of the children.
  final ExFlowDelegate delegate;

  @override
  ExRenderFlow createRenderObject(BuildContext context) => ExRenderFlow(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, ExRenderFlow renderObject) {
    renderObject.delegate = delegate;
  }

}

class ExRenderFlow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ExFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ExFlowParentData>
    implements FlowPaintingContext {

  // 记录一行中最大的item高度
  double maxItemHeight = 0;

  ExRenderFlow({
    List<RenderBox> children,
    ExFlowDelegate delegate
  }) : assert(delegate != null),
        _delegate = delegate {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    final ParentData childParentData = child.parentData;
    if (childParentData is ExFlowParentData)
      childParentData._transform = null;
    else
      child.parentData = ExFlowParentData();
  }

  /// The delegate that controls the transformation matrices of the children.
  ExFlowDelegate get delegate => _delegate;
  ExFlowDelegate _delegate;
  /// When the delegate is changed to a new delegate with the same runtimeType
  /// as the old delegate, this object will call the delegate's
  /// [FlowDelegate.shouldRelayout] and [FlowDelegate.shouldRepaint] functions
  /// to determine whether the new delegate requires this object to update its
  /// layout or painting.
  set delegate(ExFlowDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    final ExFlowDelegate oldDelegate = _delegate;
    _delegate = newDelegate;

    if (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRelayout(oldDelegate))
      markNeedsLayout();
    else if (newDelegate.shouldRepaint(oldDelegate))
      markNeedsPaint();

    if (attached) {
      oldDelegate._repaint?.removeListener(markNeedsPaint);
      newDelegate._repaint?.addListener(markNeedsPaint);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate._repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _delegate._repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  Size _getSize(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrain(_delegate.getSize(constraints));
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  double computeMinIntrinsicWidth(double height) {
    final double width = _getSize(BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double width = _getSize(BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite)
      return width;
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double height = _getSize(BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double height = _getSize(BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    //size = _getSize(constraints);
    double parentWidth = constraints.maxWidth;
    int i = 0;
    _randomAccessChildren.clear();
    RenderBox child = firstChild;

    //x坐标
    double offsetX = 0;
    //y坐标
    double offsetY = 0;

    // 已经绘制了多少行
    int lines = 1;

    // 一行中的最大高度
    double itemWidth;

    while (child != null) {
      _randomAccessChildren.add(child);
      final BoxConstraints innerConstraints = _delegate.getConstraintsForChild(i, constraints);
      child.layout(innerConstraints, parentUsesSize: true);
      itemWidth = child.size.width;

      if (offsetX + itemWidth + delegate.getItemSpace() < parentWidth) {
        // x坐标
        offsetX = (offsetX + itemWidth + delegate.getItemSpace());
        maxItemHeight = max(maxItemHeight, child.size.height);
      } else {
        lines++;
        // 最大行数有设定时才进行逻辑判断
        if (delegate.getMaxLines() != 0 && lines > delegate.getMaxLines()) {
          break;
        }
        // 重新设置x的值
        offsetX = itemWidth;
        // 计算y值
        offsetY = offsetY + child.size.height + delegate.getLineHeight();
        // 换行后如果 换行的第一项大于父控件宽度 根据 needLoseItemWhenItemWidthBig 判断是否要舍弃该item
        bool itemWidthBigThanParent = (child.size.width + delegate.getItemSpace() > parentWidth);
        if (itemWidthBigThanParent) {
          if (delegate.isNeedLoseItemWhenItemWidthBig()) {
            continue;
          } else {
            break;
          }
        }
      }
      maxItemHeight = max(maxItemHeight, child.size.height);

      final ExFlowParentData childParentData = child.parentData as ExFlowParentData;
      childParentData.offset = Offset.zero;
      child = childParentData.nextSibling;
      i += 1;
    }
    Size temp = _getSize(constraints);
    size = Size(temp.width, offsetY + maxItemHeight + lines);
  }

  // Updated during layout. Only valid if layout is not dirty.
  final List<RenderBox> _randomAccessChildren = <RenderBox>[];

  // Updated during paint.
  final List<int> _lastPaintOrder = <int>[];

  // Only valid during paint.
  PaintingContext _paintingContext;
  Offset _paintingOffset;

  @override
  Size getChildSize(int i) {
    if (i < 0 || i >= _randomAccessChildren.length)
      return null;
    return _randomAccessChildren[i].size;
  }

  @override
  void paintChild(int i, { Matrix4 transform, double opacity = 1.0 }) {
    transform ??= Matrix4.identity();
    final RenderBox child = _randomAccessChildren[i];
    final ExFlowParentData childParentData = child.parentData as ExFlowParentData;
    assert(() {
      if (childParentData._transform != null) {
        throw FlutterError(
            'Cannot call paintChild twice for the same child.\n'
                'The flow delegate of type ${_delegate.runtimeType} attempted to '
                'paint child $i multiple times, which is not permitted.'
        );
      }
      return true;
    }());
    _lastPaintOrder.add(i);
    childParentData._transform = transform;

    // We return after assigning _transform so that the transparent child can
    // still be hit tested at the correct location.
    if (opacity == 0.0)
      return;

    void painter(PaintingContext context, Offset offset) {
      context.paintChild(child, offset);
    }
    if (opacity == 1.0) {
      _paintingContext.pushTransform(needsCompositing, _paintingOffset, transform, painter);
    } else {
      _paintingContext.pushOpacity(_paintingOffset, ui.Color.getAlphaFromOpacity(opacity), (PaintingContext context, Offset offset) {
        context.pushTransform(needsCompositing, offset, transform, painter);
      });
    }
  }

  void _paintWithDelegate(PaintingContext context, Offset offset) {
    _lastPaintOrder.clear();
    _paintingContext = context;
    _paintingOffset = offset;
    for (final RenderBox child in _randomAccessChildren) {
      final ExFlowParentData childParentData = child.parentData as ExFlowParentData;
      childParentData._transform = null;
    }
    try {
      _delegate.paintChildren(this);
    } finally {
      _paintingContext = null;
      _paintingOffset = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, _paintWithDelegate);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    final List<RenderBox> children = getChildrenAsList();
    for (int i = _lastPaintOrder.length - 1; i >= 0; --i) {
      final int childIndex = _lastPaintOrder[i];
      if (childIndex >= children.length)
        continue;
      final RenderBox child = children[childIndex];
      final ExFlowParentData childParentData = child.parentData as ExFlowParentData;
      final Matrix4 transform = childParentData._transform;
      if (transform == null)
        continue;
      final bool absorbed = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset position) {
          return child.hitTest(result, position: position);
        },
      );
      if (absorbed)
        return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final ExFlowParentData childParentData = child.parentData as ExFlowParentData;
    if (childParentData._transform != null)
      transform.multiply(childParentData._transform);
    super.applyPaintTransform(child, transform);
  }


}

abstract class ExFlowDelegate {

  const ExFlowDelegate({ Listenable repaint }) : _repaint = repaint;

  final Listenable _repaint;


  Size getSize(BoxConstraints constraints) => constraints.biggest;

  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) => constraints;

  void paintChildren(FlowPaintingContext context);

  bool shouldRelayout(covariant ExFlowDelegate oldDelegate) => false;


  bool shouldRepaint(covariant ExFlowDelegate oldDelegate);

  /// 最大行数
  int getMaxLines();

  /// item间距
  double getItemSpace();

  /// 行高
  double getLineHeight();

  /// 是否丢弃大于行宽的item 如果某一项大于行宽了 如果不丢弃则无法继续换行了
  bool isNeedLoseItemWhenItemWidthBig();

  @override
  String toString() => objectRuntimeType(this, 'ExFlowDelegate');
}


class ExFlowParentData extends ContainerBoxParentData<RenderBox> {
  Matrix4 _transform;
}