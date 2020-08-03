import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

abstract class ExMultiChildLayoutDelegate {
  /// Creates a layout delegate.
  ///
  /// The layout will update whenever [relayout] notifies its listeners.
  ExMultiChildLayoutDelegate({ Listenable relayout }) : _relayout = relayout;

  final Listenable _relayout;

  Map<Object, RenderBox> _idToChild;
  Set<RenderBox> _debugChildrenNeedingLayout;

  /// True if a non-null LayoutChild was provided for the specified id.
  ///
  /// Call this from the [performLayout] or [getSize] methods to
  /// determine which children are available, if the child list might
  /// vary.
  bool hasChild(Object childId) => _idToChild[childId] != null;

  /// Ask the child to update its layout within the limits specified by
  /// the constraints parameter. The child's size is returned.
  ///
  /// Call this from your [performLayout] function to lay out each
  /// child. Every child must be laid out using this function exactly
  /// once each time the [performLayout] function is called.
  Size layoutChild(Object childId, BoxConstraints constraints) {
    final RenderBox child = _idToChild[childId];
    assert(() {
      if (child == null) {
        throw FlutterError(
            'The $this custom multichild layout delegate tried to lay out a non-existent child.\n'
                'There is no child with the id "$childId".'
        );
      }
      if (!_debugChildrenNeedingLayout.remove(child)) {
        throw FlutterError(
            'The $this custom multichild layout delegate tried to lay out the child with id "$childId" more than once.\n'
                'Each child must be laid out exactly once.'
        );
      }
      try {
        assert(constraints.debugAssertIsValid(isAppliedConstraint: true));
      } on AssertionError catch (exception) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The $this custom multichild layout delegate provided invalid box constraints for the child with id "$childId".'),
          DiagnosticsProperty<AssertionError>('Exception', exception, showName: false),
          ErrorDescription(
              'The minimum width and height must be greater than or equal to zero.\n'
                  'The maximum width must be greater than or equal to the minimum width.\n'
                  'The maximum height must be greater than or equal to the minimum height.'
          )
        ]);
      }
      return true;
    }());
    child.layout(constraints, parentUsesSize: true);
    return child.size;
  }

  /// Specify the child's origin relative to this origin.
  ///
  /// Call this from your [performLayout] function to position each
  /// child. If you do not call this for a child, its position will
  /// remain unchanged. Children initially have their position set to
  /// (0,0), i.e. the top left of the [RenderCustomMultiChildLayoutBox].
  void positionChild(Object childId, Offset offset) {
    final RenderBox child = _idToChild[childId];
    assert(() {
      if (child == null) {
        throw FlutterError(
            'The $this custom multichild layout delegate tried to position out a non-existent child:\n'
                'There is no child with the id "$childId".'
        );
      }
      if (offset == null) {
        throw FlutterError(
            'The $this custom multichild layout delegate provided a null position for the child with id "$childId".'
        );
      }
      return true;
    }());
    final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;
    childParentData.offset = offset;
  }

  DiagnosticsNode _debugDescribeChild(RenderBox child) {
    final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;
    return DiagnosticsProperty<RenderBox>('${childParentData.id}', child);
  }

  void _callPerformLayout(Size size, RenderBox firstChild) {
    // A particular layout delegate could be called reentrantly, e.g. if it used
    // by both a parent and a child. So, we must restore the _idToChild map when
    // we return.
    final Map<Object, RenderBox> previousIdToChild = _idToChild;

    Set<RenderBox> debugPreviousChildrenNeedingLayout;
    assert(() {
      debugPreviousChildrenNeedingLayout = _debugChildrenNeedingLayout;
      _debugChildrenNeedingLayout = <RenderBox>{};
      return true;
    }());

    try {
      _idToChild = <Object, RenderBox>{};
      RenderBox child = firstChild;
      while (child != null) {
        final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;
        assert(() {
          if (childParentData.id == null) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('Every child of a RenderCustomMultiChildLayoutBox must have an ID in its parent data.'),
              child.describeForError('The following child has no ID'),
            ]);
          }
          return true;
        }());
        _idToChild[childParentData.id] = child;
        assert(() {
          _debugChildrenNeedingLayout.add(child);
          return true;
        }());
        child = childParentData.nextSibling;
      }
      performLayout(size);
      assert(() {
        if (_debugChildrenNeedingLayout.isNotEmpty) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Each child must be laid out exactly once.'),
            DiagnosticsBlock(
              name:
              'The $this custom multichild layout delegate forgot '
                  'to lay out the following '
                  '${_debugChildrenNeedingLayout.length > 1 ? 'children' : 'child'}',
              properties: _debugChildrenNeedingLayout.map<DiagnosticsNode>(_debugDescribeChild).toList(),
              style: DiagnosticsTreeStyle.whitespace,
            ),
          ]);
        }
        return true;
      }());
    } finally {
      _idToChild = previousIdToChild;
      assert(() {
        _debugChildrenNeedingLayout = debugPreviousChildrenNeedingLayout;
        return true;
      }());
    }
  }

  /// Override this method to return the size of this object given the
  /// incoming constraints.
  ///
  /// The size cannot reflect the sizes of the children. If this layout has a
  /// fixed width or height the returned size can reflect that; the size will be
  /// constrained to the given constraints.
  ///
  /// By default, attempts to size the box to the biggest size
  /// possible given the constraints.
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  /// Override this method to lay out and position all children given this
  /// widget's size.
  ///
  /// This method must call [layoutChild] for each child. It should also specify
  /// the final position of each child with [positionChild].
  void performLayout(Size size);

  /// Override this method to return true when the children need to be
  /// laid out.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(covariant ExMultiChildLayoutDelegate oldDelegate);

  /// Override this method to include additional information in the
  /// debugging data printed by [debugDumpRenderTree] and friends.
  ///
  /// By default, returns the [runtimeType] of the class.
  @override
  String toString() => objectRuntimeType(this, 'MultiChildLayoutDelegate');
}

class RenderCustomMultiChildLayoutBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  /// Creates a render object that customizes the layout of multiple children.
  ///
  /// The [delegate] argument must not be null.
  RenderCustomMultiChildLayoutBox({
    List<RenderBox> children,
    @required ExMultiChildLayoutDelegate delegate,
  }) : assert(delegate != null),
        _delegate = delegate {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = MultiChildLayoutParentData();
  }

  /// The delegate that controls the layout of the children.
  ExMultiChildLayoutDelegate get delegate => _delegate;
  ExMultiChildLayoutDelegate _delegate;
  set delegate(ExMultiChildLayoutDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate)
      return;
    final ExMultiChildLayoutDelegate oldDelegate = _delegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRelayout(oldDelegate))
      markNeedsLayout();
    _delegate = newDelegate;
    if (attached) {
      oldDelegate?._relayout?.removeListener(markNeedsLayout);
      newDelegate?._relayout?.addListener(markNeedsLayout);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate?._relayout?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _delegate?._relayout?.removeListener(markNeedsLayout);
    super.detach();
  }

  Size _getSize(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrain(_delegate.getSize(constraints));
  }

  // TODO(ianh): It's a bit dubious to be using the getSize function from the delegate to
  // figure out the intrinsic dimensions. We really should either not support intrinsics,
  // or we should expose intrinsic delegate callbacks and throw if they're not implemented.

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
    // 先布局 设置尽可能大的宽高
    size = _getSize(constraints);
    delegate._callPerformLayout(size, firstChild);
    // 布局完成获取 最终的宽高
    size = _getSize(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }
}

class ExIconWidgetDelegate extends ExMultiChildLayoutDelegate {
  double width = 0;
  double height = 0;

  double maxWidth = 0;
  double maxHeihgt = 0;

  bool isFirst = true;

  ExIconWidgetDelegate({@required this.maxWidth,@required this.maxHeihgt});

  @override
  Size getSize(BoxConstraints constraints) {
    if (isFirst) {
      isFirst = false;
      return Size(maxWidth,maxHeihgt);
    }
    return Size(width, height);
  }

  @override
  void performLayout(Size size) {
    print('performLayout');
    BoxConstraints constraints = BoxConstraints(maxWidth: maxWidth);
    // 上icon
    Size top;
    Size left;
    Size right;
    Size bottom;
    Size content;
    // 上icon
    if (hasChild(ExIconWidgetId.top)) {
      top = layoutChild(ExIconWidgetId.top, constraints);
    }
    // 底部icon
    if (hasChild(ExIconWidgetId.bottom)) {
      bottom = layoutChild(ExIconWidgetId.bottom, constraints);
    }

    // 左icon
    if (hasChild(ExIconWidgetId.left)) {
      left = layoutChild(ExIconWidgetId.left, constraints);
    }
    // 内容
    if (hasChild(ExIconWidgetId.content)) {
      content = layoutChild(ExIconWidgetId.content, constraints);
    }

    // 右icon
    if (hasChild(ExIconWidgetId.right)) {
      right = layoutChild(ExIconWidgetId.right, constraints);
    }

    if (top != null) {
      positionChild(ExIconWidgetId.top,
          Offset((left?.width ?? 0) + getTowSizeWidthDis(content, top) / 2, 0));
    }

    if (left != null) {
      positionChild(
          ExIconWidgetId.left,
          Offset(
              0, (top?.height ?? 0) + getTowSizeHeightDis(content, left) / 2));
    }

    if (content != null) {
      positionChild(
          ExIconWidgetId.content, Offset(left?.width ?? 0, top?.height ?? 0));
    }

    if (right != null) {
      positionChild(
          ExIconWidgetId.right,
          Offset(getTowSizeWidth(left, content),
              (top?.height ?? 0) + getTowSizeHeightDis(content, right) / 2));
    }

    if (bottom != null) {
      positionChild(
          ExIconWidgetId.bottom,
          Offset(getTowSizeWidthDis(content, bottom) / 2 + (left?.width ?? 0),
              (top?.height ?? 0) + getTowSizeHeightDis(content, bottom) / 2));
    }

    width = (left?.width ?? 0) + (content?.width ?? 0) + (right?.width ?? 0);
    height = (top?.height ?? 0) + (content?.height ?? 0) + (bottom?.height ?? 0);
    print('performLayout width$width');
    //size = Size(width,height);
  }

  /// 获取两个Size的宽度
  double getTowSizeWidth(Size one, Size tow) {
    return (one?.width ?? 0) + (tow?.width ?? 0);
  }

  /// 获取两个Size宽度的相差值
  double getTowSizeWidthDis(Size one, Size tow) {
    return (one?.width ?? 0) - (tow?.width ?? 0);
  }

  /// 获取两个Size的高度
  double getTowSizeHeight(Size one, Size tow) {
    return (one?.height ?? 0) + (tow?.height ?? 0);
  }

  /// 获取两个Size高度的相差值
  double getTowSizeHeightDis(Size one, Size tow) {
    return (one?.height ?? 0) - (tow?.height ?? 0);
  }

  @override
  bool shouldRelayout(ExMultiChildLayoutDelegate oldDelegate) {
    return false;
  }
}

enum ExIconWidgetId { left, top, right, bottom, content }