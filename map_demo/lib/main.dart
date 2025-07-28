import 'package:flutter/material.dart';
import 'package:map_demo/bar_chart/bar_chart_screen.dart';
import 'package:map_demo/cloud_chart/cloud_chart_screen.dart';
import 'package:map_demo/list/list_screen.dart';
import 'package:map_demo/pie_chart/pie_chart2_screen.dart';
import 'package:map_demo/pie_chart/pie_chart_screen.dart';
import 'package:map_demo/shp_map_chart_screen.dart';
import 'package:map_demo/web_view/web_view_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Korea Custom Map Chart',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KoreaCustomMapScreen(),
                    ),
                  );
                },
                child: Text('SHP 지도 차트'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PieChartScreen(),
                    ),
                  );
                },
                child: Text('PIE 차트'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PieChart2Screen(),
                    ),
                  );
                },
                child: Text('PIE 차트2'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarChartScreen(),
                    ),
                  );
                },
                child: Text('BAR 차트'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CloudChartScreen(),
                    ),
                  );
                },
                child: Text('클라우드 차트'),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 30),
                height: 1,
                width: MediaQuery.of(context).size.width,
                color: Colors.grey,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListScreen(),
                    ),
                  );
                },
                child: Text('리스트 화면에서 보기'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebViewScreen(),
                    ),
                  );
                },
                child: Text('카차트 웹뷰'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
