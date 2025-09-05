// 확대/축소 및 이동 상태를 관리하는 StatefulWidget
import 'package:flutter/material.dart';

class ZoomableWidget extends StatefulWidget {
  const ZoomableWidget({super.key});

  @override
  State<ZoomableWidget> createState() => _ZoomableWidgetState();
}

class _ZoomableWidgetState extends State<ZoomableWidget> {
  // 현재 확대 비율
  double _scale = 1.0;
  // 직전 확대 비율 (onScaleUpdate에서 계산을 위해 사용)
  double _previousScale = 1.0;

  // 현재 캔버스 이동 오프셋
  Offset _offset = Offset.zero;
  // 제스처 시작 시의 기준 오프셋
  Offset _previousOffset = Offset.zero;

  // 제스처 시작 시 손가락의 중심점
  Offset _focalPoint = Offset.zero;

  Offset _updateFocalPoint = Offset.zero;

  Offset _midPoint = Offset.zero;

  LinearFunction linearFunction = LinearFunction.fromPoints(Offset.zero, Offset.zero);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = constraints.biggest;
        print('screenSize : $screenSize');
        return GestureDetector(
          // 확대/축소 시작
          onScaleStart: (details) {
            // 제스처 시작 시의 상태를 저장
            _previousScale = _scale;
            _previousOffset = _offset;
            _focalPoint = details.focalPoint;
            linearFunction = LinearFunction.fromPoints(details.focalPoint, _offset + Offset(screenSize.width / 2, screenSize.height / 2));
          },
          // 확대/축소 중
          onScaleUpdate: (details) {
            setState(() {
              // 1. 새로운 스케일 계산
              _scale = _previousScale * details.scale;
              // 스케일 최소/최대값 제한 (선택 사항)
              _scale = _scale.clamp(1, 3.0);

              // 2. 새로운 오프셋 계산 (핵심 로직)
              // 손가락이 있는 지점을 기준으로 확대/축소하기 위한 오프셋 조정
              Offset offsetChange = details.focalPoint - _focalPoint;
              Offset newOffset = _previousOffset + offsetChange;

              double screenWidth = screenSize.width;
              double screenHeight = screenSize.height;

              // if (details.scale != 1) {
              //   // offsetChange = (details.focalPoint - _focalPoint) * _scale;
              //   Offset midPoint = newOffset + Offset(screenWidth / 2, screenHeight / 2);
              //   _midPoint = midPoint;
              //   Offset pinedFocalPoint = _focalPoint;
              //
              //   // final linearFunction = LinearFunction.fromPoints(midPoint, pinedFocalPoint);
              //   double xValue = _focalPoint.dx * _scale;
              //   double yValue = linearFunction.getY(xValue);
              //   newOffset = _previousOffset + Offset(xValue, yValue);
              //   // offsetChange = (midPoint - _focalPoint);
              //   // tempOffset = _previousOffset + offsetChange;
              // }
              print('_scale : $_scale');
              print('offsetChange : $offsetChange');

              print('tempOffset : $newOffset');
              _offset = newOffset;
              _updateFocalPoint = details.focalPoint;
            });
          },
          child: Container(
            color: Colors.grey[200],
            child: CustomPaint(
              // size: Size.infinite,
              // CustomPainter를 실제 그림을 그리는 역할
              painter: RectanglePainter(
                scale: _scale,
                offset: _offset,
                focalPoint: _focalPoint,
                updateFocalPoint: _updateFocalPoint,
                width: MediaQuery.of(context).size.width / 2,
                midPoint: _midPoint,
              ),
            ),
          ),
        );
      },
    );
  }
}

// 실제로 캔버스에 사각형을 그리는 CustomPainter
class RectanglePainter extends CustomPainter {
  final double scale;
  final Offset offset;
  final Offset focalPoint; // 추가: Gesture가 감지한 손가락의 중심점
  final Offset updateFocalPoint;
  final double width;
  final Offset midPoint;

  RectanglePainter({required this.scale, required this.offset, required this.focalPoint, required this.updateFocalPoint, required this.width, required this.midPoint});

  @override
  void paint(Canvas canvas, Size size) {
    print('offset : $offset');
    // 캔버스의 원점을 화면 중앙으로 이동합니다.
    canvas.translate(size.width / 2, size.height / 2);
    print('size : $size');

    // ★ 캔버스가 최종적으로 이동한 위치를 표시하는 점 (스케일의 실제 중심점)
    // 이 지점이 (0,0)이 되며, scale()이 이 지점을 기준으로 확대합니다.
    final currentCanvasOriginPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 10 / scale, currentCanvasOriginPaint); // 스케일에 반비례하여 점 크기 유지

    canvas.scale(scale);
    // 사용자의 제스처로 계산된 offset 적용
    canvas.translate(offset.dx, offset.dy);
    // canvas.translate(0, 0);
    // 확대/축소의 기준점을 현재 캔버스 원점으로 설정 (여기서 scale 적용)

