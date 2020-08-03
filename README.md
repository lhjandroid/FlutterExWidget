# flutter_ex_widget

Flutter扩展组件库

## Getting Started

针对业务中需要在列表滚动停止时上报屏幕中的item数据，搜索了下网络上的获取屏幕中item机制都不太友好，比如重写delegate
或者设置屏幕外缓存距离为0都不能高效的实现业务需求。
所以通过重写SliverGridView和SliverListView来达到此效果。
以下是栗子🌰

#ExSliverList
``
ExSliverList1(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Container(
                  height: (index % 2 == 0) ? 50 : 100,
                  child: Text('$index'),
                  color: Color.fromARGB(
                      255,
                      Random.secure().nextInt(255),
                      Random.secure().nextInt(255),
                      Random.secure().nextInt(255)),
                );
              }, childCount: 30),
              onLayoutPosition: (start,end) {
                print('start$start  end$end');
              },
          )
``
只需要传入onLayoutPosition方法就会回调屏幕中的item 不包含屏幕外的

#ExSliverGrid
``
ExSliverGrid(
          onLayoutPosition: (start,end) {
            print('start$start  end$end');
          },
          delegate: SliverChildBuilderDelegate((context, index) {
            return Container(
              child: Text('$index'),
              color: Color.fromARGB(255, Random.secure().nextInt(255),
                  Random.secure().nextInt(255), Random.secure().nextInt(255)),
            );
          }),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 30,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
        )
``
同上 传入onLayoutPosition即可在布局完成后回调最新的屏幕中的item

当然可以在滚动停止时主动获取，但目前没有支持，如果需要的话可以后期支持

#ExIconWidget
可以在控件四周添加别的控件
类似安卓的 drawableLeft,drawableRight,drawableTop,drawableBottom
``
ExIconWidget(
                content: Text(
                  '已收到货',
                  style: TextStyle(
                      fontSize: 14, color: Color(AppColors.textBlack474245)),
                  overflow: TextOverflow.ellipsis,
                ),
                rightIcon: Image.asset(
                  'images/ic_arrow_detail_right.png',
                  width: 12,
                  height: 12,
                ),
                maxWidth: 200,
                maxHeight: 300,
              )
``
注意需要设置maxHeight,maxWidth.如果宽高没有要求可以尽量大一些，但最终会以实际大小为准。内部会自动计算最终的控件大小

#如果后续大家有现有基础控件上无法实现的效果，或者比较复杂的布局想简化时，也可以告知我 非常乐意扩展简单易用的控件，让后续
业务开发中更加快捷方便😊
