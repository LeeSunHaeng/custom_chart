import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:point_in_polygon/point_in_polygon.dart';
import 'dart:ui' as ui; // 명시적으로 dart:ui 임포트

Map<String, String> provinceNameToSigCodePrefix = {
  "서울특별시": "11",
  "부산광역시": "21",
  "대구광역시": "22",
  "인천광역시": "23",
  "광주광역시": "24",
  "대전광역시": "25",
  "울산광역시": "26",
  "세종특별자치시": "29",
  "경기도": "31",
  "강원특별자치도": "32",
  "충청북도": "33",
  "충청남도": "34",
  "전북특별자치도": "35",
  "전라남도": "36",
  "경상북도": "37",
  "경상남도": "38",
  "제주특별자치도": "39",
  "전라북도": "35",
  "강원도": "32"
};

// 지도의 전체 경계를 나타내는 클래스 (최소/최대 위도, 경도)
class MapBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapBounds && runtimeType == other.runtimeType && minLat == other.minLat && maxLat == other.maxLat && minLon == other.minLon && maxLon == other.maxLon;

  @override
  int get hashCode => minLat.hashCode ^ maxLat.hashCode ^ minLon.hashCode ^ maxLon.hashCode;
}

// 각 폴리곤에 대한 정보 (이름, 데이터, 경계 좌표, 탭 테스트용 좌표)
class ProvinceData {
  final String name;
  final double value;
  final List<List<LatLng>> latLngCoordinates; // 원본 LatLng 좌표 (MultiPolygon 고려)
  final List<List<Point>> geoPointsForHitTest; // point_in_polygon용 Point 좌표

