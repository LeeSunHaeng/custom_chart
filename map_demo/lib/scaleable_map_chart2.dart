import 'package:flutter/material.dart';

class FocalPointZoomContainer extends StatefulWidget {
  const FocalPointZoomContainer({super.key});

  @override
  State<FocalPointZoomContainer> createState() => _FocalPointZoomContainerState();
}

class _FocalPointZoomContainerState extends State<FocalPointZoomContainer> {
  // 위젯의 위치, 크기 정보를 얻기 위한 GlobalKey
  final GlobalKey _containerKey = GlobalKey();

  double _scale = 1.0;
  double _baseScale = 1.0;

  // Transform.scale의 중심점(origin)
  Offset _origin = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focal Point Zoom'),
        actions: [
          // 초기화 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _scale = 1.0;
                _baseScale = 1.0;
                _origin = Offset.zero;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Transform.scale(
          scale: _scale,
          // 확대의 중심점을 _origin 상태값으로 지정
          origin: _origin,
          child: GestureDetector(
            onScaleStart: (details) {
              // 줌 제스처 시작 시 현재 스케일 값을 저장
              _baseScale = _scale;
            },
            onScaleUpdate: (details) {
              // 위젯의 RenderBox 정보를 가져옴
              final RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;

              // 화면 전체 기준의 focal point(글로벌 좌표)를
              // 컨테이너 위젯 기준의 로컬 좌표로 변환
              final localFocalPoint = renderBox.globalToLocal(details.focalPoint);

              setState(() {
                // 새로운 스케일 값과 origin(중심점)을 업데이트
                _scale = _baseScale * details.scale;
                _origin = localFocalPoint;
              });
            },
            child: Container(
              // 위젯에 Key를 할당
              key: _containerKey,
              width: 200,
              height: 200,
              color: Colors.blue,
              child: const Center(
                child: Text(
                  'Zoom Me!',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
