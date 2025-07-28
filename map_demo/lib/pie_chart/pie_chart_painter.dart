import 'dart:math';

import 'package:flutter/material.dart';

class PieChartPainter extends CustomPainter {
  final List<double> data; // 차트에 사용 될 데이터
  final List<Color> colors; // 각 항목에 해당하는 색상 리스트
  final int? selectedIndex;
  final double selectedRadiusIncrease;
  final double rotationAngle;
  PieChartPainter({
    required this.data,
    required this.colors,
    required this.selectedIndex,
    required this.selectedRadiusIncrease,
    required this.rotationAngle,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.fold(0, (sum, item) => sum + item); //데이터 총합
    final Offset center = Offset(size.width / 2, size.height / 2); //원의 중심
    // 시작 각도에 회전 각도 더해줌
    double startAngle = -pi / 2 + rotationAngle;
    final double radius = min(size.width / 2, size.height / 2);

    print('total : $total');
    print('center : $center');
    print('radius : $radius');
    print('startAngle : $startAngle');
    // 2. 각 데이터 항목에 대해 부채꼴 그리기
    for (int i = 0; i < data.length; i++) {
      final bool isSelected = i == selectedIndex;
      final double currentRadius = radius + (isSelected ? selectedRadiusIncrease : 0.0);
      final double sweepAngle = (data[i] / total) * 2 * pi; //데이터가 차지하는 각도(라디안)
      print('sweepAngle : $sweepAngle');
      final paint = Paint()
        ..color = colors[i % colors.length] // 색상 지정
        ..style = PaintingStyle.fill;
      // 3. canvas.drawArc() 호출
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      //텍스트 영역 그리기
      final percentage = (data[i] / total * 100);
      final percentageText = '${percentage.toStringAsFixed(0)}%';
      final midAngle = startAngle + sweepAngle / 2;

      final textSpan = TextSpan(
        text: percentageText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      startAngle = startAngle + sweepAngle;
    }
    //중간 흰 영역 그리기
    final paint = Paint()
      ..color = Colors.white // 색상 지정
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius / 2),
      startAngle,
      2 * pi,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colors != colors ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.selectedRadiusIncrease != selectedRadiusIncrease ||
        oldDelegate.rotationAngle != rotationAngle; // 👈 회전 각도 변경 시 다시 그리기
  }
}
