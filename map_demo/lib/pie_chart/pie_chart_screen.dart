import 'dart:math';

import 'package:flutter/material.dart';
import 'package:map_demo/pie_chart/pie_chart_painter.dart';

// 파일을 StatefulWidget으로 변경
class PieChartScreen extends StatefulWidget {
  final bool useAppBar;
  const PieChartScreen({super.key, this.useAppBar = true});

  @override
  State<PieChartScreen> createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen> with TickerProviderStateMixin {
  // 👈 Ticker 2개 쓰기 위해 TickerProviderStateMixin으로 변경
  int _selectedIndex = 0;
  late AnimationController _sizeController; // 크기 변경 컨트롤러
  late Animation<double> _sizeAnimation;
  late AnimationController _rotationController; // 회전 컨트롤러
  late Animation<double> _rotationAnimation;

  double _cumulativeRotation = pi / 4;

  final List<double> data = const [40, 30, 15, 15, 34, 23, 64, 23];
  final List<String> dataName = const [
    '김다혜',
    '이선행',
    '이혜윤',
    '안수빈',
    '염수환',
    '김수연',
    '암새암',
    '노푸른',
  ];
  final List<Color> colors = const [
    Color(0xFF0FC3B9), // Blue
    Color(0xFF278EFF), // Orange
    Color(0xFFFFCA28), // Purple
    Color(0xFF788CA1), // Green
    Color(0xFFD1D5DA), // Green
    Color(0xFFFF810D), // Green
    Color(0xFF9747FF), // Green
    Color(0xFFFF4747), // Green
  ];

  @override
  void initState() {
    super.initState();
    // 크기 애니메이션 컨트롤러
    _sizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sizeAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _sizeController, curve: Curves.easeOut),
    );

    //시작 애니메이션 세팅
    final double total = data.fold(0, (sum, item) => sum + item);
    final double sweep = data[0] / total * 2 * pi;
    final double rotate = pi / 2 - sweep / 2;

    // 회전 애니메이션 컨트롤러
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: rotate).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _rotationController.forward(from: 0.0);
    _sizeController.forward(from: 0.0);

    _cumulativeRotation = rotate;
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useAppBar ? AppBar(title: const Text('파이차트')) : null,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          // Row로 차트와 버튼 배치
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // AnimatedBuilder를 사용하여 두 애니메이션 동시 처리
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_sizeController, _rotationController]),
                  builder: (context, child) {
                    return GestureDetector(
                      onTapUp: (details) {
                        // ... 탭 로직은 이전과 동일하게 사용 ...
                      },
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: PieChartPainter(
                          data: data,
                          colors: colors,
                          selectedIndex: _selectedIndex,
                          selectedRadiusIncrease: _sizeAnimation.value,
                          rotationAngle: _rotationAnimation.value, // 회전 애니메이션 값 전달
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 40),
              // 회전 버튼
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up, color: Color(0xFFACB1BB)),
                    onPressed: () => _rotateChart(-1), // 위로 (이전)
                  ),
                  Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(text: '', children: [
                      TextSpan(text: '${dataName[_selectedIndex ?? 0]}\n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Color(0xFF0FC3B9))),
                      TextSpan(
                          text: '${(data[_selectedIndex ?? 0] / data.fold(0, (sum, item) => sum + item) * 100).toStringAsFixed(0)}%\n',
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                      TextSpan(text: '${data[_selectedIndex ?? 0].toStringAsFixed(0)}건', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                    ]),
                  ),
                  IconButton(
                    alignment: Alignment.center,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFACB1BB)),
                    onPressed: () => _rotateChart(1), // 아래로 (다음)
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 차트를 회전시키는 메인 로직
  void _rotateChart(int direction) {
    if (data.isEmpty) return;

    final int currentIndex = _selectedIndex;

    // 1. 다음 선택 인덱스 계산
    int newIndex = currentIndex + direction;
    if (newIndex >= data.length) newIndex = 0;
    if (newIndex < 0) newIndex = data.length - 1;

    setState(() {
      _selectedIndex = newIndex;
    });

    final double currentMidAngle = _getMidAngleOfSlice(currentIndex);
    final double newMinAngle = _getMidAngleOfSlice(newIndex);

    double angleDifference = (newMinAngle + currentMidAngle) / 2;

    double targetRotation = _cumulativeRotation;
    if (direction == 1) {
      targetRotation = targetRotation - angleDifference;
    } else {
      targetRotation = targetRotation + angleDifference;
    }

    // 4. 애니메이션 실행
    _rotationAnimation = Tween<double>(
      begin: _rotationAnimation.value,
      end: targetRotation,
    ).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
    _rotationController.forward(from: 0.0);
    _sizeController.forward(from: 0.0);
    _cumulativeRotation = targetRotation;
  }

  double _getMidAngleOfSlice(int index) {
    final double total = data.fold(0.0, (sum, item) => sum + item);
    final sweepAngle = (data[index] / total) * 2 * pi;
    return sweepAngle;
  }

  // 탭 했을 때의 로직 (회전 기능 추가)
  void _findTappedSlice(Offset tapPosition) {
    // ... 이전과 동일한 로직 ...
    // 단, 탭 했을 때도 회전시키려면 여기서 _rotateChart 호출
  }
}
