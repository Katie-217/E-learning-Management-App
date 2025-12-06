// Stats card widget
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  const StatsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final isXSmall = screenWidth < 400;
    // Tăng chiều cao card để chứa text nhiều dòng
    final cardHeight = isXSmall
        ? 150.0
        : isSmall
            ? 160.0
            : 170.0;
    final iconBox = isXSmall ? 32.0 : isSmall ? 36.0 : 40.0;
    // Tăng kích thước chữ cho màn hình nhỏ
    final titleSize = isXSmall ? 16.0 : isSmall ? 18.0 : 22.0;
    final valueSize = isXSmall ? 26.0 : isSmall ? 28.0 : 30.0;
    final padding = isXSmall ? 12.0 : isSmall ? 16.0 : 20.0;

    final borderColor = bgStart.withOpacity(0.3);
    return SizedBox(
      height: cardHeight,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart.withOpacity(0.18), bgEnd.withOpacity(0.18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: bgStart.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconBox * 0.6,
                  ),
                ),
                SizedBox(width: isXSmall ? 8 : 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2, // Cho phép tối đa 2 dòng
                    softWrap: true, // Cho phép wrap text
                    overflow: TextOverflow.visible, // Hiển thị đầy đủ text
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: titleSize,
                      height: 1.2, // Giảm line height để text gọn hơn
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
