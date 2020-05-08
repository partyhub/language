import 'package:flutter/material.dart';
import 'package:lan_tools/page_client.dart';
import 'package:lan_tools/page_server.dart';

import 'table.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _selectPlatform = 0;
  TextStyle _selectStyle,_unselectStyle;
  PageController _pageController;
  GlobalKey<PageClientState> _globalKey = GlobalKey();
  GlobalKey<PageServerState> _serverlKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectStyle = TextStyle(color: Colors.white,fontSize: 18);
    _unselectStyle = TextStyle(color: Colors.white.withOpacity(0.6),fontSize: 16);

    _pageController =
        PageController(initialPage: 0);
    _pageController.addListener(() {

    });
  }

  void _incrementCounter() {
    Navigator.of(context).push(MaterialPageRoute(builder:(context)=>LanTable()));
  }

  void zip() async{

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: <Widget>[
            FlatButton.icon(
              icon: Icon(Icons.phone_iphone,color: Colors.white.withOpacity(_selectPlatform==0?1:0.6),size: _selectPlatform==0?24:22,),
              label: Text('Client',style: _selectPlatform==0?_selectStyle:_unselectStyle,),
              onPressed: (){
                _pageController.jumpToPage(0);
                setState(() {
                  _selectPlatform=0;
                });
              },
            ),
            SizedBox(width: 20,),
            FlatButton.icon(
              icon: Icon(Icons.web,color: Colors.white.withOpacity(_selectPlatform==1?1:0.6),size: _selectPlatform==1?24:22),
              label: Text('Server',style: _selectPlatform==1?_selectStyle:_unselectStyle,),
              onPressed: (){
                _pageController.jumpToPage(1);
                setState(() {
                  _selectPlatform=1;
                });
              },
            ),
          ],
        ),
        actions: <Widget>[
          FlatButton.icon(onPressed: (){
            if(_selectPlatform == 0) _globalKey.currentState.save();
            else _serverlKey.currentState.save();
          },
              icon: Icon(Icons.file_download,size: 24,color: Colors.white,),
              label: Text("Export",style: _selectStyle,))
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: new NeverScrollableScrollPhysics(),
        children: <Widget>[
          PageClient(
            key: _globalKey,
          ),
          PageServer(key: _serverlKey)
        ],
      )
    );
  }
}
