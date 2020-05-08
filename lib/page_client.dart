import 'dart:collection';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:html' as html;

import 'Toast.dart';
import 'table_1.dart';

typedef OnLanSaveCallback(String key,List<ArchiveFile> files);

class PageClient extends StatefulWidget{

  PageClient({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PageClientState();
  }

}

class PageClientState extends State<PageClient> with SingleTickerProviderStateMixin{

  bool _imported = false;

  bool _isLoading = true;

  TabController _tabController;

  PageController _pageController;

  LinkedHashMap<String,List<ArchiveFile>> _data;

  Archive archive;

  @override
  void initState() {
    super.initState();
    _data = LinkedHashMap.of({});
  }

  @override
  void dispose() {
    super.dispose();
    if(_tabController != null) _tabController.dispose();
    if(_pageController != null) _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(!_imported){
      return _buildImport();
    }
    return _isLoading?Center(child: CircularProgressIndicator()): _buildBody();
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        _buildTab(),
        Expanded(
          child: PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: _data.keys.map((key){
              List<ArchiveFile> files = _data[key];
              return Lan1Table(files,key,_onLanSaveCallback);
            }).toList()
          ),
        )
      ],
    );
  }

  Widget _buildImport() {
    return Center(
      child: FlatButton.icon(
        icon: Icon(Icons.cloud_upload,size: 48,),
        label: Text('导入zip文件',style: TextStyle(fontSize: 20),),
        onPressed: (){
          setState(() {
            _startFilePicker();
          });
        }
      ),
    );
  }

  _startFilePicker() async {
    _isLoading = true;
    _imported = true;
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files.length == 1) {
        final file = files[0];
        html.FileReader reader =  html.FileReader();
        reader.onLoadEnd.listen((e) {
          setState(() {
            print("loaded: ${file.name}");
            print("type: ${reader.result.runtimeType}");
            unzip(reader.result);
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            Toast.show("Some Error occured while reading the file", context);
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  void unzip(Uint8List uploadFile) {
    archive = ZipDecoder().decodeBytes(uploadFile);
    for (ArchiveFile archiveFile in archive) {
      String name = archiveFile.name;
      List<String> splitNames = name.split('/');
      if(splitNames == null || splitNames.isEmpty) continue;
      if(splitNames[0] == '__MACOSX') continue;
      splitNames.removeWhere((item)=>(item==null||item.isEmpty));
      if(splitNames.length < 2) continue;

      if (archiveFile.isFile) {
        String dirName = splitNames[splitNames.length-2].toUpperCase();
        if(_data[dirName] == null){
          _data[dirName] = [];
        }
        _data[dirName].add(archiveFile);
      }
    }
    this._tabController = TabController(length: this._data.keys.length, vsync: this);
    this._tabController.addListener((){
      _pageController.jumpToPage(_tabController.index);
    });
    this._pageController = PageController();
    _isLoading = false;
  }

  Widget _buildTab() {
    return Container(
      padding: EdgeInsetsDirectional.only(start: 10,end: 10,top: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.6)
          )
        )
      ),
      child: TabBar(
      isScrollable: true,
      controller: _tabController,
      labelColor: Colors.blue,
      unselectedLabelColor: Color(0xff888888),
      labelStyle: TextStyle(fontSize: 16.0),
      tabs: _data.keys.map((item) {
        return Tab(
          text: item,
        );
      }).toList(),
    ));
  }


  _onLanSaveCallback(String key, List<ArchiveFile> files) {
    _data[key] = files;
    print("_onLanSaveCallback- key-> $key");
    print("_onLanSaveCallback- files-> ${files.toString()}");
    for(int i=0;i<archive.length;i++){
      ArchiveFile archiveFile = archive[i];
      for(ArchiveFile af in files){
        if(af.name == archiveFile.name){
          archive.files[i] = af;
        }
      }
    }
  }

  void save(){
    List<int> encodeZip = ZipEncoder().encode(archive);
    final blob = html.Blob([encodeZip]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    DateTime now = DateTime.now();
    String nowTime = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";

    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'trans_client_$nowTime.zip';
    html.document.body.children.add(anchor);
    anchor.click();
  }
}