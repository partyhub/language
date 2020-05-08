import 'dart:collection';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lan_tools/page_client.dart';

import 'Toast.dart';
import 'dialogLoading.dart';

const String ZH_CN = "ZH_CN";

typedef OnLanItemClickCallback(int index, Lan lan);

class Lan {
  String key;
  LinkedHashMap<String, String> values;

  int editIndex = 0;

  Lan({this.key, this.values});
}

class MyTable extends DataTableSource {
  List<Lan> lans;
  OnLanItemClickCallback onLanItemClickCallback;

  MyTable(this.lans, this.onLanItemClickCallback);

  int _selectCount = 0; //当前选中的行数
  bool _isRowCountApproximate = false; //行数确定

  @override
  DataRow getRow(int index) {
    //根据索引获取内容行
    if (index >= lans.length || index < 0) throw FlutterError('兄弟，取错数据了吧');
    //如果索引不在商品列表里面，抛出一个异常
    final Lan shop = lans[index];

    List<DataCell> cells = [
      DataCell(Text('${shop.key}'), onTap: () {
        if (onLanItemClickCallback != null) {
          onLanItemClickCallback(index, shop);
        }
      })
    ];

    shop.values.forEach((k, v) {
      cells.add(DataCell(Container(
        child: Text(
          v ?? '',
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
        constraints: BoxConstraints(maxWidth: 200),
      )));
    });

    return DataRow.byIndex(
      cells: cells,
      index: index,
    );
  }

  @override //是否行数不确定
  bool get isRowCountApproximate => _isRowCountApproximate;

  @override //有多少行
  int get rowCount => lans.length;

  @override //选中的行数
  int get selectedRowCount => _selectCount;

  void notifyItem(int editIndex, Lan editLan) {
    lans[editIndex] = editLan;
    notifyListeners();
  }

//  //选中单个
//  void selectOne(int index, bool isSelected) {
//    Shop shop = _shops[index];
//    if (shop.selected != isSelected) {
//      //如果选中就选中数量加一，否则减一
//      _selectCount = _selectCount += isSelected ? 1 : -1;
//      shop.selected = isSelected;
//      //更新
//      notifyListeners();
//    }
//  }

//  //选中全部
//  void selectAll(bool checked) {
//    for (Shop _shop in _shops) {
//      _shop.selected = checked;
//    }
//    _selectCount = checked ? _shops.length : 0;
//    notifyListeners(); //通知监听器去刷新
//  }

//  //排序,
//  void _sort<T>(Comparable<T> getField(Shop shop), bool b) {
//    _shops.sort((Shop s1, Shop s2) {
//      if (!b) {
//        //两个项进行交换
//        final Shop temp = s1;
//        s1 = s2;
//        s2 = temp;
//      }
//      final Comparable<T> s1Value = getField(s1);
//      final Comparable<T> s2Value = getField(s2);
//      return Comparable.compare(s1Value, s2Value);
//    });
//    notifyListeners();
//  }
}

class Lan1Table extends StatefulWidget {
  List<ArchiveFile> files;
  String moduleName;
  OnLanSaveCallback onLanSaveCallback;

  Lan1Table(this.files, this.moduleName, this.onLanSaveCallback);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<Lan1Table> {
  Uint8List uploadFile;
  bool _isLoading = true;
  Map<String, Map> _lanMap = {};

  Lan _editLan;
  int _editIndex;
  DialogLoadingController dialogLoadingController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    dialogLoadingController = DialogLoadingController();
    _initData();
  }