  ProvinceData({
    required this.name,
    required this.value,
    required this.latLngCoordinates,
    required this.geoPointsForHitTest,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProvinceData && runtimeType == other.runtimeType && name == other.name && value == other.value; // 좌표는 비교하지 않음 (너무 김)

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}

// 시/군/구 폴리곤에 대한 정보 (코드, 이름, 경계 좌표, 탭 테스트용 좌표)
class SigunGuData {
  final String code; // SIG_CD
  final String name; // SIG_KOR_NM
  final List<List<LatLng>> latLngCoordinates; // 원본 LatLng 좌표 (MultiPolygon 고려)
  final List<List<Point>> geoPointsForHitTest; // point_in_polygon용 Point 좌표

  SigunGuData({
    required this.code,
    required this.name,
    required this.latLngCoordinates,
    required this.geoPointsForHitTest,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || other is SigunGuData && runtimeType == other.runtimeType && code == other.code && name == other.name; // 좌표는 비교하지 않음

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}

class KoreaCustomMapScreen extends StatefulWidget {
  final bool useAppBar;
  const KoreaCustomMapScreen({super.key, this.useAppBar = true});

  @override
  State<KoreaCustomMapScreen> createState() => _KoreaCustomMapScreenState();
}

class _KoreaCustomMapScreenState extends State<KoreaCustomMapScreen> with SingleTickerProviderStateMixin {
  Future<List<ProvinceData>>? _provinceDataFuture;
  Future<List<SigunGuData>>? _sigunGuDataFuture;

  // 통계 데이터 (예시 값, 실제 데이터로 교체 가능)
  final Map<String, double> _provinceStatisticalData = {
    "서울특별시": 6.3,
    "부산광역시": 10.1,
    "대구광역시": 2.0,
    "인천광역시": 13.1,
    "광주광역시": 1.4,
    "대전광역시": 6.8,
    "울산광역시": 10.1,
    "세종특별자치시": 0.0,
    "경기도": 56.3,
    "강원특별자치도": 1.6, // 강원특별자치도 데이터 예시
    "충청북도": 2.2,
    "충청남도": 6.8,
    "전라북도": 0.5,
    "전라남도": 1.4,
    "경상북도": 2.0,
    "경상남도": 10.1,
    "제주특별자치도": 0.0,
  };

  // 시/군/구 통계 데이터 (예시 값, 필요 시 실제 데이터로 교체)
  // key: SIG_CD, value: 통계값
  final Map<String, double> _sigunGuStatisticalData = {
    // 서울특별시 (SIG_CD는 GeoJSON 파일의 실제 값과 일치해야 합니다)
    "11010": 5.1, // 종로구
    "11020": 4.5, // 중구
    "11030": 6.0, // 용산구
    "11040": 5.8, // 성동구
    "11050": 6.5, // 광진구
    "11060": 7.0, // 동대문구
    "11070": 6.2, // 중랑구
    "11080": 6.8, // 성북구
    "11090": 5.5, // 강북구
    "11100": 5.3, // 도봉구
    "11110": 5.9, // 노원구
    "11120": 7.2, // 은평구
    "11130": 6.7, // 서대문구
    "11140": 6.1, // 마포구
    "11150": 6.9, // 양천구
    "11160": 7.1, // 강서구
    "11170": 6.4, // 구로구
    "11180": 6.6, // 금천구
    "11190": 5.7, // 영등포구
    "11200": 5.2, // 동작구
    "11210": 7.3, // 관악구
    "11220": 7.5, // 서초구
    "11230": 7.8, // 강남구
    "11240": 7.4, // 송파구
    "11250": 6.0, // 강동구
    // 강원특별자치도 (SIG_CD 접두사 '51' 사용)
    "32010": 1.1, // 춘천시
    "32020": 0.9, // 원주시
    "32030": 0.7, // 강릉시
    "32040": 0.5, // 동해시
    "32050": 0.4, // 태백시
    "32060": 0.3, // 속초시
    "32070": 0.6, // 삼척시
    "32510": 0.2, // 홍천군
    "32520": 0.1, // 횡성군
    "32530": 0.15, // 영월군
    "32540": 0.25, // 평창군
    "32550": 0.3, // 정선군
    "32560": 0.18, // 철원군
    "32570": 0.08, // 화천군
    "32580": 0.05, // 양구군
    "32590": 0.07, // 인제군
    "32600": 0.09, // 고성군
    "32610": 0.12, // 양양군
  };

  MapBounds? _mapBounds; // 전체 시/도 지도의 경계
  double _minDataValue = 0.0; // 시/도 통계 데이터 최소값
  double _maxDataValue = 0.0; // 시/도 통계 데이터 최대값

  MapBounds? _currentSigunGuMapBounds; // 현재 보여지는 시/군/구 지도의 경계 (클릭된 시/도에 한함)
  double _minSigunGuDataValue = 0.0; // 시/군/구 통계 데이터 최소값
  double _maxSigunGuDataValue = 0.0; // 시/군/구 통계 데이터 최대값

  String? _tappedProvinceName; // 롱프레스 시 하이라이트될 시/도 이름
  String? _tappedSigunGuCode; // 롱프레스 시 하이라이트될 시/군/구 코드
  bool _isPressing = false; // "누르고 있는" 상태를 나타냄 (롱프레스)

  // 시/도 -> 시/군/구 전환 관련 상태 변수
  bool _isShowingSigunGu = false; // 최종적으로 시/군/구 지도를 보여주는지 여부
  String? _expandedProvinceName; // 현재 확대되어 보여지는 시/도의 이름
  List<SigunGuData> _loadedSigunGuData = []; // 전체 시/군/구 데이터를 미리 로드하여 저장

  // CustomPainter에 전달할 현재 지도 변환 정보 (필요시 사용)
  Map<String, double> _currentMapTransform = {
    'scale': 1.0,
    'offsetX': 0.0,
    'offsetY': 0.0,
  };

  // 애니메이션 관련 변수
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 애니메이션 시작/끝 경계 (보간에 사용)
  MapBounds? _animationStartBounds;
  MapBounds? _animationEndBounds;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic, // 부드러운 곡선 애니메이션
    );

    _provinceDataFuture = _loadAndProcessGeoJson();
    _sigunGuDataFuture = _loadAndProcessSigunGuGeoJson().then((data) {
      print('_loadAndProcessSigunGuGeoJson : $data');
      _loadedSigunGuData = data;
      // 시/군/구 데이터 로드 후 최소/최대값 계산 (전체 시/군/구 대상)
      if (_sigunGuStatisticalData.isNotEmpty) {
        _minSigunGuDataValue = _sigunGuStatisticalData.values.reduce(min);
        _maxSigunGuDataValue = _sigunGuStatisticalData.values.reduce(max);
      }
      return data;
    });

    // 애니메이션 리스너: 애니메이션 완료 시 _isShowingSigunGu 상태 업데이트
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 정방향 애니메이션 (확대) 완료
        if (_animationController.value == 1.0) {
          setState(() {
            _isShowingSigunGu = true;
          });
        }
      } else if (status == AnimationStatus.dismissed) {
        // 역방향 애니메이션 (축소) 완료
        if (_animationController.value == 0.0) {
          setState(() {
            _isShowingSigunGu = false;
            _expandedProvinceName = null;
            _currentSigunGuMapBounds = null;
            _animationStartBounds = null;
            _animationEndBounds = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // GeoJSON 좌표계 순서에 따라 인덱스 조정 (lon, lat)
  static const int _lonIndex = 0;
  static const int _latIndex = 1;

  Future<List<ProvinceData>> _loadAndProcessGeoJson() async {
    final String response = await rootBundle.loadString('assets/geojson/korea_provinces.geojson');
    final Map<String, dynamic> geoJsonData = json.decode(response);

    final List features = geoJsonData['features'];
    List<ProvinceData> loadedProvinceData = [];

    double minLat = 90.0, maxLat = -90.0;
    double minLon = 180.0, maxLon = -180.0;

    for (var feature in features) {
      final properties = feature['properties'];
      final String? provinceName = properties['SIDO_NM'];
      final geometry = feature['geometry'];

      if (provinceName != null && geometry != null) {
        final double value = _provinceStatisticalData[provinceName] ?? 0.0;

        List<List<LatLng>> latLngCoordinates = [];
        List<List<Point>> geoPointsForHitTest = [];

        if (geometry['type'] == 'Polygon') {
          List<LatLng> outerRingLatLngs = [];
          List<Point> outerRingPoints = [];
          for (var coordSet in geometry['coordinates'][0]) {
            outerRingLatLngs.add(LatLng(coordSet[_latIndex], coordSet[_lonIndex]));
            outerRingPoints.add(Point(x: coordSet[_lonIndex], y: coordSet[_latIndex]));

            minLat = min(minLat, coordSet[_latIndex]);
            maxLat = max(maxLat, coordSet[_latIndex]);
            minLon = min(minLon, coordSet[_lonIndex]);
            maxLon = max(maxLon, coordSet[_lonIndex]);
          }
          latLngCoordinates.add(outerRingLatLngs);
          geoPointsForHitTest.add(outerRingPoints);
        } else if (geometry['type'] == 'MultiPolygon') {
          for (var singlePolygonPart in geometry['coordinates']) {
            List<LatLng> outerRingLatLngs = [];
            List<Point> outerRingPoints = [];
            for (var coordSet in singlePolygonPart[0]) {
              outerRingLatLngs.add(LatLng(coordSet[_latIndex], coordSet[_lonIndex]));
              outerRingPoints.add(Point(x: coordSet[_lonIndex], y: coordSet[_latIndex]));

              minLat = min(minLat, coordSet[_latIndex]);
              maxLat = max(maxLat, coordSet[_latIndex]);
              minLon = min(minLon, coordSet[_lonIndex]);
              maxLon = max(maxLon, coordSet[_lonIndex]);
            }
            latLngCoordinates.add(outerRingLatLngs);
            geoPointsForHitTest.add(outerRingPoints);
          }
        }

        loadedProvinceData.add(ProvinceData(
          name: provinceName,
          value: value,
          latLngCoordinates: latLngCoordinates,
          geoPointsForHitTest: geoPointsForHitTest,
        ));
      }
    }

    if (_provinceStatisticalData.isNotEmpty) {
      _minDataValue = 0.0;
      _maxDataValue = _provinceStatisticalData.values.reduce(max);
    }

    _mapBounds = MapBounds(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon);

    return loadedProvinceData;
  }

  Future<List<SigunGuData>> _loadAndProcessSigunGuGeoJson() async {
    final String response = await rootBundle.loadString('assets/geojson/korea_sigungu.geojson');
    final Map<String, dynamic> geoJsonData = json.decode(response);

    final List features = geoJsonData['features'];
    List<SigunGuData> loadedSigunGuData = [];

    for (var feature in features) {
      final properties = feature['properties'];
      final String? sigunGuName = properties['SIGUNGU_NM'];
      final String? sigunGuCode = properties['SIGUNGU_CD'];
      final geometry = feature['geometry'];
      if (sigunGuName != null && sigunGuCode != null && geometry != null) {
        List<List<LatLng>> latLngCoordinates = [];
        List<List<Point>> geoPointsForHitTest = [];

        if (geometry['type'] == 'Polygon') {
          List<LatLng> outerRingLatLngs = [];
          List<Point> outerRingPoints = [];
          for (var coordSet in geometry['coordinates'][0]) {
            outerRingLatLngs.add(LatLng(coordSet[_latIndex], coordSet[_lonIndex]));
            outerRingPoints.add(Point(x: coordSet[_lonIndex], y: coordSet[_latIndex]));
          }
          latLngCoordinates.add(outerRingLatLngs);
          geoPointsForHitTest.add(outerRingPoints);
        } else if (geometry['type'] == 'MultiPolygon') {
          for (var singlePolygonPart in geometry['coordinates']) {
            List<LatLng> outerRingLatLngs = [];
            List<Point> outerRingPoints = [];
            for (var coordSet in singlePolygonPart[0]) {
              outerRingLatLngs.add(LatLng(coordSet[_latIndex], coordSet[_lonIndex]));
              outerRingPoints.add(Point(x: coordSet[_lonIndex], y: coordSet[_latIndex]));
            }
            latLngCoordinates.add(outerRingLatLngs);
            geoPointsForHitTest.add(outerRingPoints);
          }
        }

        loadedSigunGuData.add(SigunGuData(
          code: sigunGuCode,
          name: sigunGuName,
          latLngCoordinates: latLngCoordinates,
          geoPointsForHitTest: geoPointsForHitTest,
        ));
      }
    }
    return loadedSigunGuData;
  }

  Color _getColorForValue(double value, double minVal, double maxVal) {
    if (maxVal == minVal) {
      return Colors.blueGrey.withOpacity(0.5);
    }
    final normalizedValue = (value - minVal) / (maxVal - minVal);
    final Color startColor = Colors.blue.shade200;
    final Color endColor = Colors.blue.shade500;
    return Color.lerp(startColor, endColor, normalizedValue)!;
  }

  Color _getProvinceColorForValue(double value) {
    return _getColorForValue(value, _minDataValue, _maxDataValue);
  }

  Color _getSigunGuColorForValue(double value) {
    return _getColorForValue(value, _minSigunGuDataValue, _maxSigunGuDataValue);
  }

  Widget _buildLegend() {
    int numberOfSteps = 5;
    double minVal = _isShowingSigunGu ? _minSigunGuDataValue : _minDataValue;
    double maxVal = _isShowingSigunGu ? _maxSigunGuDataValue : _maxDataValue;
    double stepSize = (maxVal - minVal) / numberOfSteps;

    List<Widget> legendItems = [];
    if (maxVal == minVal) {
      legendItems.add(Row(
        children: [
          Container(width: 20, height: 20, color: Colors.blueGrey.withOpacity(0.5), margin: const EdgeInsets.only(right: 8)),
          const Text('데이터 없음', style: TextStyle(fontSize: 12)),
        ],
      ));
    } else {
      for (int i = 0; i < numberOfSteps; i++) {
        double lowerBound = minVal + (stepSize * i);
        double upperBound = minVal + (stepSize * (i + 1));

        if (i == numberOfSteps - 1) {
          upperBound = maxVal;
        }

        Color color = _getColorForValue(lowerBound + stepSize / 2, minVal, maxVal);

        legendItems.add(
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: color,
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                '${lowerBound.toStringAsFixed(1)}% - ${upperBound.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }
    }

    return Positioned(
      bottom: 20,
      right: 15,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isShowingSigunGu ? '시/군/구 통계 지표 (%)' : '시/도 통계 지표 (%)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...legendItems,
            ],
          ),
        ),
      ),
    );
  }

  void _updateMapTransform(double scale, double offsetX, double offsetY) {
    _currentMapTransform = {
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  void _onPanStart(DragStartDetails details, List<ProvinceData> provinces) {
    // 애니메이션 중일 땐 롱프레스 관련 제스처 무시
    if (_animationController.isAnimating) return;

    setState(() {
      _isPressing = true;
    });
    _processPanEvent(details.localPosition, provinces, _loadedSigunGuData);
  }

  void _onPanUpdate(DragUpdateDetails details, List<ProvinceData> provinces) {
    if (_animationController.isAnimating) return;

    if (_isPressing) {
      _processPanEvent(details.localPosition, provinces, _loadedSigunGuData);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_animationController.isAnimating) return;

    setState(() {
      _isPressing = false;
      _tappedProvinceName = null;
      _tappedSigunGuCode = null; // 시/군/구 하이라이트도 해제
    });
  }

  void _onLongPressStart(LongPressStartDetails details, List<ProvinceData> provinces) {
    if (_animationController.isAnimating) return;

    if (!_isPressing) {
      setState(() {
        _isPressing = true;
      });
      _processPanEvent(details.localPosition, provinces, _loadedSigunGuData);
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_animationController.isAnimating) return;

    setState(() {
      _isPressing = false;
      _tappedProvinceName = null;
      _tappedSigunGuCode = null; // 시/군/구 하이라이트도 해제
    });
  }

  void _processPanEvent(Offset localPosition, List<ProvinceData> provinces, List<SigunGuData> sigunGuData) {
    if (_currentMapTransform['scale'] == null || _currentMapTransform['scale']! == 0.0 || _currentMapTransform['offsetX'] == null || _currentMapTransform['offsetY'] == null || _mapBounds == null) {
      return;
    }

    final double scale = _currentMapTransform['scale']!;
    final double offsetX = _currentMapTransform['offsetX']!;
    final double offsetY = _currentMapTransform['offsetY']!;

    final MapBounds currentBoundsForHitTest = _isShowingSigunGu && _currentSigunGuMapBounds != null ? _currentSigunGuMapBounds! : _mapBounds!;

    final tapLon = (localPosition.dx - offsetX) / scale + currentBoundsForHitTest.minLon;
    final tapLat = currentBoundsForHitTest.maxLat - (localPosition.dy - offsetY) / scale;
    final tapPoint = Point(x: tapLon, y: tapLat);

    String? newTappedProvinceName = null;
    String? newTappedSigunGuCode = null;

    if (!_isShowingSigunGu) {
      // 시/도 맵 상태일 때
      for (var provinceData in provinces) {
        bool isInPolygon = false;
        for (var ringPoints in provinceData.geoPointsForHitTest) {
          if (Poly.isPointInPolygon(tapPoint, ringPoints)) {
            isInPolygon = true;
            break;
          }
        }
        if (isInPolygon) {
          newTappedProvinceName = provinceData.name;
          break;
        }
      }
    } else {
      // 시/군/구 맵 상태일 때
      // 현재 확대된 시/도에 해당하는 시/군/구 데이터만 필터링
      List<SigunGuData> displayedSigunGu = sigunGuData.where((sigunGu) {
        String? targetSigCodePrefix = provinceNameToSigCodePrefix[_expandedProvinceName!];

        if (targetSigCodePrefix != null) {
          return sigunGu.code.startsWith(targetSigCodePrefix);
        }
        return false; // 매칭되는 접두사가 없으면 제외
      }).toList();

      for (var sigunGuData in displayedSigunGu) {
        bool isInPolygon = false;
        for (var ringPoints in sigunGuData.geoPointsForHitTest) {
          if (Poly.isPointInPolygon(tapPoint, ringPoints)) {
            isInPolygon = true;
            break;
          }
        }
        if (isInPolygon) {
          newTappedSigunGuCode = sigunGuData.code;
          break;
        }
      }
    }

    if (newTappedProvinceName != _tappedProvinceName || newTappedSigunGuCode != _tappedSigunGuCode) {
      setState(() {
        _tappedProvinceName = newTappedProvinceName;
        _tappedSigunGuCode = newTappedSigunGuCode;
      });
    }
  }

  // 시/도 클릭 시 시/군/구 지도로 전환 로직
  void _onProvinceTapped(ProvinceData provinceData) {
    print('_onProvinceTapped');
    // 애니메이션 시작 경계 설정
    _animationStartBounds = _mapBounds;

    setState(() {
      _expandedProvinceName = provinceData.name;
      _tappedProvinceName = null; // 롱프레스 강조 해제 (새로운 동작 시작)
      _tappedSigunGuCode = null; // 혹시 모를 시/군/구 하이라이트도 해제
      List<SigunGuData> filteredSigunGu = _loadedSigunGuData.where((sigunGu) {
        String? targetSigCodePrefix = provinceNameToSigCodePrefix[provinceData.name];
        if (targetSigCodePrefix != null) {
          return sigunGu.code.startsWith(targetSigCodePrefix);
        }
        return sigunGu.name.startsWith(provinceData.name.substring(0, 2));
      }).toList();
      if (filteredSigunGu.isNotEmpty) {
        double minLat = 90.0, maxLat = -90.0;
        double minLon = 180.0, maxLon = -180.0;
        for (var sigunGu in filteredSigunGu) {
          for (var polygon in sigunGu.latLngCoordinates) {
            for (var latlng in polygon) {
              minLat = min(minLat, latlng.latitude);
              maxLat = max(maxLat, latlng.latitude);
              minLon = min(minLon, latlng.longitude);
              maxLon = max(maxLon, latlng.longitude);
            }
          }
        }
        _currentSigunGuMapBounds = MapBounds(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon);
        _animationEndBounds = _currentSigunGuMapBounds; // 애니메이션 끝 경계 설정
      } else {
        _currentSigunGuMapBounds = null;
        _animationEndBounds = null;
      }
    });
    if (_animationStartBounds != null && _animationEndBounds != null) {
      _animationController.forward(from: 0.0); // 애니메이션 시작 (시작점 0.0에서 1.0으로)
    } else {
      setState(() {
        _isShowingSigunGu = true;
      });
    }
  }

  // 시/군/구 지도에서 다시 시/도 지도로 돌아가는 로직
  void _resetMapToProvince() {
    _animationController.reverse(from: 1.0); // 애니메이션 역재생 (1.0에서 0.0으로)
  }

  void _onTapUp(TapUpDetails details, List<ProvinceData> provinces) {
    if (_isPressing || _animationController.isAnimating) return; // 애니메이션 중이거나 롱프레스 중 탭 이벤트 무시

    if (_currentMapTransform['scale'] == null || _currentMapTransform['scale']! == 0.0 || _currentMapTransform['offsetX'] == null || _currentMapTransform['offsetY'] == null) {
      return;
    }

    final tappedOffset = details.localPosition;
    final double scale = _currentMapTransform['scale']!;
    final double offsetX = _currentMapTransform['offsetX']!;
    final double offsetY = _currentMapTransform['offsetY']!;

    final MapBounds currentBoundsForHitTest = _isShowingSigunGu && _currentSigunGuMapBounds != null ? _currentSigunGuMapBounds! : _mapBounds!;

    final tapLon = (tappedOffset.dx - offsetX) / scale + currentBoundsForHitTest.minLon;
    final tapLat = currentBoundsForHitTest.maxLat - (tappedOffset.dy - offsetY) / scale;
    final tapPoint = Point(x: tapLon, y: tapLat);

    if (!_isShowingSigunGu) {
      for (var provinceData in provinces) {
        bool isInPolygon = false;
        for (var ringPoints in provinceData.geoPointsForHitTest) {
          if (Poly.isPointInPolygon(tapPoint, ringPoints)) {
            isInPolygon = true;
            break;
          }
        }
        print('isInPolygon : $isInPolygon');
        if (isInPolygon) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${provinceData.name}: ${provinceData.value.toStringAsFixed(1)}%')),
          );
          _onProvinceTapped(provinceData); // 시/도 탭 시 시/군/구 지도로 전환 애니메이션 시작
          break;
        }
      }
    } else {
      if (_loadedSigunGuData.isEmpty || _expandedProvinceName == null || _currentSigunGuMapBounds == null) {
        return;
      }

      List<SigunGuData> displayedSigunGu = _loadedSigunGuData.where((sigunGu) {
        String? targetSigCodePrefix = provinceNameToSigCodePrefix[_expandedProvinceName!];

        if (targetSigCodePrefix != null) {
          return sigunGu.code.startsWith(targetSigCodePrefix);
        }
        return sigunGu.name.startsWith(_expandedProvinceName!.substring(0, 2));
      }).toList();

      for (var sigunGuData in displayedSigunGu) {
        bool isInPolygon = false;
        for (var ringPoints in sigunGuData.geoPointsForHitTest) {
          if (Poly.isPointInPolygon(tapPoint, ringPoints)) {
            isInPolygon = true;
            break;
          }
        }
        if (isInPolygon) {
          double sigunGuValue = _sigunGuStatisticalData[sigunGuData.code] ?? 0.0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${sigunGuData.name}: ${sigunGuValue.toStringAsFixed(1)}%')),
          );
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useAppBar
          ? AppBar(
              title: Text(_isShowingSigunGu ? '시/군/구 지도' : '한국 시/도 통계 지도 차트'),
              leading: _isShowingSigunGu || _animationController.isAnimating
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _animationController.isAnimating ? null : _resetMapToProvince,
                    )
                  : null,
            )
          : null,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, details) {
          print('didPop : $didPop');
          print('details : $details');
          print('bool : $_isShowingSigunGu');
          if (didPop) return;
          if (_isShowingSigunGu) {
            _resetMapToProvince();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: FutureBuilder<List<ProvinceData>>(
          future: _provinceDataFuture,
          builder: (context, provinceSnapshot) {
            if (provinceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (provinceSnapshot.hasError) {
              return Center(child: Text('시/도 지도 데이터를 불러오는데 오류가 발생했습니다: ${provinceSnapshot.error}'));
            } else if (!provinceSnapshot.hasData || provinceSnapshot.data!.isEmpty || _mapBounds == null) {
              return const Center(child: Text('시/도 지도 데이터가 없거나 로드할 수 없습니다. GeoJSON 파일을 확인해주세요.'));
            }

            return FutureBuilder<List<SigunGuData>>(
              future: _sigunGuDataFuture,
              builder: (context, sigunGuSnapshot) {
                if (sigunGuSnapshot.connectionState == ConnectionState.waiting && (_isShowingSigunGu || _animationController.isAnimating)) {
                  return const Center(child: CircularProgressIndicator());
                } else if (sigunGuSnapshot.hasError && (_isShowingSigunGu || _animationController.isAnimating)) {
                  return Center(child: Text('시/군/구 지도 데이터를 불러오는데 오류가 발생했습니다: ${sigunGuSnapshot.error}'));
                }
                if (!provinceSnapshot.hasData || !sigunGuSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)));
                }

                List<ProvinceData> allProvinces = provinceSnapshot.data!;

                List<SigunGuData> displayedSigunGuDataForExpandedProvince = [];
                if (_expandedProvinceName != null) {
                  displayedSigunGuDataForExpandedProvince = _loadedSigunGuData.where((sigunGu) {
                    String? targetSigCodePrefix = provinceNameToSigCodePrefix[_expandedProvinceName!];

                    if (targetSigCodePrefix != null) {
                      return sigunGu.code.startsWith(targetSigCodePrefix);
                    }
                    return sigunGu.name.startsWith(_expandedProvinceName!.substring(0, 2));
                  }).toList();
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        MapBounds currentRenderBounds;

                        if (_animationStartBounds != null && _animationEndBounds != null) {
                          currentRenderBounds = MapBounds(
                            minLat: ui.lerpDouble(_animationStartBounds!.minLat, _animationEndBounds!.minLat, _animation.value)!,
                            maxLat: ui.lerpDouble(_animationStartBounds!.maxLat, _animationEndBounds!.maxLat, _animation.value)!,
                            minLon: ui.lerpDouble(_animationStartBounds!.minLon, _animationEndBounds!.minLon, _animation.value)!,
                            maxLon: ui.lerpDouble(_animationStartBounds!.maxLon, _animationEndBounds!.maxLon, _animation.value)!,
                          );
                        } else {
                          currentRenderBounds = _mapBounds!;
                        }

                        Color Function(double value) currentColorFunc;
                        if (_animation.value > 0.5) {
                          currentColorFunc = _getSigunGuColorForValue;
                        } else {
                          currentColorFunc = _getProvinceColorForValue;
                        }

                        double currentMinDataValue = _animation.value > 0.5 ? _minSigunGuDataValue : _minDataValue;
                        double currentMaxDataValue = _animation.value > 0.5 ? _maxSigunGuDataValue : _maxDataValue;

                        return GestureDetector(
                          onPanStart: (details) => _onPanStart(details, allProvinces),
                          onPanUpdate: (details) => _onPanUpdate(details, allProvinces),
                          onPanEnd: (details) => _onPanEnd(details),
                          onTapUp: (details) => _onTapUp(details, allProvinces),
                          onLongPressStart: (details) => _onLongPressStart(details, allProvinces),
                          onLongPressEnd: (details) => _onLongPressEnd(details),
                          child: CustomPaint(
                            painter: _MapPainter(
                              allProvinces: allProvinces,
                              allSigunGuDataForExpandedProvince: displayedSigunGuDataForExpandedProvince,
                              minDataValue: currentMinDataValue,
                              maxDataValue: currentMaxDataValue,
                              mapBounds: currentRenderBounds,
                              getColorForValue: currentColorFunc,
                              tappedProvinceName: _tappedProvinceName,
                              tappedSigunGuCode: _tappedSigunGuCode, // 변경된 부분: 시/군/구 코드 전달
                              isPressing: _isPressing,
                              onMapTransformCalculated: _updateMapTransform,
                              isShowingSigunGu: _isShowingSigunGu,
                              animationValue: _animation.value,
                              sigunGuStatisticalData: _sigunGuStatisticalData,
                              clickedProvinceForZoom: _expandedProvinceName,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// CustomPainter 구현
class _MapPainter extends CustomPainter {
  final List<ProvinceData> allProvinces;
  final List<SigunGuData> allSigunGuDataForExpandedProvince;
  final double minDataValue;
  final double maxDataValue;
  final MapBounds mapBounds;
  final Color Function(double value) getColorForValue;
  final String? tappedProvinceName; // (long press) 탭된 시/도 이름
  final String? tappedSigunGuCode; // (long press) 탭된 시/군/구 코드 (추가)
  final bool isPressing; // (long press) 누르고 있는 상태
  final Function(double scale, double offsetX, double offsetY) onMapTransformCalculated;
  final bool isShowingSigunGu;
  final double animationValue;
  final Map<String, double> sigunGuStatisticalData;
  final String? clickedProvinceForZoom;

  _MapPainter({
    required this.allProvinces,
    required this.allSigunGuDataForExpandedProvince,
    required this.minDataValue,
    required this.maxDataValue,
    required this.mapBounds,
    required this.getColorForValue,
    this.tappedProvinceName,
    this.tappedSigunGuCode, // 추가
    required this.isPressing,
    required this.onMapTransformCalculated,
    required this.isShowingSigunGu,
    required this.animationValue,
    required this.sigunGuStatisticalData,
    this.clickedProvinceForZoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black54;

    final Paint leaderLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black87;

    final double lonRange = mapBounds.maxLon - mapBounds.minLon;
    final double latRange = mapBounds.maxLat - mapBounds.minLat;

    double scaleX = size.width / lonRange;
    double scaleY = size.height / latRange;

    double baseScale = min(scaleX, scaleY);
    double offsetX = (size.width - lonRange * baseScale) / 2;
    double offsetY = (size.height - latRange * baseScale) / 2;

    onMapTransformCalculated(baseScale, offsetX, offsetY);

    // --- 1. 일반 시/도 지역 그리기 (애니메이션 중 페이드아웃 또는 롱프레스 시 불투명화) ---
    // isShowingSigunGu가 false일 때만 시/도 지도를 그립니다.
    // 애니메이션이 진행 중이면, 클릭되지 않은 지역은 점점 사라집니다.
    if (!isShowingSigunGu) {
      for (var province in allProvinces) {
        // 현재 롱프레스 하이라이트 대상이거나, 확대 전환 중인 지역은 이 레이어에서 제외
        if (province.name == tappedProvinceName || province.name == clickedProvinceForZoom) {
          continue;
        }

        double currentOpacity = 1.0;

        // 애니메이션이 진행 중 (시/도에서 시/군/구로 전환 중)
        if (animationValue > 0 && animationValue < 1.0) {
          currentOpacity = (1.0 - animationValue).clamp(0.0, 1.0); // 애니메이션 진행에 따라 페이드아웃
        }
        // 롱프레스 하이라이트 상태일 때 다른 지역의 불투명도 조절
        else if (isPressing && tappedProvinceName != null) {
          currentOpacity = 0.3; // 롱프레스 시 다른 지역 30% 불투명
        }

        Color currentFillColor = getColorForValue(province.value).withOpacity(currentOpacity);
        paint.color = currentFillColor;
        // borderPaint.color = Colors.black54.withOpacity(currentOpacity);
        borderPaint.color = Colors.white;

        _drawPath(canvas, province.latLngCoordinates, paint, borderPaint, baseScale, offsetX, offsetY);
      }
    }

    // --- 2. 클릭된 시/도 그리기 (확대 애니메이션) ---
    if (clickedProvinceForZoom != null) {
      ProvinceData? zoomingProvince = allProvinces.firstWhereOrNull((p) => p.name == clickedProvinceForZoom);
      if (zoomingProvince != null) {
        // 애니메이션 완료 상태(isShowingSigunGu)가 아니거나, 아직 애니메이션 중일 때만 그립니다.
        // 이때, 롱프레스 하이라이트된 시/도는 여기서 그리지 않음 (4번에서 그려질 것임)
        if ((!isShowingSigunGu || (isShowingSigunGu && animationValue < 1.0)) && tappedProvinceName != zoomingProvince.name) {
          paint.color = getColorForValue(zoomingProvince.value).withOpacity(1.0); // 항상 불투명하게
          borderPaint.color = Colors.black54; // 항상 불투명한 테두리
          _drawPath(canvas, zoomingProvince.latLngCoordinates, paint, borderPaint, baseScale, offsetX, offsetY);
        }
      }
    }

    // --- 3. 시/군/구 지도 그리기 (스르륵 나타나기 및 롱프레스 시 불투명화) ---
    // 애니메이션 진행 값에 따라 투명도 조절 (0.0 -> 1.0)
    double sigunGuFadeInOpacity = animationValue.clamp(0.0, 1.0);

    if (sigunGuFadeInOpacity > 0.0) {
      paint.color = Colors.transparent; // 초기화
      borderPaint.color = Colors.black54.withOpacity(sigunGuFadeInOpacity);

      for (var sigunGu in allSigunGuDataForExpandedProvince) {
        // 현재 롱프레스 하이라이트 대상인 시/군/구는 이 레이어에서 제외 (나중에 4번에서 위에 그려질 것임)
        if (sigunGu.code == tappedSigunGuCode && isPressing) {
          continue;
        }

        double currentSigunGuOpacity = sigunGuFadeInOpacity;
        // 시/군/구 지도 상태이고, 롱프레스 중이며, 다른 시/군/구가 하이라이트될 때
        if (isShowingSigunGu && isPressing && tappedSigunGuCode != null) {
          currentSigunGuOpacity *= 0.3; // 다른 지역 30% 불투명
        }

        final double value = sigunGuStatisticalData[sigunGu.code] ?? 0.0;
        paint.color = getColorForValue(value).withOpacity(currentSigunGuOpacity);
        borderPaint.color = Colors.white; // 테두리도 함께 조절
        _drawPath(canvas, sigunGu.latLngCoordinates, paint, borderPaint, baseScale, offsetX, offsetY);
      }
    }

    // --- 4. 롱프레스 하이라이트 지역 그리기 (가장 위에 그려지며, 애니메이션 중에는 사라짐) ---
    // 이 로직은 isShowingSigunGu와 관계없이 동작하도록 수정되었습니다.
    // 단, 애니메이션 진행 중 (animationValue > 0 && animationValue < 1.0) 에는 하이라이트를 그리지 않습니다.
    if (isPressing && animationValue == 0.0) {
      // 시/도 맵 상태에서의 하이라이트 (애니메이션이 시작되지 않았을 때만)
      if (tappedProvinceName != null && !isShowingSigunGu) {
        ProvinceData? longPressedProvince = allProvinces.firstWhereOrNull((p) => p.name == tappedProvinceName);
        if (longPressedProvince != null) {
          double highlightScale = baseScale * 1.05;

          final centerLatLng = _getPolygonCenter(longPressedProvince.latLngCoordinates.expand((e) => e).toList());
          double newOffsetX = offsetX - (centerLatLng.longitude - mapBounds.minLon) * (highlightScale - baseScale);
          double newOffsetY = offsetY - (mapBounds.maxLat - centerLatLng.latitude) * (highlightScale - baseScale);

          Paint shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.4)
            ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5.0);

          canvas.save();
          canvas.translate(newOffsetX, newOffsetY);
          canvas.scale(highlightScale / baseScale);

          for (var polygonRingLatLngs in longPressedProvince.latLngCoordinates) {
            final ui.Path path = ui.Path();
            bool firstPoint = true;
            for (var latlng in polygonRingLatLngs) {
              double pixelX = (latlng.longitude - mapBounds.minLon) * baseScale;
              double pixelY = (mapBounds.maxLat - latlng.latitude) * baseScale;
              if (firstPoint) {
                path.moveTo(pixelX, pixelY);
                firstPoint = false;
              } else {
                path.lineTo(pixelX, pixelY);
              }
            }
            path.close();
            canvas.drawPath(path, shadowPaint);
          }
          canvas.restore();

          paint.color = getColorForValue(longPressedProvince.value).withOpacity(1.0);
          _drawPath(canvas, longPressedProvince.latLngCoordinates, paint, Paint()..style = PaintingStyle.fill, highlightScale, newOffsetX, newOffsetY);
          _drawProvinceLabel(canvas, size, longPressedProvince, highlightScale, newOffsetX, newOffsetY, 1.0, leaderLinePaint);
        }
      }
    } else if (isPressing && animationValue == 1.0 && isShowingSigunGu) {
      // 시/군/구 맵 상태에서의 하이라이트 (애니메이션 완료 후)
      if (tappedSigunGuCode != null) {
        SigunGuData? longPressedSigunGu = allSigunGuDataForExpandedProvince.firstWhereOrNull((s) => s.code == tappedSigunGuCode);
        if (longPressedSigunGu != null) {
          double highlightScale = baseScale * 1.05;

          final centerLatLng = _getPolygonCenter(longPressedSigunGu.latLngCoordinates.expand((e) => e).toList());
          double newOffsetX = offsetX - (centerLatLng.longitude - mapBounds.minLon) * (highlightScale - baseScale);
          double newOffsetY = offsetY - (mapBounds.maxLat - centerLatLng.latitude) * (highlightScale - baseScale);

          Paint shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.4)
            ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5.0);

          canvas.save();
          canvas.translate(newOffsetX, newOffsetY);
          canvas.scale(highlightScale / baseScale);

          for (var polygonRingLatLngs in longPressedSigunGu.latLngCoordinates) {
            final ui.Path path = ui.Path();
            bool firstPoint = true;
            for (var latlng in polygonRingLatLngs) {
              double pixelX = (latlng.longitude - mapBounds.minLon) * baseScale;
              double pixelY = (mapBounds.maxLat - latlng.latitude) * baseScale;
              if (firstPoint) {
                path.moveTo(pixelX, pixelY);
                firstPoint = false;
              } else {
                path.lineTo(pixelX, pixelY);
              }
            }
            path.close();
            canvas.drawPath(path, shadowPaint);
          }
          canvas.restore();

          final double sigunGuValue = sigunGuStatisticalData[longPressedSigunGu.code] ?? 0.0;
          paint.color = getColorForValue(sigunGuValue).withOpacity(1.0);
          _drawPath(canvas, longPressedSigunGu.latLngCoordinates, paint, Paint()..style = PaintingStyle.fill, highlightScale, newOffsetX, newOffsetY);
          _drawSigunGuLabel(canvas, size, longPressedSigunGu, sigunGuValue, highlightScale, newOffsetX, newOffsetY, 1.0, leaderLinePaint);
        }
      }
    }
  }

  // 폴리곤 경로를 그리는 헬퍼 함수
  // borderPaint가 PaintingStyle.fill 이면 테두리를 그리지 않음 (하이라이트 시 사용)
  void _drawPath(Canvas canvas, List<List<LatLng>> coordinates, Paint fillPaint, Paint borderPaint, double scale, double offsetX, double offsetY) {
    for (var polygonRingLatLngs in coordinates) {
      final ui.Path path = ui.Path();
      bool firstPoint = true;
      for (var latlng in polygonRingLatLngs) {
        double pixelX = (latlng.longitude - mapBounds.minLon) * scale + offsetX;
        double pixelY = (mapBounds.maxLat - latlng.latitude) * scale + offsetY;
        if (firstPoint) {
          path.moveTo(pixelX, pixelY);
          firstPoint = false;
        } else {
          path.lineTo(pixelX, pixelY);
        }
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      if (borderPaint.style == PaintingStyle.stroke) {
        // 테두리가 stroke 스타일일 때만 그림
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  // 롱프레스 시 시/도 라벨을 그리는 헬퍼 함수
  void _drawProvinceLabel(Canvas canvas, Size size, ProvinceData province, double currentScale, double currentOffsetX, double currentOffsetY, double opacity, Paint leaderPaint) {
    final String labelText = '${province.name} ${province.value.toStringAsFixed(1)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: Colors.black87.withOpacity(opacity),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width * 0.4);

    final centerLatLng = _getPolygonCenter(province.latLngCoordinates.expand((e) => e).toList());

    // 라벨 위치 계산은 하이라이트된 지역의 실제 위치/스케일에 맞춰 조정 (이동 없음)
    double polyCenterX = (centerLatLng.longitude - mapBounds.minLon) * currentScale + currentOffsetX;
    double polyCenterY = (mapBounds.maxLat - centerLatLng.latitude) * currentScale + currentOffsetY;

    Offset labelPoint;
    Offset lineBreakPoint;
    double distance = 80.0;
    double angle = -pi / 4;

    if (province.name.contains("서울") || province.name.contains("경기") || province.name.contains("인천")) {
      labelPoint = Offset(polyCenterX - distance * cos(pi / 4), polyCenterY - distance * sin(pi / 4));
      lineBreakPoint = Offset(polyCenterX - 30, polyCenterY - 30);
    } else if (province.name.contains("부산") || province.name.contains("울산") || province.name.contains("경남")) {
      labelPoint = Offset(polyCenterX + distance * cos(pi / 6), polyCenterY + distance * sin(pi / 6));
      lineBreakPoint = Offset(polyCenterX + 30, polyCenterY + 30);
    } else {
      labelPoint = Offset(polyCenterX + distance * cos(angle), polyCenterY + distance * sin(angle));
      lineBreakPoint = Offset(polyCenterX + 30, polyCenterY - 30);
    }

    labelPoint = Offset(labelPoint.dx - textPainter.width / 2, labelPoint.dy - textPainter.height / 2);

    final ui.Path linePath = ui.Path();
    linePath.moveTo(polyCenterX, polyCenterY);
    linePath.lineTo(lineBreakPoint.dx, lineBreakPoint.dy);
    if (labelPoint.dx > lineBreakPoint.dx) {
      linePath.lineTo(labelPoint.dx + textPainter.width / 2, lineBreakPoint.dy);
    } else {
      linePath.lineTo(labelPoint.dx + textPainter.width / 2, lineBreakPoint.dy);
    }
    canvas.drawPath(linePath, leaderPaint..color = leaderPaint.color.withOpacity(opacity));
    textPainter.paint(canvas, labelPoint);
  }

  // 롱프레스 시 시/군/구 라벨을 그리는 헬퍼 함수 (새로 추가)
  void _drawSigunGuLabel(Canvas canvas, Size size, SigunGuData sigunGu, double value, double currentScale, double currentOffsetX, double currentOffsetY, double opacity, Paint leaderPaint) {
    final String labelText = '${sigunGu.name} ${value.toStringAsFixed(1)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: Colors.black87.withOpacity(opacity),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width * 0.4);

    final centerLatLng = _getPolygonCenter(sigunGu.latLngCoordinates.expand((e) => e).toList());

    double polyCenterX = (centerLatLng.longitude - mapBounds.minLon) * currentScale + currentOffsetX;
    double polyCenterY = (mapBounds.maxLat - centerLatLng.latitude) * currentScale + currentOffsetY;

    Offset labelPoint;
    Offset lineBreakPoint;
    double distance = 80.0;
    double angle = -pi / 4; // 기본 각도

    // 시/군/구에 대한 특정 위치 조정이 필요할 경우 추가
    // 예: if (sigunGu.name.contains("강남구")) { ... } else { ... }

    labelPoint = Offset(polyCenterX + distance * cos(angle), polyCenterY + distance * sin(angle));
    lineBreakPoint = Offset(polyCenterX + 30, polyCenterY - 30);

    labelPoint = Offset(labelPoint.dx - textPainter.width / 2, labelPoint.dy - textPainter.height / 2);

    final ui.Path linePath = ui.Path();
    linePath.moveTo(polyCenterX, polyCenterY);
    linePath.lineTo(lineBreakPoint.dx, lineBreakPoint.dy);
    if (labelPoint.dx > lineBreakPoint.dx) {
      linePath.lineTo(labelPoint.dx + textPainter.width / 2, lineBreakPoint.dy);
    } else {
      linePath.lineTo(labelPoint.dx + textPainter.width / 2, lineBreakPoint.dy);
    }
    canvas.drawPath(linePath, leaderPaint..color = leaderPaint.color.withOpacity(opacity));
    textPainter.paint(canvas, labelPoint);
  }

  // 폴리곤의 중심 계산
  LatLng _getPolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double latSum = 0;
    double lngSum = 0;
    for (var p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) {
    return oldDelegate.allProvinces != allProvinces ||
        oldDelegate.allSigunGuDataForExpandedProvince != allSigunGuDataForExpandedProvince ||
        oldDelegate.minDataValue != minDataValue ||
        oldDelegate.maxDataValue != maxDataValue ||
        oldDelegate.mapBounds != mapBounds ||
        oldDelegate.tappedProvinceName != tappedProvinceName ||
        oldDelegate.tappedSigunGuCode != tappedSigunGuCode || // 추가
        oldDelegate.isPressing != isPressing ||
        oldDelegate.isShowingSigunGu != isShowingSigunGu ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.getColorForValue != getColorForValue ||
        oldDelegate.sigunGuStatisticalData != sigunGuStatisticalData ||
        oldDelegate.clickedProvinceForZoom != clickedProvinceForZoom;
  }
}

// List.firstWhereOrNull 확장 메서드 (null safety를 위해 필요)
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
