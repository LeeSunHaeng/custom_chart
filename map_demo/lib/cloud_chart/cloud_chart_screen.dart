import 'package:flutter/material.dart';
import 'package:word_cloud/word_cloud.dart';
import 'package:word_cloud/word_cloud_data.dart';

class CloudChartScreen extends StatefulWidget {
  final bool useAppBar;
  const CloudChartScreen({super.key, this.useAppBar = true});

  @override
  State<CloudChartScreen> createState() => _CloudChartScreenState();
}

class _CloudChartScreenState extends State<CloudChartScreen> {
  //example data list
  List<Map> word_list = [
    {'word': 'Apple', 'value': 100},
    {'word': 'Samsung', 'value': 60},
    {'word': 'Intel', 'value': 55},
    {'word': 'Tesla', 'value': 50},
    {'word': 'AMD', 'value': 40},
    {'word': 'Google', 'value': 35},
    {'word': 'Qualcom', 'value': 31},
    {'word': 'Netflix', 'value': 27},
    {'word': 'Meta', 'value': 27},
    {'word': 'Amazon', 'value': 26},
    {'word': 'Nvidia', 'value': 25},
    {'word': 'Microsoft', 'value': 25},
    {'word': 'TSMC', 'value': 24},
    {'word': 'PayPal', 'value': 24},
    {'word': 'AT&T', 'value': 24},
    {'word': 'Oracle', 'value': 23},
    {'word': 'Unity', 'value': 23},
    {'word': 'Roblox', 'value': 23},
    {'word': 'Lucid', 'value': 22},
    {'word': 'Naver', 'value': 20},
    {'word': 'Kakao', 'value': 18},
    {'word': 'NC Soft', 'value': 18},
    {'word': 'LG', 'value': 16},
    {'word': 'Hyundai', 'value': 16},
    {'word': 'KIA', 'value': 16},
    {'word': 'twitter', 'value': 16},
    {'word': 'Tencent', 'value': 15},
    {'word': 'Alibaba', 'value': 15},
    {'word': 'LG', 'value': 16},
    {'word': 'Hyundai', 'value': 16},
    {'word': 'KIA', 'value': 16},
    {'word': 'twitter', 'value': 16},
    {'word': 'Tencent', 'value': 15},
    {'word': 'Alibaba', 'value': 15},
    {'word': 'Disney', 'value': 14},
    {'word': 'Spotify', 'value': 14},
    {'word': 'Udemy', 'value': 13},
    {'word': 'Quizlet', 'value': 13},
    {'word': 'Visa', 'value': 12},
    {'word': 'Lucid', 'value': 22},
    {'word': 'Naver', 'value': 20},
    {'word': 'Hyundai', 'value': 16},
    {'word': 'KIA', 'value': 16},
    {'word': 'twitter', 'value': 16},
    {'word': 'Tencent', 'value': 15},
    {'word': 'Alibaba', 'value': 15},
    {'word': 'Disney', 'value': 14},
    {'word': 'Spotify', 'value': 14},
    {'word': 'Visa', 'value': 12},
    {'word': 'Microsoft', 'value': 10},
    {'word': 'TSMC', 'value': 10},
    {'word': 'PayPal', 'value': 24},
    {'word': 'AT&T', 'value': 10},
    {'word': 'Oracle', 'value': 10},
    {'word': 'Unity', 'value': 10},
    {'word': 'Roblox', 'value': 10},
    {'word': 'Lucid', 'value': 10},
    {'word': 'Naver', 'value': 10},
    {'word': 'Kakao', 'value': 18},
    {'word': 'NC Soft', 'value': 18},
    {'word': 'LG', 'value': 16},
    {'word': 'Hyundai', 'value': 16},
    {'word': 'KIA', 'value': 16},
    {'word': 'twitter', 'value': 16},
    {'word': 'Tencent', 'value': 10},
    {'word': 'Alibaba', 'value': 10},
    {'word': 'Disney', 'value': 14},
    {'word': 'Spotify', 'value': 14},
    {'word': 'Udemy', 'value': 13},
    {'word': 'NC Soft', 'value': 12},
    {'word': 'LG', 'value': 16},
    {'word': 'Hyundai', 'value': 10},
    {'word': 'KIA', 'value': 16},
  ];
  int count = 0;
  String wordstring = '';

  @override
  Widget build(BuildContext context) {
    WordCloudData wcdata = WordCloudData(data: word_list);
    WordCloudTap wordtaps = WordCloudTap();

    //WordCloudTap Setting
    for (int i = 0; i < word_list.length; i++) {
      void tap() {
        setState(() {
          count += 1;
          wordstring = word_list[i]['word'];
        });
      }

      wordtaps.addWordtap(word_list[i]['word'], tap);
    }

    return Scaffold(
      appBar: widget.useAppBar
          ? AppBar(
              title: Text('클라우드 차트'),
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: WordCloudView(
            data: wcdata,
            mapcolor: Colors.transparent,
            mapwidth: MediaQuery.of(context).size.width - 40,
            mapheight: MediaQuery.of(context).size.width - 40,
            fontWeight: FontWeight.bold,
            colorlist: [Colors.black, Colors.redAccent, Colors.indigoAccent],
            maxtextsize: 30,
            mintextsize: 10,
          ),
        ),
      ),
    );
  }
}