    // --- 이제 실제 도형을 그립니다 ---
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7) // 투명도 추가하여 아래 점이 보이게
      ..style = PaintingStyle.fill;

    double rectSize = width;
    final rect = Rect.fromCenter(
      center: Offset.zero, // 캔버스 원점을 기준으로 하므로 Offset.zero
      width: rectSize,
      height: rectSize,
    );

    canvas.drawRect(rect, paint);

    // ★ 시각적으로 확인하고 싶은, 제스처가 시작된 '화면상의' focalPoint
    // 이 점은 캔버스 변환과 별개로 화면의 절대 좌표에 그려져야 합니다.
    // 하지만 지금은 캔버스 변환이 이미 이루어진 상태이므로,
    // 역변환을 통해 focalPoint를 계산하여 그려야 합니다.
    //---------------------------------------
    // // 캔버스 변환 이전의 상태를 저장하고
    // canvas.save();
    // // 모든 변환을 되돌린 다음 focalPoint를 그립니다.
    // // (캔버스 정중앙 이동, offset 이동, scale 확대/축소 모두 역변환)
    // canvas.scale(1 / scale); // scale 역변환
    // canvas.translate(-offset.dx, -offset.dy); // offset 역변환
    // canvas.translate(-size.width / 2, -size.height / 2); // 화면 중앙 이동 역변환
    //
    // final focalPointPaint = Paint()
    //   ..color = Colors.green
    //   ..style = PaintingStyle.fill;
    // // _focalPoint는 화면의 절대 좌표를 가지고 있습니다.
    // canvas.drawCircle(focalPoint, 5, focalPointPaint);
    // canvas.drawCircle(
    //     focalPoint,
    //     15,
    //     focalPointPaint
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 2);
    //
    // // updateFocalPoint는 화면의 절대 좌표를 가지고 있습니다.
    // canvas.drawCircle(updateFocalPoint, 5, focalPointPaint);
    // canvas.drawCircle(
    //     updateFocalPoint,
    //     15,
    //     focalPointPaint
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 2);
    //
    // // updateFocalPoint는 화면의 절대 좌표를 가지고 있습니다.
    // canvas.drawCircle(offset, 5, focalPointPaint);
    // canvas.drawCircle(
    //     offset,
    //     15,
    //     focalPointPaint
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 2);
    // canvas.drawCircle(
    //     midPoint,
    //     15,
    //     focalPointPaint
    //       ..style = PaintingStyle.stroke
    //       ..color = Colors.red
    //       ..strokeWidth = 2);
    //
    // // 저장했던 캔버스 상태를 복원합니다.
    // canvas.restore();

    // 캔버스 변환이 모두 끝난 후 focalPoint에 작은 점을 그리는 방법은 복잡합니다.
    // 이는 focalPoint 자체가 '화면 좌표'이기 때문입니다.
    // 캔버스는 이미 여러 번 변환된 상태이므로 focalPoint를 캔버스에 직접 그리려면
    // 현재 캔버스의 역변환을 계산해서 focalPoint의 '캔버스 좌표'를 찾아야 합니다.
    // 이는 복잡하기 때문에, 여기서는 '실제 스케일이 적용되는 캔버스의 원점'을 표시하는 것에 집중합니다.
  }

  @override
  bool shouldRepaint(covariant RectanglePainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.offset != offset || oldDelegate.focalPoint != focalPoint;
  }
}

/// 두 점(Offset)을 지나는 일차함수를 나타내는 클래스
class LinearFunction {
  /// 기울기 (slope)
  final double slope;

  /// y절편 (y-intercept)
  final double yIntercept;

  /// x절편 (x-intercept) - 수직선일 경우에만 사용
  final double? xInterceptForVerticalLine;

  /// private 생성자
  LinearFunction._({
    required this.slope,
    required this.yIntercept,
    this.xInterceptForVerticalLine,
  });

  /// 두 Offset으로부터 일차함수 객체를 생성하는 factory 생성자
  factory LinearFunction.fromPoints(Offset p1, Offset p2) {
    // 두 점의 x좌표가 거의 같은 경우 (수직선)
    if ((p1.dx - p2.dx).abs() < 0.00001) {
      return LinearFunction._(
        slope: double.infinity, // 기울기는 무한대
        yIntercept: double.nan, // y절편은 존재하지 않음 (NaN)
        xInterceptForVerticalLine: p1.dx, // x절편은 고정된 x값
      );
    } else {
      // 1. 기울기 계산
      final double slope = (p2.dy - p1.dy) / (p2.dx - p1.dx);

      // 2. y절편 계산
      final double yIntercept = p1.dy - slope * p1.dx;

      return LinearFunction._(
        slope: slope,
        yIntercept: yIntercept,
      );
    }
  }

  /// 현재 함수가 수직선인지 여부
  bool get isVertical => slope.isInfinite;

  /// 주어진 x값에 대한 y값을 계산하여 반환
  /// 만약 수직선인데 x값이 x절편과 다르면 NaN(Not a Number)을 반환
  double getY(double x) {
    if (isVertical) {
      // 수직선인 경우, 입력된 x가 x절편과 같을 때만 유효 (이론적으로 y는 무한대)
      // 여기서는 x가 일치하는지 여부에 따라 처리할 수 있도록 값을 반환
      return (x - xInterceptForVerticalLine!).abs() < 0.00001 ? double.infinity : double.nan;
    }
    return slope * x + yIntercept;
  }

  /// 주어진 y값에 대한 x값을 계산하여 반환
  double getX(double y) {
    if (isVertical) {
      return xInterceptForVerticalLine!;
    }
    if (slope.abs() < 0.00001) {
      // 수평선
      return double.nan; // x는 무한히 많음
    }
    return (y - yIntercept) / slope;
  }

  @override
  String toString() {
    if (isVertical) {
      return 'x = $xInterceptForVerticalLine';
    }
    return 'y = ${slope.toStringAsFixed(2)}x + ${yIntercept.toStringAsFixed(2)}';
  }
}
