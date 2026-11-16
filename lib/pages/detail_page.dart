import 'package:flutter/material.dart';

import '../data/book_repo.dart';
import '../widgets/book_cover.dart';

/// 步骤一：详情页。
///
/// 交互：Hero 封面从列表位飞过来，正文淡入（FadeTransition）。
/// 缺陷（问题二·异常与规范）：二段加载的 catch 里只打印日志，
/// 不 setState、不给界面任何反馈 —— 断网时正文区永远空白（静默白屏）。
class BookDetailPage extends StatefulWidget {
  const BookDetailPage({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  BookDetail? _detail;

  @override
  void initState() {
    super.initState();
    // 页面级控制器：initState 建一次、dispose 释放，这是正确姿势
    // （对比列表 item 里每建一次就 new 一次）。
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final BookDetail detail = await BookRepo.instance.fetchDetail(
        widget.book.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _detail = detail);
    } catch (e) {
      // 【问题二·病根】断网时到这里就结束了：
      // 只打印，没有 setState 切错误态，也没有重试入口，界面保持一片空白。
      debugPrint('load detail failed: $e');
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          FadeTransition(
            opacity: _fade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Hero(
                    // tag 必须按条目唯一，否则多个 Hero 同屏会撞车。
                    tag: 'book-${widget.book.id}',
                    child: BookCover(
                      book: widget.book,
                      width: 180,
                      height: 220,
                      radius: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(widget.book.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  widget.book.author,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 二段加载区：断网时这里就是用户看到的“白屏”。
          if (_detail == null)
            const SizedBox(height: 220)
          else
            _DetailSection(detail: _detail!),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.detail});

  final BookDetail detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('内容简介', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          detail.intro,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String tag in detail.tags) Chip(label: Text(tag)),
          ],
        ),
        const SizedBox(height: 24),
        Text('读者评论', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final String comment in detail.comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(comment, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
