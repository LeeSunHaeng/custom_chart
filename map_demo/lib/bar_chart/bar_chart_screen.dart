import 'dart:async';
import 'dart:math';

// import 'package:fl_chart_app/presentation/resources/app_resources.dart';
// import 'package:fl_chart_app/util/extensions/color_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartScreen extends StatefulWidget {
  final bool useAppBar;
  BarChartScreen({super.key, this.useAppBar = true});

  List<Color> get availableColors => const <Color>[
        Colors.purpleAccent,
        Colors.yellow,
        Colors.blue,
        Colors.orange,
        Colors.pink,
        Colors.red,
      ];

  final Color barBackgroundColor = Color(0xFFEBEDF1);
  final Color barColor = Color(0xFF0FC3B9).withOpacity(0.3);
  final Color touchedBarColor = Color(0xFF0FC3B9);
  bool isTimeLine = true;

  @override
  State<StatefulWidget> createState() => BarChartScreenState();
}

class BarChartScreenState extends State<BarChartScreen> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useAppBar
          ? AppBar(
              title: Text('바 차트'),
              centerTitle: false,
            )
          : null,
      body: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              typeButton(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BarChart(
                    isPlaying ? randomData() : mainBarData(),
                    duration: animDuration,
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color? barColor,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    barColor ??= widget.barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? widget.touchedBarColor : barColor,
          width: width,
          borderSide: isTouched ? BorderSide(color: widget.touchedBarColor) : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: widget.barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<double> valueList() {
    return [
      widget.isTimeLine ? 5 : 7,
      widget.isTimeLine ? 6.5 : 3.5,
      widget.isTimeLine ? 5 : 8,
      widget.isTimeLine ? 7.5 : 10,
      widget.isTimeLine ? 9 : 2,
      widget.isTimeLine ? 11.5 : 5,
      widget.isTimeLine ? 6.5 : 13,
    ];
  }

  List<BarChartGroupData> showingGroups() => List.generate(7, (i) {
        switch (i) {
          case 0:
            return makeGroupData(0, widget.isTimeLine ? 5 : 7, isTouched: i == touchedIndex);
          case 1:
            return makeGroupData(1, widget.isTimeLine ? 6.5 : 3.5, isTouched: i == touchedIndex);
          case 2:
            return makeGroupData(2, widget.isTimeLine ? 5 : 8, isTouched: i == touchedIndex);
          case 3:
            return makeGroupData(3, widget.isTimeLine ? 7.5 : 10, isTouched: i == touchedIndex);
          case 4:
            return makeGroupData(4, widget.isTimeLine ? 9 : 2, isTouched: i == touchedIndex);
          case 5:
            return makeGroupData(5, widget.isTimeLine ? 11.5 : 5, isTouched: i == touchedIndex);
          case 6:
            return makeGroupData(6, widget.isTimeLine ? 6.5 : 13, isTouched: i == touchedIndex);
          default:
            return throw Error();
        }
      });

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => widget.barColor,
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          // tooltipMargin: -10,
          // tooltipHorizontalOffset: -20,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String weekDay;
            switch (group.x) {
              case 0:
                weekDay = widget.isTimeLine ? '00~04' : '월요일';
                break;
              case 1:
                weekDay = widget.isTimeLine ? '04~08' : '화요일';
                break;
              case 2:
                weekDay = widget.isTimeLine ? '08~12' : '수요일';
                break;
              case 3:
                weekDay = widget.isTimeLine ? '12~16' : '목요일';
                break;
              case 4:
                weekDay = widget.isTimeLine ? '16~20' : '금요일';
                break;
              case 5:
                weekDay = widget.isTimeLine ? '20~24' : '토요일';
                break;
              case 6:
                weekDay = widget.isTimeLine ? '기타' : '일요일';
                break;
              default:
                throw Error();
            }
            return BarTooltipItem(
              '$weekDay\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY - 1).toString(),
                  style: const TextStyle(
                    color: Colors.white, //widget.touchedBarColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitlesTop,
            reservedSize: 38,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
      gridData: FlGridData(
        show: false,
        // horizontalInterval: 1,
        // verticalInterval: 1,
      ),
    );
  }

  Widget getTitlesTop(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w400,
      fontSize: 11,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      case 1:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      case 2:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      case 3:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      case 4:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      case 5:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      case 6:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
      default:
        text = Text('${valueList()[value.toInt()]}', style: style);
        break;
    }
    return SideTitleWidget(
      space: 16,
      axisSide: AxisSide.top,
      child: text,
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w400,
      fontSize: 11,
    );
    Widget text;
    if (widget.isTimeLine) {
      switch (value.toInt()) {
        case 0:
          text = const Text('00~04', style: style);
          break;
        case 1:
          text = const Text('04~08', style: style);
          break;
        case 2:
          text = const Text('08~12', style: style);
          break;
        case 3:
          text = const Text('12~16', style: style);
          break;
        case 4:
          text = const Text('16~20', style: style);
          break;
        case 5:
          text = const Text('20~24', style: style);
          break;
        case 6:
          text = const Text('기타', style: style);
          break;
        default:
          text = const Text('', style: style);
          break;
      }
    } else {
      switch (value.toInt()) {
        case 0:
          text = const Text('월', style: style);
          break;
        case 1:
          text = const Text('화', style: style);
          break;
        case 2:
          text = const Text('수', style: style);
          break;
        case 3:
          text = const Text('목', style: style);
          break;
        case 4:
          text = const Text('금', style: style);
          break;
        case 5:
          text = const Text('토', style: style);
          break;
        case 6:
          text = const Text('일', style: style);
          break;
        default:
          text = const Text('', style: style);
          break;
      }
    }

    return SideTitleWidget(
      space: 16,
      axisSide: AxisSide.top,
      child: text,
    );
  }

  BarChartData randomData() {
    return BarChartData(
      barTouchData: BarTouchData(
        enabled: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: List.generate(7, (i) {
        switch (i) {
          case 0:
            return makeGroupData(
              0,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          case 1:
            return makeGroupData(
              1,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          case 2:
            return makeGroupData(
              2,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          case 3:
            return makeGroupData(
              3,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          case 4:
            return makeGroupData(
              4,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          case 5:
            return makeGroupData(
              5,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          case 6:
            return makeGroupData(
              6,
              Random().nextInt(15).toDouble() + 6,
              barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)],
            );
          default:
            return throw Error();
        }
      }),
      gridData: const FlGridData(show: false),
    );
  }

  Future<dynamic> refreshState() async {
    setState(() {});
    await Future<dynamic>.delayed(
      animDuration + const Duration(milliseconds: 50),
    );
    if (isPlaying) {
      await refreshState();
    }
  }

  Widget typeButton() {
    Color timeColor = widget.isTimeLine ? Color(0xFF87E1DC) : Color(0xFFEBEDF1);
    Color weekColor = !widget.isTimeLine ? Color(0xFF87E1DC) : Color(0xFFEBEDF1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              widget.isTimeLine = true;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: timeColor.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Text(
              '시간',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: timeColor,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              widget.isTimeLine = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: weekColor.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Text(
              '요일',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: weekColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