  @override
  void dispose() {
    super.dispose();
    dialogLoadingController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color(0xffe3e3e3),
        child: Column(
          children: <Widget>[
            Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : getPaginatedDataTable()),
            if (_editLan != null)
              Container(
                  alignment: Alignment.centerLeft,
                  padding:
                      EdgeInsets.only(left: 16, right: 16, bottom: 5, top: 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: Text(
                        'Translation',
                        style: TextStyle(fontSize: 18),
                      )),
                      RaisedButton(
                          onPressed: () async {
                            table.notifyItem(_editIndex, _editLan);
                            _save();
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(fontSize: 18),
                          ))
                    ],
                  )),
            if (_editLan != null) _renderEdit()
          ],
        ));
  }

  //默认的行数
  int _defalutRowPageCount = 100;
  int _sortColumnIndex;
  bool _sortAscending = true;
  MyTable table;
  ScrollController _scrollController;

  //排序关联_sortColumnIndex,_sortAscending
  void _sort<T>(Comparable<T> getField(Lan s), int index, bool b) {
//    table._sort(getField, b);
//    setState(() {
//      this._sortColumnIndex = index;
//      this._sortAscending = b;
//    });
  }

  List<DataColumn> getColumn() {
    List<DataColumn> columns = table.lans.first.values.keys.map((key) {
      return DataColumn(
          label: Text(
        key.toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.w600),
      ));
    }).toList();

    columns.insert(
        0,
        DataColumn(
            label: Text(
          "KEY",
          style: TextStyle(fontWeight: FontWeight.w600),
        )));
    return columns;
  }

  Widget getPaginatedDataTable() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: PaginatedDataTable(
        rowsPerPage: _defalutRowPageCount,
        onRowsPerPageChanged: (value) {
          setState(() {
            _defalutRowPageCount = value;
          });
        },
        sortColumnIndex: _sortColumnIndex,
        initialFirstRowIndex: 0,
        sortAscending: _sortAscending,
        availableRowsPerPage: [50, 100],
        onPageChanged: (value) {
          print('$value');
        },
//        onSelectAll: table.selectAll,
        header: Text('Translation List'),
        columns: getColumn(),
        source: table,
      ),
    );
  }

  _startFilePicker() async {
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      // read file content as dataURL
      final files = uploadInput.files;
      if (files.length == 1) {
        final file = files[0];
        html.FileReader reader = html.FileReader();
        html.FileReader reader2 = html.FileReader();
        reader.onLoadEnd.listen((e) {
          setState(() {
            uploadFile = reader.result;
            print("loaded: ${file.name}");
            print("type: ${reader.result.runtimeType}");

//            Uint8List uni = reader.result;
            unzip(reader.result);
            _isLoading = false;
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            Toast.show("Some Error occured while reading the file", context);
          });
        });

        reader.readAsArrayBuffer(file);

        reader2.readAsDataUrl(file);
//        reader.onLoadEnd.listen((e) {
//          setState(() {
//            print("loaded:2 ${file.name}");
//            print("type:2 ${reader2.result.runtimeType}");
//          });
//        });
      }
    });
  }

  void testDownload() {
    final blob = html.Blob([uploadFile]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'some_name.diff';
    html.document.body.children.add(anchor);
    anchor.click();
  }

  void unzip(Uint8List uploadFile) {
    Archive archive = ZipDecoder().decodeBytes(uploadFile);
    for (ArchiveFile archiveFile in archive) {
      if (archiveFile.isFile) {
        print("isFile-->" + archiveFile.name);
      } else {
        print("isDiretory-->" + archiveFile.name);
      }
    }
  }

  void _initData() async {
    for (ArchiveFile archiveFile in widget.files) {
      if (archiveFile.name.contains("string_")) {
        List<String> names = archiveFile.name.split('/');
        String fileName = names.last;
        int i = fileName.indexOf("_");
        int pointI = fileName.lastIndexOf(".");
        String lan = fileName.substring(i + 1, pointI).toUpperCase();
        Map lanMap = json.decode(utf8.decode(archiveFile.content));
        _lanMap[lan] = lanMap;
      }
    }

    List<Lan> lans = [];
    for (String key in _lanMap[ZH_CN].keys) {
      Lan lan = Lan();
      lan.key = key;
      lan.values = LinkedHashMap.from({});
      lan.values[ZH_CN] = _lanMap[ZH_CN][key];
      for (String lanKey in _lanMap.keys) {
        if (lanKey == ZH_CN) continue;
        lan.values[lanKey] = _lanMap[lanKey][key];
      }
      lans.add(lan);
    }
    setState(() {
      _isLoading = false;
      table = MyTable(lans, _onLanItemClickCallback);
    });
  }

  _onLanItemClickCallback(int index, Lan lan) {
    setState(() {
      _editLan = lan;
      _editIndex = index;
    });
  }

  Widget _renderEdit() {
    List<Widget> widgets = [];
    _editLan.values.forEach((k, v) {
      widgets.add(TextField(
        decoration: InputDecoration(
          labelText: k,
        ),
        controller: TextEditingController(text: v),
        onChanged: (s) {
          _editLan.values[k] = s;
        },
      ));
    });

    return Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: widgets,
          ),
        ));
  }

  void _save() async {
    _editLan.values.forEach((k, v) {
      _lanMap[k][_editLan.key] = v;
    });

    int index = 0;
    for (; index < widget.files.length; index++) {
      ArchiveFile archiveFile = widget.files[index];
      for (String lanKey in _lanMap.keys) {
        String name = archiveFile.name.toUpperCase();
        String lanKeyUp = 'string_$lanKey'.toUpperCase();
        int m = name.indexOf(lanKeyUp);
        if (m >= 0) {
          JsonEncoder encoder = new JsonEncoder.withIndent('  ');
          Uint8List uint8list = utf8.encode(encoder.convert(_lanMap[lanKey]));
          widget.files[index] =
              ArchiveFile(archiveFile.name, uint8list.lengthInBytes, uint8list);
        }
      }
    }

    if (widget.onLanSaveCallback != null) {
      widget.onLanSaveCallback(widget.moduleName, widget.files);
    }

    dialogLoadingController.close();

  }
}

