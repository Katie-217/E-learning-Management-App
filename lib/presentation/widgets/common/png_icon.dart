import 'package:flutter/material.dart';

class PngIcon extends StatelessWidget {
  final String iconPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const PngIcon({
    Key? key,
    required this.iconPath,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      iconPath,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }
}

// Predefined icon paths for easy access
class AppIcons {
  // ========================================
  // PHẦN: Available Icons
  // MÔ TẢ: Các icon thực sự có sẵn
  // ========================================
  static const String googleLogo = 'assets/icons/logo-google.png';
  static const String backgroundRoler = 'assets/icons/background-roler.png';

  // ========================================
  // PHẦN: Navigation Icons (Material Icons)
  // MÔ TẢ: Sử dụng Material Icons thay vì PNG
  // ========================================
  static const IconData home = Icons.home;
  static const IconData course = Icons.school;
  static const IconData profile = Icons.person;
  static const IconData notification = Icons.notifications;
  static const IconData settings = Icons.settings;

  // ========================================
  // PHẦN: Feature Icons (Material Icons)
  // MÔ TẢ: Sử dụng Material Icons thay vì PNG
  // ========================================
  static const IconData assignment = Icons.assignment;
  static const IconData quiz = Icons.quiz;
  static const IconData calendar = Icons.calendar_today;

  // ========================================
  // HÀM: getIconWidget()
  // MÔ TẢ: Tạo widget icon từ IconData
  // ========================================
  static Widget getIconWidget(
    IconData icon, {
    double? size,
    Color? color,
  }) {
    return Icon(
      icon,
      size: size ?? 24,
      color: color,
    );
  }
}
