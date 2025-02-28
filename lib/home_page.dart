import 'package:d9l_weather/dio_client.dart';
import 'package:d9l_weather/model.dart';
import 'package:d9l_weather/search_page.dart';
import 'package:d9l_weather/sp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'about_page.dart';

class HomePage extends StatefulWidget {
  HomePage({this.realTimeWeather, this.dailyForecastList});

  final RealTimeWeather realTimeWeather;
  final List<DailyForecast> dailyForecastList;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String cid;
  RealTimeWeather realTimeWeather;
  List<DailyForecast> dailyForecastList = [];

  bool isNoNetwork = false;
  RealTimeWeather _noNetworkWeather = RealTimeWeather(
    basic: Basic(location: '未知'),
    now: Now(tmp: 'N/A', condTxt: '', windDir: '--', hum: '--', pres: '--'),
  );
  List<DailyForecast> _noNetworkForecastList = [
    DailyForecast(condTxtD: '???', condCodeD: '999', tmpMin: '--', tmpMax: '--', date: '2019-05-27 13:23:10'),
    DailyForecast(condTxtD: '???', condCodeD: '999', tmpMin: '--', tmpMax: '--', date: '2019-05-28 13:23:10'),
    DailyForecast(condTxtD: '???', condCodeD: '999', tmpMin: '--', tmpMax: '--', date: '2019-05-29 13:23:10'),
  ];

  @override
  void initState() {
    super.initState();
    if (SpClient.sp.getString('cid') != null) {
      cid = SpClient.sp.getString('cid');
    }
    if (widget.realTimeWeather != null) {
      realTimeWeather = widget.realTimeWeather;
    } else {
      isNoNetwork = true;
      realTimeWeather = _noNetworkWeather;
    }
    if (widget.dailyForecastList != null) {
      dailyForecastList = widget.dailyForecastList;
    } else {
      isNoNetwork = true;
      dailyForecastList = _noNetworkForecastList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Colors.blue, Colors.blue.withOpacity(0.4)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 100.0),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    realTimeWeather.basic.location,
                    style: TextStyle(fontSize: 40.0, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${realTimeWeather.now.tmp}°',
                        style: TextStyle(fontSize: 80.0, color: Colors.white),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          realTimeWeather.now.condCode == null
                              ? Container()
                              : Image.asset('assets/images/weather/${realTimeWeather.now.condCode}.png', color: Colors.white),
                          SizedBox(height: 10.0),
                          Text(
                            '${realTimeWeather.now.condTxt}',
                            style: TextStyle(fontSize: 20.0, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isNoNetwork
                      ? Align(
                          alignment: Alignment.center,
                          child: Text('请检查你的网络状态', style: TextStyle(color: Colors.white, fontSize: 20.0)),
                        )
                      : Container(),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _someMessage(
                        icon: 'assets/images/wind_direction.png',
                        title: '风向',
                        data: realTimeWeather.now.windDir,
                      ),
                      _someMessage(
                        icon: 'assets/images/humidity.png',
                        title: '湿度',
                        data: realTimeWeather.now.hum + '%',
                      ),
                      _someMessage(
                        icon: 'assets/images/air_pressure.png',
                        title: '气压',
                        data: realTimeWeather.now.pres + 'hpa',
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: dailyForecastList.map((item) {
                      return _threeDayWeather(item);
                    }).toList(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 6.0),
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Text('d9lweather', style: TextStyle(color: Color(0xffe2e2e2))),
                ),
              ],
            ),
          ),
          RefreshIndicator(
            onRefresh: _pullDownRefresh,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Center(child: SizedBox(height: 500.0)),
            ),
          ),
          Positioned(
            top: 27.0,
            right: 0.0,
            child: IconButton(
              icon: Image.asset('assets/images/setting.png'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          title: Text('切换城市'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, CupertinoPageRoute(builder: (_) => SearchPage())).then((result) {
                              if (result != null) {
                                cid = result;
                                isNoNetwork = false;
                                _updateWeather();
                              }
                            });
                          },
                        ),
                        Divider(height: 0.0),
                        ListTile(
                          title: Text('选择语言'),
                          onTap: () {
                            Navigator.pop(context);
                            Fluttertoast.showToast(msg: '暂时不能选择语言');
                          },
                        ),
                        Divider(height: 0.0),
                        ListTile(
                          title: Text('关于'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, CupertinoPageRoute(builder: (_) => AboutPage()));
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _threeDayWeather(DailyForecast dailyForecast) {
    String date = DateFormat('EE', 'zh_CN').format(
      DateTime.parse(dailyForecast.date),
    );
    return Column(
      children: <Widget>[
        Text(date, style: TextStyle(color: Color(0xff8a8a8a))),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Image.asset('assets/images/weather/${dailyForecast.condCodeD}.png', color: Colors.blue),
        ),
        Text(dailyForecast.condTxtD, style: TextStyle(color: Color(0xff8a8a8a))),
        Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(dailyForecast.tmpMin + '℃~' + dailyForecast.tmpMax + '℃', style: TextStyle(color: Color(0xff8a8a8a))),
        ),
      ],
    );
  }

  Widget _someMessage({String icon, String title, String data}) {
    return Row(
      children: <Widget>[
        Image.asset(icon, width: 30.0, fit: BoxFit.fill),
        Column(
          children: <Widget>[
            Text(title, style: TextStyle(color: Colors.white)),
            Text(data, style: TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }

  // refresh
  Future<void> _pullDownRefresh() async {
    bool result = await _updateWeather();
    if (result) {
      isNoNetwork = false;
      Fluttertoast.showToast(msg: '更新成功！');
    } else {
      Fluttertoast.showToast(msg: '更新失败！');
    }
  }

  Future<bool> _updateWeather() async {
    bool flag = true;
    await DioClient().getRealTimeWeather(cid).then((v) {
      if (v != null && this.mounted) {
        if (v.status.contains('permission')) {
          Fluttertoast.showToast(msg: '没有权限');
          cid = SpClient.sp.getString('cid');
          return;
        }
        SpClient.sp.setString('cid', cid);
        setState(() {
          realTimeWeather = v;
        });
      } else {
        flag = false;
      }
    });

    await DioClient().getThreeDaysForecast(cid).then((v) {
      if (v != null && this.mounted) {
        setState(() {
          dailyForecastList = v.dailyForecasts;
        });
      } else {
        flag = false;
      }
    });
    return flag;
  }
}