class LanServerTable extends StatefulWidget {
  List<ArchiveFile> files;
  OnLanSaveCallback onLanSaveCallback;

  LanServerTable(this.files, this.onLanSaveCallback);

  @override
  State<StatefulWidget> createState() {
    return _LanServerState();
  }
}

class _LanServerState extends State<LanServerTable> {
  Uint8List uploadFile;
  bool _isLoading = true;
  Map<String, Map> _lanMap = {};

  Lan _editLan;
  int _editIndex;
  DialogLoadingController dialogLoadingController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    dialogLoadingController = DialogLoadingController();
    _initData();
  }

  @override
  void dispose() {
    super.dispose();
    dialogLoadingController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color(0xffe3e3e3),
        child: Column(
          children: <Widget>[
            Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : getPaginatedDataTable()),
            if (_editLan != null)
              Container(
                  alignment: Alignment.centerLeft,
                  padding:
                      EdgeInsets.only(left: 16, right: 16, bottom: 5, top: 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: Text(
                        'Translation',
                        style: TextStyle(fontSize: 18),
                      )),
                      RaisedButton(
                          onPressed: () async {
                            dialogLoadingController.show(context: context);
                            table.notifyItem(_editIndex, _editLan);
                            _save();
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(fontSize: 18),
                          ))
                    ],
                  )),
            if (_editLan != null) _renderEdit()
          ],
        ));
  }

  //默认的行数
  int _defalutRowPageCount = 100;
  int _sortColumnIndex;
  bool _sortAscending = true;
  MyTable table;
  ScrollController _scrollController;

  //排序关联_sortColumnIndex,_sortAscending
  void _sort<T>(Comparable<T> getField(Lan s), int index, bool b) {
//    table._sort(getField, b);
//    setState(() {
//      this._sortColumnIndex = index;
//      this._sortAscending = b;
//    });
  }

  List<DataColumn> getColumn() {
    List<DataColumn> columns = table.lans.first.values.keys.map((key) {
      return DataColumn(
          label: Text(
        key.toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.w600),
      ));
    }).toList();

    columns.insert(
        0,
        DataColumn(
            label: Text(
          "KEY",
          style: TextStyle(fontWeight: FontWeight.w600),
        )));
    return columns;
  }

  Widget getPaginatedDataTable() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: PaginatedDataTable(
        rowsPerPage: _defalutRowPageCount,
        onRowsPerPageChanged: (value) {
          setState(() {
            _defalutRowPageCount = value;
          });
        },
        sortColumnIndex: _sortColumnIndex,
        initialFirstRowIndex: 0,
        sortAscending: _sortAscending,
        availableRowsPerPage: [50, 100],
        onPageChanged: (value) {
          print('$value');
        },
//        onSelectAll: table.selectAll,
        header: Text('Translation List'),
        columns: getColumn(),
        source: table,
      ),
    );
  }

  _startFilePicker() async {
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      // read file content as dataURL
      final files = uploadInput.files;
      if (files.length == 1) {
        final file = files[0];
        html.FileReader reader = html.FileReader();
        html.FileReader reader2 = html.FileReader();
        reader.onLoadEnd.listen((e) {
          setState(() {
            uploadFile = reader.result;
            print("loaded: ${file.name}");
            print("type: ${reader.result.runtimeType}");

//            Uint8List uni = reader.result;
            unzip(reader.result);
            _isLoading = false;
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            Toast.show("Some Error occured while reading the file", context);
          });
        });

        reader.readAsArrayBuffer(file);

        reader2.readAsDataUrl(file);
//        reader.onLoadEnd.listen((e) {
//          setState(() {
//            print("loaded:2 ${file.name}");
//            print("type:2 ${reader2.result.runtimeType}");
//          });
//        });
      }
    });
  }

  void unzip(Uint8List uploadFile) {
    Archive archive = ZipDecoder().decodeBytes(uploadFile);
    for (ArchiveFile archiveFile in archive) {
      if (archiveFile.isFile) {
        print("isFile-->" + archiveFile.name);
      } else {
        print("isDiretory-->" + archiveFile.name);
      }
    }
  }

  void _initData() async {
    print("_isLoading");

    for (ArchiveFile archiveFile in widget.files) {
      print("_isLoading-name=="+archiveFile.name);
      List<String> names = archiveFile.name.split('.');
      String lan = names.first.toUpperCase();
      print("_isLoading-lan=="+lan);
      Map lanMap = json.decode(utf8.decode(archiveFile.content));
      print("_isLoading-lanSize=="+lanMap.length.toString());
      _lanMap[lan] = lanMap;
    }

    List<Lan> lans = [];
    for (String key in _lanMap[ZH_CN].keys) {
      Lan lan = Lan();
      lan.key = key;
      lan.values = LinkedHashMap.from({});
      lan.values[ZH_CN] = _lanMap[ZH_CN][key];
      for (String lanKey in _lanMap.keys) {
        if (lanKey == ZH_CN) continue;
        lan.values[lanKey] = _lanMap[lanKey][key];
      }
      lans.add(lan);
    }
    print("_isLoading");
    setState(() {
      _isLoading = false;
      table = MyTable(lans, _onLanItemClickCallback);
    });
  }

  _onLanItemClickCallback(int index, Lan lan) {
    setState(() {
      _editLan = lan;
      _editIndex = index;
    });
  }

  Widget _renderEdit() {
    List<Widget> widgets = [];
    _editLan.values.forEach((k, v) {
      widgets.add(TextField(
        decoration: InputDecoration(
          labelText: k,
        ),
        controller: TextEditingController(text: v),
        onChanged: (s) {
          _editLan.values[k] = s;
        },
      ));
    });

    return Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: widgets,
          ),
        ));
  }

  void _save() async {
    _editLan.values.forEach((k, v) {
      _lanMap[k][_editLan.key] = v;
    });

    int index = 0;
    for (; index < widget.files.length; index++) {
      ArchiveFile archiveFile = widget.files[index];
      for (String lanKey in _lanMap.keys) {
        String name = archiveFile.name.toUpperCase();
        String lanKeyUp = '$lanKey'.toUpperCase();
        int m = name.indexOf(lanKeyUp);
        if (m >= 0) {
          JsonEncoder encoder = new JsonEncoder.withIndent('  ');
          Uint8List uint8list = utf8.encode(encoder.convert(_lanMap[lanKey]));
          widget.files[index] =
              ArchiveFile(archiveFile.name, uint8list.lengthInBytes, uint8list);
        }
      }
    }
    if (widget.onLanSaveCallback != null) {
      widget.onLanSaveCallback('', widget.files);
    }

    Future.delayed(Duration(seconds: 1)).then((dynamic val) {
      dialogLoadingController.close();
    });

  }
}
