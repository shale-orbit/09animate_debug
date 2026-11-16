import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/book_repo.dart';
import '../widgets/book_cover.dart';
import 'detail_page.dart';

/// 步骤二（已修复问题一）：收藏列表页。
///
/// 修复要点：
///   1. 动画控制器从 item 上提到页面 State，initState 建一次、dispose 释放；
///   2. itemBuilder 不再创建任何重对象，item 改成无状态组件，滚动只做增量构建；
///   3. 骨架占位条换回真实副标题，列表不再有“呼吸闪烁”的假加载效果。
class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage>
    with SingleTickerProviderStateMixin {
  final Set<int> _likedIds = <int>{};

  // 整页只留一个控制器：只负责列表入场渐显，forward 一次就结束，
  // 不会像修复前那样逐帧通知每一个 item 重建。
  late final AnimationController _entrance;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _toggleLike(int id) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (!_likedIds.remove(id)) {
        _likedIds.add(id);
      }
    });
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BookDetailPage(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: <Widget>[
          // 演示用开关：切换后详情页会模拟断网，正文加载不出来（问题二，步骤三再修）。
          IconButton(
            tooltip: BookRepo.instance.offline ? '当前：模拟断网' : '当前：联网',
            icon: Icon(BookRepo.instance.offline ? Icons.wifi_off : Icons.wifi),
            onPressed: () => setState(
              () => BookRepo.instance.offline = !BookRepo.instance.offline,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              '长按条目收藏 · 轻点查看详情（右上角可切模拟断网）',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            // FadeTransition 只更新渲染层透明度，不会触发 ListView 及其 item 重建。
            child: FadeTransition(
              opacity: _fade,
              child: ListView.builder(
                itemCount: kBooks.length,
                // 修复后：工厂里只做参数传递，不再 new 控制器/动画对象。
                itemBuilder: (BuildContext context, int index) {
                  final Book book = kBooks[index];
                  return _BookTile(
                    book: book,
                    liked: _likedIds.contains(book.id),
                    onTap: () => _openDetail(book),
                    onLongPress: () => _toggleLike(book.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 无状态 item：滚动进出不会重建 State，也不会持有任何 ticker。
class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.liked,
    required this.onTap,
    required this.onLongPress,
  });

  final Book book;
  final bool liked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: <Widget>[
            BookCover(book: book, width: 48, height: 60, radius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  // 原来是假骨架条，现在显示真实副标题：没有加载态就不需要骨架。
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 长按收藏动画：隐式动画，只在收藏状态变化时跑 260ms，空闲不占 ticker。
            AnimatedScale(
              scale: liked ? 1.3 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.elasticOut,
              child: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? Colors.pinkAccent : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
