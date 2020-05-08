import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Toast.dart';

class Shop {
  String name;
  int number;
  String type;
  double price;
  bool selected = false; //默认为未选中
  int editIndex = 0;

  Shop(
    this.name,
    this.number,
    this.type,
    this.price,
  );
}

class MyTable extends DataTableSource {
  List<Shop> _shops = <Shop>[
    Shop(
        '小米6x', 100, '手机dcdfdscassasdssadvdsfdsgfsdgadsgdsgasdgdasgsd', 1699.0),
    Shop('华为P20', 50, '手机', 4999.0),
    Shop('华硕a61', 50, '电脑', 5700.0),
    Shop('iphone7plus耳机cdcdscsacascsacSXZCXC', 9999, '耳机', 60.0),
    Shop('iphone7plus256g', 1, '手机', 4760.0),
    Shop('金士顿8g内存条', 66, '内存条', 399.0),
    Shop('西门子洗衣机9.0kg', 890, '家电', 10399.0),
    Shop('三星66寸液晶智能电视', 800, '家电', 20389.0),
  ];

  int _selectCount = 0; //当前选中的行数
  bool _isRowCountApproximate = false; //行数确定

  @override
  DataRow getRow(int index) {
    //根据索引获取内容行
    if (index >= _shops.length || index < 0) throw FlutterError('兄弟，取错数据了吧');
    //如果索引不在商品列表里面，抛出一个异常
    final Shop shop = _shops[index];
    return DataRow.byIndex(
      cells: <DataCell>[
        DataCell(
            shop.editIndex <= 0
                ? Text('${shop.name}')
                : TextField(
                    onChanged: (content){
                      shop.name = content;
                    },
                    decoration: InputDecoration(
                        hintText: shop.name,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () {
                            shop.editIndex = 0;
                            notifyListeners();
                          },
                        )),
                  ), onTap: () {
          shop.editIndex = 1;
          notifyListeners();
        }),
        DataCell(Text('${shop.price}'), showEditIcon: true),
        DataCell(Text('${shop.number}')),
        DataCell(Text('${shop.type}')),
      ],
      selected: shop.selected,
      index: index,
    );
  }

  @override //是否行数不确定
  bool get isRowCountApproximate => _isRowCountApproximate;

  @override //有多少行
  int get rowCount => _shops.length;

  @override //选中的行数
  int get selectedRowCount => _selectCount;

  //选中单个
  void selectOne(int index, bool isSelected) {
    Shop shop = _shops[index];
    if (shop.selected != isSelected) {
      //如果选中就选中数量加一，否则减一
      _selectCount = _selectCount += isSelected ? 1 : -1;
      shop.selected = isSelected;
      //更新
      notifyListeners();
    }
  }

  //选中全部
  void selectAll(bool checked) {
    for (Shop _shop in _shops) {
      _shop.selected = checked;
    }
    _selectCount = checked ? _shops.length : 0;
    notifyListeners(); //通知监听器去刷新
  }

  //排序,
  void _sort<T>(Comparable<T> getField(Shop shop), bool b) {
    _shops.sort((Shop s1, Shop s2) {
      if (!b) {
        //两个项进行交换
        final Shop temp = s1;
        s1 = s2;
        s2 = temp;
      }
      final Comparable<T> s1Value = getField(s1);
      final Comparable<T> s2Value = getField(s2);
      return Comparable.compare(s1Value, s2Value);
    });
    notifyListeners();
  }
}

class LanTable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<LanTable> {

  Uint8List uploadFile;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LanTable"),
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(20),
            child: IconButton(icon: Icon(Icons.file_download), onPressed: (){
//              testDownload();
              _startFilePicker();
            }),
          ),
          Expanded(
              child: _isLoading?
              Center(child: CircularProgressIndicator()):
              getPaginatedDataTable()
          )
        ],
      )

    );
  }

  //默认的行数
  int _defalutRowPageCount = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex;
  bool _sortAscending = true;
  MyTable table = MyTable();

  //排序关联_sortColumnIndex,_sortAscending
  void _sort<T>(Comparable<T> getField(Shop s), int index, bool b) {
    table._sort(getField, b);
    setState(() {
      this._sortColumnIndex = index;
      this._sortAscending = b;
    });
  }

  List<DataColumn> getColumn() {
    return [
      DataColumn(
          label: Text('商品名'),
          onSort: (i, b) {
            _sort<String>((Shop p) => p.name, i, b);
          }),
      DataColumn(
          label: Text('价格'),
          onSort: (i, b) {
            _sort<num>((Shop p) => p.price, i, b);
          }),
      DataColumn(
          label: Text('库存'),
          onSort: (i, b) {
            _sort<num>((Shop p) => p.number, i, b);
          }),
      DataColumn(
          label: Text('类型'),
          onSort: (i, b) {
            _sort<String>((Shop p) => p.type, i, b);
          }),
    ];
  }

  Widget getPaginatedDataTable() {
    return SingleChildScrollView(
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
        availableRowsPerPage: [5, 10],
        onPageChanged: (value) {
          print('$value');
        },
        onSelectAll: table.selectAll,
        header: Text('商品库存'),
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
        html.FileReader reader =  html.FileReader();
        html.FileReader reader2 =  html.FileReader();
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
    for(ArchiveFile archiveFile in archive){
      if(archiveFile.isFile){
        print("isFile-->"+archiveFile.name);
      }else{
        print("isDiretory-->"+archiveFile.name);
//        unzip(archiveFile.content);
      }
    }
  }
}
