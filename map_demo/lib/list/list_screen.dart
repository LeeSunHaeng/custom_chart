import 'package:flutter/material.dart';
import 'package:map_demo/bar_chart/bar_chart_screen.dart';
import 'package:map_demo/cloud_chart/cloud_chart_screen.dart';
import 'package:map_demo/pie_chart/pie_chart2_screen.dart';
import 'package:map_demo/pie_chart/pie_chart_screen.dart';
import 'package:map_demo/shp_map_chart_screen.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('목록 화면'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: KoreaCustomMapScreen(
              useAppBar: false,
            ),
          ),
          spacer(context),
          SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: PieChartScreen(
              useAppBar: false,
            ),
          ),
          spacer(context),
          SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: PieChart2Screen(
              useAppBar: false,
            ),
          ),
          spacer(context),
          SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: BarChartScreen(
              useAppBar: false,
            ),
          ),
          spacer(context),
          SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: CloudChartScreen(
              useAppBar: false,
            ),
          ),
          // CloudChartScreen(title: '클라우드 차트'),
        ],
      ),
    );
  }

  Widget spacer(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 1,
      color: Colors.grey,
    );
  }
}
