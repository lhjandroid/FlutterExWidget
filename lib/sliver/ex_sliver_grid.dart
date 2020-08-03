
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

typedef OnLayoutPosition(int start,int end);

class ExSliverGrid extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement.

  OnLayoutPosition onLayoutPosition;

  ExSliverGrid({
    Key key,
    this.onLayoutPosition,
    @required SliverChildDelegate delegate,
    @required this.gridDelegate,
  }) : super(key: key, delegate: delegate);

  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement with a fixed number of tiles in the cross axis.
  ///
  /// Uses a [SliverGridDelegateWithFixedCrossAxisCount] as the [gridDelegate],
  /// and a [SliverChildListDelegate] as the [delegate].
  ///
  /// See also:
  ///
  ///  * [new GridView.count], the equivalent constructor for [GridView] widgets.
  ExSliverGrid.count({
    Key key,
    @required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    List<Widget> children = const <Widget>[],
  }) : gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  ),
        super(key: key, delegate: SliverChildListDelegate(children));

  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement with tiles that each have a maximum cross-axis extent.
  ///
  /// Uses a [SliverGridDelegateWithMaxCrossAxisExtent] as the [gridDelegate],
  /// and a [SliverChildListDelegate] as the [delegate].
  ///
  /// See also:
  ///
  ///  * [new GridView.extent], the equivalent constructor for [GridView] widgets.
  ExSliverGrid.extent({
    Key key,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    @required int crossAxisCount,
    List<Widget> children = const <Widget>[],
  }) : gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxCrossAxisExtent,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  ),
        super(key: key, delegate: SliverChildListDelegate(children));

  /// The delegate that controls the size and position of the children.
  final SliverGridDelegate gridDelegate;

  @override
  ExRenderSliverGrid createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return ExRenderSliverGrid(childManager: element, gridDelegate: gridDelegate,
        layoutPosition: onLayoutPosition);
  }

  @override
  void updateRenderObject(BuildContext context, ExRenderSliverGrid renderObject) {
    renderObject.gridDelegate = gridDelegate;
  }

  @override
  double estimateMaxScrollOffset(
      SliverConstraints constraints,
      int firstIndex,
      int lastIndex,
      double leadingScrollOffset,
      double trailingScrollOffset,
      ) {
    return super.estimateMaxScrollOffset(
      constraints,
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    ) ?? gridDelegate.getLayout(constraints).computeMaxScrollOffset(delegate.estimatedChildCount);
  }
}

