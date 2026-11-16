import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/book_repo.dart';
import '../widgets/book_cover.dart';
import 'detail_page.dart';

/// 步骤一：收藏列表页。
///
/// 交互：轻点进详情（Hero 转场），长按收藏/取消收藏（心形弹一下）。
/// 缺陷（问题一·布局/重建）：控制器被放在每个 item 的 State 里创建，
/// 而 itemBuilder 是“滚到才建、滚出就丢”的工厂 —— 滚回来一次就新建一个动画对象。
class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final Set<int> _likedIds = <int>{};

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
          // 演示用开关：切换后详情页会模拟断网，正文永远加载不出来。
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
            child: ListView.builder(
              itemCount: kBooks.length,
              // 缺陷定位点：工厂里每次重建 item，就会重新 initState、重新 new 控制器。
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
        ],
      ),
    );
  }
}

class _BookTile extends StatefulWidget {
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
  State<_BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<_BookTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _skeleton;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    // 【问题一·病根】每建一个 item 就 new 一个控制器：
    // 常驻的 12 个 + 每次滚动重建又新建一个，而且这里的 repeat 会一直占着 vsync 逐帧通知。
    _skeleton = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _skeleton, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _skeleton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // 【问题一·放大器】整块包在 AnimatedBuilder 里：控制器每帧通知，这一行的 build 就每帧重跑。
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        return InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: <Widget>[
                // 封面“加载中”的骨架脉冲，就是肉眼看到的闪。
                FadeTransition(
                  opacity: _pulse,
                  child: BookCover(
                    book: widget.book,
                    width: 48,
                    height: 60,
                    radius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _pulse,
                        child: Container(
                          height: 10,
                          width: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 长按收藏动画：隐式动画，缩放回弹（这处是正常代码，不是缺陷）
                AnimatedScale(
                  scale: widget.liked ? 1.3 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.elasticOut,
                  child: Icon(
                    widget.liked ? Icons.favorite : Icons.favorite_border,
                    color: widget.liked
                        ? Colors.pinkAccent
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
