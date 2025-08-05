import 'dart:math';

import 'package:flutter/material.dart';
import 'package:map_demo/pie_chart/pie_chart_painter.dart';

class PieChartDataModel {
  final String name;
  final int value;
  final Color color;
  PieChartDataModel({required this.name, required this.value, required this.color});

  Map<String, int> toJson() => {name: value};
}

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

  final List<PieChartDataModel> chartData = [
    PieChartDataModel(name: '김다혜', value: 40, color: Color(0xFF0FC3B9)),
    PieChartDataModel(name: '이선행', value: 30, color: Color(0xFF278EFF)),
    PieChartDataModel(name: '이혜윤', value: 15, color: Color(0xFFFFCA28)),
    PieChartDataModel(name: '안수빈', value: 15, color: Color(0xFF788CA1)),
    PieChartDataModel(name: '염수환', value: 34, color: Color(0xFFD1D5DA)),
    PieChartDataModel(name: '김수연', value: 23, color: Color(0xFFFF810D)),
    PieChartDataModel(name: '암새암', value: 64, color: Color(0xFF9747FF)),
  ];
  //
  // final List<double> data = const [
  //   40,
  //   30,
  //   15,
  //   15,
  //   34,
  //   23,
  //   64,
  //   23,
  // ];
  // final List<String> dataName = const [
  //   '김다혜',
  //   '이선행',
  //   '이혜윤',
  //   '안수빈',
  //   '염수환',
  //   '김수연',
  //   '암새암',
  //   '노푸른',
  // ];
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

  final chartKey = GlobalKey();

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
    // final double total = data.fold(0, (sum, item) => sum + item);
    final double total = chartData.fold(0, (sum, item) => sum + item.value);
    final double sweep = chartData[0].value / total * 2 * pi;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AnimatedBuilder를 사용하여 두 애니메이션 동시 처리
                  AnimatedBuilder(
                    key: chartKey,
                    animation: Listenable.merge([_sizeController, _rotationController]),
                    builder: (context, child) {
                      return GestureDetector(
                        onTapUp: (details) {
                          // ... 탭 로직은 이전과 동일하게 사용 ...
                          _handleTap(details.localPosition);
                        },
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: PieChartPainter(
                            data: chartData.map((e) => e.value.toDouble()).toList(),
                            colors: colors,
                            selectedIndex: _selectedIndex,
                            selectedRadiusIncrease: _sizeAnimation.value,
                            rotationAngle: _rotationAnimation.value, // 회전 애니메이션 값 전달
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 40),
                  // 회전 버튼
                  Expanded(
                    child: Column(
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
                            TextSpan(text: '${chartData[_selectedIndex ?? 0].name}\n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Color(0xFF0FC3B9))),
                            TextSpan(
                                text: '${(chartData[_selectedIndex ?? 0].value / chartData.fold(0, (sum, item) => sum + item.value) * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                            TextSpan(text: '${chartData[_selectedIndex ?? 0].value.toStringAsFixed(0)}건', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                          ]),
                        ),
                        IconButton(
                          alignment: Alignment.center,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFACB1BB)),
                          onPressed: () => _rotateChart(1), // 아래로 (다음)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _categoryWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _tapRotateChart(int targetIndex) {
    // 동작 원리
    // 간단히 selectedIndex = s, targetIndex = t 라고 정의함
    // 1. s ~ t 사이의 모든 파이 Angle 값을 더한다
    // 2. 3시 방향에 t 파이의 중간이 와야 하므로 s, t Angle 값은 1/2만 더한다 ex) length = 6일때 s = 3, t = 2라고 하면 3, 2 index는 1/2만 더하고 4, 5, 0, 1 의 index는 그대로 더함
    // 3. 더해진 Angle의 합을 sumAngle로 저장
    // 4. sumAngle 값이 pi 보다 작으면 오른쪽으로 sumAngle 만큼 회전 (+)
    // 5. sumAngle 값이 pi 보다 크면 (2*pi) - sumAngle 만큼 왼쪽으로 회전 (-)

    double sumAngle = 0; // _selectedIndex 부터 targetIndex까지 index를 + 1 씩 해가면서 더한 앵글의 합
    int index = _selectedIndex;
    // 현재 인덱스 1/2 ~ 선택 인덱스 -1 까지 덧셈
    while (index != targetIndex) {
      print('index : $index');
      if (index == _selectedIndex || index == targetIndex) {
        sumAngle += _getMidAngleOfSlice(index) / 2;
      } else {
        sumAngle += _getMidAngleOfSlice(index);
      }
      index = (index + 1) % chartData.length;
    }
    //선택한 인덱스의 앵글 1/2 합
    sumAngle += _getMidAngleOfSlice(targetIndex) / 2;

    double targetRotation = _cumulativeRotation;
    // sumAngle이 pi보다 작으면 왼쪽으로 회전 (-) 크면 오른쪽으로 회전 (+)
    if (sumAngle < pi) {
      targetRotation = targetRotation - sumAngle;
    } else {
      targetRotation = targetRotation + ((2 * pi) - sumAngle);
    }
    setState(() {
      _selectedIndex = targetIndex;
    });

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

  // 차트를 회전시키는 메인 로직
  void _rotateChart(int direction) {
    if (chartData.isEmpty) return;

    final int currentIndex = _selectedIndex;

    // 1. 다음 선택 인덱스 계산
    int newIndex = currentIndex + direction;
    if (newIndex < 0) newIndex += chartData.length;
    if (newIndex >= chartData.length) newIndex = 0;
    if (newIndex < 0) newIndex = chartData.length - 1;

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
    final double total = chartData.fold(0.0, (sum, item) => sum + item.value);
    final sweepAngle = (chartData[index].value / total) * 2 * pi;
    return sweepAngle;
  }

  // 탭 했을 때의 로직 (회전 기능 추가)
  void _findTappedSlice(Offset tapPosition) {
    // ... 이전과 동일한 로직 ...
    // 단, 탭 했을 때도 회전시키려면 여기서 _rotateChart 호출
  }

  Widget _categoryWidget() {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 139 / 14,
      mainAxisSpacing: 11,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...chartData.map(
          (e) => _categoryItem(name: e.name, color: e.color),
        )
      ],
    );
  }

  Widget _categoryItem({required String name, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(
          width: 4,
        ),
        Text(
          name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300, height: 1),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 차트를 탭했을 때 호출될 함수
  void _handleTap(Offset localPosition) {
    final RenderBox keyRenderBox = chartKey.currentContext?.findRenderObject() as RenderBox;
    final Offset chartOffset = keyRenderBox.localToGlobal(Offset.zero);
    if (!keyRenderBox.hasSize) return;

    final size = keyRenderBox.size;
    final center = Offset(chartOffset.dx + 100, chartOffset.dy + 100);
    final touchedPosition = Offset(localPosition.dx + chartOffset.dx, localPosition.dy + chartOffset.dy);
    final radius = min(size.width / 2, size.height / 2);

    // 탭한 위치가 차트의 흰 영역(중심) 또는 외부 영역이면 무시
    final distance = (touchedPosition - center).distance;
    // if (distance > radius || distance < radius / 2) return;

    // 탭한 위치의 각도 계산 (3시 방향이 0 라디안)
    final tapAngle = atan2(touchedPosition.dy - center.dy, touchedPosition.dx - center.dx);

    // 현재 회전값을 반영하여 탭한 각도를 정규화
    // 차트의 논리적 0점(첫번째 슬라이스의 시작점)은 -pi/2 에서 시작하여 회전함
    double relativeAngle = tapAngle - (_rotationAnimation.value - pi / 2);
    if (relativeAngle < 0) relativeAngle += 2 * pi;
    relativeAngle %= (2 * pi);

    final total = chartData.fold(0.0, (sum, item) => sum + item.value);
    double startAngle = 0.0;
    int tappedIndex = -1;

    // 정규화된 각도를 기반으로 어떤 슬라이스가 탭되었는지 찾기
    for (int i = 0; i < chartData.length; i++) {
      final sweepAngle = (chartData[i].value / total) * 2 * pi;
      if (relativeAngle >= startAngle && relativeAngle < startAngle + sweepAngle) {
        tappedIndex = i;
        break;
      }
      startAngle += sweepAngle;
    }
    // 해당 슬라이스로 회전
    if (tappedIndex != -1) {
      _tapRotateChart(tappedIndex);
    }
  }
}