class ExRenderSliverGrid extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that contains multiple box children that whose size and
  /// position are determined by a delegate.
  ///
  /// The [childManager] and [gridDelegate] arguments must not be null.
  int reaStartPosition = 0;
  int reaEndPosition = 0;

  OnLayoutPosition _layoutPosition;

  ExRenderSliverGrid({
    @required RenderSliverBoxChildManager childManager,
    @required SliverGridDelegate gridDelegate,
    @required OnLayoutPosition layoutPosition
  }) : assert(gridDelegate != null),
        _gridDelegate = gridDelegate,
        super(childManager: childManager) {
    this._layoutPosition = layoutPosition;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverGridParentData) {
      child.parentData = SliverGridParentData();
    }
  }

  /// The delegate that controls the size and position of the children.
  SliverGridDelegate get gridDelegate => _gridDelegate;
  SliverGridDelegate _gridDelegate;
  set gridDelegate(SliverGridDelegate value) {
    assert(value != null);
    if (_gridDelegate == value)
      return;
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate))
      markNeedsLayout();
    _gridDelegate = value;
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverGridParentData childParentData = child.parentData;
    //print('child.constraints.maxWidth${child.constraints.maxWidth} height${child.constraints.maxHeight} aaa${childParentData}');
    return childParentData.crossAxisOffset;
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    // 首次在屏幕中的item
    bool firstInLayoutItem = true;
    // constraints.scrollOffset 布局已经滚动了多少
    // constraints.cacheOrigin 预布局的相对位置 它主要提升滑动体验，会在屏幕外的区域预先布局下一次滚动即将展示的的内容
    //print('constraints.scrollOffset ${constraints.scrollOffset}   constraints.cacheOrigin${constraints.cacheOrigin}  constraints.viewportMainAxisExtent${constraints.viewportMainAxisExtent}');
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    // constraints.remainingCacheExtent剩余需要缓存的范围
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    // 最终结束的位置 当前屏幕的高度加屏幕外的缓存高度
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final SliverGridLayout layout = _gridDelegate.getLayout(constraints);

    // 该位置可见的最小item的position
    final int firstIndex = layout.getMinChildIndexForScrollOffset(scrollOffset);
    // 在此滚动偏移处（或之前）可见的最大子索引。
    final int targetLastIndex = targetEndScrollOffset.isFinite ?
    layout.getMaxChildIndexForScrollOffset(targetEndScrollOffset) : null;

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild);
      final int oldLastIndex = indexOf(lastChild);
      // 找到前面需要回收的垃圾项
      final int leadingGarbage = (firstIndex - oldFirstIndex).clamp(0, childCount);
      // 之后的
      final int trailingGarbage = targetLastIndex == null ? 0 : (oldLastIndex - targetLastIndex).clamp(0, childCount);
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    // 获取第一项控件的大小
    final SliverGridGeometry firstChildGridGeometry = layout.getGeometryForChildIndex(firstIndex);
    // 头部偏移
    final double leadingScrollOffset = firstChildGridGeometry.scrollOffset;
    // 尾部偏移
    double trailingScrollOffset = firstChildGridGeometry.trailingScrollOffset;

    // 如果没有子控件
    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, layoutOffset: firstChildGridGeometry.scrollOffset)) {
        // There are either no children, or we are past the end of all our children.
        final double max = layout.computeMaxScrollOffset(childManager.childCount);
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox trailingChildWithLayout;

    // y变小的时候 往回滑动时 插入头部布局
    for (int index = indexOf(firstChild) - 1; index >= firstIndex; --index) {
      final SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(index);
      final RenderBox child = insertAndLayoutLeadingChild(
        gridGeometry.getBoxConstraints(constraints),
      );
      final SliverGridParentData childParentData = child.parentData;
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
      trailingScrollOffset = math.max(trailingScrollOffset, gridGeometry.trailingScrollOffset);
    }

    if (trailingChildWithLayout == null) {
      firstChild.layout(firstChildGridGeometry.getBoxConstraints(constraints));
      final SliverGridParentData childParentData = firstChild.parentData;
      childParentData.layoutOffset = firstChildGridGeometry.scrollOffset;
      childParentData.crossAxisOffset = firstChildGridGeometry.crossAxisOffset;
      trailingChildWithLayout = firstChild;
    }

    SliverGridParentData gridParentData = trailingChildWithLayout?.parentData;

    // 如果第一项在屏幕内 直接使用
    if (gridParentData != null && trailingChildWithLayout != null
        && trailingChildWithLayout.constraints != null
        && gridParentData != null
        && (gridParentData.layoutOffset - constraints.scrollOffset + trailingChildWithLayout.constraints.constrainHeight() >= 0)) {
      firstInLayoutItem = false;
      reaStartPosition = indexOf(trailingChildWithLayout);
    }

    // 确定本次范围，包换头部的预缓存和屏幕中的和尾部屏幕外的
    for (int index = indexOf(trailingChildWithLayout) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      final SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(index);
      // 约束布局的大小
      final BoxConstraints childConstraints = gridGeometry.getBoxConstraints(constraints);
      // RenderBox 就是绘制上使用的基类
      RenderBox child = childAfter(trailingChildWithLayout);
      if (child == null || indexOf(child) != index) {
        // 在之前找到的布局后面创建RenderBox
        child = insertAndLayoutChild(childConstraints, after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      assert(child != null);
      final SliverGridParentData childParentData = child.parentData;
      childParentData.layoutOffset = gridGeometry.scrollOffset;
      childParentData.crossAxisOffset = gridGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingScrollOffset = math.max(trailingScrollOffset, gridGeometry.trailingScrollOffset);

      // 判断当前 控件是否在屏幕中
      if ((gridGeometry.scrollOffset - constraints.scrollOffset + childConstraints.constrainHeight() >= 0)
          && (gridGeometry.scrollOffset - constraints.scrollOffset <= constraints.viewportMainAxisExtent)) {
        if (firstInLayoutItem) {
          firstInLayoutItem = false;
          reaStartPosition = index;
        }
        reaEndPosition = index;
      }
    }

    final int lastIndex = indexOf(lastChild);

    assert(childScrollOffset(firstChild) <= scrollOffset);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    final double estimatedTotalExtent = childManager.estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintExtent,
      maxPaintExtent: estimatedTotalExtent,
      cacheExtent: cacheExtent,
      // Conservative to avoid complexity.
      hasVisualOverflow: true,
    );

    // We may have started the layout while scrolled to the end, which
    // would not expose a new child.
    if (estimatedTotalExtent == trailingScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
    if (_layoutPosition != null) {
      _layoutPosition(reaStartPosition,reaEndPosition);
    }
  }
}