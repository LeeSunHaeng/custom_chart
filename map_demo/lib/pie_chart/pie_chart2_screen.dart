import 'dart:math';
import 'package:flutter/material.dart';

// 데이터 모델은 이전과 동일
class PieData {
  final String label;
  final double value;
  final Color color;

  PieData({required this.label, required this.value, required this.color});
}

// 1. StatefulWidget으로 변경
class PieChart2Screen extends StatefulWidget {
  final bool useAppBar;
  const PieChart2Screen({super.key, this.useAppBar = true});

  @override
  State<PieChart2Screen> createState() => _PieChart2ScreenState();
}

class _PieChart2ScreenState extends State<PieChart2Screen> {
  // 데이터를 State 클래스 내부로 이동
  final List<PieData> data = [
    PieData(label: '작업 A', value: 40, color: Color(0xFF0FC3B9)),
    PieData(label: '작업 B', value: 30, color: Color(0xFF278EFF)),
    PieData(label: '작업 C', value: 15, color: Color(0xFFFFCA28)),
    PieData(label: '작업 D', value: 15, color: Color(0xFF788CA1)),
  ];

  // 선택된 파이 조각의 인덱스를 저장할 상태 변수
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    double commonSize = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: widget.useAppBar
          ? AppBar(
              title: const Text('선택 가능한 파이 차트'),
            )
          : null,
      body: Center(
        // 2. GestureDetector로 감싸기
        child: GestureDetector(
          // 3. 탭 이벤트 처리
          onTapDown: (details) {
            final touchPosition = details.localPosition;
            Size size = Size(commonSize, commonSize); // CustomPaint의 사이즈와 동일해야 함
            final center = size.center(Offset.zero);
            final radius = size.width / 3.5;

            // 터치 위치가 파이 차트 바깥이면 무시
            final distance = (touchPosition - center).distance;
            if (distance > radius + 20) {
              // 약간의 여유 공간을 줌
              setState(() => selectedIndex = null);
              return;
            }

            // 터치 위치의 각도 계산
            double touchAngle = (touchPosition - center).direction;

            // atan2는 -pi ~ pi 범위를 반환하므로, 0 ~ 2pi 범위로 변환
            if (touchAngle < 0) {
              touchAngle += 2 * pi;
            }

            // 각 파이 조각의 각도와 비교하여 선택된 인덱스 찾기
            final totalValue = data.fold(0.0, (sum, item) => sum + item.value);
            double startAngle = -pi / 2;

            // painter와 동일하게 12시 방향(-pi/2) 기준으로 정규화
            double normalizedStartAngle = (startAngle + 2 * pi) % (2 * pi);
            if (touchAngle < normalizedStartAngle) {
              touchAngle += 2 * pi;
            }

            for (int i = 0; i < data.length; i++) {
              final sweepAngle = (data[i].value / totalValue) * 2 * pi;
              final endAngle = normalizedStartAngle + sweepAngle;

              if (touchAngle >= normalizedStartAngle && touchAngle < endAngle) {
                setState(() {
                  // 이미 선택된 것을 다시 탭하면 선택 해제
                  if (selectedIndex == i) {
                    selectedIndex = null;
                  } else {
                    selectedIndex = i;
                  }
                });
                return;
              }
              normalizedStartAngle = endAngle;
            }
          },
          child: SizedBox(
            width: commonSize,
            height: commonSize,
            child: CustomPaint(
              // 5. 선택된 인덱스를 painter에 전달
              painter: PieChartPainter(
                pieData: data,
                selectedIndex: selectedIndex,
              ),
              size: const Size(300, 300),
            ),
          ),
        ),
      ),
    );
  }
}

// 5. CustomPainter 수정
class PieChartPainter extends CustomPainter {
  final List<PieData> pieData;
  final int? selectedIndex; // 선택된 인덱스를 받음

  PieChartPainter({required this.pieData, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double baseRadius = size.width / 3.5;
    final double totalValue = pieData.fold(0, (sum, item) => sum + item.value);
    double startAngle = -pi / 2;

    for (int i = 0; i < pieData.length; i++) {
      final data = pieData[i];
      final sweepAngle = (data.value / totalValue) * 2 * pi;

      // 현재 그리는 조각이 선택된 조각인지 확인
      final bool isSelected = (i == selectedIndex);
      final double currentRadius = isSelected ? baseRadius + 15 : baseRadius; // 선택되면 반지름 증가
      final Paint piePaint = Paint()
        ..style = PaintingStyle.fill
        // 선택되면 색상을 약간 밝게 하여 강조
        ..color = isSelected ? data.color.withOpacity(0.8) : data.color;

      // 변경된 반지름으로 파이 그리기
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle,
        sweepAngle,
        true,
        piePaint,
      );

      // (선과 텍스트 로직은 선택적으로 수정 가능, 여기선 반지름만 반영)
      final double midAngle = startAngle + sweepAngle / 2;
      final lineStartPoint = Offset(
        center.dx + currentRadius * 3 / 4 * cos(midAngle),
        center.dy + currentRadius * 3 / 4 * sin(midAngle),
      );
      final lineEndPoint = Offset(
        center.dx + (baseRadius + 30) * cos(midAngle),
        center.dy + (baseRadius + 30) * sin(midAngle),
      );

      final linePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      if (isSelected) canvas.drawLine(lineStartPoint, lineEndPoint, linePaint);

      final textSpan = TextSpan(
        text: '${data.value.toInt()}건',
        style: TextStyle(color: const Color(0xFF1FC5BB), fontSize: 21, fontWeight: isSelected ? FontWeight.w700 : FontWeight.bold),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      Offset textOffset = Offset(
        lineEndPoint.dx - (textPainter.width / 2),
        lineEndPoint.dy - (textPainter.height / 2),
      );
      if (cos(midAngle) < 0) {
        textOffset = Offset(lineEndPoint.dx - textPainter.width - 5, textOffset.dy);
      } else {
        textOffset = Offset(lineEndPoint.dx + 5, textOffset.dy);
      }
      if (isSelected) textPainter.paint(canvas, textOffset);

      startAngle += sweepAngle;
    }

    final centerPiePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: baseRadius / 2),
      0,
      2 * pi,
      true,
      centerPiePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    // selectedIndex가 변경되었을 때도 다시 그리도록 조건 추가
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.pieData != pieData;
  }
}
