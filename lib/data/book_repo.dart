import 'package:flutter/material.dart';

/// 收藏条目：列表页与详情页共用的展示数据（列表数据是本地假数据，不走网络）。
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverColor,
  });

  final int id;
  final String title;
  final String author;
  final Color coverColor;
}

/// 详情页二段加载的内容，真实项目里来自接口。
class BookDetail {
  const BookDetail({
    required this.intro,
    required this.tags,
    required this.comments,
  });

  final String intro;
  final List<String> tags;
  final List<String> comments;
}

const List<Book> kBooks = <Book>[
  Book(
    id: 1,
    title: 'Flutter 实战',
    author: '第 9 章 · 动画与调试',
    coverColor: Colors.indigo,
  ),
  Book(
    id: 2,
    title: '动画四角色',
    author: 'Controller · Curve · Tween',
    coverColor: Colors.teal,
  ),
  Book(
    id: 3,
    title: 'Hero 共享元素',
    author: '两页同 tag 才飞得动',
    coverColor: Colors.deepOrange,
  ),
  Book(
    id: 4,
    title: 'AnimatedSwitcher',
    author: '新旧 child 同时过渡',
    coverColor: Colors.pink,
  ),
  Book(id: 5, title: '隐式动画家族', author: '一行代码换一个过渡', coverColor: Colors.purple),
  Book(
    id: 6,
    title: 'DevTools 两板斧',
    author: 'Inspector · rebuild 高亮',
    coverColor: Colors.blueGrey,
  ),
  Book(
    id: 7,
    title: '全局异常捕获',
    author: 'FlutterError · PlatformDispatcher',
    coverColor: Colors.green,
  ),
  Book(id: 8, title: '列表性能三反例', author: '别在工厂里造重物', coverColor: Colors.brown),
  Book(id: 9, title: '自定义 Sliver', author: '滚动视口进阶', coverColor: Colors.blue),
  Book(
    id: 10,
    title: '状态管理入门',
    author: 'InheritedWidget 到 Provider',
    coverColor: Colors.deepPurple,
  ),
  Book(
    id: 11,
    title: '网络与 JSON',
    author: 'async / await 与序列化',
    coverColor: Colors.cyan,
  ),
  Book(id: 12, title: '打包与发布', author: '构建产物与渠道', coverColor: Colors.red),
];

/// 假数据仓库：用 Future.delayed 模拟网络时延，用 [offline] 模拟断网。
class BookRepo {
  BookRepo._();

  static final BookRepo instance = BookRepo._();

  /// 断网开关：列表页右上角可切换，用来复现“断网时详情页静默白屏”。
  bool offline = false;

  /// 拉取详情正文。断网时抛异常，由调用方决定怎么处理。
  Future<BookDetail> fetchDetail(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (offline) {
      throw Exception(
        'SocketException: Failed host lookup: api.demo (book $id)',
      );
    }
    final Book book = kBooks.firstWhere((Book b) => b.id == id);
    return BookDetail(
      intro:
          '「${book.title}」（${book.author}）是第 9 课的配套示例。'
          '它同时用到了显式动画、共享元素转场和第二段网络加载：'
          '先看封面怎么飞进来，再看正文怎么渐显，最后把滚动卡顿和断网白屏两处问题排查掉。',
      tags: const <String>['动画', '调试', 'Flutter'],
      comments: const <String>[
        'Hero 那段终于看懂了，tag 必须唯一这点很关键。',
        '断网那节建议再演示一次，我项目里也遇到过。',
        '骨架屏闪烁的问题我这边也有，原来不是渲染的问题。',
      ],
    );
  }
}
