import 'package:flutter/material.dart';

import '../data/book_repo.dart';

/// 封面占位：没有美术资源，用色块 + 首字表示一本书。
/// 列表页是小尺寸，详情页是大尺寸，Hero 靠同一个 tag 在两页之间衔接。
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final Book book;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: book.coverColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        book.title.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.34,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
