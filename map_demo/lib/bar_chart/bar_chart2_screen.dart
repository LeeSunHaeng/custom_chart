import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart'; // 숫자 포맷팅을 위해 intl 패키지 추가 (pubspec.yaml)

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData({required this.label, required this.value, required this.color});
}

// lib/bar_chart_row.dart

class BarChartRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue; // 전체 값들 중 최대값 (비율 계산용)
  final Color color;

  const BarChartRow({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 숫자 포맷터 (예: 10000 -> 10,000)
    final numberFormatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 1. 라벨 (예: "20대")
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),

          // 2. 막대그래프
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 막대그래프의 최대 너비를 가져옴
                final double barMaxWidth = constraints.maxWidth;
                // 현재 값에 따른 막대 너비 계산
                final double barWidth = (value / maxValue) * barMaxWidth;

                return Stack(
                  children: [
                    // 배경 막대
                    Container(
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                      ),
                    ),
                    // 값 막대
                    Container(
                      height: 25,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // 3. 값 텍스트 (예: "10,000")
          SizedBox(
            width: 80,
            child: Text(
              numberFormatter.format(value),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarChart2Screen extends StatefulWidget {
  const BarChart2Screen({super.key});

  @override
  State<BarChart2Screen> createState() => _BarChart2ScreenState();
}

class _BarChart2ScreenState extends State<BarChart2Screen> {
  final List<ChartData> chartDataList = [
    ChartData(label: '20대', value: 3500, color: Colors.amber),
    ChartData(label: '30대', value: 6800, color: Colors.blue),
    ChartData(label: '40대', value: 12000, color: Colors.teal),
    ChartData(label: '50대', value: 7500, color: Colors.indigo.shade400),
    ChartData(label: '60대 ~', value: 2800, color: Colors.grey.shade600),
  ];

  int get maxValue {
    // 데이터 중 가장 큰 값을 찾아 반환
    return chartDataList.map((data) => data.value).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연령대별 차트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '단위: 개수',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 20),
              // 데이터를 기반으로 차트 행들을 동적으로 생성
              ...chartDataList.map((data) => BarChartRow(
                    label: data.label,
                    value: data.value,
                    maxValue: maxValue,
                    color: data.color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
