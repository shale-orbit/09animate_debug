import 'package:flutter/material.dart';

import '../app_errors.dart';
import '../data/book_repo.dart';
import '../widgets/book_cover.dart';

/// 步骤三（已修复问题二）：详情页。
///
/// 交互：Hero 封面从列表位飞过来，正文淡入（FadeTransition）。
/// 修复要点：二段加载分「加载中 / 成功 / 失败」三态；
/// 失败时接住异常、切错误态，界面内给错误条 + 重试，并交给全局异常入口留痕。
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
  String? _error;

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

  Future<void> _loadDetail({bool reset = false}) async {
    if (reset) {
      setState(() {
        _detail = null;
        _error = null;
      });
    }
    try {
      final BookDetail detail = await BookRepo.instance.fetchDetail(
        widget.book.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _detail = detail);
    } catch (e, s) {
      if (!mounted) {
        return;
      }
      // 修复后：接住 → 交给全局入口留痕 → setState 切错误态，界面可见可重试。
      AppErrors.report(e, s, source: 'BookDetailPage.load');
      setState(() => _error = '网络开小差了，请检查网络后重试。');
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
          // 二段加载区：加载中转圈、失败给错误条、成功出正文，不再有静默白屏。
          if (_error != null)
            _ErrorBar(message: _error!, onRetry: () => _loadDetail(reset: true))
          else if (_detail == null)
            const _LoadingBlock()
          else
            _DetailSection(detail: _detail!),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 界面内错误条：断网时替代原来的空白，告诉用户发生了什么、能做什么。
class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '加载失败',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: colors.onErrorContainer,
            ),
            child: const Text('重试'),
          ),
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
